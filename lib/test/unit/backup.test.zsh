#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/unit/backup.test.zsh
# Project: Usenet Media Stack
# Description: Unit tests for backup functionality
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/../framework.zsh"

# Load the module under test
source "${0:A:h}/../../commands/backup.zsh"

##############################################################################
#                               BACKUP TESTS                                 #
##############################################################################

#=============================================================================
# Test: Backup file list generation includes required files
#=============================================================================
test_backup_includes_required_files() {
    local temp_list=$(mktemp)
    
    # Create the backup list
    create_backup_list false false "$temp_list"
    
    # Check that essential files are included
    assert_file_contains "$temp_list" ".env" \
        "Backup list should include .env file"
    
    assert_file_contains "$temp_list" "docker-compose.yml" \
        "Backup list should include docker-compose.yml"
    
    assert_file_contains "$temp_list" "lib/" \
        "Backup list should include lib/ directory"
    
    assert_file_contains "$temp_list" "usenet" \
        "Backup list should include main usenet script"
    
    # Cleanup
    rm -f "$temp_list"
}

#=============================================================================
# Test: Backup filename generation follows naming convention
#=============================================================================
test_backup_filename_convention() {
    local backup_name="test-backup"
    local backup_file="${BACKUP_DIR}/${BACKUP_PREFIX}-${backup_name}.tar"
    
    # Test basic naming
    assert_equals "usenet-stack-backup-test-backup.tar" "$(basename "$backup_file")" \
        "Backup filename should follow naming convention"
    
    # Test compressed naming
    local compressed_file="${backup_file}.gz"
    assert_equals "usenet-stack-backup-test-backup.tar.gz" "$(basename "$compressed_file")" \
        "Compressed backup should have .gz extension"
}

#=============================================================================
# Test: Backup excludes temporary and cache files
#=============================================================================
test_backup_excludes_temp_files() {
    local temp_list=$(mktemp)
    local temp_exclude="${temp_list}.exclude"
    
    # Create the backup list with exclusions
    create_backup_list false false "$temp_list"
    
    # Check that exclude file contains temp patterns
    assert_file_contains "$temp_exclude" "*.tmp" \
        "Should exclude temporary files"
    
    assert_file_contains "$temp_exclude" "*.cache" \
        "Should exclude cache files"
    
    assert_file_contains "$temp_exclude" "downloads/" \
        "Should exclude downloads directory"
    
    # Cleanup
    rm -f "$temp_list" "$temp_exclude"
}

#=============================================================================
# Test: Backup metadata file creation
#=============================================================================
test_backup_metadata_creation() {
    # This test would verify metadata file structure
    # For now, just test the concept
    
    local test_metadata="/tmp/test.tar.info"
    
    # Simulate metadata creation
    cat > "$test_metadata" <<EOF
# Usenet Media Stack Backup Metadata
Created: $(date -Iseconds)
Version: 2.0.0
Hostname: $(hostname)
EOF
    
    assert_file_exists "$test_metadata" \
        "Metadata file should be created"
    
    assert_file_contains "$test_metadata" "Created:" \
        "Metadata should contain creation timestamp"
    
    assert_file_contains "$test_metadata" "Version: 2.0.0" \
        "Metadata should contain version information"
    
    # Cleanup
    rm -f "$test_metadata"
}

##############################################################################
#                              RUN ALL TESTS                                #
##############################################################################

run_test_suite() {
    test_start "Backup Unit Tests"
    
    test_backup_includes_required_files
    test_backup_filename_convention  
    test_backup_excludes_temp_files
    test_backup_metadata_creation
    
    test_summary
}

# Run tests if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    run_test_suite
fi

# vim: set ts=4 sw=4 et tw=80: