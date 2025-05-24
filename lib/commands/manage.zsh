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
        log_info "Starting $service..."
        if docker compose up -d "$service"; then
            log_success "$service started"
            return 0
        else
            log_error "Failed to start $service"
            return 1
        fi
    else
        log_info "Starting all services..."
        if docker compose up -d; then
            log_success "All services started"
            
            # Show status
            print "\n${COLOR_BOLD}Service Status:${COLOR_RESET}"
            docker compose ps --format "table {{.Service}}\t{{.Status}}" | head -20
            
            return 0
        else
            log_error "Failed to start services"
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
        log_info "Stopping $service..."
        if docker compose stop "$service"; then
            log_success "$service stopped"
            return 0
        else
            log_error "Failed to stop $service"
            return 1
        fi
    else
        log_info "Stopping all services..."
        if docker compose stop; then
            log_success "All services stopped"
            return 0
        else
            log_error "Failed to stop services"
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
        log_info "Restarting $service..."
        if docker compose restart "$service"; then
            log_success "$service restarted"
            return 0
        else
            log_error "Failed to restart $service"
            return 1
        fi
    else
        log_info "Restarting all services..."
        if docker compose restart; then
            log_success "All services restarted"
            
            # Show status after restart
            sleep 5
            print "\n${COLOR_BOLD}Service Status:${COLOR_RESET}"
            docker compose ps --format "table {{.Service}}\t{{.Status}}" | head -20
            
            return 0
        else
            log_error "Failed to restart services"
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
        log_info "Showing logs for $service..."
        docker compose logs "${opts[@]}" "$service"
    else
        log_info "Showing logs for all services..."
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
    
    # Basic status table
    docker compose ps
    
    print "\n${COLOR_BOLD}Resource Usage${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Show resource usage
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | head -20
    
    print "\n${COLOR_BOLD}Service URLs${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Service URLs
    local -A service_urls=(
        [sabnzbd]="http://localhost:8080"
        [prowlarr]="http://localhost:9696"
        [sonarr]="http://localhost:8989"
        [radarr]="http://localhost:7878"
        [readarr]="http://localhost:8787"
        [lidarr]="http://localhost:8686"
        [bazarr]="http://localhost:6767"
        [mylar3]="http://localhost:8090"
        [jellyfin]="http://localhost:8096"
        [overseerr]="http://localhost:5055"
        [portainer]="http://localhost:9000"
    )
    
    for service url in ${(kv)service_urls}; do
        if docker compose ps -q "$service" 2>/dev/null | grep -q .; then
            print "  ${COLOR_GREEN}●${COLOR_RESET} $service: $url"
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
        log_info "Updating $service..."
        
        # Pull latest image
        if docker compose pull "$service"; then
            log_success "Downloaded latest $service image"
            
            # Recreate container
            if docker compose up -d "$service"; then
                log_success "$service updated successfully"
                return 0
            else
                log_error "Failed to recreate $service container"
                return 1
            fi
        else
            log_error "Failed to pull $service image"
            return 1
        fi
    else
        log_info "Updating all services..."
        
        # Pull all images
        if docker compose pull; then
            log_success "Downloaded latest images"
            
            # Recreate containers
            if docker compose up -d; then
                log_success "All services updated successfully"
                
                # Clean up old images
                log_info "Cleaning up old images..."
                docker image prune -f
                
                return 0
            else
                log_error "Failed to recreate containers"
                return 1
            fi
        else
            log_error "Failed to pull images"
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
    
    log_info "Creating configuration backup..."
    
    # Create backup
    if tar -czf "$backup_file" \
        -C "$PROJECT_ROOT" \
        config/ \
        .env \
        docker-compose.yml \
        docker-compose.*.yml 2>/dev/null; then
        
        log_success "Backup created: $backup_file"
        
        # Show backup size
        local size=$(du -h "$backup_file" | cut -f1)
        info "Backup size: $size"
        
        return 0
    else
        log_error "Failed to create backup"
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
            
        *)
            log_error "Unknown command: $cmd"
            print "\nAvailable commands:"
            print "  start [service]    - Start services"
            print "  stop [service]     - Stop services"
            print "  restart [service]  - Restart services"
            print "  logs [service]     - Show logs"
            print "  status            - Show service status"
            print "  update [service]  - Update to latest images"
            print "  backup [path]     - Backup configurations"
            return 1
            ;;
    esac
}

# Run main function
main "$@"

# vim: set ts=4 sw=4 et tw=80: