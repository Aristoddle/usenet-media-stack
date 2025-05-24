#!/bin/bash
###############################################################################
#  test-setup.sh - Test and validate the complete Usenet stack setup
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Testing Usenet Stack Setup ==="
echo

# Test service accessibility
test_service() {
    local name="$1"
    local url="$2"
    local expected_code="${3:-200}"
    
    printf "Testing %-15s" "$name..."
    
    local code=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
    
    if [[ "$code" == "$expected_code" ]] || [[ "$code" == "301" ]] || [[ "$code" == "302" ]] || [[ "$code" == "303" ]]; then
        echo -e "${GREEN}✓${NC} Accessible at $url"
        return 0
    else
        echo -e "${RED}✗${NC} Not accessible (HTTP $code)"
        return 1
    fi
}

# Test API endpoints
test_api() {
    local name="$1"
    local url="$2"
    local api_key="$3"
    
    printf "Testing %-15s" "$name API..."
    
    local response=$(curl -s "$url" 2>/dev/null || echo "")
    
    if [[ -n "$response" ]] && [[ "$response" != *"error"* ]]; then
        echo -e "${GREEN}✓${NC} API responding"
        return 0
    else
        echo -e "${RED}✗${NC} API not responding"
        return 1
    fi
}

# Main tests
echo "1. Service Accessibility Tests"
echo "------------------------------"
test_service "SABnzbd" "http://localhost:8080"
test_service "Prowlarr" "http://localhost:9696"
test_service "Sonarr" "http://localhost:8989"
test_service "Radarr" "http://localhost:7878"
test_service "Readarr" "http://localhost:8787"
test_service "Bazarr" "http://localhost:6767"
test_service "Mylar3" "http://localhost:8090"
test_service "Transmission" "http://localhost:9092"
test_service "Portainer" "http://localhost:9000"
test_service "Netdata" "http://localhost:19999"

echo
echo "2. Configuration Validation"
echo "---------------------------"

# Check SABnzbd providers
printf "SABnzbd providers..."
if grep -q "Newshosting" "$SCRIPT_DIR/../config/sabnzbd/sabnzbd.ini" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Configured in config file"
else
    echo -e "${RED}✗${NC} Not configured"
fi

# Check authentication settings
printf "Local access auth..."
if grep -q "username = $" "$SCRIPT_DIR/../config/sabnzbd/sabnzbd.ini" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} Passwordless access enabled"
else
    echo -e "${YELLOW}⚠${NC} Authentication may be required"
fi

echo
echo "3. API Key Extraction"
echo "--------------------"

# Extract API keys
for service in sabnzbd prowlarr sonarr radarr readarr; do
    printf "%-15s" "$service..."
    
    case $service in
        sabnzbd)
            api_key=$(grep -oP '(?<=api_key = )[^\s]+' "$SCRIPT_DIR/../config/sabnzbd/sabnzbd.ini" 2>/dev/null || echo "")
            ;;
        *)
            api_key=$(grep -oP '(?<=<ApiKey>)[^<]+' "$SCRIPT_DIR/../config/$service/config.xml" 2>/dev/null || echo "")
            ;;
    esac
    
    if [[ -n "$api_key" ]]; then
        echo -e "${GREEN}✓${NC} ${api_key:0:8}..."
    else
        echo -e "${RED}✗${NC} Not found"
    fi
done

echo
echo "4. Download Directory Permissions"
echo "---------------------------------"

# Check download directories
for dir in complete incomplete; do
    printf "downloads/%-10s" "$dir..."
    if [[ -d "$SCRIPT_DIR/../downloads/$dir" ]] && [[ -w "$SCRIPT_DIR/../downloads/$dir" ]]; then
        echo -e "${GREEN}✓${NC} Exists and writable"
    else
        echo -e "${RED}✗${NC} Missing or not writable"
    fi
done

echo
echo "=== Test Summary ==="
echo "Services are configured for passwordless local access."
echo "To complete setup, use the web interfaces to:"
echo "1. Add indexers to Prowlarr"
echo "2. Connect Prowlarr to *arr apps"
echo "3. Connect SABnzbd to *arr apps"
echo "4. Test a download"
echo
echo "Or run: ./one-click-setup.sh for automated configuration"