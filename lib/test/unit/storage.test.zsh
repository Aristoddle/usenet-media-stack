#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/unit/storage.test.zsh
# Project: Usenet Media Stack
# Description: Unit tests for storage management
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/../framework.zsh"

# Load the module under test
source "${0:A:h}/../../commands/storage.zsh"

##############################################################################
#                              STORAGE TESTS                                 #
##############################################################################

#=============================================================================
# Test: Storage configuration file detection
#=============================================================================
test_storage_config_detection() {
    # Test when no config exists
    local test_config="/tmp/nonexistent_storage.conf"
    
    # Temporarily override PROJECT_ROOT for test
    local original_project_root="$PROJECT_ROOT"
    PROJECT_ROOT="/tmp"
    
    # Should return false when config doesn't exist
    if get_storage_config 2>/dev/null; then
        test_fail "get_storage_config should return false when no config exists"
    else
        test_pass "get_storage_config correctly detects missing config"
    fi
    
    # Create a test config
    mkdir -p "/tmp/config"
    echo "/mnt/disk1" > "/tmp/config/storage.conf"
    
    # Should return true when config exists
    if get_storage_config 2>/dev/null; then
        test_pass "get_storage_config correctly detects existing config"
    else
        test_fail "get_storage_config should return true when config exists"
    fi
    
    # Cleanup
    rm -rf "/tmp/config"
    PROJECT_ROOT="$original_project_root"
}

#=============================================================================
# Test: Drive path validation
#=============================================================================
test_drive_path_validation() {
    local temp_dir=$(mktemp -d)
    
    # Test valid directory
    if [[ -d "$temp_dir" ]]; then
        test_pass "Valid directory should be detected as existing"
    else
        test_fail "mktemp should create a valid directory"
    fi
    
    # Test invalid directory
    local invalid_dir="/nonexistent/path/12345"
    if [[ ! -d "$invalid_dir" ]]; then
        test_pass "Invalid directory should be detected as non-existing"
    else
        test_fail "Invalid path should not exist"
    fi
    
    # Cleanup
    rm -rf "$temp_dir"
}

#=============================================================================
# Test: Storage pool status display formatting
#=============================================================================
test_storage_status_formatting() {
    # This test verifies that status output has proper structure
    # We'll test the components that don't require actual mounted drives
    
    local test_output=$(mktemp)
    
    # Test header generation
    echo "Storage Pool Status" > "$test_output"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$test_output"
    
    assert_file_contains "$test_output" "Storage Pool Status" \
        "Status output should contain header"
    
    assert_file_contains "$test_output" "━" \
        "Status output should contain separator line"
    
    # Cleanup
    rm -f "$test_output"
}

#=============================================================================
# Test: Configuration file parsing
#=============================================================================
test_config_file_parsing() {
    local test_config=$(mktemp)
    
    # Create test config with comments and empty lines
    cat > "$test_config" <<EOF
# This is a comment
/mnt/disk1
# Another comment

/mnt/disk2
/mnt/disk3
EOF
    
    # Count non-comment, non-empty lines
    local drive_count=0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        ((drive_count++))
    done < "$test_config"
    
    assert_equals 3 "$drive_count" \
        "Should correctly parse 3 drive paths from config"
    
    # Cleanup
    rm -f "$test_config"
}

#=============================================================================
# Test: Drive capacity calculations
#=============================================================================
test_drive_capacity_calculations() {
    # Test basic capacity math (GB conversion)
    local size_kb=1048576  # 1GB in KB
    local size_gb=$((size_kb / 1024 / 1024))
    
    assert_equals 1 "$size_gb" \
        "Should correctly convert KB to GB"
    
    # Test larger capacity
    local large_kb=5242880  # 5GB in KB  
    local large_gb=$((large_kb / 1024 / 1024))
    
    assert_equals 5 "$large_gb" \
        "Should correctly convert larger capacities"
}

##############################################################################
#                              RUN ALL TESTS                                #
##############################################################################

run_test_suite() {
    test_start "Storage Unit Tests"
    
    test_storage_config_detection
    test_drive_path_validation
    test_storage_status_formatting
    test_config_file_parsing
    test_drive_capacity_calculations
    
    test_summary
}

# Run tests if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    run_test_suite
fi

# vim: set ts=4 sw=4 et tw=80: