#!/usr/bin/env zsh
##############################################################################
# File: ./lib/test/integration/full-stack.test.zsh
# Project: Usenet Media Stack
# Description: Integration tests for complete stack
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
##############################################################################

# Load test framework
source "${0:A:h}/../framework.zsh"

# Load stack
source "${0:A:h}/../../core/common.zsh"
source "${0:A:h}/../../core/init.zsh"

##############################################################################
#                         INTEGRATION TESTS                                  #
##############################################################################

test_configuration_loading() {
    test_start "Stack configuration loads without errors"
    
    # Should load config successfully
    if load_stack_config; then
        test_pass
    else
        test_fail "Configuration failed to load"
        return 1
    fi
    
    # Should have service URLs
    assert_not_empty "${SERVICE_URLS[sonarr]}" "Sonarr URL should be set"
    assert_not_empty "${SERVICE_URLS[sabnzbd]}" "SABnzbd URL should be set"
}

test_environment_variables() {
    test_start "Required environment variables are present"
    
    # Load config first
    load_stack_config
    
    # Check domain
    assert_not_empty "$DOMAIN" "Domain should be configured"
    assert_equals "beppesarrstack.net" "$DOMAIN" "Should use correct domain"
    
    # Check at least one provider
    if [[ ${#PROVIDERS[@]} -eq 0 ]]; then
        test_fail "No Usenet providers configured"
        return 1
    else
        test_pass
    fi
    
    # Check at least one indexer
    if [[ ${#INDEXERS[@]} -eq 0 ]]; then
        test_fail "No indexers configured"
        return 1
    else
        test_pass
    fi
}

test_service_urls_format() {
    test_start "Service URLs are properly formatted"
    
    load_stack_config
    
    for service url in ${(kv)SERVICE_URLS}; do
        # URL should start with http
        if [[ "$url" =~ ^https?:// ]]; then
            test_pass
        else
            test_fail "Invalid URL format for $service: $url"
            return 1
        fi
    done
}

test_docker_compose_exists() {
    test_start "Docker compose file exists and is valid"
    
    local compose_file="$PROJECT_ROOT/docker-compose.yml"
    assert_file_exists "$compose_file" "Main compose file should exist"
    
    # Should be valid YAML
    if command -v docker >/dev/null 2>&1; then
        if docker compose -f "$compose_file" config >/dev/null 2>&1; then
            test_pass
        else
            test_fail "Docker compose file is invalid"
            return 1
        fi
    else
        test_result "Docker validation" "skip" "Docker not available"
    fi
}

test_directory_structure() {
    test_start "Required directories exist"
    
    local required_dirs=(
        "$PROJECT_ROOT/lib/core"
        "$PROJECT_ROOT/lib/commands"
        "$PROJECT_ROOT/lib/test"
        "$PROJECT_ROOT/docs"
    )
    
    for dir in $required_dirs; do
        if [[ -d "$dir" ]]; then
            test_pass
        else
            test_fail "Required directory missing: $dir"
            return 1
        fi
    done
}

##############################################################################
#                              RUN TESTS                                     #
##############################################################################

# Run all integration tests
test_configuration_loading
test_environment_variables
test_service_urls_format
test_docker_compose_exists
test_directory_structure

# vim: set ts=4 sw=4 et tw=80: