#!/usr/bin/env zsh
#=============================================================================
# webtest.zsh - Web UI automation testing using Playwright
# Part of Usenet Media Stack v1.0
#
# Provides comprehensive web interface testing including:
# - UI element validation
# - Service-specific functionality
# - Performance benchmarking
# - API endpoint validation
# - Cross-browser compatibility
#=============================================================================

# Load core utilities
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/../core/common.zsh" 2>/dev/null || {
    echo "Error: Cannot load common utilities" >&2
    exit 1
}

# Web testing directory
WEB_TEST_DIR="${SCRIPT_DIR}/../web-testing"

#=============================================================================
# Function: setup_web_testing
# Description: Install and configure Playwright testing environment
#=============================================================================
setup_web_testing() {
    info "🛠️ Setting up web testing environment..."
    
    # Check if Node.js is available
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js is required for web testing"
        info "Install Node.js:"
        info "  • Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && sudo apt-get install -y nodejs"
        info "  • macOS: brew install node"
        return 1
    fi
    
    local node_version=$(node --version)
    success "✓ Node.js available: ${node_version}"
    
    # Check if web testing directory exists
    if [[ ! -d "$WEB_TEST_DIR" ]]; then
        error "Web testing directory not found: $WEB_TEST_DIR"
        return 1
    fi
    
    # Install dependencies if needed
    if [[ ! -d "${WEB_TEST_DIR}/node_modules" ]]; then
        info "Installing Playwright and dependencies..."
        
        cd "$WEB_TEST_DIR" || return 1
        
        # Install npm packages
        if npm install; then
            success "✓ Dependencies installed"
        else
            error "Failed to install dependencies"
            return 1
        fi
        
        # Install browser binaries
        info "Installing Chromium browser for testing..."
        if npx playwright install chromium; then
            success "✓ Chromium browser installed"
        else
            warning "⚠ Browser installation failed (tests may still work with system browser)"
        fi
        
        cd - >/dev/null
    else
        success "✓ Dependencies already installed"
    fi
    
    return 0
}

#=============================================================================
# Function: run_web_tests
# Description: Execute web UI tests using Playwright
#=============================================================================
run_web_tests() {
    local suite="$1"
    [[ -z "$suite" ]] && suite="all"
    
    info "🧪 Running web UI tests (suite: ${suite})..."
    
    # Ensure setup is complete
    if ! setup_web_testing; then
        error "Web testing setup failed"
        return 1
    fi
    
    # Run the tests
    cd "$WEB_TEST_DIR" || return 1
    
    case "$suite" in
        web|ui)
            info "Testing web interfaces only..."
            node test-runner.js --suite=web
            ;;
        api)
            info "Testing API endpoints only..."
            node test-runner.js --suite=api
            ;;
        all)
            info "Running comprehensive test suite..."
            node test-runner.js --suite=all
            ;;
        *)
            error "Unknown test suite: $suite"
            return 1
            ;;
    esac
    
    local exit_code=$?
    cd - >/dev/null
    
    # Show report location
    if [[ -f "${WEB_TEST_DIR}/test-report.json" ]]; then
        echo
        info "📄 Detailed report available at:"
        info "   ${WEB_TEST_DIR}/test-report.json"
    fi
    
    return $exit_code
}

#=============================================================================
# Function: show_report
# Description: Display the latest test report
#=============================================================================
show_report() {
    local report_file="${WEB_TEST_DIR}/test-report.json"
    
    if [[ ! -f "$report_file" ]]; then
        warning "No test report found. Run 'usenet webtest all' first."
        return 1
    fi
    
    info "📊 Latest Test Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Parse and display summary using jq if available
    if command -v jq >/dev/null 2>&1; then
        local summary=$(jq -r '.summary' "$report_file" 2>/dev/null)
        if [[ -n "$summary" && "$summary" != "null" ]]; then
            echo "$summary" | jq -r '
                "📊 Total Tests: " + (.total | tostring) + "\n" +
                "✅ Passed: " + (.passed | tostring) + "\n" +
                "❌ Failed: " + (.failed | tostring) + "\n" +
                "⏱️ Duration: " + .duration + "\n" +
                "🕐 Timestamp: " + .timestamp
            '
        else
            # Fallback to simple display
            cat "$report_file"
        fi
    else
        # Simple display without jq
        info "Install 'jq' for formatted report display"
        cat "$report_file"
    fi
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 0
}

#=============================================================================
# Function: clean_test_environment
# Description: Clean up test environment and temporary files
#=============================================================================
clean_test_environment() {
    info "🧹 Cleaning web testing environment..."
    
    # Remove node_modules and package-lock.json
    if [[ -d "${WEB_TEST_DIR}/node_modules" ]]; then
        rm -rf "${WEB_TEST_DIR}/node_modules"
        success "✓ Removed node_modules"
    fi
    
    if [[ -f "${WEB_TEST_DIR}/package-lock.json" ]]; then
        rm -f "${WEB_TEST_DIR}/package-lock.json"
        success "✓ Removed package-lock.json"
    fi
    
    # Remove test reports
    if [[ -f "${WEB_TEST_DIR}/test-report.json" ]]; then
        rm -f "${WEB_TEST_DIR}/test-report.json"
        success "✓ Removed test reports"
    fi
    
    success "✅ Web testing environment cleaned"
    return 0
}

#=============================================================================
# Main command handler
#=============================================================================
main() {
    local action="$1"
    shift
    
    case "$action" in
        setup)
            setup_web_testing
            ;;
        run|test)
            local suite="${1:-all}"
            run_web_tests "$suite"
            ;;
        web|ui)
            run_web_tests "web"
            ;;
        api)
            run_web_tests "api"
            ;;
        all)
            run_web_tests "all"
            ;;
        report|show)
            show_report
            ;;
        clean)
            clean_test_environment
            ;;
        --help|-h|help)
            show_help
            return 0
            ;;
        "")
            # Default action: run all tests
            run_web_tests "all"
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
🧪 Web UI Automation Testing

USAGE
    usenet webtest [action] [options]

ACTIONS
    setup               Install and configure Playwright testing environment
    web                 Test web interfaces only  
    api                 Test API endpoints only
    all                 Run comprehensive test suite (default)
    report              Show latest test report
    clean               Clean up test environment

EXAMPLES
    Setup testing environment:
        $ usenet webtest setup
        
    Test web interfaces:
        $ usenet webtest web
        
    Test APIs:
        $ usenet webtest api
        
    Run all tests:
        $ usenet webtest all
        
    View test report:
        $ usenet webtest report

NOTES
    • Requires Node.js for Playwright automation
    • Tests validate actual UI functionality, not just HTTP responses
    • Generates detailed JSON reports with performance metrics
    • Supports headless browser testing for CI/CD integration
    • Tests service-specific UI elements and navigation

This provides comprehensive validation of web interface functionality.
EOF
}

# Execute main function with all arguments
main "$@"