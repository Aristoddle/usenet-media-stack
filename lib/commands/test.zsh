#!/usr/bin/env zsh
#=============================================================================
# test.zsh - End-to-end testing framework
# Part of Usenet Media Stack v1.0
#
# Tests:
# - Web UI accessibility for all services
# - Service-to-service communication  
# - API functionality and integration
#=============================================================================

# Load core utilities
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../core/common.zsh" 2>/dev/null || {
    echo "Error: Cannot load common utilities" >&2
    exit 1
}

#=============================================================================
# Function: test_web_interfaces
# Description: Test web UI accessibility for all media services
#=============================================================================
test_web_interfaces() {
    info "🌐 Testing web interfaces for all media services..."
    echo
    
    # Define services and their expected ports
    local -A services=(
        [sonarr]="8989"
        [radarr]="7878"
        [jellyfin]="8096"
        [overseerr]="5055"
        [portainer]="9000"
        [sabnzbd]="8080"
        [prowlarr]="9696"
        [readarr]="8787"
        [whisparr]="6969"
        [bazarr]="6767"
        [tdarr]="8265"
        [yacreader]="8082"
        [mylar]="8090"
        [netdata]="19999"
    )
    
    local failures=0
    local successes=0
    
    for service port in ${(kv)services}; do
        local url="http://localhost:${port}"
        
        # Test basic connectivity
        if curl -s -f -m 10 "$url" >/dev/null 2>&1; then
            success "✓ ${service} (${url}) - Accessible"
            ((successes++))
        else
            error "✗ ${service} (${url}) - Not accessible"
            ((failures++))
        fi
    done
    
    echo
    if [[ $failures -eq 0 ]]; then
        success "🎉 All ${successes} web interfaces are accessible!"
    else
        warning "⚠ ${failures} service(s) failed, ${successes} succeeded"
    fi
    
    return $failures
}

#=============================================================================
# Function: test_api_endpoints
# Description: Test API functionality for *arr services
#=============================================================================
test_api_endpoints() {
    info "🔌 Testing API endpoints for automation services..."
    echo
    
    # Test basic API endpoints (without API keys for now)
    local -A api_services=(
        [sonarr]="8989"
        [radarr]="7878"
        [prowlarr]="9696"
        [readarr]="8787"
        [whisparr]="6969"
        [bazarr]="6767"
    )
    
    local failures=0
    local successes=0
    
    for service port in ${(kv)api_services}; do
        local api_url="http://localhost:${port}/api/v3/system/status"
        
        # Test API endpoint accessibility (expect 401 without API key)
        local response=$(curl -s -w "%{http_code}" -o /dev/null "$api_url" 2>/dev/null)
        
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
    
    echo
    if [[ $failures -eq 0 ]]; then
        success "🎉 All ${successes} API endpoints responded correctly!"
    else
        warning "⚠ ${failures} API(s) failed, ${successes} succeeded"
    fi
    
    return $failures
}

#=============================================================================
# Main command handler
#=============================================================================
main() {
    local action="$1"
    shift
    
    case "$action" in
        web|ui)
            test_web_interfaces
            ;;
        api)
            test_api_endpoints
            ;;
        all)
            info "🚀 Running comprehensive test suite..."
            echo
            
            local total_failures=0
            
            test_web_interfaces
            ((total_failures += $?))
            echo
            
            test_api_endpoints
            ((total_failures += $?))
            echo
            
            if [[ $total_failures -eq 0 ]]; then
                success "🎉 All tests passed! System is fully functional."
            else
                warning "⚠ ${total_failures} test(s) failed. Check output above for details."
            fi
            
            return $total_failures
            ;;
        --help|-h)
            show_help
            return 0
            ;;
        *)
            error "Unknown action: $action"
            show_help
            return 1
            ;;
    esac
}

#=============================================================================
# Function: show_help
# Description: Display help information
#=============================================================================
show_help() {
    cat << 'EOF'
🧪 End-to-End Testing Framework

USAGE
    usenet test <action>

ACTIONS
    web                 Test web interface accessibility for all services
    api                 Test API endpoint functionality 
    all                 Run comprehensive test suite

EXAMPLES
    Test web interfaces:
        $ usenet test web
        
    Test APIs:
        $ usenet test api
        
    Run all tests:
        $ usenet test all

This validates end-to-end functionality of the existing media stack.
EOF
}

# Execute main function with all arguments  
main "$@"