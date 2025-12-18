#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/e2e-test-suite.zsh
# Project: Usenet Media Stack
# Description: Comprehensive End-to-End Test Suite
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-28
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/framework.zsh"

# Load required modules
source "${0:A:h}/../core/common.zsh"
source "${0:A:h}/../core/init.zsh"

##############################################################################
#                         COMPREHENSIVE E2E TEST SUITE                       #
##############################################################################

# Test configuration
readonly E2E_TEST_TIMEOUT=30
readonly E2E_SCREENSHOT_DIR="${0:A:h}/../../test-results/screenshots"
readonly E2E_REPORT_DIR="${0:A:h}/../../test-results"

#=============================================================================
# Setup: Prepare test environment
#=============================================================================
setup_e2e_environment() {
    info "Setting up E2E test environment..."
    
    # Create directories
    mkdir -p "$E2E_SCREENSHOT_DIR"
    mkdir -p "$E2E_REPORT_DIR"
    
    # Load stack configuration
    load_stack_config
    
    # Ensure we're in the right directory
    local stack_dir="${0:A:h}/../.."
    if [[ ! -f "$stack_dir/docker-compose.yml" ]]; then
        error "Could not find docker-compose.yml. Current dir: $(pwd)"
        return 1
    fi
    
    info "E2E environment setup complete"
}

#=============================================================================
# Layer 1: Container Health Testing
#=============================================================================
test_layer1_container_health() {
    test_start "Layer 1: Container Health Validation"
    
    local stack_dir="${0:A:h}/../.."
    cd "$stack_dir"
    
    # Test 1: All expected services are defined
    local defined_services=$(docker compose config --services | wc -l)
    if [[ $defined_services -gt 20 ]]; then
        test_pass "Docker Compose defines $defined_services services"
    else
        test_fail "Expected >20 services, found $defined_services"
    fi
    
    # Test 2: Services are running
    local running_services=$(docker compose ps --format json | jq -r 'select(.State == "running") | .Name' | wc -l)
    local total_services=$(docker compose ps --format json | jq -r '.Name' | wc -l)
    
    info "Container status: $running_services/$total_services running"
    
    if [[ $running_services -ge 20 ]]; then
        test_pass "Sufficient services running ($running_services/$total_services)"
    else
        test_fail "Insufficient services running ($running_services/$total_services)"
        
        # Report failed services
        local failed_services=$(docker compose ps --format json | jq -r 'select(.State != "running") | "\(.Name): \(.State)"')
        if [[ -n "$failed_services" ]]; then
            warning "Failed services:"
            echo "$failed_services" | while read line; do
                warning "  $line"
            done
        fi
    fi
    
    # Test 3: No services in error state
    local error_services=$(docker compose ps --format json | jq -r 'select(.State | test("error|failed|dead")) | .Name' | wc -l)
    if [[ $error_services -eq 0 ]]; then
        test_pass "No services in error state"
    else
        test_fail "$error_services services in error state"
    fi
}

#=============================================================================
# Layer 2: Network Connectivity Testing
#=============================================================================
test_layer2_network_connectivity() {
    test_start "Layer 2: Network Connectivity Validation"
    
    # Core service ports to test
    local -A core_ports=(
        [32400]="plex"
        [5055]="overseerr"
        [9696]="prowlarr"
        [8989]="sonarr"
        [7878]="radarr"
        [8080]="sabnzbd"
        [9000]="portainer"
        [19999]="netdata"
        [9998]="stash"
    )
    
    local accessible_count=0
    local total_ports=${#core_ports}
    
    for port service in ${(kv)core_ports}; do
        # Test TCP connectivity
        if timeout 5 bash -c "cat < /dev/null > /dev/tcp/localhost/$port" 2>/dev/null; then
            test_pass "$service ($port): TCP connection successful"
            ((accessible_count++))
            
            # Test HTTP response
            local http_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://localhost:$port" 2>/dev/null || echo "000")
            if [[ "$http_status" =~ ^[23] ]]; then
                test_pass "$service ($port): HTTP response $http_status"
            elif [[ "$http_status" == "302" ]] || [[ "$http_status" == "401" ]]; then
                test_pass "$service ($port): HTTP redirect/auth $http_status (expected)"
            else
                test_fail "$service ($port): HTTP response $http_status"
            fi
        else
            test_fail "$service ($port): TCP connection failed"
        fi
    done
    
    # Summary
    local success_rate=$((accessible_count * 100 / total_ports))
    if [[ $success_rate -ge 80 ]]; then
        test_pass "Network connectivity: $success_rate% ($accessible_count/$total_ports) accessible"
    else
        test_fail "Network connectivity: $success_rate% ($accessible_count/$total_ports) accessible (need ≥80%)"
    fi
}

#=============================================================================
# Layer 3: Web UI Functionality Testing (Enhanced Playwright)
#=============================================================================
test_layer3_web_ui_functionality() {
    test_start "Layer 3: Web UI Functionality Validation"
    
    local web_test_dir="${0:A:h}/../web-testing"
    
    if [[ ! -f "$web_test_dir/test-runner.js" ]]; then
        test_fail "Web testing framework not found"
        return 1
    fi
    
    # Run enhanced web tests with screenshots
    cd "$web_test_dir"
    
    info "Running comprehensive web UI tests..."
    if npm run test-web > "$E2E_REPORT_DIR/web-test-output.log" 2>&1; then
        test_pass "Web UI tests completed successfully"
        
        # Parse results
        local web_report="$web_test_dir/test-report.json"
        if [[ -f "$web_report" ]]; then
            local passed_tests=$(jq '.summary.passed' "$web_report" 2>/dev/null || echo "0")
            local failed_tests=$(jq '.summary.failed' "$web_report" 2>/dev/null || echo "0")
            local total_tests=$(jq '.summary.total' "$web_report" 2>/dev/null || echo "0")
            
            info "Web UI test results: $passed_tests/$total_tests passed"
            
            if [[ $failed_tests -eq 0 ]]; then
                test_pass "All web UI tests passed"
            else
                test_fail "$failed_tests web UI tests failed"
                
                # Report specific failures
                local failures=$(jq -r '.tests[] | select(.passed == false) | .name' "$web_report" 2>/dev/null)
                if [[ -n "$failures" ]]; then
                    warning "Failed web tests:"
                    echo "$failures" | while read test_name; do
                        warning "  $test_name"
                    done
                fi
            fi
        fi
    else
        test_fail "Web UI tests failed to run"
        warning "Check log: $E2E_REPORT_DIR/web-test-output.log"
    fi
}

#=============================================================================
# Layer 4: API Integration Testing
#=============================================================================
test_layer4_api_integration() {
    test_start "Layer 4: API Integration Validation"
    
    # API services with their endpoints
    local -A api_services=(
        [sonarr]="8989:/api/v3/system/status"
        [radarr]="7878:/api/v3/system/status"
        [prowlarr]="9696:/api/v1/system/status"
        [bazarr]="6767:/api/system/status"
    )
    
    local api_accessible=0
    local total_apis=${#api_services}
    
    for service endpoint in ${(kv)api_services}; do
        local port=${endpoint%:*}
        local path=${endpoint#*:}
        local url="http://localhost:$port$path"
        
        # Test API endpoint
        local api_status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
        
        if [[ "$api_status" == "200" ]]; then
            test_pass "$service API: endpoint accessible (200)"
            ((api_accessible++))
        elif [[ "$api_status" == "401" ]] || [[ "$api_status" == "403" ]]; then
            test_pass "$service API: endpoint protected ($api_status)"
            ((api_accessible++))
        else
            test_fail "$service API: endpoint returned $api_status"
        fi
    done
    
    # Summary
    local api_success_rate=$((api_accessible * 100 / total_apis))
    if [[ $api_success_rate -ge 70 ]]; then
        test_pass "API integration: $api_success_rate% ($api_accessible/$total_apis) accessible"
    else
        test_fail "API integration: $api_success_rate% ($api_accessible/$total_apis) accessible (need ≥70%)"
    fi
}

#=============================================================================
# Layer 5: End-to-End Workflow Testing
#=============================================================================
test_layer5_e2e_workflows() {
    test_start "Layer 5: End-to-End Workflow Validation"
    
    local stack_dir="${0:A:h}/../.."
    cd "$stack_dir"
    
    # Test 1: Configuration loading
    if load_stack_config >/dev/null 2>&1; then
        test_pass "Stack configuration loads successfully"
    else
        test_fail "Stack configuration failed to load"
    fi
    
    # Test 2: Storage discovery
    if ./usenet storage list >/dev/null 2>&1; then
        test_pass "Storage discovery command works"
    else
        test_fail "Storage discovery command failed"
    fi
    
    # Test 3: Hardware detection
    if ./usenet hardware detect >/dev/null 2>&1; then
        test_pass "Hardware detection command works"
    else
        test_fail "Hardware detection command failed"
    fi
    
    # Test 4: Service management
    if ./usenet services list >/dev/null 2>&1; then
        test_pass "Service management command works"
    else
        test_fail "Service management command failed"
    fi
    
    # Test 5: Validation system
    if ./usenet validate >/dev/null 2>&1; then
        test_pass "Validation system works"
    else
        test_fail "Validation system failed"
    fi
}

#=============================================================================
# Fresh System Deployment Test (Nuclear Option)
#=============================================================================
test_fresh_system_deployment() {
    test_start "Fresh System Deployment Test (DESTRUCTIVE)"
    
    warning "This test will destroy and recreate the entire stack!"
    warning "Use only in test environments or with explicit permission."
    
    # This test is disabled by default for safety
    local enable_destructive_tests="${ENABLE_DESTRUCTIVE_TESTS:-false}"
    
    if [[ "$enable_destructive_tests" != "true" ]]; then
        test_skip "Fresh deployment test skipped (set ENABLE_DESTRUCTIVE_TESTS=true to enable)"
        return 0
    fi
    
    local stack_dir="${0:A:h}/../.."
    cd "$stack_dir"
    
    # Step 1: Clean shutdown
    info "Shutting down existing stack..."
    if docker compose down --timeout 30; then
        test_pass "Stack shutdown successful"
    else
        test_fail "Stack shutdown failed"
        return 1
    fi
    
    # Step 2: Clean deployment
    info "Deploying fresh stack..."
    if ./usenet deploy --auto; then
        test_pass "Fresh deployment successful"
    else
        test_fail "Fresh deployment failed"
        return 1
    fi
    
    # Step 3: Verify deployment
    sleep 30  # Allow services to start
    
    local running_after=$(docker compose ps --format json | jq -r 'select(.State == "running") | .Name' | wc -l)
    if [[ $running_after -ge 20 ]]; then
        test_pass "Fresh deployment: $running_after services running"
    else
        test_fail "Fresh deployment: only $running_after services running"
    fi
}

#=============================================================================
# Generate comprehensive test report
#=============================================================================
generate_e2e_report() {
    local report_file="$E2E_REPORT_DIR/e2e-test-report.json"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # System information
    local system_info=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "system": {
        "os": "$(uname -s)",
        "kernel": "$(uname -r)",
        "docker_version": "$(docker --version | cut -d' ' -f3 | tr -d ',')",
        "compose_version": "$(docker compose version --short)"
    },
    "stack": {
        "directory": "$(pwd)",
        "services_defined": $(docker compose config --services | wc -l),
        "services_running": $(docker compose ps --format json | jq -r 'select(.State == "running") | .Name' | wc -l),
        "services_total": $(docker compose ps --format json | jq -r '.Name' | wc -l)
    },
    "test_results": {
        "total_tests": $TEST_TOTAL,
        "passed_tests": $TEST_PASSED,
        "failed_tests": $TEST_FAILED,
        "skipped_tests": $TEST_SKIPPED
    }
}
EOF
    )
    
    echo "$system_info" > "$report_file"
    
    info "E2E test report generated: $report_file"
    
    # Console summary
    echo "\n" "=".repeat(80)
    info "🧪 COMPREHENSIVE E2E TEST SUMMARY"
    echo "=".repeat(80)
    echo "📊 Total Tests: $TEST_TOTAL"
    echo "✅ Passed: $TEST_PASSED"
    echo "❌ Failed: $TEST_FAILED"
    echo "⏭️  Skipped: $TEST_SKIPPED"
    echo "📄 Report: $report_file"
    echo "=".repeat(80)
}

##############################################################################
#                              MAIN EXECUTION                               #
##############################################################################

run_comprehensive_e2e_tests() {
    info "🚀 Starting Comprehensive E2E Test Suite"
    info "Test environment: $(pwd)"
    info "Screenshot dir: $E2E_SCREENSHOT_DIR"
    info "Report dir: $E2E_REPORT_DIR"
    
    # Setup
    setup_e2e_environment || {
        error "Failed to setup E2E environment"
        return 1
    }
    
    # Run test layers
    test_layer1_container_health
    test_layer2_network_connectivity
    test_layer3_web_ui_functionality
    test_layer4_api_integration
    test_layer5_e2e_workflows
    
    # Optional destructive test
    test_fresh_system_deployment
    
    # Generate comprehensive report
    generate_e2e_report
    
    # Exit with appropriate code
    if [[ $TEST_FAILED -gt 0 ]]; then
        error "E2E tests completed with $TEST_FAILED failures"
        return 1
    else
        success "All E2E tests passed successfully!"
        return 0
    fi
}

# Run tests if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    run_comprehensive_e2e_tests
fi

# vim: set ts=4 sw=4 et tw=80:
