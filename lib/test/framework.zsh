#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/framework.zsh
# Project: Usenet Media Stack
# Description: Testing framework following Stan's principles
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# A testing framework Stan would approve of:
# - Clear test names that explain what they test
# - Helpful failure messages that guide debugging
# - No clever tricks, just straightforward assertions
# - Each test is independent and repeatable
##############################################################################

##############################################################################
#                          TEST FRAMEWORK CORE                               #
##############################################################################

# Test counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g CURRENT_TEST=""

# Test output
typeset -g TEST_OUTPUT=""
typeset -g VERBOSE_TESTS=false

#=============================================================================
# Function: test_start
# Description: Begin a test with clear description
#
# Stan's rule: "Test names should explain what you're testing"
#
# Arguments:
#   $1 - Test description
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   test_start "Config loads environment variables correctly"
#=============================================================================
test_start() {
    local description=$1
    
    CURRENT_TEST="$description"
    ((TESTS_RUN++))
    
    if [[ "$VERBOSE_TESTS" == "true" ]]; then
        print "Running: $description"
    fi
}

#=============================================================================
# Function: assert_equals
# Description: Assert two values are equal
#
# Arguments:
#   $1 - Expected value
#   $2 - Actual value
#   $3 - Failure message (optional)
#
# Returns:
#   0 - Values are equal
#   1 - Values differ
#
# Example:
#   assert_equals "expected" "$result" "Function should return expected"
#=============================================================================
assert_equals() {
    local expected=$1
    local actual=$2
    local message="${3:-Values should be equal}"
    
    if [[ "$expected" == "$actual" ]]; then
        test_pass
        return 0
    else
        test_fail "$message" \
            "Expected: '$expected'" \
            "Actual:   '$actual'"
        return 1
    fi
}

#=============================================================================
# Function: assert_not_empty
# Description: Assert value is not empty
#
# Arguments:
#   $1 - Value to check
#   $2 - Failure message (optional)
#
# Returns:
#   0 - Value is not empty
#   1 - Value is empty
#
# Example:
#   assert_not_empty "$config_value" "Config should be loaded"
#=============================================================================
assert_not_empty() {
    local value=$1
    local message="${2:-Value should not be empty}"
    
    if [[ -n "$value" ]]; then
        test_pass
        return 0
    else
        test_fail "$message" \
            "Expected: non-empty value" \
            "Actual:   empty"
        return 1
    fi
}

#=============================================================================
# Function: assert_file_exists
# Description: Assert file exists
#
# Arguments:
#   $1 - File path
#   $2 - Failure message (optional)
#
# Returns:
#   0 - File exists
#   1 - File does not exist
#
# Example:
#   assert_file_exists "/path/to/config" "Config file should exist"
#=============================================================================
assert_file_exists() {
    local file_path=$1
    local message="${2:-File should exist}"
    
    if [[ -f "$file_path" ]]; then
        test_pass
        return 0
    else
        test_fail "$message" \
            "Expected: file exists at $file_path" \
            "Actual:   file not found"
        return 1
    fi
}

#=============================================================================
# Function: test_pass
# Description: Record test success
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   test_pass
#=============================================================================
test_pass() {
    ((TESTS_PASSED++))
    
    if [[ "$VERBOSE_TESTS" == "true" ]]; then
        print "  ✓ PASS: $CURRENT_TEST"
    fi
}

#=============================================================================
# Function: test_fail
# Description: Record test failure with helpful message
#
# Arguments:
#   $@ - Failure message lines
#
# Returns:
#   0 - Always succeeds (just records failure)
#
# Example:
#   test_fail "Config validation failed" "Missing required key: API_TOKEN"
#=============================================================================
test_fail() {
    ((TESTS_FAILED++))
    
    print "  ✗ FAIL: $CURRENT_TEST"
    
    for line in "$@"; do
        print "    $line"
    done
    
    print ""
}

#=============================================================================
# Function: run_test_suite
# Description: Run all tests in a directory
#
# Arguments:
#   $1 - Test directory path
#
# Returns:
#   0 - All tests passed
#   1 - Some tests failed
#
# Example:
#   run_test_suite "lib/test/unit"
#=============================================================================
run_test_suite() {
    local test_dir=$1
    
    print "Running test suite: $test_dir"
    print "═══════════════════════════════════════════════════════════════"
    
    # Reset counters
    TESTS_RUN=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    
    # Run all test files
    for test_file in "$test_dir"/*.test.zsh; do
        if [[ -f "$test_file" ]]; then
            print "\nRunning: $(basename "$test_file")"
            print "─────────────────────────────────────────────────────────"
            
            # Source and run the test
            source "$test_file"
        fi
    done
    
    # Show results
    show_test_results
    
    return $(( TESTS_FAILED > 0 ? 1 : 0 ))
}

#=============================================================================
# Function: show_test_results
# Description: Display test results summary
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   show_test_results
#=============================================================================
show_test_results() {
    print "\n"
    print "Test Results"
    print "═══════════════════════════════════════════════════════════════"
    print "Total:  $TESTS_RUN"
    print "Passed: $TESTS_PASSED"
    print "Failed: $TESTS_FAILED"
    
    if (( TESTS_FAILED == 0 )); then
        print "\n✅ All tests passed! Stan would be proud."
    else
        print "\n❌ $TESTS_FAILED test(s) failed. Stan says: fix them."
    fi
}

# Export functions
typeset -fx test_start assert_equals assert_not_empty assert_file_exists
typeset -fx test_pass test_fail run_test_suite show_test_results

# vim: set ts=4 sw=4 et tw=80: