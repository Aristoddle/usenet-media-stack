#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/test.zsh
# Project: Usenet Media Stack
# Description: Comprehensive testing and validation suite
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module provides testing functionality for the entire stack, including
# service health checks, API validation, configuration testing, and 
# performance benchmarks. Consolidates all test-*.sh scripts.
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

# Test counters
typeset -g PASSED=0
typeset -g FAILED=0
typeset -g WARNINGS=0

##############################################################################
#                           TEST UTILITIES                                   #
##############################################################################

#=============================================================================
# Function: test_result
# Description: Display test result with consistent formatting
#
# Shows test name and result with color coding and updates counters.
#
# Arguments:
#   $1 - Test name
#   $2 - Result (pass, fail, warn, skip)
#   $3 - Message (optional)
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   test_result "Docker daemon" "pass"
#   test_result "API key" "fail" "Not found"
#=============================================================================
test_result() {
    local test_name=$1
    local result=$2
    local message="${3:-}"
    
    # Format test name with dots
    local formatted_name="${test_name:0:40}"
    local dots_count=$((45 - ${#formatted_name}))
    local dots=$(printf '.%.0s' {1..$dots_count})
    
    print -n "${formatted_name}${dots} "
    
    case "$result" in
        pass)
            print "${COLOR_GREEN}✓ PASS${COLOR_RESET}"
            ((PASSED++))
            ;;
        fail)
            print "${COLOR_RED}✗ FAIL${COLOR_RESET} ${message:+($message)}"
            ((FAILED++))
            ;;
        warn)
            print "${COLOR_YELLOW}⚠ WARN${COLOR_RESET} ${message:+($message)}"
            ((WARNINGS++))
            ;;
        skip)
            print "${COLOR_BLUE}→ SKIP${COLOR_RESET} ${message:+($message)}"
            ;;
    esac
}

#=============================================================================
# Function: test_command
# Description: Test if a command exists
#
# Checks if a command is available in PATH.
#
# Arguments:
#   $1 - Command name
#   $2 - Test description (optional)
#
# Returns:
#   0 - Command exists
#   1 - Command not found
#
# Example:
#   test_command docker "Docker CLI"
#=============================================================================
test_command() {
    local cmd=$1
    local desc="${2:-$cmd}"
    
    if command -v "$cmd" &>/dev/null; then
        test_result "$desc" "pass"
        return 0
    else
        test_result "$desc" "fail" "not found"
        return 1
    fi
}

#=============================================================================
# Function: test_url
# Description: Test HTTP endpoint availability
#
# Checks if a URL responds with expected status code.
#
# Arguments:
#   $1 - Service name
#   $2 - URL
#   $3 - Expected status (optional, default: 200)
#
# Returns:
#   0 - URL accessible
#   1 - URL not accessible
#
# Example:
#   test_url "Sonarr" "http://localhost:8989"
#=============================================================================
test_url() {
    local name=$1
    local url=$2
    local expected="${3:-200}"
    
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
    
    if [[ "$status" == "$expected" ]] || [[ "$status" =~ ^(301|302|303)$ ]]; then
        test_result "$name" "pass"
        return 0
    else
        test_result "$name" "fail" "HTTP $status"
        return 1
    fi
}

##############################################################################
#                         DEPENDENCY TESTS                                   #
##############################################################################

#=============================================================================
# Function: test_dependencies
# Description: Test system dependencies
#
# Verifies all required commands and tools are available.
#
# Arguments:
#   None
#
# Returns:
#   0 - All dependencies met
#   1 - Missing dependencies
#
# Example:
#   test_dependencies
#=============================================================================
test_dependencies() {
    print "\n${COLOR_BOLD}System Dependencies${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Core requirements
    test_command docker "Docker"
    test_command docker-compose "Docker Compose v1" || \
        docker compose version &>/dev/null && test_result "Docker Compose v2" "pass"
    
    # Utilities
    test_command curl "curl"
    test_command jq "jq"
    test_command grep "grep"
    test_command sed "sed"
    test_command awk "awk"
    
    # Optional but recommended
    test_command git "git" || test_result "git" "warn" "optional"
    test_command htop "htop" || test_result "htop" "warn" "optional"
}

##############################################################################
#                          SERVICE TESTS                                     #
##############################################################################

#=============================================================================
# Function: test_services
# Description: Test all service endpoints
#
# Checks availability of all core and optional services.
#
# Arguments:
#   None
#
# Returns:
#   0 - All services accessible
#   1 - Some services not accessible
#
# Example:
#   test_services
#=============================================================================
test_services() {
    print "\n${COLOR_BOLD}Service Availability${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Core services
    test_url "SABnzbd" "http://localhost:8080/sabnzbd/"
    test_url "Prowlarr" "http://localhost:9696"
    test_url "Sonarr" "http://localhost:8989"
    test_url "Radarr" "http://localhost:7878"
    test_url "Readarr" "http://localhost:8787"
    test_url "Lidarr" "http://localhost:8686"
    test_url "Bazarr" "http://localhost:6767"
    test_url "Mylar3" "http://localhost:8090"
    
    # Media services
    test_url "Jellyfin" "http://localhost:8096" || \
        test_result "Jellyfin" "skip" "optional service"
    test_url "Overseerr" "http://localhost:5055" || \
        test_result "Overseerr" "skip" "optional service"
    
    # Management services
    test_url "Portainer" "http://localhost:9000" || \
        test_result "Portainer" "skip" "optional service"
}

##############################################################################
#                         CONTAINER TESTS                                    #
##############################################################################

#=============================================================================
# Function: test_containers
# Description: Test Docker container health
#
# Verifies containers are running and healthy.
#
# Arguments:
#   None
#
# Returns:
#   0 - All containers healthy
#   1 - Some containers unhealthy
#
# Example:
#   test_containers
#=============================================================================
test_containers() {
    print "\n${COLOR_BOLD}Docker Containers${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local -a services=(
        sabnzbd prowlarr sonarr radarr readarr 
        lidarr bazarr mylar3 jellyfin overseerr
    )
    
    for service in $services; do
        if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
            # Check health status
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "none")
            
            case "$health" in
                healthy)
                    test_result "Container: $service" "pass"
                    ;;
                unhealthy)
                    test_result "Container: $service" "fail" "unhealthy"
                    ;;
                starting)
                    test_result "Container: $service" "warn" "starting"
                    ;;
                none|"")
                    test_result "Container: $service" "pass"
                    ;;
            esac
        else
            test_result "Container: $service" "fail" "not running"
        fi
    done
}

##############################################################################
#                           API TESTS                                        #
##############################################################################

#=============================================================================
# Function: test_apis
# Description: Test service API endpoints
#
# Verifies API keys are configured and APIs are responding.
#
# Arguments:
#   None
#
# Returns:
#   0 - All APIs accessible
#   1 - Some APIs not accessible
#
# Example:
#   test_apis
#=============================================================================
test_apis() {
    print "\n${COLOR_BOLD}API Endpoints${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # SABnzbd API
    local sab_key=$(grep -oP 'api_key = \K.*' "$CONFIG_DIR/sabnzbd/sabnzbd.ini" 2>/dev/null || true)
    if [[ -n "$sab_key" ]]; then
        test_url "SABnzbd API" "http://localhost:8080/sabnzbd/api?mode=version&apikey=$sab_key"
    else
        test_result "SABnzbd API" "warn" "no API key"
    fi
    
    # Prowlarr API
    local prowlarr_key=$(grep -oP '<ApiKey>\K[^<]+' "$CONFIG_DIR/prowlarr/config.xml" 2>/dev/null || true)
    if [[ -n "$prowlarr_key" ]]; then
        test_url "Prowlarr API" "http://localhost:9696/api/v1/health?apikey=$prowlarr_key"
    else
        test_result "Prowlarr API" "warn" "no API key"
    fi
    
    # Sonarr API
    local sonarr_key=$(grep -oP '<ApiKey>\K[^<]+' "$CONFIG_DIR/sonarr/config.xml" 2>/dev/null || true)
    if [[ -n "$sonarr_key" ]]; then
        test_url "Sonarr API" "http://localhost:8989/api/v3/health?apikey=$sonarr_key"
    else
        test_result "Sonarr API" "warn" "no API key"
    fi
}

##############################################################################
#                      CONFIGURATION TESTS                                   #
##############################################################################

#=============================================================================
# Function: test_configuration
# Description: Test service configurations
#
# Verifies configuration files exist and contain required settings.
#
# Arguments:
#   None
#
# Returns:
#   0 - Configurations valid
#   1 - Configuration issues
#
# Example:
#   test_configuration
#=============================================================================
test_configuration() {
    print "\n${COLOR_BOLD}Configuration Files${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Check config directory
    if [[ -d "$CONFIG_DIR" ]]; then
        test_result "Config directory" "pass"
    else
        test_result "Config directory" "fail" "not found"
        return 1
    fi
    
    # Check service configs
    local -A config_files=(
        [SABnzbd]="$CONFIG_DIR/sabnzbd/sabnzbd.ini"
        [Prowlarr]="$CONFIG_DIR/prowlarr/config.xml"
        [Sonarr]="$CONFIG_DIR/sonarr/config.xml"
        [Radarr]="$CONFIG_DIR/radarr/config.xml"
    )
    
    for service file in ${(kv)config_files}; do
        if [[ -f "$file" ]]; then
            test_result "$service config" "pass"
        else
            test_result "$service config" "warn" "not found"
        fi
    done
}

##############################################################################
#                       PERFORMANCE TESTS                                    #
##############################################################################

#=============================================================================
# Function: test_performance
# Description: Test system performance metrics
#
# Checks disk space, memory usage, and response times.
#
# Arguments:
#   None
#
# Returns:
#   0 - Performance acceptable
#   1 - Performance issues
#
# Example:
#   test_performance
#=============================================================================
test_performance() {
    print "\n${COLOR_BOLD}Performance Metrics${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Disk space
    local disk_usage=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $5}' | sed 's/%//')
    if (( disk_usage < 80 )); then
        test_result "Disk space" "pass" "${disk_usage}% used"
    elif (( disk_usage < 90 )); then
        test_result "Disk space" "warn" "${disk_usage}% used"
    else
        test_result "Disk space" "fail" "${disk_usage}% used"
    fi
    
    # Memory usage
    local mem_available=$(free -m | awk 'NR==2{print $7}')
    if (( mem_available > 2048 )); then
        test_result "Memory available" "pass" "${mem_available}MB"
    elif (( mem_available > 1024 )); then
        test_result "Memory available" "warn" "${mem_available}MB"
    else
        test_result "Memory available" "fail" "${mem_available}MB"
    fi
    
    # Response time test
    local start_time=$(date +%s%N)
    curl -s -o /dev/null "http://localhost:8989" 2>/dev/null
    local end_time=$(date +%s%N)
    local response_time=$(( (end_time - start_time) / 1000000 ))
    
    if (( response_time < 1000 )); then
        test_result "Service response time" "pass" "${response_time}ms"
    elif (( response_time < 3000 )); then
        test_result "Service response time" "warn" "${response_time}ms"
    else
        test_result "Service response time" "fail" "${response_time}ms"
    fi
}

##############################################################################
#                      INTEGRATION TESTS                                     #
##############################################################################

#=============================================================================
# Function: test_integration
# Description: Test service integrations
#
# Verifies services can communicate with each other.
#
# Arguments:
#   None
#
# Returns:
#   0 - Integrations working
#   1 - Integration issues
#
# Example:
#   test_integration
#=============================================================================
test_integration() {
    print "\n${COLOR_BOLD}Service Integration${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Test Prowlarr -> Sonarr connection
    local prowlarr_key=$(grep -oP '<ApiKey>\K[^<]+' "$CONFIG_DIR/prowlarr/config.xml" 2>/dev/null || true)
    if [[ -n "$prowlarr_key" ]]; then
        if curl -s -H "X-Api-Key: $prowlarr_key" "http://localhost:9696/api/v1/applications" | grep -q "sonarr"; then
            test_result "Prowlarr → Sonarr" "pass"
        else
            test_result "Prowlarr → Sonarr" "warn" "not configured"
        fi
    else
        test_result "Prowlarr → Sonarr" "skip" "no API key"
    fi
    
    # Test Sonarr -> SABnzbd connection
    local sonarr_key=$(grep -oP '<ApiKey>\K[^<]+' "$CONFIG_DIR/sonarr/config.xml" 2>/dev/null || true)
    if [[ -n "$sonarr_key" ]]; then
        if curl -s -H "X-Api-Key: $sonarr_key" "http://localhost:8989/api/v3/downloadclient" | grep -q "sabnzbd"; then
            test_result "Sonarr → SABnzbd" "pass"
        else
            test_result "Sonarr → SABnzbd" "warn" "not configured"
        fi
    else
        test_result "Sonarr → SABnzbd" "skip" "no API key"
    fi
}

##############################################################################
#                         TEST SUITES                                        #
##############################################################################

#=============================================================================
# Function: run_quick_tests
# Description: Run minimal test suite
#
# Runs only essential tests for quick validation.
#
# Arguments:
#   None
#
# Returns:
#   0 - All tests passed
#   1 - Some tests failed
#
# Example:
#   run_quick_tests
#=============================================================================
run_quick_tests() {
    print "${COLOR_BLUE}🧪 Quick Test Suite${COLOR_RESET}"
    print "===================="
    
    test_services
    test_containers
    
    show_summary
}

#=============================================================================
# Function: run_full_tests
# Description: Run comprehensive test suite
#
# Runs all available tests for thorough validation.
#
# Arguments:
#   None
#
# Returns:
#   0 - All tests passed
#   1 - Some tests failed
#
# Example:
#   run_full_tests
#=============================================================================
run_full_tests() {
    print "${COLOR_BLUE}🧪 Full Test Suite${COLOR_RESET}"
    print "=================="
    
    test_dependencies
    test_services
    test_containers
    test_apis
    test_configuration
    test_performance
    test_integration
    
    show_summary
}

#=============================================================================
# Function: show_summary
# Description: Display test summary
#
# Shows final count of passed, failed, and warning tests.
#
# Arguments:
#   None
#
# Returns:
#   0 - No failures
#   1 - Had failures
#
# Example:
#   show_summary
#=============================================================================
show_summary() {
    print "\n${COLOR_BOLD}Test Summary${COLOR_RESET}"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print "Passed:   ${COLOR_GREEN}$PASSED${COLOR_RESET}"
    print "Failed:   ${COLOR_RED}$FAILED${COLOR_RESET}"
    print "Warnings: ${COLOR_YELLOW}$WARNINGS${COLOR_RESET}"
    
    if (( FAILED == 0 )); then
        print "\n${COLOR_GREEN}✅ All tests passed!${COLOR_RESET}"
        return 0
    else
        print "\n${COLOR_RED}❌ Some tests failed${COLOR_RESET}"
        return 1
    fi
}

##############################################################################
#                            MAIN HANDLER                                    #
##############################################################################

#=============================================================================
# Function: show_test_help
# Description: Display help for test command
#
# Shows available test suites and options.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   show_test_help
#=============================================================================
show_test_help() {
    cat <<'HELP'
TEST COMMAND

Usage: usenet test [suite] [options]

Run automated tests to verify stack health and configuration.

TEST SUITES
    quick              Essential tests only (default)
    full               Comprehensive test suite
    deps               Dependency tests only
    services           Service availability tests
    containers         Docker container tests
    api                API endpoint tests
    config             Configuration tests
    performance        Performance metrics
    integration        Service integration tests

OPTIONS
    --verbose, -v      Show detailed output
    --help, -h         Show this help

EXAMPLES
    Quick validation:
        $ usenet test
        
    Full test suite:
        $ usenet test full
        
    Specific tests:
        $ usenet test services
        $ usenet test api

EXIT CODES
    0 - All tests passed
    1 - Some tests failed

HELP
}

#=============================================================================
# Function: main
# Description: Main entry point for test command
#
# Routes test requests to appropriate test functions.
#
# Arguments:
#   $@ - Command line arguments
#
# Returns:
#   0 - Tests passed
#   1 - Tests failed
#
# Example:
#   main full --verbose
#=============================================================================
main() {
    local suite="${1:-quick}"
    shift || true
    
    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose|-v)
                set -x
                ;;
            --help|-h)
                show_test_help
                return 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_test_help
                return 1
                ;;
        esac
        shift
    done
    
    # Run requested test suite
    case "$suite" in
        quick|all)
            run_quick_tests
            ;;
        full)
            run_full_tests
            ;;
        deps|dependencies)
            test_dependencies
            show_summary
            ;;
        services)
            test_services
            show_summary
            ;;
        containers|docker)
            test_containers
            show_summary
            ;;
        api|apis)
            test_apis
            show_summary
            ;;
        config|configuration)
            test_configuration
            show_summary
            ;;
        performance|perf)
            test_performance
            show_summary
            ;;
        integration|int)
            test_integration
            show_summary
            ;;
        *)
            log_error "Unknown test suite: $suite"
            show_test_help
            return 1
            ;;
    esac
}

# Run main function
main "$@"

# vim: set ts=4 sw=4 et tw=80: