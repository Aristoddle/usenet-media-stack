#!/bin/bash
###############################################################################
# validate-deployment.sh - Final validation that everything is ready
###############################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         USENET STACK DEPLOYMENT VALIDATION                ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Validation results
READY=true
ISSUES=()

# Check function
check() {
    local name="$1"
    local condition="$2"
    local critical="${3:-true}"
    
    echo -n "• $name: "
    if eval "$condition" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        ISSUES+=("$name")
        if [[ "$critical" == "true" ]]; then
            READY=false
        fi
    fi
}

echo -e "${YELLOW}1. Core Infrastructure${NC}"
check "Docker installed" "command -v docker"
check "Docker Compose v2" "docker compose version"
check "Project directory" "[[ -d $SCRIPT_DIR ]]"

echo -e "\n${YELLOW}2. Essential Files${NC}"
check "docker-compose.yml" "[[ -f docker-compose.yml ]]"
check "one-click-setup.sh" "[[ -f one-click-setup.sh && -x one-click-setup.sh ]]"
check "manage.sh" "[[ -f manage.sh && -x manage.sh ]]"
check "op-helper.sh" "[[ -f op-helper.sh && -x op-helper.sh ]]"

echo -e "\n${YELLOW}3. Directory Structure${NC}"
check "config/" "[[ -d config ]]"
check "downloads/" "[[ -d downloads ]]"
check "scripts/" "[[ -d scripts ]]"
check "modules/" "[[ -d modules ]]"
check "media/" "[[ -d $HOME/media ]]"

echo -e "\n${YELLOW}4. Script Validation${NC}"
check "one-click-setup.sh syntax" "bash -n one-click-setup.sh"
check "manage.sh syntax" "bash -n manage.sh"
check "setup-all.sh syntax" "bash -n setup-all.sh"
check "Test integration" "grep -q 'run_comprehensive_tests' one-click-setup.sh"
check "Test-only mode" "grep -q -- '--test-only' one-click-setup.sh"

echo -e "\n${YELLOW}5. Documentation${NC}"
check "README.md" "[[ -f README.md ]]"
check "COMPLETE_DOCUMENTATION.md" "[[ -f COMPLETE_DOCUMENTATION.md ]]"
check "TECHNICAL_REFERENCE.md" "[[ -f TECHNICAL_REFERENCE.md ]]"
check "QUICK_START.md" "[[ -f QUICK_START.md ]]"

echo -e "\n${YELLOW}6. Dependencies${NC}"
check "jq" "command -v jq"
check "curl" "command -v curl"
check "git" "command -v git"
check "1Password CLI (optional)" "command -v op" false

echo -e "\n${YELLOW}7. Git Repository${NC}"
check "Git initialized" "[[ -d .git ]]"
check "Git remote" "git remote -v | grep -q origin" false

# Summary
echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}Validation Summary:${NC}"

if [[ "$READY" == "true" ]]; then
    echo -e "\n${GREEN}✅ DEPLOYMENT READY${NC}"
    echo -e "${GREEN}All essential checks passed. The system is stable and ready.${NC}"
    echo ""
    echo -e "${BOLD}To deploy the entire stack:${NC}"
    echo -e "  ${BLUE}./one-click-setup.sh${NC}"
    echo ""
    echo -e "${BOLD}To run tests only:${NC}"
    echo -e "  ${BLUE}./one-click-setup.sh --test-only${NC}"
    echo ""
    echo -e "${BOLD}Available commands:${NC}"
    echo "  • ./manage.sh status     - Check service status"
    echo "  • ./manage.sh logs       - View logs"
    echo "  • ./manage.sh restart    - Restart services"
    echo ""
    exit 0
else
    echo -e "\n${RED}❌ NOT READY FOR DEPLOYMENT${NC}"
    echo -e "${YELLOW}Please fix the following critical issues:${NC}"
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue"
    done
    echo ""
    exit 1
fi