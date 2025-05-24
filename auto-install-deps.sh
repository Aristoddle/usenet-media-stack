#!/bin/bash
###############################################################################
# auto-install-deps.sh - Automatically install missing dependencies
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║        AUTO-INSTALL DEPENDENCIES FOR USENET STACK         ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MGR="apt"
    UPDATE_CMD="sudo apt update"
    INSTALL_CMD="sudo apt install -y"
elif command -v yum &> /dev/null; then
    PKG_MGR="yum"
    UPDATE_CMD="sudo yum check-update || true"
    INSTALL_CMD="sudo yum install -y"
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    UPDATE_CMD="sudo dnf check-update || true"
    INSTALL_CMD="sudo dnf install -y"
else
    echo -e "${RED}Could not detect package manager (apt/yum/dnf)${NC}"
    exit 1
fi

echo -e "${BLUE}Detected package manager: $PKG_MGR${NC}\n"

# Tools to install
TOOLS_TO_INSTALL=()

# Check and queue missing tools
check_tool() {
    local tool="$1"
    local package="${2:-$1}"  # Package name if different from tool name
    
    if ! command -v "$tool" &> /dev/null; then
        echo -e "${YELLOW}✗ $tool not found${NC}"
        TOOLS_TO_INSTALL+=("$package")
    else
        echo -e "${GREEN}✓ $tool already installed${NC}"
    fi
}

echo -e "${BLUE}Checking required tools:${NC}"
check_tool "curl"
check_tool "jq"
check_tool "git"
check_tool "docker" "docker.io"  # Use docker.io for apt

# Handle Docker separately as it needs special installation
if ! command -v docker &> /dev/null; then
    echo -e "\n${YELLOW}Docker requires special installation${NC}"
    echo "Would you like to install Docker? (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker "$USER"
        echo -e "${GREEN}Docker installed! You may need to log out and back in.${NC}"
    fi
    # Remove docker from regular install list
    TOOLS_TO_INSTALL=("${TOOLS_TO_INSTALL[@]/docker.io/}")
fi

# Install missing tools
if [[ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]]; then
    echo -e "\n${YELLOW}Missing tools: ${TOOLS_TO_INSTALL[*]}${NC}"
    echo "Would you like to install them? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "\n${BLUE}Updating package lists...${NC}"
        $UPDATE_CMD
        
        echo -e "\n${BLUE}Installing missing tools...${NC}"
        $INSTALL_CMD "${TOOLS_TO_INSTALL[@]}"
        
        echo -e "\n${GREEN}Installation complete!${NC}"
    else
        echo -e "${YELLOW}Skipping installation${NC}"
        exit 1
    fi
else
    echo -e "\n${GREEN}All required tools are already installed!${NC}"
fi

# Start Docker if needed
if command -v docker &> /dev/null && ! docker ps &> /dev/null; then
    echo -e "\n${YELLOW}Docker is installed but not running${NC}"
    echo "Would you like to start Docker? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        if command -v systemctl &> /dev/null; then
            sudo systemctl start docker
            sudo systemctl enable docker
        elif command -v service &> /dev/null; then
            sudo service docker start
        fi
        
        if docker ps &> /dev/null; then
            echo -e "${GREEN}Docker started successfully!${NC}"
        else
            echo -e "${RED}Failed to start Docker${NC}"
        fi
    fi
fi

# Final verification
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Final verification:${NC}"

ALL_GOOD=true
for tool in curl jq git docker; do
    if command -v "$tool" &> /dev/null; then
        echo -e "${GREEN}✓ $tool${NC}"
    else
        echo -e "${RED}✗ $tool${NC}"
        ALL_GOOD=false
    fi
done

if docker ps &> /dev/null; then
    echo -e "${GREEN}✓ Docker daemon running${NC}"
else
    echo -e "${RED}✗ Docker daemon not running${NC}"
    ALL_GOOD=false
fi

if [[ "$ALL_GOOD" == "true" ]]; then
    echo -e "\n${GREEN}✅ All dependencies are installed and ready!${NC}"
    echo -e "You can now run: ${BLUE}./usenet setup${NC}"
    exit 0
else
    echo -e "\n${RED}Some dependencies are still missing${NC}"
    exit 1
fi