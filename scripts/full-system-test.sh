#!/bin/bash
###############################################################################
#  full-system-test.sh - Comprehensive end-to-end test of the entire stack
###############################################################################

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Usenet Media Stack - Full System Test ===${NC}"
echo "Starting at: $(date)"
echo

# Test results tracking
PASSED=0
FAILED=0
WARNINGS=0

# Helper functions
test_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# 1. Container Health Check
echo -e "${BLUE}1. Container Health Check${NC}"
echo "------------------------"

# Check if all containers are running
EXPECTED_CONTAINERS=(
    "sabnzbd" "prowlarr" "sonarr" "radarr" "readarr" "bazarr" "mylar"
    "transmission" "jackett" "netdata" "portainer" "yacreader"
    "jellyfin" "overseerr" "unpackerr" "tautulli"
)

for container in "${EXPECTED_CONTAINERS[@]}"; do
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        test_pass "Container $container is running"
    else
        # Check if it exists but stopped
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            test_warn "Container $container exists but is not running"
        else
            test_fail "Container $container not found"
        fi
    fi
done

echo

# 2. Service Accessibility Test
echo -e "${BLUE}2. Service Accessibility Test${NC}"
echo "-----------------------------"

declare -A SERVICES=(
    ["SABnzbd"]="http://localhost:8080"
    ["Prowlarr"]="http://localhost:9696"
    ["Sonarr"]="http://localhost:8989"
    ["Radarr"]="http://localhost:7878"
    ["Readarr"]="http://localhost:8787"
    ["Bazarr"]="http://localhost:6767"
    ["Mylar3"]="http://localhost:8090"
    ["Transmission"]="http://localhost:9092"
    ["Jackett"]="http://localhost:9117"
    ["Netdata"]="http://localhost:19999"
    ["Portainer"]="http://localhost:9000"
    ["YACReader"]="http://localhost:8082"
    ["Jellyfin"]="http://localhost:8096"
    ["Overseerr"]="http://localhost:5055"
    ["Tautulli"]="http://localhost:8181"
)

for service in "${!SERVICES[@]}"; do
    URL="${SERVICES[$service]}"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$URL" 2>/dev/null || echo "000")
    
    case $HTTP_CODE in
        200|301|302|303|307)
            test_pass "$service is accessible at $URL (HTTP $HTTP_CODE)"
            ;;
        401|403)
            test_warn "$service requires authentication at $URL (HTTP $HTTP_CODE)"
            ;;
        000)
            test_fail "$service is not responding at $URL"
            ;;
        *)
            test_warn "$service returned unexpected code at $URL (HTTP $HTTP_CODE)"
            ;;
    esac
done

echo

# 3. API Key Validation
echo -e "${BLUE}3. API Key Validation${NC}"
echo "---------------------"

# Check SABnzbd API
SABNZBD_API=$(grep -oP '(?<=api_key = )[^\s]+' $HOME/usenet/config/sabnzbd/sabnzbd.ini 2>/dev/null || echo "")
if [[ -n "$SABNZBD_API" ]]; then
    if curl -s "http://localhost:8080/sabnzbd/api?mode=version&apikey=$SABNZBD_API&output=json" | grep -q "version"; then
        test_pass "SABnzbd API key is valid"
    else
        test_fail "SABnzbd API key is invalid"
    fi
else
    test_fail "SABnzbd API key not found"
fi

# Check Prowlarr API
PROWLARR_API=$(grep -oP '(?<=<ApiKey>)[^<]+' $HOME/usenet/config/prowlarr/config.xml 2>/dev/null || echo "")
if [[ -n "$PROWLARR_API" ]]; then
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Api-Key: $PROWLARR_API" "http://localhost:9696/api/v1/system/status" 2>/dev/null)
    if [[ "$HTTP_CODE" == "200" ]]; then
        test_pass "Prowlarr API key is valid"
    else
        test_fail "Prowlarr API key is invalid (HTTP $HTTP_CODE)"
    fi
else
    test_fail "Prowlarr API key not found"
fi

# Check other *arr services
for service in sonarr radarr readarr; do
    API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' $HOME/usenet/config/$service/config.xml 2>/dev/null || echo "")
    if [[ -n "$API_KEY" ]]; then
        test_pass "$service API key found: ${API_KEY:0:8}..."
    else
        test_warn "$service API key not found"
    fi
done

echo

# 4. Storage and Permissions
echo -e "${BLUE}4. Storage and Permissions${NC}"
echo "--------------------------"

# Check download directories
DOWNLOAD_DIRS=("$HOME/usenet/downloads/complete" "$HOME/usenet/downloads/incomplete")
for dir in "${DOWNLOAD_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        if [[ -w "$dir" ]]; then
            test_pass "Directory $dir exists and is writable"
        else
            test_fail "Directory $dir exists but is not writable"
        fi
    else
        test_fail "Directory $dir does not exist"
    fi
done

# Check media drives
MEDIA_DRIVES=$(find /media/$USER -maxdepth 1 -name "*TB*" -type d 2>/dev/null | wc -l)
if [[ $MEDIA_DRIVES -gt 0 ]]; then
    test_pass "Found $MEDIA_DRIVES media drives mounted"
else
    test_warn "No media drives found under /media/$USER"
fi

echo

# 5. Service Integration Tests
echo -e "${BLUE}5. Service Integration Tests${NC}"
echo "----------------------------"

# Check if SABnzbd has servers configured
if grep -q "\[\[Newshosting\]\]" $HOME/usenet/config/sabnzbd/sabnzbd.ini 2>/dev/null; then
    test_pass "SABnzbd has Usenet providers configured"
else
    test_fail "SABnzbd providers not configured"
fi

# Check Docker networks
if docker network ls | grep -q "media_network"; then
    test_pass "Docker media_network exists"
else
    test_fail "Docker media_network not found"
fi

if docker network ls | grep -q "sharing_network"; then
    test_pass "Docker sharing_network exists"
else
    test_warn "Docker sharing_network not found"
fi

echo

# 6. Resource Usage Check
echo -e "${BLUE}6. Resource Usage Check${NC}"
echo "-----------------------"

# Check system resources
MEMORY_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F, '{print $1}' | xargs)

if [[ $MEMORY_USAGE -lt 80 ]]; then
    test_pass "Memory usage is healthy: ${MEMORY_USAGE}%"
else
    test_warn "Memory usage is high: ${MEMORY_USAGE}%"
fi

echo "CPU Load Average: $CPU_LOAD"

# Check disk space
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $DISK_USAGE -lt 80 ]]; then
    test_pass "Root disk usage is healthy: ${DISK_USAGE}%"
else
    test_warn "Root disk usage is high: ${DISK_USAGE}%"
fi

echo

# 7. Media Flow Test
echo -e "${BLUE}7. Media Flow Test${NC}"
echo "------------------"

# Check if Jellyfin can see media directories
if docker exec jellyfin ls /media/library >/dev/null 2>&1; then
    test_pass "Jellyfin can access media library"
else
    test_fail "Jellyfin cannot access media library"
fi

# Check if Unpackerr is monitoring
if docker logs unpackerr --tail 5 2>&1 | grep -q "Queue:"; then
    test_pass "Unpackerr is actively monitoring"
else
    test_warn "Unpackerr monitoring status unclear"
fi

echo

# 8. Configuration Files Check
echo -e "${BLUE}8. Configuration Files Check${NC}"
echo "----------------------------"

CONFIG_FILES=(
    "$HOME/usenet/.env"
    "$HOME/usenet/docker-compose.yml"
    "$HOME/usenet/docker-compose.media.yml"
    "$HOME/usenet/one-click-setup.sh"
)

for file in "${CONFIG_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        test_pass "Configuration file exists: $(basename $file)"
    else
        test_fail "Configuration file missing: $(basename $file)"
    fi
done

echo

# Final Summary
echo -e "${BLUE}=== Test Summary ===${NC}"
echo "-------------------"
echo -e "Passed:   ${GREEN}$PASSED${NC}"
echo -e "Failed:   ${RED}$FAILED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ All critical tests passed!${NC}"
    echo "Your Usenet Media Stack is fully operational."
    EXIT_CODE=0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    echo "Please check the failed items above."
    EXIT_CODE=1
fi

echo
echo "Test completed at: $(date)"

# Provide next steps
echo
echo -e "${BLUE}Next Steps:${NC}"
if [[ $FAILED -eq 0 ]]; then
    echo "1. Open Jellyfin at http://localhost:8096 to set up your media library"
    echo "2. Open Overseerr at http://localhost:5055 to configure request management"
    echo "3. Make a test request to verify the full flow works"
else
    echo "1. Fix any failed tests using the troubleshooting guide"
    echo "2. Run './manage.sh logs [service-name]' to check specific service logs"
    echo "3. Re-run this test after fixes"
fi

exit $EXIT_CODE