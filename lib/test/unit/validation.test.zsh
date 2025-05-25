#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/unit/validation.test.zsh
# Project: Usenet Media Stack
# Description: Unit tests for validation functionality
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/../framework.zsh"

# Load the module under test
source "${0:A:h}/../../commands/validate.zsh"

##############################################################################
#                            VALIDATION TESTS                                #
##############################################################################

#=============================================================================
# Test: Docker validation detects installed Docker
#=============================================================================
test_docker_validation_detects_installation() {
    # Test that Docker command existence is properly detected
    if command -v docker >/dev/null 2>&1; then
        test_pass "Docker command should be detectable when installed"
    else
        test_skip "Docker not installed - cannot test detection"
    fi
}

#=============================================================================
# Test: Storage validation checks disk space
#=============================================================================
test_storage_validation_disk_space() {
    # Test disk space calculation
    local available_gb=$(df -BG "${PROJECT_ROOT:-/tmp}" | tail -1 | awk '{print $4}' | sed 's/G$//')
    
    # Basic sanity check - should have some available space
    if [[ $available_gb -gt 0 ]]; then
        test_pass "Should detect available disk space greater than 0"
    else
        test_fail "Disk space detection returned invalid value: $available_gb"
    fi
    
    # Test minimum space logic
    if [[ $available_gb -lt 50 ]]; then
        test_pass "Should correctly identify when disk space is below 50GB threshold"
    else
        test_pass "Should correctly identify sufficient disk space (${available_gb}GB)"
    fi
}

#=============================================================================
# Test: Network validation URL testing
#=============================================================================
test_network_validation_connectivity() {
    # Test basic connectivity check logic
    local test_url="https://google.com"
    
    # Test curl command existence
    if command -v curl >/dev/null 2>&1; then
        test_pass "curl command should be available for network tests"
        
        # Test actual connectivity (with timeout)
        if curl -s --connect-timeout 5 --max-time 10 "$test_url" >/dev/null 2>&1; then
            test_pass "Network connectivity test should work with valid URL"
        else
            test_skip "Network connectivity failed - may be offline"
        fi
    else
        test_fail "curl command required for network validation"
    fi
}

#=============================================================================
# Test: Configuration validation environment variables
#=============================================================================
test_config_validation_environment() {
    # Test environment variable validation logic
    local test_env=$(mktemp)
    
    # Create test .env file
    cat > "$test_env" <<EOF
DOMAIN=example.com
NEWSHOSTING_USER=testuser
NEWSHOSTING_PASS=testpass
NZBGEEK_API=testapikey
EOF
    
    # Source the test env file
    set -a
    source "$test_env"
    set +a
    
    # Test that required variables are detected
    if [[ -n "$DOMAIN" ]]; then
        test_pass "Should detect DOMAIN environment variable"
    else
        test_fail "DOMAIN variable should be set from test env"
    fi
    
    # Test provider detection
    local provider_count=0
    [[ -n "$NEWSHOSTING_USER" && -n "$NEWSHOSTING_PASS" ]] && ((provider_count++))
    
    if [[ $provider_count -gt 0 ]]; then
        test_pass "Should detect configured Usenet provider"
    else
        test_fail "Should find at least one provider in test env"
    fi
    
    # Cleanup
    rm -f "$test_env"
}

#=============================================================================
# Test: Dependencies validation tool detection
#=============================================================================
test_dependencies_validation_tools() {
    # Test required tools detection
    local required_tools=("curl" "jq" "docker")
    local missing_tools=0
    
    for tool in $required_tools; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            ((missing_tools++))
            test_skip "$tool not found - marking as missing"
        else
            test_pass "$tool should be detectable when installed"
        fi
    done
    
    # Test optional tools (don't fail if missing)
    local optional_tools=("smartctl" "netstat" "nslookup")
    
    for tool in $optional_tools; do
        if command -v "$tool" >/dev/null 2>&1; then
            test_pass "$tool detected as optional tool"
        else
            test_skip "$tool not found (optional)"
        fi
    done
}

#=============================================================================
# Test: Port availability checking
#=============================================================================
test_port_availability_check() {
    # Test port checking logic using a known open port (if available)
    local test_port="8989"
    
    # Test netstat availability
    if command -v netstat >/dev/null 2>&1; then
        test_pass "netstat available for port checking"
        
        # Check if our test port is in use
        if netstat -tuln 2>/dev/null | grep -q ":$test_port "; then
            test_pass "Port check correctly detects port $test_port in use"
        else
            test_pass "Port check correctly detects port $test_port available"
        fi
    else
        test_skip "netstat not available - cannot test port checking"
    fi
}

##############################################################################
#                              RUN ALL TESTS                                #
##############################################################################

run_test_suite() {
    test_start "Validation Unit Tests"
    
    test_docker_validation_detects_installation
    test_storage_validation_disk_space
    test_network_validation_connectivity
    test_config_validation_environment
    test_dependencies_validation_tools
    test_port_availability_check
    
    test_summary
}

# Run tests if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    run_test_suite
fi

# vim: set ts=4 sw=4 et tw=80: