#!/bin/bash
###############################################################################
#  test-everything.sh - Comprehensive automated test of the entire stack
#  Uses Playwright to test EVERYTHING through actual web interfaces
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Usenet Media Stack - Complete Automated Testing${NC}"
echo "=================================================="
echo

# Check if we have sudo
if [[ $EUID -ne 0 ]]; then
   echo "fishing123" | exec sudo -S "$0" "$@"
fi

# Function to install Python dependencies
install_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    
    # Check if Python 3 is installed
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Python 3 is required but not installed.${NC}"
        exit 1
    fi
    
    # Check if pip is installed
    if ! python3 -m pip --version &> /dev/null; then
        echo -e "${YELLOW}Installing pip...${NC}"
        apt-get update && apt-get install -y python3-pip
    fi
    
    # Set up virtual environment if needed
    VENV_DIR="$SCRIPT_DIR/.venv"
    if [[ ! -d "$VENV_DIR" ]]; then
        echo -e "${YELLOW}Creating virtual environment...${NC}"
        python3 -m venv "$VENV_DIR"
    fi
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    # Check if playwright is installed
    if ! python -c "import playwright" 2>/dev/null; then
        echo -e "${YELLOW}Installing Playwright...${NC}"
        pip install --upgrade pip
        pip install playwright
        playwright install chromium
        playwright install-deps
    fi
    
    # Check if asyncio is available (should be built-in)
    if ! python3 -c "import asyncio" 2>/dev/null; then
        echo -e "${RED}asyncio not available. Python 3.7+ required.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All dependencies satisfied${NC}"
}

# Function to run pre-flight checks
preflight_checks() {
    echo -e "\n${BLUE}Running pre-flight checks...${NC}"
    
    # Check Docker
    if ! docker ps &>/dev/null; then
        echo -e "${RED}✗ Docker is not running${NC}"
        exit 1
    else
        echo -e "${GREEN}✓ Docker is running${NC}"
    fi
    
    # Check if services are up
    RUNNING_SERVICES=$(docker ps --format "{{.Names}}" | wc -l)
    echo -e "${GREEN}✓ Found $RUNNING_SERVICES running containers${NC}"
    
    # Check network connectivity
    if ping -c 1 google.com &>/dev/null; then
        echo -e "${GREEN}✓ Internet connectivity OK${NC}"
    else
        echo -e "${YELLOW}⚠ No internet connectivity (some tests may fail)${NC}"
    fi
    
    # Check disk space
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [[ $DISK_USAGE -lt 90 ]]; then
        echo -e "${GREEN}✓ Disk space OK (${DISK_USAGE}% used)${NC}"
    else
        echo -e "${YELLOW}⚠ Low disk space (${DISK_USAGE}% used)${NC}"
    fi
}

# Function to run quick sanity checks
sanity_checks() {
    echo -e "\n${BLUE}Running sanity checks...${NC}"
    
    # Check if configuration files exist
    if [[ -f "$SCRIPT_DIR/config/sabnzbd/sabnzbd.ini" ]]; then
        echo -e "${GREEN}✓ SABnzbd configuration found${NC}"
    else
        echo -e "${YELLOW}⚠ SABnzbd configuration not found${NC}"
    fi
    
    # Check if API keys are present
    API_KEY_COUNT=0
    [[ -n "$(grep -oP '(?<=api_key = )[^\s]+' "$SCRIPT_DIR/config/sabnzbd/sabnzbd.ini" 2>/dev/null)" ]] && ((API_KEY_COUNT++))
    [[ -n "$(grep -oP '(?<=<ApiKey>)[^<]+' "$SCRIPT_DIR/config/prowlarr/config.xml" 2>/dev/null)" ]] && ((API_KEY_COUNT++))
    [[ -n "$(grep -oP '(?<=<ApiKey>)[^<]+' "$SCRIPT_DIR/config/sonarr/config.xml" 2>/dev/null)" ]] && ((API_KEY_COUNT++))
    [[ -n "$(grep -oP '(?<=<ApiKey>)[^<]+' "$SCRIPT_DIR/config/radarr/config.xml" 2>/dev/null)" ]] && ((API_KEY_COUNT++))
    
    echo -e "${GREEN}✓ Found $API_KEY_COUNT service API keys${NC}"
}

# Main execution
main() {
    # Parse arguments
    HEADLESS="--headless"
    VERBOSE=""
    
    for arg in "$@"; do
        case $arg in
            --headed)
                HEADLESS=""
                echo "Running in headed mode (browser visible)"
                ;;
            --verbose|-v)
                VERBOSE="--verbose"
                echo "Verbose mode enabled"
                ;;
            --help|-h)
                echo "Usage: $0 [options]"
                echo "Options:"
                echo "  --headed    Show browser window during tests"
                echo "  --verbose   Show detailed test output"
                echo "  --help      Show this help message"
                exit 0
                ;;
        esac
    done
    
    # Install dependencies
    install_dependencies
    
    # Run checks
    preflight_checks
    sanity_checks
    
    # Run the comprehensive test suite
    echo -e "\n${BLUE}Starting automated test suite...${NC}"
    echo "This will test all services through their web interfaces."
    echo "Tests include:"
    echo "  • Service accessibility"
    echo "  • Configuration validation"
    echo "  • Integration testing"
    echo "  • Media flow simulation"
    echo
    
    # Change to script directory
    cd "$SCRIPT_DIR"
    
    # Run the Python test script (using virtual environment's python)
    python "$SCRIPT_DIR/scripts/automated-full-test.py" $HEADLESS $VERBOSE
    
    EXIT_CODE=$?
    
    # Show results summary
    if [[ $EXIT_CODE -eq 0 ]]; then
        echo -e "\n${GREEN}✅ All tests passed!${NC}"
        echo "Your Usenet Media Stack is fully operational."
        
        echo -e "\n${BLUE}Next steps:${NC}"
        echo "1. Access Jellyfin at http://localhost:8096"
        echo "2. Use Overseerr at http://localhost:5055 to request media"
        echo "3. Monitor downloads at http://localhost:8080 (SABnzbd)"
        
    else
        echo -e "\n${RED}❌ Some tests failed.${NC}"
        echo "Check test-results.json for detailed information."
        
        echo -e "\n${BLUE}Troubleshooting steps:${NC}"
        echo "1. Check docker logs: docker logs [container-name]"
        echo "2. Verify services are running: docker ps"
        echo "3. Check configuration files in ./config/"
    fi
    
    # Show where results are saved
    echo -e "\n${BLUE}📊 Test Results:${NC}"
    echo "  • Summary displayed above"
    echo "  • Detailed results: $SCRIPT_DIR/test-results.json"
    echo "  • Screenshots (if any): $SCRIPT_DIR/test-screenshots/"
    
    exit $EXIT_CODE
}

# Create directories for test artifacts
mkdir -p "$SCRIPT_DIR/test-screenshots"
mkdir -p "$SCRIPT_DIR/test-logs"

# Run main function
main "$@"