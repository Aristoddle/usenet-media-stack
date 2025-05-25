#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/manage.zsh
# Project: Usenet Media Stack
# Description: Service management commands (start, stop, restart, logs)
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module provides service management functionality, replacing the legacy
# manage.sh script with a clean, modular implementation. It handles starting,
# stopping, restarting services, viewing logs, and performing updates.
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Get script directory and load common functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR:h}/core/common.zsh" || {
    print -u2 "ERROR: Cannot load common.zsh"
    exit 1
}
source "${SCRIPT_DIR:h}/core/init.zsh" || {
    print -u2 "ERROR: Cannot load init.zsh"
    exit 1
}

# Load configuration
load_stack_config >/dev/null 2>&1 || true

##############################################################################
#                          DOCKER DAEMON MANAGEMENT                          #
##############################################################################

#=============================================================================
# Function: start_docker_daemon
# Description: Attempt to start Docker daemon based on platform
#
# Detects the platform and uses appropriate method to start Docker.
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker started or already running
#   1 - Failed to start Docker
#
# Example:
#   start_docker_daemon || die "Cannot start Docker"
#=============================================================================
start_docker_daemon() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux)
            # Try systemd first
            if command -v systemctl >/dev/null 2>&1; then
                if sudo systemctl start docker 2>/dev/null; then
                    sleep 3
                    return 0
                fi
            fi
            
            # Try init.d
            if command -v service >/dev/null 2>&1; then
                if sudo service docker start 2>/dev/null; then
                    sleep 3
                    return 0
                fi
            fi
            
            return 1
            ;;
            
        Darwin)
            # macOS - try to open Docker Desktop
            if command -v open >/dev/null 2>&1; then
                open -a Docker 2>/dev/null
                
                # Wait up to 30 seconds for Docker to start
                local attempts=0
                while (( attempts < 30 )); do
                    if docker info >/dev/null 2>&1; then
                        return 0
                    fi
                    sleep 1
                    ((attempts++))
                done
            fi
            
            return 1
            ;;
            
        *)
            # Unknown platform
            return 1
            ;;
    esac
}

#=============================================================================
# Function: check_docker_status
# Description: Check Docker daemon status and provide helpful info
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker is running
#   1 - Docker is not running
#
# Example:
#   check_docker_status
#=============================================================================
check_docker_status() {
    print "${COLOR_BOLD}Docker Status${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if docker info >/dev/null 2>&1; then
        success "Docker daemon is running"
        
        # Show version info
        local docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,$//')
        local compose_version=$(docker compose version 2>/dev/null | cut -d' ' -f4 || echo "not available")
        
        print "Docker: $docker_version"
        print "Compose: $compose_version"
        
        # Show container count
        local container_count=$(docker ps -q | wc -l)
        print "Running containers: $container_count"
        
        return 0
    else
        warning "Docker daemon is not running"
        
        local platform=$(uname -s)
        print "Platform: $platform"
        
        case "$platform" in
            Linux)
                print "To start: sudo systemctl start docker"
                ;;
            Darwin)
                print "To start: Open Docker Desktop application"
                ;;
            *)
                print "Please start Docker daemon manually"
                ;;
        esac
        
        return 1
    fi
}

##############################################################################
#                            SERVICE OPERATIONS                              #
##############################################################################

#=============================================================================
# Function: start_services
# Description: Start all or specific services
#
# Starts Docker services using docker-compose. Can start all services or
# a specific service by name.
#
# Arguments:
#   $1 - Service name (optional, starts all if omitted)
#
# Returns:
#   0 - Services started successfully
#   1 - Failed to start services
#
# Example:
#   start_services          # Start all services
#   start_services sonarr   # Start only sonarr
#=============================================================================
start_services() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        info "Starting $service..."
        if docker compose up -d "$service"; then
            success "$service started"
            return 0
        else
            error "Failed to start $service"
            return 1
        fi
    else
        info "Starting all services..."
        if docker compose up -d; then
            success "All services started"
            
            # Show status
            print "\n${COLOR_BOLD}Service Status:${COLOR_RESET}"
            docker compose ps --format "table {{.Service}}\t{{.Status}}" | head -20
            
            return 0
        else
            error "Failed to start services"
            return 1
        fi
    fi
}

#=============================================================================
# Function: stop_services
# Description: Stop all or specific services
#
# Stops Docker services gracefully. Can stop all services or a specific
# service by name.
#
# Arguments:
#   $1 - Service name (optional, stops all if omitted)
#
# Returns:
#   0 - Services stopped successfully
#   1 - Failed to stop services
#
# Example:
#   stop_services          # Stop all services
#   stop_services radarr   # Stop only radarr
#=============================================================================
stop_services() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        info "Stopping $service..."
        if docker compose stop "$service"; then
            success "$service stopped"
            return 0
        else
            error "Failed to stop $service"
            return 1
        fi
    else
        info "Stopping all services..."
        if docker compose stop; then
            success "All services stopped"
            return 0
        else
            error "Failed to stop services"
            return 1
        fi
    fi
}

#=============================================================================
# Function: restart_services
# Description: Restart all or specific services
#
# Performs a graceful restart of Docker services. Can restart all services
# or a specific service by name.
#
# Arguments:
#   $1 - Service name (optional, restarts all if omitted)
#
# Returns:
#   0 - Services restarted successfully
#   1 - Failed to restart services
#
# Example:
#   restart_services          # Restart all services
#   restart_services bazarr   # Restart only bazarr
#=============================================================================
restart_services() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        info "Restarting $service..."
        if docker compose restart "$service"; then
            success "$service restarted"
            return 0
        else
            error "Failed to restart $service"
            return 1
        fi
    else
        info "Restarting all services..."
        if docker compose restart; then
            success "All services restarted"
            
            # Show status after restart
            sleep 5
            print "\n${COLOR_BOLD}Service Status:${COLOR_RESET}"
            docker compose ps --format "table {{.Service}}\t{{.Status}}" | head -20
            
            return 0
        else
            error "Failed to restart services"
            return 1
        fi
    fi
}

#=============================================================================
# Function: show_logs
# Description: Display logs for services
#
# Shows Docker container logs with optional tail and follow modes.
#
# Arguments:
#   $1 - Service name (optional, shows all if omitted)
#   $2 - Additional docker logs options
#
# Returns:
#   0 - Always (logs command doesn't fail)
#
# Example:
#   show_logs              # Show all logs
#   show_logs sonarr       # Show sonarr logs
#   show_logs sonarr -f    # Follow sonarr logs
#=============================================================================
show_logs() {
    local service="${1:-}"
    shift
    local opts=("$@")
    
    # Default options if none provided
    if [[ ${#opts[@]} -eq 0 ]]; then
        opts=("--tail" "100")
    fi
    
    if [[ -n "$service" ]]; then
        info "Showing logs for $service..."
        docker compose logs "${opts[@]}" "$service"
    else
        info "Showing logs for all services..."
        docker compose logs "${opts[@]}"
    fi
}

#=============================================================================
# Function: show_status
# Description: Display status of all services
#
# Shows detailed status information for all running services including
# health checks, resource usage, and uptime.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   show_status
#=============================================================================
show_status() {
    print "${COLOR_BOLD}Service Status Overview${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check Docker connectivity first
    if ! docker info >/dev/null 2>&1; then
        warning "Docker daemon not running - attempting to start..."
        
        if start_docker_daemon; then
            success "Docker started successfully"
        else
            error "Failed to start Docker daemon"
            info "Manual start required:"
            info "  • macOS/Windows: Open Docker Desktop"
            info "  • Linux: sudo systemctl start docker"
            return 1
        fi
    fi
    
    # Basic status table
    docker compose ps
    
    print "\n${COLOR_BOLD}Resource Usage${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show resource usage
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -20
    
    print "\n${COLOR_BOLD}Service URLs${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Use SERVICE_URLS from environment configuration
    # (Already loaded by init.zsh)
    
    for service url in ${(kv)SERVICE_URLS}; do
        if docker compose ps -q "$service" 2>/dev/null | grep -q .; then
            print "  ${COLOR_GREEN}●${COLOR_RESET} $service: $url"
        else
            print "  ${COLOR_RED}●${COLOR_RESET} $service: $url (not running)"
        fi
    done
}

#=============================================================================
# Function: update_services
# Description: Update service containers to latest images
#
# Pulls latest Docker images and recreates containers with new versions.
#
# Arguments:
#   $1 - Service name (optional, updates all if omitted)
#
# Returns:
#   0 - Update successful
#   1 - Update failed
#
# Example:
#   update_services         # Update all services
#   update_services sonarr  # Update only sonarr
#=============================================================================
update_services() {
    local service="${1:-}"
    
    if [[ -n "$service" ]]; then
        info "Updating $service..."
        
        # Pull latest image
        if docker compose pull "$service"; then
            success "Downloaded latest $service image"
            
            # Recreate container
            if docker compose up -d "$service"; then
                success "$service updated successfully"
                return 0
            else
                error "Failed to recreate $service container"
                return 1
            fi
        else
            error "Failed to pull $service image"
            return 1
        fi
    else
        info "Updating all services..."
        
        # Pull all images
        if docker compose pull; then
            success "Downloaded latest images"
            
            # Recreate containers
            if docker compose up -d; then
                success "All services updated successfully"
                
                # Clean up old images
                info "Cleaning up old images..."
                docker image prune -f
                
                return 0
            else
                error "Failed to recreate containers"
                return 1
            fi
        else
            error "Failed to pull images"
            return 1
        fi
    fi
}

#=============================================================================
# Function: backup_configs
# Description: Backup service configurations
#
# Creates a timestamped backup of all service configuration files.
#
# Arguments:
#   $1 - Backup destination (optional, uses default if omitted)
#
# Returns:
#   0 - Backup successful
#   1 - Backup failed
#
# Example:
#   backup_configs                    # Use default location
#   backup_configs /mnt/backup/       # Custom location
#=============================================================================
backup_configs() {
    local dest="${1:-$PROJECT_ROOT/backups}"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$dest/usenet_backup_$timestamp.tar.gz"
    
    # Create backup directory
    mkdir -p "$dest"
    
    info "Creating configuration backup..."
    
    # Create backup
    if tar -czf "$backup_file" \
        -C "$PROJECT_ROOT" \
        config/ \
        .env \
        docker-compose.yml \
        docker-compose.*.yml 2>/dev/null; then
        
        success "Backup created: $backup_file"
        
        # Show backup size
        local size=$(du -h "$backup_file" | cut -f1)
        info "Backup size: $size"
        
        return 0
    else
        error "Failed to create backup"
        return 1
    fi
}

##############################################################################
#                              MAIN HANDLER                                  #
##############################################################################

#=============================================================================
# Function: main
# Description: Main entry point for manage commands
#
# Handles command routing for all management operations.
#
# Arguments:
#   $1 - Subcommand (start, stop, restart, logs, status, update, backup)
#   $@ - Additional arguments
#
# Returns:
#   0 - Command successful
#   1 - Command failed
#
# Example:
#   main start
#   main logs sonarr -f
#=============================================================================
main() {
    local cmd="${1:-status}"
    shift
    
    case "$cmd" in
        start)
            start_services "$@"
            ;;
            
        stop)
            stop_services "$@"
            ;;
            
        restart)
            restart_services "$@"
            ;;
            
        logs)
            show_logs "$@"
            ;;
            
        status)
            show_status
            ;;
            
        update)
            update_services "$@"
            ;;
            
        backup)
            backup_configs "$@"
            ;;
            
        docker)
            check_docker_status
            ;;
            
        *)
            error "Unknown command: $cmd"
            print "\nAvailable commands:"
            print "  start [service]    - Start services"
            print "  stop [service]     - Stop services"
            print "  restart [service]  - Restart services"
            print "  logs [service]     - Show logs"
            print "  status            - Show service status"
            print "  update [service]  - Update to latest images"
            print "  backup [path]     - Backup configurations"
            print "  docker            - Check Docker daemon status"
            return 1
            ;;
    esac
}

# Run main function
main "$@"

# vim: set ts=4 sw=4 et tw=80: