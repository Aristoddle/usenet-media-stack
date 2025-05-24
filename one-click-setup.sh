#!/bin/bash
###############################################################################
#  one-click-setup.sh - Complete Usenet stack setup in one command
###############################################################################
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 ONE-CLICK USENET STACK SETUP${NC}"
echo "================================"
echo

# Check if stack is already running
if docker ps | grep -q "usenet_prowlarr"; then
  echo -e "${YELLOW}Stack appears to be running already${NC}"
else
  echo -e "${CYAN}Starting Usenet stack...${NC}"
  "$SCRIPT_DIR/manage.sh" start
  
  echo
  echo -e "${YELLOW}Waiting for services to initialize...${NC}"
  sleep 30
fi

# Wait for all services to be ready
echo
echo -e "${CYAN}Checking service readiness...${NC}"
if ! "$SCRIPT_DIR/wait-for-services.sh"; then
  echo -e "${RED}Services failed to start properly${NC}"
  exit 1
fi

# Run the automated setup
echo
echo -e "${CYAN}Running automated configuration...${NC}"
"$SCRIPT_DIR/setup-all.sh" --fresh

# Show summary
echo
echo -e "${GREEN}🎉 SETUP COMPLETE!${NC}"
echo
echo "Access your services at:"
echo "  Prowlarr:  http://localhost:9696"
echo "  Sonarr:    http://localhost:8989"
echo "  Radarr:    http://localhost:7878"
echo "  SABnzbd:   http://localhost:8080"
echo "  Readarr:   http://localhost:8787"
echo "  Mylar3:    http://localhost:8090"
echo "  Bazarr:    http://localhost:6767"
echo "  Portainer: http://localhost:9000"
echo
echo "All indexers and providers have been configured!"
echo "You can now search for content in any *arr app."
echo
echo -e "${YELLOW}Note: Some services may require initial login on first access${NC}"