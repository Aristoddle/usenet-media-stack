#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/test.zsh
# Project: Usenet Media Stack
# Description: Comprehensive Testing Command Module  
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-28
# Version: 2.0.0 - Comprehensive E2E Testing Framework
# License: MIT
##############################################################################

# Load core utilities
source "${0:A:h}/../core/common.zsh"
source "${0:A:h}/../core/init.zsh"

##############################################################################
#                            TESTING COMMAND MODULE                          #
##############################################################################

# Test suite configuration
readonly TEST_RESULTS_DIR="${PROJECT_ROOT}/test-results"
readonly TEST_REPORTS_DIR="${TEST_RESULTS_DIR}/reports"
readonly TEST_SCREENSHOTS_DIR="${TEST_RESULTS_DIR}/screenshots"
readonly TEST_LOGS_DIR="${TEST_RESULTS_DIR}/logs"

#=============================================================================
# Help: Display test command help
#=============================================================================
show_test_help() {
    cat << EOF
USENET TESTING COMMANDS

USAGE:
    usenet test <command> [options]

COMMANDS:
    # QUICK TESTS
    unit                    Run unit tests only
    integration             Run integration tests only  
    web                     Run web UI tests only
    api                     Run API endpoint tests only
    smoke                   Run smoke tests (quick validation)
    
    # COMPREHENSIVE TESTING
    e2e                     Run full End-to-End test suite
    all                     Run all test suites (comprehensive)
    
    # SPECIALIZED TESTING
    deployment              Test fresh deployment workflow (DESTRUCTIVE)
    port-conflicts          Test port conflict resolution
    storage                 Test storage discovery and management
    hardware                Test hardware detection and optimization
    
    # REPORTING & ANALYSIS  
    report                  Generate comprehensive test report
    clean                   Clean test results and artifacts
    status                  Show test environment status

OPTIONS:
    --verbose              Enable verbose output
    --screenshot           Take screenshots during web tests
    --destructive          Enable destructive tests (fresh deployment)
    --timeout <seconds>    Set test timeout (default: 300)
    --no-cleanup          Don't clean up test artifacts
    --format <type>        Output format: text, json, html (default: text)
    --parallel             Run compatible tests in parallel (default for >10 services)
    --no-parallel          Force sequential execution (disable auto-parallel)
    --profile <name>       Use specific test profile (ci, dev, production)

EXAMPLES:
    # Quick validation
    usenet test smoke
    
    # Fast parallel web interface testing (auto-parallel with 19+ services)
    usenet test web --verbose
    
    # Force sequential testing for debugging
    usenet test web --no-parallel --verbose
    
    # Complete E2E testing with parallel execution
    usenet test e2e --parallel
    
    # Test fresh deployment (WARNING: destructive)
    usenet test deployment --destructive
    
    # Fast CI testing with parallel execution
    usenet test all --profile ci --parallel --format json

TEST PROFILES:
    ci          Fast, parallel, minimal output
    dev         Standard development testing
    production  Comprehensive, with screenshots and detailed reports

For more information, visit: https://docs.usenet-media-stack.com/testing
EOF
}

#=============================================================================
# Setup: Initialize test environment
#=============================================================================
setup_test_environment() {
    info "Setting up test environment..."
    
    # Create test directories
    mkdir -p "$TEST_RESULTS_DIR" "$TEST_REPORTS_DIR" "$TEST_SCREENSHOTS_DIR" "$TEST_LOGS_DIR"
    
    # Validate we're in the right place
    if [[ ! -f "${PROJECT_ROOT}/docker-compose.yml" ]]; then
        error "Not in a valid usenet media stack directory"
        error "Expected to find docker-compose.yml in ${PROJECT_ROOT}"
        return 1
    fi
    
    # Load configuration
    load_stack_config || {
        error "Failed to load stack configuration"
        return 1
    }
    
    success "Test environment ready"
    info "Results dir: $TEST_RESULTS_DIR"
}

#=============================================================================
# Unit Tests: Run unit tests
#=============================================================================
run_unit_tests() {
    info "🧪 Running unit tests..."
    
    local test_dir="${PROJECT_ROOT}/lib/test/unit"
    local passed=0 failed=0
    
    if [[ ! -d "$test_dir" ]]; then
        warning "No unit test directory found at $test_dir"
        return 0
    fi
    
    for test_file in "$test_dir"/*.test.zsh; do
        [[ ! -f "$test_file" ]] && continue
        
        info "Running $(basename "$test_file")..."
        if zsh "$test_file" > "$TEST_LOGS_DIR/$(basename "$test_file").log" 2>&1; then
            success "✅ $(basename "$test_file")"
            ((passed++))
        else
            error "❌ $(basename "$test_file")"
            ((failed++))
        fi
    done
    
    info "Unit tests: $passed passed, $failed failed"
    return $failed
}

#=============================================================================
# Integration Tests: Run integration tests
#=============================================================================
run_integration_tests() {
    info "🔗 Running integration tests..."
    
    local test_dir="${PROJECT_ROOT}/lib/test/integration"
    local passed=0 failed=0
    
    if [[ ! -d "$test_dir" ]]; then
        warning "No integration test directory found at $test_dir"
        return 0
    fi
    
    for test_file in "$test_dir"/*.test.zsh; do
        [[ ! -f "$test_file" ]] && continue
        
        info "Running $(basename "$test_file")..."
        if zsh "$test_file" > "$TEST_LOGS_DIR/$(basename "$test_file").log" 2>&1; then
            success "✅ $(basename "$test_file")"
            ((passed++))
        else
            error "❌ $(basename "$test_file")"
            ((failed++))
        fi
    done
    
    info "Integration tests: $passed passed, $failed failed"
    return $failed
}

#=============================================================================
# Web Tests: Run web UI tests (Enhanced Legacy + Playwright)
#=============================================================================
run_web_tests() {
    info "🌐 Running web UI tests..."
    
    # First run our legacy quick web tests
    test_web_interfaces_legacy
    local legacy_result=$?
    
    # Then run comprehensive Playwright tests
    local web_test_dir="${PROJECT_ROOT}/lib/web-testing"
    
    if [[ ! -f "$web_test_dir/test-runner.js" ]]; then
        warning "Playwright testing framework not found at $web_test_dir"
        return $legacy_result
    fi
    
    cd "$web_test_dir"
    
    # Ensure dependencies are installed
    if [[ ! -d "node_modules" ]]; then
        info "Installing web test dependencies..."
        npm install > "$TEST_LOGS_DIR/npm-install.log" 2>&1
    fi
    
    # Run web tests
    local test_args="--suite=web"
    [[ "$FLAG_SCREENSHOT" == "true" ]] && test_args="$test_args --screenshot"
    
    if npm run test-web > "$TEST_LOGS_DIR/web-tests.log" 2>&1; then
        success "✅ Playwright web UI tests completed"
        
        # Copy report to our results directory
        [[ -f "test-report.json" ]] && cp "test-report.json" "$TEST_REPORTS_DIR/web-report.json"
        
        return $legacy_result
    else
        error "❌ Playwright web UI tests failed"
        return 1
    fi
}

#=============================================================================
# Legacy Web Interface Tests (Fast)
#=============================================================================
test_web_interfaces_legacy() {
    info "🌐 Testing web interfaces for all media services..."
    
    # Define all 23 services and their expected ports
    local -A services=(
        # Core Media Automation  
        [sonarr]="8989"
        [radarr]="7878"
        [readarr]="8787"
        [bazarr]="6767"
        [whisparr]="6969"
        [prowlarr]="9696"
        [mylar]="8090"
        [jackett]="9117"
        
        # Media Servers
        [jellyfin]="8096"
        [overseerr]="5055"
        [yacreader]="8083"
        [stash]="9998"
        [tautulli]="8181"
        
        # Downloads & Processing
        [sabnzbd]="8080"
        [transmission]="9091"
        [tdarr]="8265"
        
        # Infrastructure & Management
        [portainer]="9000"
        [netdata]="19999"
        
        # Documentation & Utilities
        [usenet-docs]="4173"
        
        # Note: Excluded services without web interfaces:
        # recyclarr, unpackerr, samba, nfs-server
    )
    
    # Determine parallel execution based on flag and service count
    local use_parallel="false"
    if [[ "$FLAG_PARALLEL" == "true" ]]; then
        use_parallel="true"
    elif [[ "$FLAG_PARALLEL" == "auto" ]] && [[ ${#services} -gt 5 ]]; then
        use_parallel="true"
    fi
    
    if [[ "$use_parallel" == "true" ]]; then
        test_web_interfaces_parallel
    else
        test_web_interfaces_sequential
    fi
}

test_web_interfaces_sequential() {
    # Define services directly (same as parent function)
    local -A services=(
        # Core Media Automation  
        [sonarr]="8989"
        [radarr]="7878"
        [readarr]="8787"
        [bazarr]="6767"
        [whisparr]="6969"
        [prowlarr]="9696"
        [mylar]="8090"
        [jackett]="9117"
        
        # Media Servers
        [jellyfin]="8096"
        [overseerr]="5055"
        [yacreader]="8083"
        [stash]="9998"
        [tautulli]="8181"
        
        # Downloads & Processing
        [sabnzbd]="8080"
        [transmission]="9091"
        [tdarr]="8265"
        
        # Infrastructure & Management
        [portainer]="9000"
        [netdata]="19999"
        
        # Documentation & Utilities
        [usenet-docs]="4173"
    )
    local failures=0 successes=0
    
    for service port in ${(kv)services}; do
        local url="http://localhost:${port}"
        
        # Test basic connectivity with timeout
        if curl -s -f --max-time 3 --connect-timeout 1 "$url" >/dev/null 2>&1; then
            success "✓ ${service} (${url}) - Accessible"
            ((successes++))
        else
            error "✗ ${service} (${url}) - Not accessible"
            ((failures++))
        fi
    done
    
    if [[ $failures -eq 0 ]]; then
        success "🎉 All ${successes} web interfaces are accessible!"
    else
        warning "⚠ ${failures} service(s) failed, ${successes} succeeded"
    fi
    
    return $failures
}

test_web_interfaces_parallel() {
    # Define services directly (same as parent function)
    local -A services=(
        # Core Media Automation  
        [sonarr]="8989"
        [radarr]="7878"
        [readarr]="8787"
        [bazarr]="6767"
        [whisparr]="6969"
        [prowlarr]="9696"
        [mylar]="8090"
        [jackett]="9117"
        
        # Media Servers
        [jellyfin]="8096"
        [overseerr]="5055"
        [yacreader]="8083"
        [stash]="9998"
        [tautulli]="8181"
        
        # Downloads & Processing
        [sabnzbd]="8080"
        [transmission]="9091"
        [tdarr]="8265"
        
        # Infrastructure & Management
        [portainer]="9000"
        [netdata]="19999"
        
        # Documentation & Utilities
        [usenet-docs]="4173"
    )
    local temp_dir=$(mktemp -d)
    local pids=()
    
    info "Running parallel web interface tests..."
    
    # Launch parallel test jobs
    for service port in ${(kv)services}; do
        (
            local url="http://localhost:${port}"
            local result_file="$temp_dir/${service}.result"
            
            if curl -s -f --max-time 3 --connect-timeout 1 "$url" >/dev/null 2>&1; then
                echo "SUCCESS:${service}:${url}" > "$result_file"
            else
                echo "FAILURE:${service}:${url}" > "$result_file"
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all parallel jobs to complete
    for pid in $pids; do
        wait $pid
    done
    
    # Collect and display results
    local failures=0 successes=0
    for result_file in "$temp_dir"/*.result; do
        [[ -f "$result_file" ]] || continue
        
        local result=$(cat "$result_file")
        local status=${result%%:*}
        local service=${result#*:}; service=${service%%:*}
        local url=${result##*:}
        
        if [[ "$status" == "SUCCESS" ]]; then
            success "✓ ${service} (${url}) - Accessible"
            ((successes++))
        else
            error "✗ ${service} (${url}) - Not accessible"
            ((failures++))
        fi
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [[ $failures -eq 0 ]]; then
        success "🎉 All ${successes} web interfaces are accessible! (parallel)"
    else
        warning "⚠ ${failures} service(s) failed, ${successes} succeeded (parallel)"
    fi
    
    return $failures
}

#=============================================================================
# API Tests: Run API endpoint tests
#=============================================================================
run_api_tests() {
    info "🔌 Running API endpoint tests..."
    
    # Run legacy API tests first
    test_api_endpoints_legacy
    local legacy_result=$?
    
    # Then run comprehensive API tests via Playwright
    local web_test_dir="${PROJECT_ROOT}/lib/web-testing"
    
    if [[ -f "$web_test_dir/test-runner.js" ]]; then
        cd "$web_test_dir"
        
        if npm run test-api > "$TEST_LOGS_DIR/api-tests.log" 2>&1; then
            success "✅ API endpoint tests completed"
        else
            error "❌ API endpoint tests failed"
            return 1
        fi
    fi
    
    return $legacy_result
}

#=============================================================================
# Legacy API Tests (Fast)
#=============================================================================
test_api_endpoints_legacy() {
    info "🔌 Testing API endpoints for automation services..."
    
    # Test basic API endpoints (without API keys for now)
    local -A api_services=(
        [sonarr]="8989"
        [radarr]="7878"
        [prowlarr]="9696"
        [readarr]="8787"
        [whisparr]="6969"
        [bazarr]="6767"
    )
    
    # Determine parallel execution for API tests
    local use_parallel="false"
    if [[ "$FLAG_PARALLEL" == "true" ]]; then
        use_parallel="true"
    elif [[ "$FLAG_PARALLEL" == "auto" ]] && [[ ${#api_services} -gt 3 ]]; then
        use_parallel="true"
    fi
    
    if [[ "$use_parallel" == "true" ]]; then
        test_api_endpoints_parallel
    else
        test_api_endpoints_sequential
    fi
}

test_api_endpoints_sequential() {
    local -A api_services=("${(@kv)1}")
    local failures=0 successes=0
    
    for service port in ${(kv)api_services}; do
        local api_url="http://localhost:${port}/api/v3/system/status"
        
        # Test API endpoint accessibility (expect 401 without API key)
        local response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 3 --connect-timeout 1 "$api_url" 2>/dev/null || echo "000")
        
        case "$response" in
            200)
                success "✓ ${service} API - Public endpoint accessible"
                ((successes++))
                ;;
            401)
                success "✓ ${service} API - Protected (requires authentication)"
                ((successes++))
                ;;
            404)
                warning "⚠ ${service} API - Endpoint not found (may use different version)"
                ;;
            000)
                error "✗ ${service} API - Service not responding"
                ((failures++))
                ;;
            *)
                warning "⚠ ${service} API - Unexpected response: ${response}"
                ;;
        esac
    done
    
    if [[ $failures -eq 0 ]]; then
        success "🎉 All ${successes} API endpoints responded correctly!"
    else
        warning "⚠ ${failures} API(s) failed, ${successes} succeeded"
    fi
    
    return $failures
}

test_api_endpoints_parallel() {
    local -A api_services=("${(@kv)1}")
    local temp_dir=$(mktemp -d)
    local pids=()
    
    info "Running parallel API endpoint tests..."
    
    # Launch parallel API test jobs
    for service port in ${(kv)api_services}; do
        (
            local api_url="http://localhost:${port}/api/v3/system/status"
            local result_file="$temp_dir/${service}_api.result"
            
            local response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 3 --connect-timeout 1 "$api_url" 2>/dev/null || echo "000")
            echo "${service}:${response}" > "$result_file"
        ) &
        pids+=($!)
    done
    
    # Wait for all parallel jobs to complete
    for pid in $pids; do
        wait $pid
    done
    
    # Collect and display results
    local failures=0 successes=0
    for result_file in "$temp_dir"/*_api.result; do
        [[ -f "$result_file" ]] || continue
        
        local result=$(cat "$result_file")
        local service=${result%%:*}
        local response=${result##*:}
        
        case "$response" in
            200)
                success "✓ ${service} API - Public endpoint accessible"
                ((successes++))
                ;;
            401)
                success "✓ ${service} API - Protected (requires authentication)"
                ((successes++))
                ;;
            404)
                warning "⚠ ${service} API - Endpoint not found (may use different version)"
                ;;
            000)
                error "✗ ${service} API - Service not responding"
                ((failures++))
                ;;
            *)
                warning "⚠ ${service} API - Unexpected response: ${response}"
                ;;
        esac
    done
    
    # Cleanup
    rm -rf "$temp_dir"
    
    if [[ $failures -eq 0 ]]; then
        success "🎉 All ${successes} API endpoints responded correctly! (parallel)"
    else
        warning "⚠ ${failures} API(s) failed, ${successes} succeeded (parallel)"
    fi
    
    return $failures
}

#=============================================================================
# Smoke Tests: Quick validation
#=============================================================================
run_smoke_tests() {
    info "💨 Running smoke tests (quick validation)..."
    
    local failed=0
    
    # Test 1: Docker Compose validity
    cd "$PROJECT_ROOT"
    if docker compose config >/dev/null 2>&1; then
        success "✅ Docker Compose configuration valid"
    else
        error "❌ Docker Compose configuration invalid"
        ((failed++))
    fi
    
    # Test 2: Core services running
    local running_services=$(docker compose ps --format json 2>/dev/null | jq -r 'select(.State == "running") | .Name' | wc -l)
    if [[ $running_services -ge 15 ]]; then
        success "✅ Core services running ($running_services services)"
    else
        error "❌ Insufficient services running ($running_services < 15)"
        ((failed++))
    fi
    
    # Test 3: Key ports accessible (parallel)
    local key_ports=(8096 5055 9696 8080 9000)
    local temp_dir=$(mktemp -d)
    local pids=()
    
    # Test ports in parallel
    for port in $key_ports; do
        (
            if curl -s --max-time 2 --connect-timeout 1 "http://localhost:$port" >/dev/null 2>&1; then
                echo "SUCCESS" > "$temp_dir/port_$port.result"
            else
                echo "FAILURE" > "$temp_dir/port_$port.result"
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all tests to complete
    for pid in $pids; do
        wait $pid
    done
    
    # Count successes
    local accessible=0
    for result_file in "$temp_dir"/port_*.result; do
        [[ -f "$result_file" ]] || continue
        if [[ "$(cat "$result_file")" == "SUCCESS" ]]; then
            ((accessible++))
        fi
    done
    
    rm -rf "$temp_dir"
    
    if [[ $accessible -ge 3 ]]; then
        success "✅ Key services accessible ($accessible/5 ports)"
    else
        error "❌ Key services inaccessible ($accessible/5 ports)"
        ((failed++))
    fi
    
    # Test 4: CLI commands work
    if ./usenet --help >/dev/null 2>&1; then
        success "✅ CLI commands functional"
    else
        error "❌ CLI commands failed"
        ((failed++))
    fi
    
    info "Smoke tests: $((4-failed))/4 passed"
    return $failed
}

#=============================================================================
# E2E Tests: Full end-to-end testing
#=============================================================================
run_e2e_tests() {
    info "🚀 Running comprehensive End-to-End tests..."
    
    local e2e_script="${PROJECT_ROOT}/lib/test/e2e-test-suite.zsh"
    
    if [[ ! -f "$e2e_script" ]]; then
        error "E2E test suite not found at $e2e_script"
        return 1
    fi
    
    # Set environment variables for E2E tests
    export E2E_SCREENSHOT_DIR="$TEST_SCREENSHOTS_DIR"
    export E2E_REPORT_DIR="$TEST_REPORTS_DIR"
    export ENABLE_DESTRUCTIVE_TESTS="${FLAG_DESTRUCTIVE:-false}"
    
    if zsh "$e2e_script" > "$TEST_LOGS_DIR/e2e-tests.log" 2>&1; then
        success "✅ E2E tests completed successfully"
        return 0
    else
        error "❌ E2E tests failed"
        warning "Check log: $TEST_LOGS_DIR/e2e-tests.log"
        return 1
    fi
}

#=============================================================================
# Show Test Status
#=============================================================================
show_test_status() {
    info "🔍 Test Environment Status"
    echo
    
    # Test directories
    echo "📁 Test Directories:"
    echo "   Results:     $TEST_RESULTS_DIR"
    echo "   Reports:     $TEST_REPORTS_DIR" 
    echo "   Screenshots: $TEST_SCREENSHOTS_DIR"
    echo "   Logs:        $TEST_LOGS_DIR"
    echo
    
    # Recent test runs
    echo "📊 Recent Test Runs:"
    if [[ -d "$TEST_LOGS_DIR" ]]; then
        find "$TEST_LOGS_DIR" -name "*.log" -printf '%TF %TT %f\n' 2>/dev/null | sort -r | head -5 | while read date time file; do
            echo "   $date $time $(basename "$file" .log)"
        done
    else
        echo "   No test runs found"
    fi
    echo
    
    # System readiness
    echo "🏥 System Readiness:"
    
    # Docker
    if docker info >/dev/null 2>&1; then
        echo "   ✅ Docker running"
    else
        echo "   ❌ Docker not available"
    fi
    
    # Services
    local running=$(docker compose ps --format json 2>/dev/null | jq -r 'select(.State == "running") | .Name' | wc -l)
    echo "   📊 Services running: $running"
    
    # Web testing
    if [[ -f "$PROJECT_ROOT/lib/web-testing/package.json" ]]; then
        echo "   ✅ Web testing framework available"
    else
        echo "   ❌ Web testing framework missing"
    fi
    
    # Node.js
    if command -v node >/dev/null 2>&1; then
        echo "   ✅ Node.js available ($(node --version))"
    else
        echo "   ❌ Node.js not available"
    fi
}

##############################################################################
#                              MAIN COMMAND LOGIC                           #
##############################################################################

main() {
    local action="${1:-help}"
    shift
    
    # Parse flags
    local FLAG_VERBOSE="false"
    local FLAG_SCREENSHOT="false"
    local FLAG_DESTRUCTIVE="false"
    local FLAG_TIMEOUT="300"
    local FLAG_NO_CLEANUP="false"
    local FLAG_FORMAT="text"
    local FLAG_PARALLEL="auto"  # auto, true, false
    local FLAG_PROFILE="dev"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --verbose)
                FLAG_VERBOSE="true"
                shift
                ;;
            --screenshot)
                FLAG_SCREENSHOT="true"
                shift
                ;;
            --destructive)
                FLAG_DESTRUCTIVE="true"
                shift
                ;;
            --timeout)
                FLAG_TIMEOUT="$2"
                shift 2
                ;;
            --no-cleanup)
                FLAG_NO_CLEANUP="true"
                shift
                ;;
            --format)
                FLAG_FORMAT="$2"
                shift 2
                ;;
            --parallel)
                FLAG_PARALLEL="true"
                shift
                ;;
            --no-parallel)
                FLAG_PARALLEL="false"
                shift
                ;;
            --profile)
                FLAG_PROFILE="$2"
                shift 2
                ;;
            *)
                error "Unknown flag: $1"
                return 1
                ;;
        esac
    done
    
    # Set verbose mode
    [[ "$FLAG_VERBOSE" == "true" ]] && set -x
    
    # Setup test environment
    setup_test_environment || return 1
    
    # Route to appropriate function
    case "$action" in
        help)
            show_test_help
            ;;
        unit)
            run_unit_tests
            ;;
        integration)
            run_integration_tests
            ;;
        web)
            run_web_tests
            ;;
        api)
            run_api_tests
            ;;
        smoke)
            run_smoke_tests
            ;;
        e2e)
            run_e2e_tests
            ;;
        all)
            local total_failed=0
            run_unit_tests; ((total_failed += $?))
            run_integration_tests; ((total_failed += $?))
            run_web_tests; ((total_failed += $?))
            run_api_tests; ((total_failed += $?))
            run_e2e_tests; ((total_failed += $?))
            
            if [[ $total_failed -eq 0 ]]; then
                success "🎉 All test suites passed!"
            else
                error "❌ $total_failed test suite(s) failed"
            fi
            return $total_failed
            ;;
        status)
            show_test_status
            ;;
        *)
            error "Unknown test command: $action"
            error "Use 'usenet test help' for available commands"
            return 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80:
