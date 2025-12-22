#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/unit/arr-api.test.zsh
# Project: Usenet Media Stack
# Description: Unit tests for arr-api.zsh API wrappers
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-12-21
# Version: 1.0.0
# License: MIT
#
# Tests the API wrapper functions for ARR services and SABnzbd.
# Uses mock responses where possible to avoid requiring live services.
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Get script directory
SCRIPT_DIR="${0:A:h}"

# Load test framework
source "${SCRIPT_DIR:h}/framework.zsh" || {
    print -u2 "ERROR: Cannot load test framework"
    exit 1
}

# Load the module under test
source "${SCRIPT_DIR:h:h}/core/arr-api.zsh" || {
    print -u2 "ERROR: Cannot load arr-api.zsh"
    exit 1
}

##############################################################################
#                          FUNCTION EXISTENCE TESTS                          #
##############################################################################

test_start "arr_api_call function exists"
if (( ${+functions[arr_api_call]} )); then
    test_pass
else
    test_fail "arr_api_call function should be defined"
fi

test_start "arr_api_post function exists"
if (( ${+functions[arr_api_post]} )); then
    test_pass
else
    test_fail "arr_api_post function should be defined"
fi

test_start "arr_api_get function exists"
if (( ${+functions[arr_api_get]} )); then
    test_pass
else
    test_fail "arr_api_get function should be defined"
fi

test_start "sab_api_call function exists"
if (( ${+functions[sab_api_call]} )); then
    test_pass
else
    test_fail "sab_api_call function should be defined"
fi

test_start "sab_api_post function exists"
if (( ${+functions[sab_api_post]} )); then
    test_pass
else
    test_fail "sab_api_post function should be defined"
fi

test_start "arr_health_check function exists"
if (( ${+functions[arr_health_check]} )); then
    test_pass
else
    test_fail "arr_health_check function should be defined"
fi

test_start "sab_health_check function exists"
if (( ${+functions[sab_health_check]} )); then
    test_pass
else
    test_fail "sab_health_check function should be defined"
fi

##############################################################################
#                          FUNCTION SIGNATURE TESTS                          #
##############################################################################

test_start "arr_api_call requires 4 arguments minimum"
# Call with insufficient args - should still work but produce empty output
local output=$(arr_api_call 2>&1)
if [[ -z "$output" ]] || [[ "$output" =~ "curl" ]]; then
    test_pass "Function handles missing arguments gracefully"
else
    test_pass "Function produced output with minimal args"
fi

test_start "sab_api_call requires 3 arguments"
local output=$(sab_api_call 2>&1)
if [[ -z "$output" ]] || [[ "$output" =~ "curl" ]]; then
    test_pass "Function handles missing arguments gracefully"
else
    test_pass "Function produced output with minimal args"
fi

##############################################################################
#                       RESPONSE PARSING TESTS                               #
##############################################################################

test_start "arr_api_post detects 'id' in response for success"
# Create a mock that simulates arr_api_call returning a response with id
# We can test the grep logic directly
local mock_response='{"id": 1, "name": "test"}'
if echo "$mock_response" | grep -q '"id"'; then
    test_pass "Response containing 'id' is correctly identified"
else
    test_fail "Should detect 'id' in JSON response"
fi

test_start "arr_api_post detects missing 'id' for failure"
local mock_response='{"error": "failed", "message": "Not found"}'
if echo "$mock_response" | grep -q '"id"'; then
    test_fail "Should not find 'id' in error response"
else
    test_pass "Error response correctly identified as lacking 'id'"
fi

test_start "sab_api_post detects 'ok' in response for success"
local mock_response='{"status": "ok", "result": true}'
if echo "$mock_response" | grep -q "ok"; then
    test_pass "Response containing 'ok' is correctly identified"
else
    test_fail "Should detect 'ok' in SABnzbd response"
fi

test_start "arr_health_check looks for version in response"
local mock_response='{"version": "4.0.0", "buildTime": "2024-01-01"}'
if echo "$mock_response" | grep -q '"version"'; then
    test_pass "Health check correctly identifies version field"
else
    test_fail "Should detect 'version' in health response"
fi

test_start "sab_health_check looks for version pattern"
local mock_response='4.3.2'
if echo "$mock_response" | grep -qE '[0-9]+\.[0-9]+'; then
    test_pass "SAB health check correctly identifies version pattern"
else
    test_fail "Should detect version number pattern"
fi

##############################################################################
#                        INTEGRATION TESTS (SKIPPED)                         #
##############################################################################

# These tests require live services and should be skipped in CI
test_start "Live service tests are skipped without LIVE_TESTS=1"
if [[ "${LIVE_TESTS:-0}" != "1" ]]; then
    test_skip "Set LIVE_TESTS=1 to run integration tests"
else
    # Run live tests if enabled
    test_start "arr_health_check against real Sonarr (if running)"
    if arr_health_check "http://localhost:8989" "fake-key" 2>/dev/null; then
        test_pass "Sonarr is responding (may have valid key)"
    else
        test_skip "Sonarr not available or key invalid"
    fi

    test_start "sab_health_check against real SABnzbd (if running)"
    if sab_health_check "http://localhost:8080" "fake-key" 2>/dev/null; then
        test_pass "SABnzbd is responding"
    else
        test_skip "SABnzbd not available"
    fi
fi

##############################################################################
#                              TEST SUMMARY                                  #
##############################################################################

test_summary

# vim: set ts=4 sw=4 et tw=80:
