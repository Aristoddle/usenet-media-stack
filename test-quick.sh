#!/bin/bash
###############################################################################
# test-quick.sh - Quick test suite that doesn't require sudo
# Focuses on API connectivity and basic functionality
###############################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0

# Test function
test_service() {
    local name="$1"
    local url="$2"
    local expected="$3"
    
    echo -n "Testing $name... "
    if curl -s -f -o /dev/null --max-time 2 "$url"; then
        echo -e "${GREEN}✓${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC}"
        ((FAILED++))
    fi
}

echo -e "${BLUE}🧪 Quick Usenet Stack Tests${NC}"
echo "=============================="

# Test service availability
echo -e "\n${YELLOW}Service Availability:${NC}"
test_service "SABnzbd" "http://localhost:8080/sabnzbd/" "200"
test_service "Prowlarr" "http://localhost:9696" "200"
test_service "Sonarr" "http://localhost:8989" "200"
test_service "Radarr" "http://localhost:7878" "200"
test_service "Readarr" "http://localhost:8787" "200"
test_service "Mylar3" "http://localhost:8090" "200"
test_service "Bazarr" "http://localhost:6767" "200"
test_service "Jellyfin" "http://localhost:8096" "200"
test_service "Overseerr" "http://localhost:5055" "200"

# Test API endpoints
echo -e "\n${YELLOW}API Endpoints:${NC}"

# SABnzbd API
if sabnzbd_key=$(grep -oP 'api_key = \K.*' "$SCRIPT_DIR/config/sabnzbd/sabnzbd.ini" 2>/dev/null); then
    test_service "SABnzbd API" "http://localhost:8080/sabnzbd/api?mode=version&apikey=$sabnzbd_key" "200"
else
    echo -e "SABnzbd API... ${YELLOW}⚠ No API key found${NC}"
fi

# Prowlarr API
if prowlarr_key=$(grep -oP '<ApiKey>\K[^<]+' "$SCRIPT_DIR/config/prowlarr/config.xml" 2>/dev/null); then
    test_service "Prowlarr API" "http://localhost:9696/api/v1/health?apikey=$prowlarr_key" "200"
else
    echo -e "Prowlarr API... ${YELLOW}⚠ No API key found${NC}"
fi

# Test Docker containers
echo -e "\n${YELLOW}Docker Containers:${NC}"
services=(sabnzbd prowlarr sonarr radarr readarr mylar3 bazarr jellyfin overseerr)
for service in "${services[@]}"; do
    echo -n "Container $service... "
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        echo -e "${GREEN}✓ Running${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗ Not running${NC}"
        ((FAILED++))
    fi
done

# Summary
echo -e "\n${BLUE}Test Summary:${NC}"
echo "=============="
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed${NC}"
    exit 1
fi