#!/bin/bash
###############################################################################
#  wait-for-services.sh - Wait for all Usenet stack services to be ready
###############################################################################
set -e

# Service endpoints to check
declare -A SERVICES=(
  ["prowlarr"]="http://localhost:9696"
  ["sonarr"]="http://localhost:8989"
  ["radarr"]="http://localhost:7878"
  ["readarr"]="http://localhost:8787"
  ["mylar3"]="http://localhost:8090"
  ["bazarr"]="http://localhost:6767"
  ["sabnzbd"]="http://localhost:8080"
  ["portainer"]="http://localhost:9000"
)

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

# Check if service is accessible
check_service() {
  local name="$1"
  local url="$2"
  local max_attempts="${3:-30}"
  local attempt=0
  
  echo -n "Checking $name..."
  
  while (( attempt < max_attempts )); do
    if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|301\|302"; then
      echo -e " ${GREEN}✓${NC}"
      return 0
    fi
    
    ((attempt++))
    echo -n "."
    sleep 2
  done
  
  echo -e " ${RED}✗${NC} (timeout after $((attempt * 2)) seconds)"
  return 1
}

# Main
echo "Waiting for Usenet stack services to be ready..."
echo "=============================================="

all_ready=true

for service in "${!SERVICES[@]}"; do
  if ! check_service "$service" "${SERVICES[$service]}"; then
    all_ready=false
  fi
done

echo

if $all_ready; then
  echo -e "${GREEN}All services are ready!${NC}"
  
  # Show service URLs
  echo
  echo "Service URLs:"
  echo "============="
  for service in "${!SERVICES[@]}"; do
    printf "%-12s: %s\n" "$service" "${SERVICES[$service]}"
  done
  
  # Check for API keys
  echo
  echo "Checking for API keys..."
  echo "======================="
  
  for service in prowlarr sonarr radarr sabnzbd; do
    config_path="$HOME/usenet/config/$service"
    
    if [[ -f "$config_path/config.xml" ]]; then
      api_key=$(grep -oP '(?<=<ApiKey>)[^<]+' "$config_path/config.xml" 2>/dev/null || echo "")
    elif [[ -f "$config_path/config.ini" ]]; then
      api_key=$(grep -oP '(?<=api_key = )[^\s]+' "$config_path/config.ini" 2>/dev/null || echo "")
    else
      api_key=""
    fi
    
    if [[ -n "$api_key" ]]; then
      echo -e "$service: ${GREEN}✓${NC} API key found"
    else
      echo -e "$service: ${YELLOW}⚠${NC}  No API key found (initial setup may be required)"
    fi
  done
  
  echo
  echo -e "${GREEN}Ready to run setup-all.sh!${NC}"
  exit 0
else
  echo -e "${RED}Some services failed to start${NC}"
  echo
  echo "Troubleshooting:"
  echo "1. Check service logs: ./manage.sh logs [service-name]"
  echo "2. Verify Docker is running: docker ps"
  echo "3. Check disk space: df -h"
  echo "4. Restart services: ./manage.sh restart"
  exit 1
fi