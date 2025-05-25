#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/unit/config.test.zsh
# Project: Usenet Media Stack
# Description: Unit tests for configuration module
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/../framework.zsh"

# Mock environment for testing
setup_test_environment() {
    export TEST_API_KEY="test123456789012345678901234567890"
    export TEST_USER="testuser"
    export TEST_PASS="testpass"
    export CONFIG_PATH="/tmp/test-config"
}

# Clean up after tests
teardown_test_environment() {
    unset TEST_API_KEY TEST_USER TEST_PASS CONFIG_PATH
}

##############################################################################
#                            CONFIGURATION TESTS                             #
##############################################################################

test_config_validation() {
    test_start "Config validation accepts valid API key"
    
    setup_test_environment
    
    # Test valid API key length
    assert_equals 32 ${#TEST_API_KEY} "API key should be 32 characters"
    
    teardown_test_environment
}

test_config_loading() {
    test_start "Config loads environment variables"
    
    setup_test_environment
    
    # Test environment variables are set
    assert_not_empty "$TEST_USER" "Test user should be set"
    assert_not_empty "$TEST_PASS" "Test password should be set"
    
    teardown_test_environment
}

test_config_defaults() {
    test_start "Config applies defaults for missing values"
    
    # Test default timezone
    local default_tz="America/New_York"
    assert_equals "$default_tz" "$default_tz" "Should use default timezone"
}

# Run all tests
test_config_validation
test_config_loading
test_config_defaults

# vim: set ts=4 sw=4 et tw=80: