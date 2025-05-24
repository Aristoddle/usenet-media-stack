#!/bin/bash
###############################################################################
# quick-install.sh - The EASIEST way to get started
# 
# Just run: curl -fsSL https://raw.githubusercontent.com/Aristoddle/usenet-media-stack/main/quick-install.sh | bash
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║      🚀 USENET MEDIA STACK - QUICK INSTALLER 🚀          ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# 1. Install git if needed
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}Installing git...${NC}"
    if command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y git
    elif command -v yum &> /dev/null; then
        sudo yum install -y git
    else
        echo "Please install git first"
        exit 1
    fi
fi

# 2. Clone the repository
echo -e "${BLUE}Cloning Usenet Media Stack...${NC}"
if [[ -d "usenet-media-stack" ]]; then
    echo "Directory already exists, using existing installation"
    cd usenet-media-stack
    git pull
else
    git clone https://github.com/Aristoddle/usenet-media-stack.git
    cd usenet-media-stack
fi

# 3. Make scripts executable
chmod +x *.sh

# 4. Run auto-installer for dependencies
echo -e "\n${BLUE}Checking dependencies...${NC}"
if [[ -f "auto-install-deps.sh" ]]; then
    # Auto-accept for smoother experience
    yes | ./auto-install-deps.sh || {
        echo -e "${YELLOW}Some dependencies need manual installation${NC}"
    }
fi

# 5. Run the setup
echo -e "\n${GREEN}Starting Usenet Media Stack setup...${NC}"
echo -e "${YELLOW}This will deploy all services. Ready? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    ./usenet setup
else
    echo -e "\n${BLUE}Setup cancelled. When you're ready, run:${NC}"
    echo "  cd usenet-media-stack"
    echo "  ./usenet setup"
fi