#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/integration/service-urls.test.zsh
# Project: Usenet Media Stack
# Description: Integration tests for SERVICE_URLS configuration
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/../framework.zsh"

# Load required modules
source "${0:A:h}/../../core/common.zsh"
source "${0:A:h}/../../core/init.zsh"

##############################################################################
#                         SERVICE URLS INTEGRATION TESTS                     #
##############################################################################

#=============================================================================
# Test: SERVICE_URLS loads all required services
#=============================================================================
test_service_urls_loads_all_services() {
    # Load configuration
    load_stack_config >/dev/null 2>&1
    
    # Test core services are defined
    local core_services=("sabnzbd" "prowlarr" "sonarr" "radarr" "lidarr" "bazarr" "mylar3")
    
    for service in $core_services; do
        if [[ -n "$SERVICE_URLS[$service]" ]]; then
            test_pass "SERVICE_URLS contains $service"
        else
            test_fail "SERVICE_URLS missing $service"
        fi
    done
    
    # Test media services are defined
    local media_services=("plex" "overseerr")
    
    for service in $media_services; do
        if [[ -n "$SERVICE_URLS[$service]" ]]; then
            test_pass "SERVICE_URLS contains media service $service"
        else
            test_fail "SERVICE_URLS missing media service $service"
        fi
    done
    
    # Test management services are defined
    local mgmt_services=("portainer" "tautulli" "netdata")
    
    for service in $mgmt_services; do
        if [[ -n "$SERVICE_URLS[$service]" ]]; then
            test_pass "SERVICE_URLS contains management service $service"
        else
            test_fail "SERVICE_URLS missing management service $service"
        fi
    done
}

#=============================================================================
# Test: SERVICE_URLS use environment variables correctly
#=============================================================================
test_service_urls_use_environment_variables() {
    # Load configuration
    load_stack_config >/dev/null 2>&1
    
    # Test that URLs follow expected format
    for service url in ${(kv)SERVICE_URLS}; do
        if [[ "$url" =~ ^https?://[^:]+:[0-9]+$ ]]; then
            test_pass "$service URL follows correct format: $url"
        else
            test_fail "$service URL has invalid format: $url"
        fi
    done
}

#=============================================================================
# Test: No hardcoded localhost URLs in command files
#=============================================================================
test_no_hardcoded_localhost_urls() {
    local commands_dir="${0:A:h}/../../commands"
    local hardcoded_found=false
    
    # Search for hardcoded localhost URLs (excluding comments)
    for file in "$commands_dir"/*.zsh; do
        [[ ! -f "$file" ]] && continue
        
        # Check for hardcoded localhost (excluding comment lines)
        local hardcoded_lines=$(grep -n "localhost:[0-9]" "$file" | grep -v "^[[:space:]]*#" | wc -l)
        
        if [[ $hardcoded_lines -gt 0 ]]; then
            test_fail "Found $hardcoded_lines hardcoded localhost URLs in $(basename "$file")"
            hardcoded_found=true
        fi
    done
    
    if [[ "$hardcoded_found" == "false" ]]; then
        test_pass "No hardcoded localhost URLs found in command files"
    fi
}

#=============================================================================
# Test: Commands use SERVICE_URLS instead of hardcoded values
#=============================================================================
test_commands_use_service_urls() {
    local commands_dir="${0:A:h}/../../commands"
    
    # Check that SERVICE_URLS is referenced in key files
    local key_files=("manage.zsh" "test.zsh" "setup.zsh")
    
    for file in $key_files; do
        local file_path="$commands_dir/$file"
        [[ ! -f "$file_path" ]] && continue
        
        if grep -q "SERVICE_URLS\[" "$file_path"; then
            test_pass "$file uses SERVICE_URLS array"
        else
            test_fail "$file should use SERVICE_URLS array"
        fi
    done
}

#=============================================================================
# Test: Environment variable defaults work correctly
#=============================================================================
test_environment_variable_defaults() {
    # Temporarily unset environment variables to test defaults
    local original_sonarr_host="$SONARR_HOST"
    local original_sonarr_port="$SONARR_PORT"
    
    unset SONARR_HOST SONARR_PORT
    
    # Reload configuration
    load_stack_config >/dev/null 2>&1
    
    # Check that defaults are applied
    local expected_url="http://localhost:8989"
    if [[ "$SERVICE_URLS[sonarr]" == "$expected_url" ]]; then
        test_pass "Default values applied correctly for Sonarr"
    else
        test_fail "Default values not applied: got $SERVICE_URLS[sonarr], expected $expected_url"
    fi
    
    # Restore original values
    export SONARR_HOST="$original_sonarr_host"
    export SONARR_PORT="$original_sonarr_port"
}

#=============================================================================
# Test: Custom environment variables override defaults
#=============================================================================
test_custom_environment_overrides() {
    # Set custom values
    export RADARR_HOST="custom-host"
    export RADARR_PORT="7777"
    
    # Reload configuration
    load_stack_config >/dev/null 2>&1
    
    # Check that custom values are used
    local expected_url="http://custom-host:7777"
    if [[ "$SERVICE_URLS[radarr]" == "$expected_url" ]]; then
        test_pass "Custom environment variables override defaults"
    else
        test_fail "Custom values not used: got $SERVICE_URLS[radarr], expected $expected_url"
    fi
    
    # Restore defaults
    unset RADARR_HOST RADARR_PORT
}

##############################################################################
#                              RUN ALL TESTS                                #
##############################################################################

run_test_suite() {
    test_start "SERVICE_URLS Integration Tests"
    
    test_service_urls_loads_all_services
    test_service_urls_use_environment_variables
    test_no_hardcoded_localhost_urls
    test_commands_use_service_urls
    test_environment_variable_defaults
    test_custom_environment_overrides
    
    test_summary
}

# Run tests if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    run_test_suite
fi

# vim: set ts=4 sw=4 et tw=80:
