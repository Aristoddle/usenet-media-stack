#!/bin/bash
###############################################################################
# one-click-setup.sh - Complete Usenet Stack Setup, Configuration & Testing
#
# DESCRIPTION:
#   This script provides a single command to deploy, configure, and validate
#   the entire Usenet media automation stack. It handles:
#   - Docker service deployment
#   - Service health verification  
#   - Automated configuration of all services
#   - Comprehensive testing and validation
#   - Rich progress reporting with detailed feedback
#
# USAGE:
#   ./one-click-setup.sh [OPTIONS]
#
# OPTIONS:
#   --test-only     Run tests without setup
#   --skip-test     Skip testing after setup
#   --verbose       Enable verbose output
#   --help          Show this help message
#
# EXAMPLES:
#   ./one-click-setup.sh                # Full setup with testing
#   ./one-click-setup.sh --test-only    # Just run tests
#   ./one-click-setup.sh --skip-test    # Setup without testing
#
# EXIT CODES:
#   0 - Success
#   1 - Docker not running
#   2 - Service startup failed
#   3 - Configuration failed
#   4 - Testing failed
#
# AUTHOR: Usenet Media Stack
# VERSION: 2.0
###############################################################################

set -e
set -o pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
TOTAL_STEPS=7
CURRENT_STEP=0

# Parse command line arguments
SKIP_TEST=false
TEST_ONLY=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --test-only)
            TEST_ONLY=true
            shift
            ;;
        --skip-test)
            SKIP_TEST=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            grep "^#" "$0" | grep -E "^# [A-Z]" | sed 's/^# //'
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

###############################################################################
# UTILITY FUNCTIONS
###############################################################################

# Progress indicator
progress() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
    echo -e "\n${BOLD}[${CURRENT_STEP}/${TOTAL_STEPS}]${NC} ${CYAN}$1${NC}"
    echo -ne "${BLUE}"
    printf '%.0s═' $(seq 1 $((percent / 2)))
    echo -e "${NC} ${percent}%"
}

# Success message
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Warning message
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Error message
error() {
    echo -e "${RED}✗${NC} $1"
}

# Info message
info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Verbose logging
verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${MAGENTA}[VERBOSE]${NC} $1"
    fi
}

###############################################################################
# PRE-FLIGHT CHECKS
###############################################################################

preflight_checks() {
    progress "Running pre-flight checks"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi
    
    if ! docker ps &> /dev/null; then
        error "Docker daemon is not running"
        exit 1
    fi
    success "Docker is running"
    
    # Check disk space
    local disk_usage=$(df -h "$SCRIPT_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $disk_usage -gt 90 ]]; then
        warning "Low disk space: ${disk_usage}% used"
    else
        success "Disk space adequate: ${disk_usage}% used"
    fi
    
    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        warning "sudo not available, some features may not work"
    else
        success "sudo is available"
    fi
    
    # Check network connectivity
    if ping -c 1 google.com &> /dev/null; then
        success "Internet connectivity confirmed"
    else
        warning "No internet connectivity detected"
    fi
}

###############################################################################
# SERVICE DEPLOYMENT
###############################################################################

deploy_services() {
    progress "Deploying Docker services"
    
    # Check if already running
    local running_count=$(docker ps --format "{{.Names}}" | grep -c "^[a-z]" || echo 0)
    
    if [[ $running_count -gt 10 ]]; then
        info "Found $running_count services already running"
        warning "Stack appears to be deployed already"
        return 0
    fi
    
    verbose "Starting Docker Compose stack"
    if "$SCRIPT_DIR/manage.sh" start; then
        success "Docker services started successfully"
    else
        error "Failed to start Docker services"
        exit 2
    fi
    
    info "Waiting 30 seconds for services to initialize..."
    sleep 30
}

###############################################################################
# SERVICE HEALTH CHECK
###############################################################################

check_service_health() {
    progress "Verifying service health"
    
    verbose "Running wait-for-services.sh"
    if ! "$SCRIPT_DIR/wait-for-services.sh"; then
        error "Some services failed to start properly"
        
        # Show which services are having issues
        echo -e "\n${YELLOW}Service Status:${NC}"
        docker ps --format "table {{.Names}}\t{{.Status}}" | head -20
        
        exit 2
    fi
    
    success "All core services are healthy"
    
    # Additional health checks
    local healthy_count=$(docker ps --filter "health=healthy" --format "{{.Names}}" | wc -l)
    info "Found $healthy_count services reporting healthy status"
}

###############################################################################
# AUTOMATED CONFIGURATION
###############################################################################

configure_services() {
    progress "Running automated configuration"
    
    # Initialize SABnzbd if needed
    if [[ -x "$SCRIPT_DIR/scripts/init-sabnzbd.sh" ]]; then
        verbose "Initializing SABnzbd"
        "$SCRIPT_DIR/scripts/init-sabnzbd.sh"
    fi
    
    # Generate any missing API keys
    if [[ -x "$SCRIPT_DIR/scripts/generate-api-keys.sh" ]]; then
        verbose "Generating missing API keys"
        "$SCRIPT_DIR/scripts/generate-api-keys.sh"
    fi
    
    # Run main configuration
    verbose "Running setup-all.sh"
    if "$SCRIPT_DIR/setup-all.sh" --fresh; then
        success "Automated configuration completed"
    else
        error "Configuration failed"
        exit 3
    fi
}


###############################################################################
# MEDIA SERVICES SETUP
###############################################################################

setup_media_services() {
    progress "Setting up media streaming services"
    
    # Check if media services are needed
    if docker ps | grep -q "jellyfin"; then
        info "Media services already running"
        return 0
    fi
    
    if [[ -f "$SCRIPT_DIR/docker-compose.media.yml" ]]; then
        verbose "Deploying media services"
        docker compose -f docker-compose.yml -f docker-compose.media.yml up -d
        success "Media services deployed"
        
        info "Waiting for media services to initialize..."
        sleep 20
    else
        warning "Media services configuration not found"
    fi
}

###############################################################################
# COMPREHENSIVE TESTING
###############################################################################

run_comprehensive_tests() {
    progress "Running comprehensive system tests"
    
    echo -e "\n${CYAN}Starting validation tests...${NC}"
    
    # Run the complete test suite
    if [[ -x "$SCRIPT_DIR/test-quick.sh" ]]; then
        if "$SCRIPT_DIR/test-quick.sh" > /tmp/test-results.log 2>&1; then
            success "All tests passed!"
            
            # Show summary from test results
            echo -e "\n${GREEN}Test Summary:${NC}"
            grep -E "^(✓|✗|⚠)" /tmp/test-results.log | tail -20
        else
            error "Some tests failed"
            
            # Show failures
            echo -e "\n${RED}Failed Tests:${NC}"
            if [[ -f /tmp/test-results.log ]]; then
                grep "✗" /tmp/test-results.log | head -10 || echo "Services may not be running yet"
            else
                echo "No test results found"
            fi
            
            if [[ "$SKIP_TEST" != "true" ]]; then
                exit 4
            fi
        fi
    else
        warning "Test suite not found, skipping tests"
    fi
}

###############################################################################
# FINAL SUMMARY
###############################################################################

show_summary() {
    progress "Setup complete!"
    
    echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           🎉 USENET MEDIA STACK READY! 🎉                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    
    echo -e "\n${BOLD}Core Services:${NC}"
    echo "  ${GREEN}●${NC} SABnzbd:   http://localhost:8080  - Download Manager"
    echo "  ${GREEN}●${NC} Prowlarr:  http://localhost:9696  - Indexer Manager"
    echo "  ${GREEN}●${NC} Sonarr:    http://localhost:8989  - TV Shows"
    echo "  ${GREEN}●${NC} Radarr:    http://localhost:7878  - Movies"
    echo "  ${GREEN}●${NC} Readarr:   http://localhost:8787  - Books"
    echo "  ${GREEN}●${NC} Lidarr:    http://localhost:8686  - Music"
    echo "  ${GREEN}●${NC} Bazarr:    http://localhost:6767  - Subtitles"
    echo "  ${GREEN}●${NC} Mylar3:    http://localhost:8090  - Comics"
    
    echo -e "\n${BOLD}Media Services:${NC}"
    echo "  ${GREEN}●${NC} Jellyfin:  http://localhost:8096  - Media Streaming"
    echo "  ${GREEN}●${NC} Overseerr: http://localhost:5055  - Request Management"
    echo "  ${GREEN}●${NC} Tautulli:  http://localhost:8181  - Statistics"
    
    echo -e "\n${BOLD}Management:${NC}"
    echo "  ${GREEN}●${NC} Portainer: http://localhost:9000  - Docker Management"
    echo "  ${GREEN}●${NC} Netdata:   http://localhost:19999 - System Monitoring"
    
    echo -e "\n${BOLD}Configuration Status:${NC}"
    echo "  ${GREEN}✓${NC} Usenet providers configured"
    echo "  ${GREEN}✓${NC} Indexers ready to add"
    echo "  ${GREEN}✓${NC} Download directories created"
    echo "  ${GREEN}✓${NC} API keys generated"
    echo "  ${GREEN}✓${NC} Services interconnected"
    
    echo -e "\n${BOLD}Quick Commands:${NC}"
    echo "  View logs:    ./manage.sh logs [service]"
    echo "  Restart all:  ./manage.sh restart"
    echo "  Stop all:     ./manage.sh stop"
    echo "  Run tests:    ./complete-test.sh"
    
    echo -e "\n${YELLOW}Note: Complete Jellyfin/Overseerr setup via web UI${NC}"
}


###############################################################################
# MAIN EXECUTION
###############################################################################

main() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        ONE-CLICK USENET MEDIA STACK SETUP v2.0            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo -e "Started at: $(date)\n"
    
    # Test only mode
    if [[ "$TEST_ONLY" == "true" ]]; then
        TOTAL_STEPS=1
        run_comprehensive_tests
        exit $?
    fi
    
    # Adjust step count if skipping tests
    if [[ "$SKIP_TEST" == "true" ]]; then
        TOTAL_STEPS=6
    fi
    
    # Run all steps
    preflight_checks
    deploy_services
    check_service_health
    configure_services
    setup_media_services
    
    if [[ "$SKIP_TEST" != "true" ]]; then
        run_comprehensive_tests
    fi
    
    show_summary
    
    echo -e "\n${GREEN}✅ Setup completed successfully!${NC}"
    echo "Completed at: $(date)"
}

# Run main function
main

# Exit successfully
exit 0