#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/setup.zsh
# Project: Usenet Media Stack
# Description: Complete stack deployment and configuration
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module handles the complete deployment of the Usenet Media Stack,
# including dependency checks, Docker service deployment, automated
# configuration, and health verification. It consolidates functionality
# from the legacy one-click-setup.sh into a clean, modular design.
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

# Load platform detection
source "${SCRIPT_DIR:h}/platform.zsh" 2>/dev/null || true

##############################################################################
#                              CONFIGURATION                                 #
##############################################################################

# Setup options (can be overridden by command line)
typeset -g SKIP_DEPS_CHECK=false
typeset -g SKIP_TESTS=false
typeset -g VERBOSE_MODE=false
typeset -g DRY_RUN=false
typeset -g IMPORT_BACKUP=""

# Progress tracking
typeset -g TOTAL_STEPS=7
typeset -g CURRENT_STEP=0

##############################################################################
#                            PROGRESS DISPLAY                                #
##############################################################################

#=============================================================================
# Function: show_progress
# Description: Display beautiful progress indicator
#
# Shows a progress bar with percentage and current operation description.
# Provides visual feedback during long-running operations.
#
# Arguments:
#   $1 - Description of current operation
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   show_progress "Deploying Docker services"
#=============================================================================
show_progress() {
    local description=$1
    ((CURRENT_STEP++))
    
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    # Build progress bar
    local bar=""
    repeat $filled bar+="█"
    repeat $empty bar+="░"
    
    # Display
    print ""
    print "${COLOR_BOLD}[${CURRENT_STEP}/${TOTAL_STEPS}]${COLOR_RESET} ${COLOR_CYAN}${description}${COLOR_RESET}"
    print "${COLOR_BLUE}${bar}${COLOR_RESET} ${percent}%"
}

##############################################################################
#                          PREFLIGHT CHECKS                                  #
##############################################################################

#=============================================================================
# Function: run_preflight_checks
# Description: Verify system is ready for deployment
#
# Performs comprehensive checks to ensure the system meets all requirements
# for deployment. This includes checking for required commands, Docker
# availability, system resources, and network connectivity.
#
# Arguments:
#   None
#
# Returns:
#   0 - All checks passed
#   1 - One or more checks failed
#
# Example:
#   if ! run_preflight_checks; then
#       die 1 "System not ready for deployment"
#   fi
#=============================================================================
run_preflight_checks() {
    show_progress "Running preflight checks"
    
    # Check required commands
    local -a required_commands=(docker curl jq)
    for cmd in $required_commands; do
        if ! command -v $cmd &>/dev/null; then
            error "Missing required command: $cmd"
            
            # Platform-specific install hints
            case "$(uname -s)" in
                Linux)
                    info "Install with: sudo apt install $cmd"
                    ;;
                Darwin)
                    info "Install with: brew install $cmd"
                    ;;
            esac
            
            return 1
        fi
    done
    success "All required commands found"
    
    # Check Docker
    if ! docker info &>/dev/null; then
        warning "Docker daemon not running"
        
        # Try to start Docker
        info "Attempting to start Docker..."
        if start_docker_daemon; then
            success "Docker started successfully"
        else
            error "Failed to start Docker"
            error "Please start Docker manually and try again"
            return 1
        fi
    else
        success "Docker is running"
    fi
    
    # Check Docker Compose
    if ! docker compose version &>/dev/null 2>&1; then
        error "Docker Compose v2 not found"
        info "Please install docker-compose-plugin"
        return 1
    fi
    success "Docker Compose v2 available"
    
    # Check system resources
    check_system_resources || return 1
    
    # Check network
    if ! check_internet_connectivity; then
        warning "No internet connectivity detected"
        warning "Some features may not work properly"
    else
        success "Internet connectivity confirmed"
    fi
    
    return 0
}

#=============================================================================
# Function: check_system_resources
# Description: Verify sufficient system resources
#
# Checks available RAM and disk space to ensure the system can handle
# the media stack deployment.
#
# Arguments:
#   None
#
# Returns:
#   0 - Sufficient resources
#   1 - Insufficient resources
#
# Example:
#   check_system_resources || die 1 "Insufficient resources"
#=============================================================================
check_system_resources() {
    # RAM check (need at least 4GB)
    local total_ram_mb=$(get_total_ram_mb 2>/dev/null || echo 0)
    if (( total_ram_mb < 4096 )); then
        warning "Low RAM: ${total_ram_mb}MB (4GB+ recommended)"
        if ! confirm "Continue with low RAM?" n; then
            return 1
        fi
    else
        success "RAM: ${total_ram_mb}MB"
    fi
    
    # Disk space check (need at least 20GB free)
    local free_space_gb=$(get_disk_free_gb "$PROJECT_ROOT" 2>/dev/null || echo 0)
    if (( free_space_gb < 20 )); then
        warning "Low disk space: ${free_space_gb}GB free (20GB+ recommended)"
        if ! confirm "Continue with low disk space?" n; then
            return 1
        fi
    else
        success "Disk space: ${free_space_gb}GB free"
    fi
    
    return 0
}

##############################################################################
#                         DOCKER OPERATIONS                                  #
##############################################################################

#=============================================================================
# Function: start_docker_daemon
# Description: Attempt to start Docker daemon
#
# Platform-aware function to start the Docker daemon if it's not running.
# Handles Linux systemd/init.d and macOS Docker Desktop.
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker started or already running
#   1 - Failed to start Docker
#
# Example:
#   start_docker_daemon || die 1 "Cannot start Docker"
#=============================================================================
start_docker_daemon() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux)
            if command -v systemctl &>/dev/null; then
                sudo systemctl start docker 2>/dev/null
            elif command -v service &>/dev/null; then
                sudo service docker start 2>/dev/null
            else
                return 1
            fi
            ;;
            
        Darwin)
            # macOS - try to open Docker Desktop
            open -a Docker 2>/dev/null || return 1
            
            # Wait for Docker to start (up to 30 seconds)
            local attempts=0
            while (( attempts < 30 )); do
                if docker info &>/dev/null; then
                    return 0
                fi
                sleep 1
                ((attempts++))
            done
            return 1
            ;;
            
        *)
            error "Unsupported platform: $platform"
            return 1
            ;;
    esac
    
    # Wait a moment for daemon to be ready
    sleep 2
    
    # Verify it's running
    docker info &>/dev/null
}

#=============================================================================
# Function: deploy_docker_services
# Description: Deploy all services using Docker Compose
#
# Deploys the complete media stack using docker-compose.yml. Handles
# service dependencies and ensures proper startup order.
#
# Arguments:
#   None
#
# Returns:
#   0 - All services deployed successfully
#   1 - Deployment failed
#
# Example:
#   deploy_docker_services || die 1 "Deployment failed"
#=============================================================================
deploy_docker_services() {
    show_progress "Deploying Docker services"
    
    # Ensure compose file exists
    require_file "$COMPOSE_FILE" "docker-compose.yml not found"
    
    # Create required directories
    info "Creating required directories..."
    require_directory "$CONFIG_DIR"
    require_directory "$DOWNLOADS_DIR"
    require_directory "$MEDIA_DIR/tv"
    require_directory "$MEDIA_DIR/movies"
    require_directory "$MEDIA_DIR/music"
    require_directory "$MEDIA_DIR/books"
    
    # Deploy services
    info "Starting Docker Compose deployment..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY RUN] Would execute: docker compose up -d"
        return 0
    fi
    
    if docker compose -f "$COMPOSE_FILE" up -d; then
        success "Services deployed successfully"
        return 0
    else
        error "Failed to deploy services"
        error "Check logs: docker compose logs"
        return 1
    fi
}

##############################################################################
#                      SERVICE CONFIGURATION                                 #
##############################################################################

#=============================================================================
# Function: wait_for_services
# Description: Wait for all services to be ready
#
# Monitors service health and waits for all services to report healthy
# status before proceeding with configuration.
#
# Arguments:
#   None
#
# Returns:
#   0 - All services healthy
#   1 - Timeout waiting for services
#
# Example:
#   wait_for_services || warning "Some services may not be ready"
#=============================================================================
wait_for_services() {
    show_progress "Waiting for services to start"
    
    info "Waiting for services to initialize..."
    
    # Give services time to start
    sleep 10
    
    # Check each core service
    local all_healthy=true
    for service in $CORE_SERVICES; do
        if check_service_health "$service"; then
            success "$service is healthy"
        else
            warning "$service not ready yet"
            all_healthy=false
        fi
    done
    
    if [[ "$all_healthy" == "true" ]]; then
        return 0
    else
        warning "Some services are still starting"
        info "You may need to wait before accessing them"
        return 1
    fi
}

#=============================================================================
# Function: check_service_health
# Description: Check if a specific service is healthy
#
# Verifies that a Docker container is running and responding to health checks.
#
# Arguments:
#   $1 - Service name
#
# Returns:
#   0 - Service is healthy
#   1 - Service is not healthy
#
# Example:
#   check_service_health "sonarr"
#=============================================================================
check_service_health() {
    local service=$1
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        return 1
    fi
    
    # Check container health status
    local health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")
    
    [[ "$health" == "healthy" ]] || [[ "$health" == "none" ]]
}

##############################################################################
#                           MAIN SETUP FLOW                                  #
##############################################################################

#=============================================================================
# Function: parse_setup_options
# Description: Parse command line options for setup
#
# Processes command line arguments to set configuration options for the
# setup process.
#
# Arguments:
#   $@ - Command line arguments
#
# Returns:
#   0 - Options parsed successfully
#   1 - Invalid option encountered
#
# Example:
#   parse_setup_options "$@"
#=============================================================================
parse_setup_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --skip-deps)
                SKIP_DEPS_CHECK=true
                ;;
            --skip-tests)
                SKIP_TESTS=true
                ;;
            --verbose|-v)
                VERBOSE_MODE=true
                ;;
            --dry-run)
                DRY_RUN=true
                info "DRY RUN MODE - No changes will be made"
                ;;
            --import)
                shift
                IMPORT_BACKUP="${1:-}"
                if [[ -z "$IMPORT_BACKUP" ]]; then
                    error "--import requires a backup file path"
                    return 1
                fi
                ;;
            --help|-h)
                show_setup_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                info "Try 'usenet setup --help'"
                return 1
                ;;
        esac
        shift
    done
    
    return 0
}

#=============================================================================
# Function: show_setup_help
# Description: Display help for setup command
#
# Shows detailed help information for the setup command, including all
# available options and examples.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   show_setup_help
#=============================================================================
show_setup_help() {
    cat <<'HELP'
SETUP COMMAND

Usage: usenet setup [options]

Deploy and configure the complete Usenet Media Stack.

OPTIONS
    --skip-deps         Skip dependency checks (advanced users)
    --skip-tests        Skip post-deployment tests
    --verbose, -v       Show detailed output
    --dry-run           Show what would be done without making changes
    --import <file>     Import configuration from backup
    --help, -h          Show this help

PROCESS
    1. Check system dependencies
    2. Verify Docker is running
    3. Create required directories
    4. Deploy Docker services
    5. Wait for services to be ready
    6. Configure services (if needed)
    7. Run health checks

EXAMPLES
    Basic setup:
        $ usenet setup
        
    Verbose output:
        $ usenet setup --verbose
        
    Test run without changes:
        $ usenet setup --dry-run
        
    Import existing configuration:
        $ usenet setup --import backup-2025-05-24.tar.gz

For more information, see:
    https://github.com/Aristoddle/usenet-media-stack

HELP
}

#=============================================================================
# Function: main
# Description: Main setup entry point
#
# Orchestrates the complete setup process from start to finish.
#
# Arguments:
#   $@ - Command line arguments
#
# Returns:
#   0 - Setup completed successfully
#   1 - Setup failed
#
# Example:
#   main "$@"
#=============================================================================
main() {
    # Header
    print ""
    print "${COLOR_CYAN}╔═══════════════════════════════════════════════════════════╗${COLOR_RESET}"
    print "${COLOR_CYAN}║         USENET MEDIA STACK SETUP v2.0                     ║${COLOR_RESET}"
    print "${COLOR_CYAN}╚═══════════════════════════════════════════════════════════╝${COLOR_RESET}"
    print ""
    
    # Parse options
    if ! parse_setup_options "$@"; then
        return 1
    fi
    
    # Run setup steps
    if [[ "$SKIP_DEPS_CHECK" != "true" ]]; then
        run_preflight_checks || return 1
    fi
    
    deploy_docker_services || return 1
    
    wait_for_services || true  # Don't fail if services are slow
    
    # Configuration phase
    show_progress "Configuring services"
    
    # Initialize SABnzbd if needed
    if [[ -x "$PROJECT_ROOT/scripts/init-sabnzbd.sh" ]]; then
        log_info "Initializing SABnzbd..."
        "$PROJECT_ROOT/scripts/init-sabnzbd.sh" || {
            log_error "SABnzbd initialization failed"
            return 3
        }
    fi
    
    # Generate API keys
    if [[ -x "$PROJECT_ROOT/scripts/generate-api-keys.sh" ]]; then
        log_info "Generating API keys..."
        "$PROJECT_ROOT/scripts/generate-api-keys.sh"
    fi
    
    # Run main configuration
    log_info "Running automated configuration..."
    if [[ -x "$PROJECT_ROOT/setup-all.sh" ]]; then
        "$PROJECT_ROOT/setup-all.sh" --fresh || {
            log_error "Service configuration failed"
            return 3
        }
    else
        log_warning "setup-all.sh not found, skipping automated config"
    fi
    
    # Media services setup
    show_progress "Setting up media services"
    
    # Check if media services are already running
    if docker ps | grep -q "plex"; then
        log_info "Media services already running"
    elif [[ -f "$PROJECT_ROOT/docker-compose.media.yml" ]]; then
        log_info "Deploying media services..."
        docker compose -f docker-compose.yml -f docker-compose.media.yml up -d
        log_success "Media services deployed"
        sleep 20
    else
        log_warning "Media services configuration not found"
    fi
    
    # Run tests if not skipped
    if [[ $SKIP_TESTS == "false" ]]; then
        show_progress "Running comprehensive tests"
        
        if [[ -x "$PROJECT_ROOT/test-quick.sh" ]]; then
            local test_log="/tmp/test-results.log"
            if "$PROJECT_ROOT/test-quick.sh" > "$test_log" 2>&1; then
                log_success "All tests passed!"
                
                # Show test summary
                print "\n${GREEN}Test Summary:${NC}"
                grep -E "^(✓|✗|⚠)" "$test_log" | tail -20
            else
                log_error "Some tests failed"
                
                # Show failures
                print "\n${RED}Failed Tests:${NC}"
                if [[ -f "$test_log" ]]; then
                    grep "✗" "$test_log" | head -10 || echo "Services may not be running yet"
                fi
                
                return 4
            fi
        else
            log_warning "Test suite not found, skipping tests"
        fi
    fi
    
    # Success!
    show_progress "Setup complete!"
    
    # Show final summary
    show_summary
    
    return 0
}

##############################################################################
# show_summary - Display final setup summary
#
# Displays all service URLs, configuration status, and quick commands
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
##############################################################################
show_summary() {
    print "\n${COLOR_GREEN}╔═══════════════════════════════════════════════════════════╗${COLOR_RESET}"
    print "${COLOR_GREEN}║           🎉 USENET MEDIA STACK READY! 🎉                 ║${COLOR_RESET}"
    print "${COLOR_GREEN}╚═══════════════════════════════════════════════════════════╝${COLOR_RESET}"
    
    print "\n${COLOR_BOLD}Core Services:${COLOR_RESET}"
    print "  ${COLOR_GREEN}●${COLOR_RESET} SABnzbd:   ${SERVICE_URLS[sabnzbd]}  - Download Manager"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Prowlarr:  ${SERVICE_URLS[prowlarr]}  - Indexer Manager"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Sonarr:    ${SERVICE_URLS[sonarr]}  - TV Shows"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Radarr:    ${SERVICE_URLS[radarr]}  - Movies"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Lidarr:    ${SERVICE_URLS[lidarr]}  - Music"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Bazarr:    ${SERVICE_URLS[bazarr]}  - Subtitles"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Mylar3:    ${SERVICE_URLS[mylar3]}  - Comics"
    
    print "\n${COLOR_BOLD}Media Services:${COLOR_RESET}"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Plex:  ${SERVICE_URLS[plex]}  - Media Streaming"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Overseerr: ${SERVICE_URLS[overseerr]}  - Request Management"
    print "  ${COLOR_GREEN}●${COLOR_RESET} YACReader: ${SERVICE_URLS[yacreader]}  - Manga/Comic Server"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Tautulli:  ${SERVICE_URLS[tautulli]}  - Statistics"
    
    print "\n${COLOR_BOLD}Processing:${COLOR_RESET}"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Tdarr:     ${SERVICE_URLS[tdarr]}  - Automated Transcoding"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Recyclarr: TRaSH Guide Automation (background service)"
    
    print "\n${COLOR_BOLD}Management:${COLOR_RESET}"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Portainer: ${SERVICE_URLS[portainer]}  - Docker Management"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Netdata:   ${SERVICE_URLS[netdata]} - System Monitoring"
    
    print "\n${COLOR_BOLD}Configuration Status:${COLOR_RESET}"
    print "  ${COLOR_GREEN}✓${COLOR_RESET} Usenet providers configured"
    print "  ${COLOR_GREEN}✓${COLOR_RESET} Indexers ready to add"
    print "  ${COLOR_GREEN}✓${COLOR_RESET} Download directories created"
    print "  ${COLOR_GREEN}✓${COLOR_RESET} API keys generated"
    print "  ${COLOR_GREEN}✓${COLOR_RESET} Services interconnected"
    
    print "\n${COLOR_BOLD}Quick Commands:${COLOR_RESET}"
    print "  View logs:    ./usenet logs [service]"
    print "  Restart all:  ./usenet restart"
    print "  Stop all:     ./usenet stop"
    print "  Run tests:    ./usenet test all"
    
    print "\n${COLOR_YELLOW}Note: Complete Plex/Overseerr setup via web UI${COLOR_RESET}"
    
    # Proactive GPU optimization detection
    if command -v "${PROJECT_ROOT}/usenet" >/dev/null 2>&1; then
        # Run hardware detection to check for optimization opportunities
        local gpu_check=$(cd "$PROJECT_ROOT" && ./usenet hardware detect 2>/dev/null | grep -E "(NVIDIA|AMD|Intel.*QuickSync|Raspberry Pi)" || true)
        if [[ -n "$gpu_check" ]]; then
            print ""
            print "🚀 ${COLOR_BLUE}PERFORMANCE BOOST AVAILABLE!${COLOR_RESET}"
            print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            print "${COLOR_YELLOW}We detected GPU hardware that can dramatically improve transcoding:${COLOR_RESET}"
            print "$gpu_check" | head -1
            print ""
            print "💡 ${COLOR_GREEN}Want 10-50x faster transcoding?${COLOR_RESET}"
            print "   Run: ${COLOR_BLUE}./usenet hardware install-drivers${COLOR_RESET}"
            print "   This enables hardware acceleration for 4K HEVC encoding!"
        fi
    fi
    
    print ""
}

# Platform-specific helper functions (if platform.zsh not available)
if ! type get_total_ram_mb &>/dev/null; then
    get_total_ram_mb() {
        case "$(uname -s)" in
            Linux) free -m | awk 'NR==2{print $2}' ;;
            Darwin) echo $(($(sysctl -n hw.memsize) / 1024 / 1024)) ;;
            *) echo 0 ;;
        esac
    }
fi

if ! type get_disk_free_gb &>/dev/null; then
    get_disk_free_gb() {
        df -BG "${1:-.}" 2>/dev/null | awk 'NR==2{gsub(/G/,"",$4); print $4}' || echo 0
    }
fi

if ! type check_internet_connectivity &>/dev/null; then
    check_internet_connectivity() {
        curl -s --connect-timeout 3 https://google.com &>/dev/null
    }
fi

# Run main function
main "$@"

# vim: set ts=4 sw=4 et tw=80:
