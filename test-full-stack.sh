#!/bin/bash
###############################################################################
# test-full-stack.sh - Complete end-to-end test of the Usenet stack
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test results
PASSED=0
FAILED=0
WARNINGS=0

# Get sudo access
echo "fishing123" | sudo -S true 2>/dev/null || {
    echo "Failed to obtain sudo privileges"
    exit 1
}

# Test function
test_check() {
    local name="$1"
    local command="$2"
    local expected="${3:-success}"
    
    echo -n "  $name... "
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((PASSED++))
        return 0
    else
        if [[ "$expected" == "warning" ]]; then
            echo -e "${YELLOW}⚠${NC}"
            ((WARNINGS++))
            return 1
        else
            echo -e "${RED}✗${NC}"
            ((FAILED++))
            return 1
        fi
    fi
}

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║            FULL USENET STACK TEST SUITE                   ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo -e "Started at: $(date)\n"

# 1. Docker Infrastructure
echo -e "${BLUE}1. Docker Infrastructure${NC}"
test_check "Docker daemon running" "echo fishing123 | sudo -S docker info"
test_check "Docker Compose installed" "docker compose version"
test_check "Docker network exists" "echo fishing123 | sudo -S docker network ls | grep -q usenet_default" "warning"

# 2. File System
echo -e "\n${BLUE}2. File System & Permissions${NC}"
test_check "Config directory exists" "[[ -d $HOME/usenet/config ]]"
test_check "Downloads directory exists" "[[ -d $HOME/usenet/downloads ]]"
test_check "Media directory exists" "[[ -d $HOME/media ]]"
test_check "Scripts directory exists" "[[ -d $HOME/usenet/scripts ]]"
test_check "Config writable" "[[ -w $HOME/usenet/config ]]"
test_check "Downloads writable" "[[ -w $HOME/usenet/downloads ]]"

# 3. Core Files
echo -e "\n${BLUE}3. Core Files${NC}"
test_check "docker-compose.yml exists" "[[ -f $HOME/usenet/docker-compose.yml ]]"
test_check "one-click-setup.sh exists" "[[ -f $HOME/usenet/one-click-setup.sh ]]"
test_check "manage.sh exists" "[[ -f $HOME/usenet/manage.sh ]]"
test_check "op-helper.sh exists" "[[ -f $HOME/usenet/op-helper.sh ]]"

# 4. Docker Containers
echo -e "\n${BLUE}4. Docker Containers${NC}"
services=(sabnzbd prowlarr sonarr radarr readarr mylar3 bazarr jellyfin overseerr unpackerr)
for service in "${services[@]}"; do
    test_check "$service container" "echo fishing123 | sudo -S docker ps --format '{{.Names}}' | grep -q ^${service}$" "warning"
done

# 5. Service Accessibility
echo -e "\n${BLUE}5. Service Web Interfaces${NC}"
test_check "SABnzbd (8080)" "curl -sf -o /dev/null --max-time 3 http://localhost:8080/sabnzbd/" "warning"
test_check "Prowlarr (9696)" "curl -sf -o /dev/null --max-time 3 http://localhost:9696" "warning"
test_check "Sonarr (8989)" "curl -sf -o /dev/null --max-time 3 http://localhost:8989" "warning"
test_check "Radarr (7878)" "curl -sf -o /dev/null --max-time 3 http://localhost:7878" "warning"
test_check "Readarr (8787)" "curl -sf -o /dev/null --max-time 3 http://localhost:8787" "warning"
test_check "Mylar3 (8090)" "curl -sf -o /dev/null --max-time 3 http://localhost:8090" "warning"
test_check "Bazarr (6767)" "curl -sf -o /dev/null --max-time 3 http://localhost:6767" "warning"
test_check "Jellyfin (8096)" "curl -sf -o /dev/null --max-time 3 http://localhost:8096" "warning"
test_check "Overseerr (5055)" "curl -sf -o /dev/null --max-time 3 http://localhost:5055" "warning"

# 6. Configuration Files
echo -e "\n${BLUE}6. Configuration Files${NC}"
if [[ -f "$HOME/usenet/config/sabnzbd/sabnzbd.ini" ]]; then
    test_check "SABnzbd config" "[[ -f $HOME/usenet/config/sabnzbd/sabnzbd.ini ]]"
    test_check "SABnzbd API key" "grep -q 'api_key =' $HOME/usenet/config/sabnzbd/sabnzbd.ini"
fi

if [[ -f "$HOME/usenet/config/prowlarr/config.xml" ]]; then
    test_check "Prowlarr config" "[[ -f $HOME/usenet/config/prowlarr/config.xml ]]"
    test_check "Prowlarr API key" "grep -q '<ApiKey>' $HOME/usenet/config/prowlarr/config.xml"
fi

# 7. Scripts Validation
echo -e "\n${BLUE}7. Script Syntax Check${NC}"
scripts=(
    "one-click-setup.sh"
    "manage.sh"
    "setup-all.sh"
    "op-helper.sh"
    "scripts/configure-services.sh"
)
for script in "${scripts[@]}"; do
    if [[ -f "$HOME/usenet/$script" ]]; then
        test_check "$script syntax" "bash -n $HOME/usenet/$script"
    fi
done

# 8. Environment Checks
echo -e "\n${BLUE}8. Environment${NC}"
test_check "1Password CLI" "command -v op" "warning"
test_check "jq installed" "command -v jq"
test_check "curl installed" "command -v curl"
test_check "git installed" "command -v git"

# 9. Memory & Resources
echo -e "\n${BLUE}9. System Resources${NC}"
total_mem=$(free -m | awk 'NR==2{print $2}')
test_check "Sufficient memory (>4GB)" "[[ $total_mem -gt 4096 ]]"

# 10. Port Availability
echo -e "\n${BLUE}10. Port Conflicts${NC}"
ports=(8080 9696 8989 7878 8787 8090 6767 8096 5055)
for port in "${ports[@]}"; do
    test_check "Port $port" "! echo fishing123 | sudo -S lsof -i :$port | grep -v LISTEN" "warning"
done

# Summary
echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                    TEST SUMMARY                           ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo -e "Passed:   ${GREEN}$PASSED${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "Failed:   ${RED}$FAILED${NC}"

# Overall result
if [[ $FAILED -eq 0 ]]; then
    if [[ $WARNINGS -eq 0 ]]; then
        echo -e "\n${GREEN}✅ All tests passed! System is fully functional.${NC}"
        exit_code=0
    else
        echo -e "\n${YELLOW}⚠️  Tests passed with warnings. System is functional but may need attention.${NC}"
        exit_code=0
    fi
else
    echo -e "\n${RED}❌ Some tests failed. Please check the errors above.${NC}"
    exit_code=1
fi

echo -e "Completed at: $(date)"
exit $exit_code