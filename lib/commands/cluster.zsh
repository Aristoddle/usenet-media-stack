#!/usr/bin/env zsh
#=============================================================================
# cluster.zsh - Cluster management and cleanup utilities
# Part of Usenet Media Stack v1.0
#
# Provides tools to:
# - Detect running media stack instances (Docker, systemd, native)
# - Clean up orphaned services and port conflicts
# - Manage multiple stack deployments on same system
# - Validate cluster state before deployment
#=============================================================================

# Load core utilities
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../core/common.zsh" 2>/dev/null || {
    echo "Error: Cannot load common utilities" >&2
    exit 1
}

#=============================================================================
# Function: detect_media_services
# Description: Detect all running media stack services on the system
# Arguments: None
# Returns: 0 on success, 1 on error
#=============================================================================
detect_media_services() {
    local -A media_ports=(
        [8989]="sonarr"
        [7878]="radarr"  
        [8096]="jellyfin"
        [5055]="overseerr"
        [9000]="portainer"
        [8080]="sabnzbd"
        [9696]="prowlarr"
        [6969]="whisparr"
        [6767]="bazarr"
        [8265]="tdarr"
        [9092]="transmission"
        [19999]="netdata"
        [8082]="yacreader"
        [8090]="mylar"
    )
    
    info "🔍 Scanning system for media stack services..."
    echo
    
    local found_services=0
    local docker_services=()
    local system_services=()
    local unknown_processes=()
    
    # Check each known media service port
    for port service in ${(kv)media_ports}; do
        if ss -tlnp | grep -q ":${port} "; then
            found_services=$((found_services + 1))
            
            # Try to identify the source
            local process_info=$(ss -tlnp | grep ":${port} " | head -1)
            
            # Check if it's a Docker container
            if docker ps --format "table {{.Names}}\t{{.Ports}}" | grep -q ":${port}->"; then
                local container=$(docker ps --format "table {{.Names}}\t{{.Ports}}" | grep ":${port}->" | awk '{print $1}')
                docker_services+=("${port}:${service}:docker:${container}")
                success "✓ ${service} (port ${port}) - Docker container: ${container}"
            else
                # Check if it's a systemd service
                if systemctl is-active --quiet "${service}" 2>/dev/null; then
                    system_services+=("${port}:${service}:systemd")
                    warning "⚠ ${service} (port ${port}) - Systemd service"
                else
                    unknown_processes+=("${port}:${service}:unknown")
                    warning "❓ ${service} (port ${port}) - Unknown process"
                fi
            fi
        fi
    done
    
    echo
    if [[ $found_services -eq 0 ]]; then
        success "✅ No media stack services detected - ports are available"
        return 0
    fi
    
    warning "🚨 Found ${found_services} media stack service(s) already running"
    echo
    
    # Provide detailed breakdown
    if [[ ${#docker_services[@]} -gt 0 ]]; then
        echo "📦 Docker containers:"
        for service in "${docker_services[@]}"; do
            local port=$(echo "$service" | cut -d: -f1)
            local name=$(echo "$service" | cut -d: -f2)
            local container=$(echo "$service" | cut -d: -f4)
            echo "   • ${name} on port ${port} (container: ${container})"
        done
        echo
    fi
    
    if [[ ${#system_services[@]} -gt 0 ]]; then
        echo "🔧 System services:"
        for service in "${system_services[@]}"; do
            local port=$(echo "$service" | cut -d: -f1)
            local name=$(echo "$service" | cut -d: -f2)
            echo "   • ${name} on port ${port} (systemd service)"
        done
        echo
    fi
    
    if [[ ${#unknown_processes[@]} -gt 0 ]]; then
        echo "❓ Unknown processes:"
        for service in "${unknown_processes[@]}"; do
            local port=$(echo "$service" | cut -d: -f1)
            local name=$(echo "$service" | cut -d: -f2)
            echo "   • ${name} on port ${port} (unknown source)"
        done
        echo
    fi
    
    return 1
}

#=============================================================================
# Function: cleanup_docker_stack
# Description: Clean up Docker-based media stack deployments
# Arguments: None
# Returns: 0 on success, 1 on error
#=============================================================================
cleanup_docker_stack() {
    info "🧹 Cleaning up Docker-based media stack..."
    
    # Check for running Docker Compose project
    if docker compose ps -q 2>/dev/null | grep -q .; then
        warning "Found active Docker Compose services"
        info "Stopping Docker Compose stack..."
        docker compose down --remove-orphans || {
            error "Failed to stop Docker Compose stack"
            return 1
        }
        success "Docker Compose stack stopped"
    fi
    
    # Check for orphaned containers with media stack names
    local media_containers=(
        "sonarr" "radarr" "jellyfin" "overseerr" "portainer"
        "sabnzbd" "prowlarr" "whisparr" "bazarr" 
        "tdarr" "transmission" "netdata" "yacreader" "mylar"
        "recyclarr" "samba" "nfs-server"
    )
    
    local found_orphans=()
    for container_name in "${media_containers[@]}"; do
        if docker ps -a --format "{{.Names}}" | grep -q "^${container_name}\$"; then
            found_orphans+=("$container_name")
        fi
    done
    
    if [[ ${#found_orphans[@]} -gt 0 ]]; then
        warning "Found ${#found_orphans[@]} orphaned media containers"
        info "Removing orphaned containers: ${found_orphans[*]}"
        
        for container in "${found_orphans[@]}"; do
            info "Removing container: $container"
            docker rm -f "$container" 2>/dev/null || true
        done
        
        success "Orphaned containers removed"
    fi
    
    # Clean up unused networks
    local media_networks=$(docker network ls --format "{{.Name}}" | grep -E "(media|usenet|arr)")
    if [[ -n "$media_networks" ]]; then
        info "Cleaning up media-related Docker networks..."
        echo "$media_networks" | while read -r network; do
            docker network rm "$network" 2>/dev/null || true
        done
    fi
    
    # Clean up unused volumes
    info "Pruning unused Docker volumes..."
    docker volume prune -f >/dev/null 2>&1 || true
    
    success "✅ Docker cleanup completed"
    return 0
}

#=============================================================================
# Function: cleanup_system_services  
# Description: Clean up systemd-based media services
# Arguments: None
# Returns: 0 on success, 1 on error
#=============================================================================
cleanup_system_services() {
    info "🔧 Checking for systemd media services..."
    
    local media_services=(
        "sonarr" "radarr" "jellyfin" "overseerr" 
        "sabnzbd" "prowlarr" "whisparr" "bazarr"
        "transmission" "netdata"
    )
    
    local found_services=()
    for service in "${media_services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            found_services+=("$service")
        fi
    done
    
    if [[ ${#found_services[@]} -eq 0 ]]; then
        success "✅ No systemd media services found"
        return 0
    fi
    
    warning "Found ${#found_services[@]} active systemd services: ${found_services[*]}"
    
    if [[ "$fix_issues" == "true" ]]; then
        info "Stopping systemd services..."
        for service in "${found_services[@]}"; do
            info "Stopping $service..."
            sudo systemctl stop "$service" || {
                warning "Failed to stop $service (may require manual intervention)"
            }
        done
        success "Systemd services stopped"
    else
        info "Use --fix flag to automatically stop these services"
        info "Or manually stop them with: sudo systemctl stop <service>"
    fi
    
    return 0
}

#=============================================================================
# Function: suggest_ports
# Description: Suggest alternative ports for deployment when conflicts exist
# Arguments: None  
# Returns: 0 on success
#=============================================================================
suggest_ports() {
    info "💡 Suggested alternative port configuration for testing:"
    echo
    echo "Create docker-compose.ports.yml with these overrides:"
    echo "services:"
    echo "  sonarr:"
    echo "    ports:"
    echo "      - \"20989:8989\""
    echo "  radarr:"
    echo "    ports:"
    echo "      - \"20878:7878\""
    echo "  jellyfin:"
    echo "    ports:"
    echo "      - \"20096:8096\""
    echo "  overseerr:"
    echo "    ports:"
    echo "      - \"20055:5055\""
    echo "  # ... (add other services as needed)"
    echo
    echo "Then deploy with:"
    echo "  docker compose -f docker-compose.yml -f docker-compose.ports.yml up -d"
    echo
}

#=============================================================================
# Main command handler
#=============================================================================
main() {
    local action="$1"
    shift
    
    # Parse flags
    local fix_issues=false
    while [[ $# -gt 0 ]]; do
        case $1 in
            --fix)
                fix_issues=true
                shift
                ;;
            --help|-h)
                show_help
                return 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                return 1
                ;;
        esac
    done
    
    case "$action" in
        detect|scan)
            detect_media_services
            ;;
        cleanup)
            if ! detect_media_services; then
                echo
                cleanup_docker_stack
                cleanup_system_services
                echo
                info "🎉 Cleanup completed! Ports should now be available for deployment."
            else
                success "✅ No cleanup needed - system is ready for deployment"
            fi
            ;;
        docker-cleanup)
            cleanup_docker_stack
            ;;
        system-cleanup)
            cleanup_system_services
            ;;
        suggest-ports)
            suggest_ports
            ;;
        *)
            error "Unknown action: $action"
            show_help
            return 1
            ;;
    esac
}

#=============================================================================
# Function: show_help
# Description: Display help information for cluster command
#=============================================================================
show_help() {
    cat << 'EOF'
🧹 Cluster Management & Cleanup

USAGE
    usenet cluster <action> [options]

ACTIONS
    detect              Scan system for running media stack services
    cleanup             Clean up all detected media services (Docker + systemd)  
    docker-cleanup      Clean up only Docker containers and networks
    system-cleanup      Clean up only systemd services
    suggest-ports       Suggest alternative ports for testing

OPTIONS
    --fix               Automatically fix issues (stop services, remove containers)
    --help, -h          Show this help

EXAMPLES
    Scan for conflicts:
        $ usenet cluster detect
        
    Clean up everything:
        $ usenet cluster cleanup --fix
        
    Docker cleanup only:
        $ usenet cluster docker-cleanup
        
    Get port suggestions:
        $ usenet cluster suggest-ports

NOTES
    • Detection identifies Docker containers, systemd services, and unknown processes
    • Cleanup operations are safe and only affect media stack services
    • Use --fix flag to automatically resolve conflicts
    • System service cleanup may require sudo permissions

This tool prevents port conflicts and ensures clean deployments.
EOF
}

# Execute main function with all arguments
main "$@"
