#!/bin/bash
###############################################################################
# check-dependencies.sh - Verify all required tools are installed
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
MISSING=0
WARNINGS=0

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          DEPENDENCY CHECK FOR USENET STACK                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check function
check_cmd() {
    local cmd="$1"
    local required="${2:-true}"
    local install_hint="$3"
    
    echo -n "• $cmd: "
    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓ Installed${NC}"
    else
        if [[ "$required" == "true" ]]; then
            echo -e "${RED}✗ Missing (REQUIRED)${NC}"
            [[ -n "$install_hint" ]] && echo "  Install: $install_hint"
            ((MISSING++))
        else
            echo -e "${YELLOW}⚠ Missing (optional)${NC}"
            [[ -n "$install_hint" ]] && echo "  Install: $install_hint"
            ((WARNINGS++))
        fi
    fi
}

echo -e "${BLUE}1. Required Dependencies:${NC}"
check_cmd "docker" "true" "curl -fsSL https://get.docker.com | sh"
check_cmd "docker-compose" "true" "Install Docker Desktop or docker-compose-plugin"
check_cmd "curl" "true" "sudo apt install curl"
check_cmd "jq" "true" "sudo apt install jq"
check_cmd "git" "true" "sudo apt install git"

echo -e "\n${BLUE}2. Shell Requirements:${NC}"
check_cmd "bash" "true" "sudo apt install bash"
if [[ -n "${BASH_VERSION:-}" ]]; then
    echo "  Bash version: $BASH_VERSION"
fi

echo -e "\n${BLUE}3. Optional Tools:${NC}"
check_cmd "op" "false" "See https://1password.com/downloads/command-line"
check_cmd "sudo" "false" "Usually pre-installed"
check_cmd "nc" "false" "sudo apt install netcat"

echo -e "\n${BLUE}4. Docker Status:${NC}"
echo -n "• Docker daemon: "
if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    echo "  Start with: sudo systemctl start docker"
    ((MISSING++))
fi

echo -n "• Docker Compose v2: "
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✓ Available${NC}"
    docker compose version | head -1
else
    echo -e "${YELLOW}⚠ Using legacy docker-compose${NC}"
    ((WARNINGS++))
fi

echo -e "\n${BLUE}5. System Requirements:${NC}"
echo -n "• RAM: "
total_ram=$(free -m | awk 'NR==2{print $2}')
if [[ $total_ram -gt 4096 ]]; then
    echo -e "${GREEN}✓ ${total_ram}MB (sufficient)${NC}"
else
    echo -e "${YELLOW}⚠ ${total_ram}MB (4GB+ recommended)${NC}"
    ((WARNINGS++))
fi

echo -n "• Disk space: "
disk_free=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
if [[ $disk_free -gt 50 ]]; then
    echo -e "${GREEN}✓ ${disk_free}GB free (sufficient)${NC}"
else
    echo -e "${YELLOW}⚠ ${disk_free}GB free (50GB+ recommended)${NC}"
    ((WARNINGS++))
fi

# Summary
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
if [[ $MISSING -eq 0 ]]; then
    echo -e "${GREEN}✅ All required dependencies are installed!${NC}"
    if [[ $WARNINGS -gt 0 ]]; then
        echo -e "${YELLOW}⚠  $WARNINGS optional dependencies missing${NC}"
    fi
    echo -e "\nYou're ready to run: ${BLUE}./usenet setup${NC}"
    exit 0
else
    echo -e "${RED}❌ Missing $MISSING required dependencies${NC}"
    echo -e "\nPlease install missing dependencies before proceeding."
    exit 1
fi