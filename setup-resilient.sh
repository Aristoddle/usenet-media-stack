#!/bin/bash
###############################################################################
# setup-resilient.sh - Ultra-resilient setup with maximum error handling
#
# This is what one-click-setup.sh should be!
###############################################################################

set -euo pipefail

# Get script directory (handles symlinks, spaces, etc)
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")" && pwd)"

# Source resilient functions
if [[ -f "$SCRIPT_DIR/modules/resilient.sh" ]]; then
    source "$SCRIPT_DIR/modules/resilient.sh"
else
    echo "ERROR: Cannot find resilient.sh module" >&2
    exit 1
fi

# Set up signal handlers
setup_signal_handlers

# Colors (with fallback for no-color terminals)
if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' BLUE='' CYAN='' BOLD='' NC=''
fi

# Display banner
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         USENET MEDIA STACK - RESILIENT SETUP              ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Verify we can run
echo -e "${BLUE}Step 1: Checking system requirements...${NC}"

# Check bash version (need 4.0+)
if [[ "${BASH_VERSION%%.*}" -lt 4 ]]; then
    echo -e "${RED}ERROR: Bash 4.0+ required (you have $BASH_VERSION)${NC}"
    exit 1
fi

# Check if we're in the right directory
if [[ ! -f "$SCRIPT_DIR/docker-compose.yml" ]]; then
    echo -e "${RED}ERROR: docker-compose.yml not found${NC}"
    echo "Are you in the usenet-media-stack directory?"
    exit 1
fi

echo -e "${GREEN}✓ System compatible${NC}"

# Step 2: Check dependencies
echo -e "\n${BLUE}Step 2: Checking dependencies...${NC}"

MISSING_DEPS=()

# Check each dependency
for cmd in docker curl jq git; do
    if ! command -v "$cmd" &>/dev/null; then
        MISSING_DEPS+=("$cmd")
        echo -e "${RED}✗ $cmd not found${NC}"
    else
        echo -e "${GREEN}✓ $cmd${NC}"
    fi
done

# Handle missing dependencies
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}Missing dependencies: ${MISSING_DEPS[*]}${NC}"
    
    response=$(safe_read "Would you like to install them automatically? (y/n)" 30 "n")
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if safe_exec_script "$SCRIPT_DIR/auto-install-deps.sh"; then
            echo -e "${GREEN}Dependencies installed!${NC}"
        else
            echo -e "${RED}Please install manually: ${MISSING_DEPS[*]}${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Cannot proceed without dependencies${NC}"
        exit 1
    fi
fi

# Step 3: Docker check
echo -e "\n${BLUE}Step 3: Checking Docker...${NC}"

if ! check_docker; then
    echo -e "${RED}Docker is not running${NC}"
    
    if check_sudo; then
        echo "Attempting to start Docker..."
        if systemctl start docker 2>/dev/null || service docker start 2>/dev/null; then
            sleep 3
            if check_docker; then
                echo -e "${GREEN}✓ Docker started${NC}"
            else
                echo -e "${RED}Failed to start Docker${NC}"
                echo "Please start Docker manually and try again"
                exit 1
            fi
        fi
    else
        echo "Please start Docker and run this script again"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker is running${NC}"
fi

# Check Docker Compose
COMPOSE_CMD=$(check_docker_compose)
if [[ -z "$COMPOSE_CMD" ]]; then
    echo -e "${RED}Docker Compose not found${NC}"
    echo "Please install docker-compose-plugin or standalone docker-compose"
    exit 1
else
    echo -e "${GREEN}✓ Docker Compose: $COMPOSE_CMD${NC}"
fi

# Step 4: System resources
echo -e "\n${BLUE}Step 4: Checking system resources...${NC}"

# RAM check
total_ram=$(free -m 2>/dev/null | awk 'NR==2{print $2}' || echo "0")
if [[ $total_ram -lt 2048 ]]; then
    echo -e "${RED}⚠ Low RAM: ${total_ram}MB (4GB+ recommended)${NC}"
    response=$(safe_read "Continue anyway? (y/n)" 30 "n")
    [[ ! "$response" =~ ^[Yy]$ ]] && exit 1
else
    echo -e "${GREEN}✓ RAM: ${total_ram}MB${NC}"
fi

# Disk space
disk_usage=$(get_disk_usage_percent "$SCRIPT_DIR")
disk_free=$(df -BG "$SCRIPT_DIR" 2>/dev/null | awk 'NR==2{print $4}' | sed 's/G//' || echo "0")

if [[ $disk_usage -gt 90 ]]; then
    echo -e "${RED}⚠ High disk usage: ${disk_usage}%${NC}"
elif [[ $disk_free -lt 20 ]]; then
    echo -e "${YELLOW}⚠ Low disk space: ${disk_free}GB free${NC}"
else
    echo -e "${GREEN}✓ Disk space: ${disk_free}GB free (${disk_usage}% used)${NC}"
fi

# Internet check
echo -n "Checking internet... "
if check_internet; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${YELLOW}⚠ No internet detected${NC}"
    echo "Some features may not work without internet"
fi

# Step 5: Create required directories
echo -e "\n${BLUE}Step 5: Creating directories...${NC}"

for dir in config downloads media/tv media/movies media/music media/books media/comics; do
    if [[ ! -d "$SCRIPT_DIR/$dir" ]]; then
        mkdir -p "$SCRIPT_DIR/$dir"
        echo -e "${GREEN}✓ Created $dir${NC}"
    else
        echo -e "${GREEN}✓ $dir exists${NC}"
    fi
done

# Step 6: Deploy services
echo -e "\n${BLUE}Step 6: Deploying services...${NC}"
echo -e "${YELLOW}This may take several minutes on first run...${NC}"

if $COMPOSE_CMD up -d; then
    echo -e "${GREEN}✓ Services deployed${NC}"
else
    echo -e "${RED}Failed to deploy services${NC}"
    echo "Check Docker logs: docker logs <container>"
    exit 1
fi

# Step 7: Wait for services
echo -e "\n${BLUE}Step 7: Waiting for services to start...${NC}"

# Simple wait with progress
for i in {1..30}; do
    echo -ne "\r⏳ Waiting... $i/30 seconds"
    sleep 1
done
echo -e "\r${GREEN}✓ Services should be ready${NC}     "

# Step 8: Quick health check
echo -e "\n${BLUE}Step 8: Health check...${NC}"

# Count running containers
running=$(docker ps --format '{{.Names}}' | grep -E "(sabnzbd|prowlarr|sonarr|radarr)" | wc -l || echo 0)
echo -e "Running containers: $running"

if [[ $running -gt 0 ]]; then
    echo -e "${GREEN}✓ Services are running${NC}"
else
    echo -e "${YELLOW}⚠ No services detected${NC}"
    echo "Check status: docker ps"
fi

# Success!
echo -e "\n${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    SETUP COMPLETE! 🎉                     ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"

echo -e "\n${BOLD}Access your services:${NC}"
echo "• SABnzbd:   http://localhost:8080"
echo "• Prowlarr:  http://localhost:9696"
echo "• Sonarr:    http://localhost:8989"
echo "• Radarr:    http://localhost:7878"

echo -e "\n${BOLD}Next steps:${NC}"
echo "1. Check status: ./usenet manage status"
echo "2. View logs:    ./usenet manage logs"
echo "3. Run tests:    ./usenet test quick"

echo -e "\n${BLUE}Need help? Check the docs or GitHub issues${NC}"