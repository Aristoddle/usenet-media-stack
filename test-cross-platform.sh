#!/bin/bash
###############################################################################
# test-cross-platform.sh - Verify cross-platform compatibility
###############################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source platform module
source "$SCRIPT_DIR/modules/platform.sh"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║          CROSS-PLATFORM COMPATIBILITY TEST                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"

# Test platform detection
echo -e "\n${BLUE}1. Platform Detection:${NC}"
PLATFORM=$(detect_platform)
echo "   Detected: $PLATFORM"
echo "   OSTYPE: $OSTYPE"

# Test system info functions
echo -e "\n${BLUE}2. System Information:${NC}"
echo "   RAM: $(get_total_ram_mb)MB"
echo "   Disk free: $(get_disk_free_gb .)GB"
echo "   Disk usage: $(get_disk_usage_percent .)%"
echo "   CPU cores: $(get_cpu_cores)"

# Test command availability
echo -e "\n${BLUE}3. Command Compatibility:${NC}"

# Check for GNU vs BSD tools
echo -n "   grep type: "
if grep --version 2>/dev/null | grep -q GNU; then
    echo "GNU"
else
    echo "BSD/other"
fi

echo -n "   sed type: "
if sed --version 2>/dev/null | grep -q GNU; then
    echo "GNU"
else
    echo "BSD/other"
fi

# Test Docker differences
echo -e "\n${BLUE}4. Docker Compatibility:${NC}"
echo -n "   Docker location: "
command -v docker || echo "not found"

echo -n "   Docker compose command: "
if docker compose version &>/dev/null; then
    echo "docker compose (v2)"
elif command -v docker-compose &>/dev/null; then
    echo "docker-compose (standalone)"
else
    echo "not found"
fi

# Test package manager
echo -e "\n${BLUE}5. Package Manager:${NC}"
echo -n "   Available: "
if command -v apt &>/dev/null; then
    echo "apt (Debian/Ubuntu)"
elif command -v yum &>/dev/null; then
    echo "yum (RHEL/CentOS)"
elif command -v brew &>/dev/null; then
    echo "brew (Homebrew)"
elif command -v pkg &>/dev/null; then
    echo "pkg (FreeBSD)"
else
    echo "none detected"
fi

# Platform-specific warnings
echo -e "\n${BLUE}6. Platform-Specific Notes:${NC}"
case "$PLATFORM" in
    macos)
        echo "   ${YELLOW}⚠ macOS users:${NC}"
        echo "   - Install Docker Desktop from docker.com"
        echo "   - Use Homebrew for missing tools: brew install jq"
        echo "   - May need to allow Docker in Security settings"
        ;;
    wsl)
        echo "   ${YELLOW}⚠ WSL2 users:${NC}"
        echo "   - Can use Windows Docker Desktop"
        echo "   - Or install Docker in WSL2 directly"
        echo "   - Ensure WSL2 (not WSL1) for best performance"
        ;;
    linux)
        echo "   ${GREEN}✓ Native Linux - best compatibility${NC}"
        ;;
    *)
        echo "   ${YELLOW}⚠ Unknown platform - may need manual setup${NC}"
        ;;
esac

# Summary
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Cross-platform readiness check complete!${NC}"

# Check for potential issues
ISSUES=0

# Check for incompatible tools
if [[ "$PLATFORM" == "macos" ]] && ! command -v ggrep &>/dev/null; then
    echo -e "\n${YELLOW}Recommendation:${NC}"
    echo "Install GNU coreutils for better compatibility:"
    echo "  brew install coreutils"
    ((ISSUES++))
fi

if [[ $ISSUES -eq 0 ]]; then
    echo -e "\n${GREEN}✅ No compatibility issues detected${NC}"
else
    echo -e "\n${YELLOW}⚠ $ISSUES potential compatibility issues${NC}"
fi