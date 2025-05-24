#!/bin/bash
###############################################################################
#  complete-test.sh - Complete automated test of the entire Usenet stack
#  Tests all services, integrations, and workflows
###############################################################################

set -e

# Require sudo once at the beginning
if [[ $EUID -ne 0 ]]; then
   echo "This test requires sudo privileges for Docker access."
   exec sudo "$0" "$@"
fi

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Test counters
PASSED=0
FAILED=0
WARNINGS=0

# Test result functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

header() {
    echo
    echo -e "${MAGENTA}━━━ $1 ━━━${NC}"
}

# Get API keys from config files
get_api_key() {
    local service=$1
    case $service in
        sabnzbd)
            grep -oP '(?<=api_key = )[^\s]+' config/sabnzbd/sabnzbd.ini 2>/dev/null || echo ""
            ;;
        prowlarr|sonarr|radarr|readarr|lidarr|bazarr)
            grep -oP '(?<=<ApiKey>)[^<]+' "config/$service/config.xml" 2>/dev/null || echo ""
            ;;
        mylar)
            grep -oP '(?<=api_key = )[^\s]+' config/mylar/mylar/config.ini 2>/dev/null || echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

# Test API endpoint
test_api() {
    local service=$1
    local endpoint=$2
    local api_key=$3
    local expected_field=$4
    
    local response=$(curl -s -H "X-Api-Key: $api_key" "$endpoint" 2>/dev/null || echo "{}")
    
    if echo "$response" | grep -q "$expected_field"; then
        return 0
    else
        return 1
    fi
}

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         USENET MEDIA STACK - COMPLETE SYSTEM TEST         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo "Started at: $(date)"

header "1. DOCKER CONTAINER STATUS"
# Test all expected containers
CONTAINERS=(
    "sabnzbd:8080:SABnzbd"
    "prowlarr:9696:Prowlarr"
    "sonarr:8989:Sonarr"
    "radarr:7878:Radarr"
    "readarr:8787:Readarr"
    "lidarr:8686:Lidarr"
    "bazarr:6767:Bazarr"
    "mylar:8090:Mylar3"
    "jellyfin:8096:Jellyfin"
    "overseerr:5055:Overseerr"
    "transmission:9092:Transmission"
    "jackett:9117:Jackett"
    "netdata:19999:Netdata"
    "portainer:9000:Portainer"
    "unpackerr:0:Unpackerr"
    "tautulli:8181:Tautulli"
)

for container_info in "${CONTAINERS[@]}"; do
    IFS=':' read -r container port name <<< "$container_info"
    
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "^${container}" | awk '{print $2,$3,$4}')
        pass "$name container running ($status)"
    else
        if docker ps -a --format "{{.Names}}" | grep -q "^${container}$"; then
            fail "$name container exists but not running"
        else
            fail "$name container not found"
        fi
    fi
done

header "2. SERVICE ACCESSIBILITY"
# Test HTTP accessibility
for container_info in "${CONTAINERS[@]}"; do
    IFS=':' read -r container port name <<< "$container_info"
    
    if [[ "$port" != "0" ]]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null || echo "000")
        case $response in
            200|301|302|303|307)
                pass "$name web interface accessible (HTTP $response)"
                ;;
            401|403)
                warn "$name requires authentication (HTTP $response)"
                ;;
            000)
                fail "$name not responding on port $port"
                ;;
            *)
                warn "$name returned unexpected code: HTTP $response"
                ;;
        esac
    fi
done

header "3. API KEY VALIDATION"
# Check and validate API keys
SERVICES_WITH_API=(sabnzbd prowlarr sonarr radarr readarr lidarr bazarr mylar)

for service in "${SERVICES_WITH_API[@]}"; do
    api_key=$(get_api_key "$service")
    
    if [[ -n "$api_key" ]]; then
        info "$service API key found: ${api_key:0:8}..."
        
        # Test the API key
        case $service in
            sabnzbd)
                if curl -s "http://localhost:8080/sabnzbd/api?mode=version&apikey=$api_key&output=json" | grep -q "version"; then
                    pass "$service API key is valid"
                else
                    fail "$service API key is invalid"
                fi
                ;;
            prowlarr)
                if test_api "$service" "http://localhost:9696/api/v1/system/status" "$api_key" "version"; then
                    pass "$service API key is valid"
                else
                    fail "$service API key is invalid"
                fi
                ;;
            sonarr|radarr|readarr|lidarr)
                port_map=(["sonarr"]="8989" ["radarr"]="7878" ["readarr"]="8787" ["lidarr"]="8686")
                port=${port_map[$service]}
                if test_api "$service" "http://localhost:$port/api/v3/system/status" "$api_key" "version"; then
                    pass "$service API key is valid"
                else
                    fail "$service API key is invalid"
                fi
                ;;
        esac
    else
        fail "$service API key not found"
    fi
done

header "4. CONFIGURATION VALIDATION"
# Check SABnzbd providers
if grep -q "\[\[Newshosting\]\]" config/sabnzbd/sabnzbd.ini 2>/dev/null; then
    providers=$(grep -c "\[\[.*\]\]" config/sabnzbd/sabnzbd.ini | grep -v "^\[")
    pass "SABnzbd has Usenet providers configured"
else
    fail "SABnzbd providers not configured"
fi

# Check if services have root folders configured
for service in sonarr radarr readarr lidarr; do
    if [[ -f "config/$service/config.xml" ]]; then
        if grep -q "<RootFolder>" "config/$service/config.xml"; then
            pass "$service has root folders configured"
        else
            warn "$service has no root folders configured"
        fi
    fi
done

header "5. STORAGE AND PERMISSIONS"
# Check download directories
for dir in downloads/complete downloads/incomplete; do
    if [[ -d "$dir" ]]; then
        if [[ -w "$dir" ]]; then
            pass "Directory $dir exists and is writable"
        else
            fail "Directory $dir exists but not writable"
        fi
    else
        fail "Directory $dir missing"
    fi
done

# Check media drives
drive_count=$(find /media/joe -maxdepth 1 -name "*TB*" -type d 2>/dev/null | wc -l)
if [[ $drive_count -gt 0 ]]; then
    pass "Found $drive_count media drives mounted"
    # List drives
    find /media/joe -maxdepth 1 -name "*TB*" -type d 2>/dev/null | while read drive; do
        info "  - $(basename $drive)"
    done
else
    fail "No media drives found"
fi

header "6. NETWORK CONNECTIVITY"
# Check Docker networks
for network in media_network sharing_network; do
    if docker network ls --format "{{.Name}}" | grep -q "^${network}$"; then
        pass "Docker network '$network' exists"
    else
        fail "Docker network '$network' not found"
    fi
done

# Test inter-service connectivity
info "Testing service discovery..."
if docker exec prowlarr ping -c 1 sonarr &>/dev/null; then
    pass "Services can communicate (prowlarr → sonarr)"
else
    fail "Services cannot communicate"
fi

header "7. SERVICE INTEGRATIONS"
# Test Prowlarr → Sonarr/Radarr integration
prowlarr_api=$(get_api_key prowlarr)
if [[ -n "$prowlarr_api" ]]; then
    apps=$(curl -s -H "X-Api-Key: $prowlarr_api" "http://localhost:9696/api/v1/applications" 2>/dev/null || echo "[]")
    app_count=$(echo "$apps" | grep -c "name" || echo 0)
    if [[ $app_count -gt 0 ]]; then
        pass "Prowlarr has $app_count applications connected"
    else
        warn "Prowlarr has no applications connected"
    fi
fi

# Test download client connections
for service in sonarr radarr; do
    api_key=$(get_api_key "$service")
    port_map=(["sonarr"]="8989" ["radarr"]="7878")
    port=${port_map[$service]}
    
    if [[ -n "$api_key" ]]; then
        clients=$(curl -s -H "X-Api-Key: $api_key" "http://localhost:$port/api/v3/downloadclient" 2>/dev/null || echo "[]")
        client_count=$(echo "$clients" | grep -c "name" || echo 0)
        if [[ $client_count -gt 0 ]]; then
            pass "$service has $client_count download client(s) configured"
        else
            warn "$service has no download clients configured"
        fi
    fi
done

header "8. MEDIA FLOW COMPONENTS"
# Check if Jellyfin can access media
if docker exec jellyfin ls /media/library &>/dev/null; then
    pass "Jellyfin can access media library"
else
    fail "Jellyfin cannot access media library"
fi

# Check Overseerr status
if curl -s http://localhost:5055/api/v1/status | grep -q "version"; then
    pass "Overseerr API is responsive"
else
    warn "Overseerr may need initial setup"
fi

# Check Unpackerr logs
if docker logs unpackerr --tail 10 2>&1 | grep -q "Queue:"; then
    pass "Unpackerr is monitoring downloads"
else
    warn "Unpackerr status unclear"
fi

header "9. SYSTEM RESOURCES"
# Memory usage
mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}')
if (( $(echo "$mem_usage < 80" | bc -l) )); then
    pass "Memory usage healthy: ${mem_usage}%"
else
    warn "Memory usage high: ${mem_usage}%"
fi

# CPU load
cpu_load=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | xargs)
info "CPU load average: $cpu_load"

# Disk usage
disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $disk_usage -lt 80 ]]; then
    pass "Root disk usage healthy: ${disk_usage}%"
else
    warn "Root disk usage high: ${disk_usage}%"
fi

header "10. AUTOMATION SCRIPTS"
# Check if automation scripts exist and are executable
SCRIPTS=(
    "one-click-setup.sh"
    "setup-all.sh"
    "manage.sh"
    "wait-for-services.sh"
    "scripts/test-setup.sh"
    "scripts/init-sabnzbd.sh"
    "scripts/generate-api-keys.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -x "$script" ]]; then
        pass "Script $script is executable"
    elif [[ -f "$script" ]]; then
        warn "Script $script exists but not executable"
    else
        fail "Script $script not found"
    fi
done

# Summary
echo
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                      TEST SUMMARY                         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo -e "  ${GREEN}Passed:${NC}   $PASSED"
echo -e "  ${RED}Failed:${NC}   $FAILED"
echo -e "  ${YELLOW}Warnings:${NC} $WARNINGS"
echo

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}✅ ALL CRITICAL TESTS PASSED!${NC}"
    echo
    echo "Your Usenet Media Stack is fully operational."
    echo
    echo -e "${BLUE}Quick Access URLs:${NC}"
    echo "  • Jellyfin (Media):     http://localhost:8096"
    echo "  • Overseerr (Requests): http://localhost:5055"
    echo "  • SABnzbd (Downloads):  http://localhost:8080"
    echo "  • Prowlarr (Indexers):  http://localhost:9696"
    echo "  • Sonarr (TV Shows):    http://localhost:8989"
    echo "  • Radarr (Movies):      http://localhost:7878"
    echo
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Complete Jellyfin setup wizard if needed"
    echo "  2. Configure Overseerr to connect services"
    echo "  3. Make a test media request"
    EXIT_CODE=0
else
    echo -e "${RED}❌ SOME TESTS FAILED${NC}"
    echo
    echo "Please review the failed tests above and:"
    echo "  1. Check service logs: docker logs [service-name]"
    echo "  2. Run: ./manage.sh restart"
    echo "  3. Check configuration files in ./config/"
    EXIT_CODE=1
fi

if [[ $WARNINGS -gt 0 ]]; then
    echo
    echo -e "${YELLOW}Note:${NC} $WARNINGS warnings detected. These may require attention."
fi

echo
echo "Test completed at: $(date)"

# Save detailed results
{
    echo "Test Results - $(date)"
    echo "====================="
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"
    echo "Warnings: $WARNINGS"
    echo ""
    echo "Service Status:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
} > test-results-$(date +%Y%m%d-%H%M%S).log

echo
echo "Detailed results saved to: test-results-*.log"

exit $EXIT_CODE