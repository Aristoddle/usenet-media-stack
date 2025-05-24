#!/bin/bash
###############################################################################
# test-essential.sh - Essential tests for Usenet stack stability
###############################################################################

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Essential Usenet Stack Tests${NC}"
echo "================================="

# Test counters
TESTS=0
FAILURES=0

# Simple test function
test_item() {
    local desc="$1"
    local cmd="$2"
    
    TESTS=$((TESTS + 1))
    echo -n "• $desc: "
    
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"
    else
        echo -e "${RED}FAIL${NC}"
        FAILURES=$((FAILURES + 1))
    fi
}

echo -e "\n${YELLOW}Core Files:${NC}"
test_item "docker-compose.yml" "[[ -f docker-compose.yml ]]"
test_item "one-click-setup.sh" "[[ -f one-click-setup.sh && -x one-click-setup.sh ]]"
test_item "manage.sh" "[[ -f manage.sh && -x manage.sh ]]"
test_item "op-helper.sh" "[[ -f op-helper.sh && -x op-helper.sh ]]"

echo -e "\n${YELLOW}Directories:${NC}"
test_item "config/" "[[ -d config ]]"
test_item "downloads/" "[[ -d downloads ]]"
test_item "scripts/" "[[ -d scripts ]]"
test_item "media/" "[[ -d $HOME/media ]]"

echo -e "\n${YELLOW}Key Scripts:${NC}"
test_item "setup-all.sh" "[[ -f setup-all.sh ]]"
test_item "configure-services.sh" "[[ -f scripts/configure-services.sh ]]"
test_item "extract-usenet-creds.sh" "[[ -f extract-usenet-creds.sh ]]"

echo -e "\n${YELLOW}Script Syntax:${NC}"
test_item "one-click-setup.sh syntax" "bash -n one-click-setup.sh"
test_item "manage.sh syntax" "bash -n manage.sh"
test_item "setup-all.sh syntax" "bash -n setup-all.sh"

echo -e "\n${YELLOW}Documentation:${NC}"
test_item "README.md" "[[ -f README.md ]]"
test_item "DOCKER_SWARM_GUIDE.md" "[[ -f DOCKER_SWARM_GUIDE.md ]]"
test_item "SECURITY_GUIDE.md" "[[ -f SECURITY_GUIDE.md ]]"

echo -e "\n${YELLOW}Dependencies:${NC}"
test_item "Docker" "command -v docker"
test_item "Docker Compose" "docker compose version"
test_item "jq" "command -v jq"
test_item "curl" "command -v curl"

# Check for common issues
echo -e "\n${YELLOW}Common Issues:${NC}"

# Check for duplicate functions in one-click-setup.sh
echo -n "• No duplicate functions: "
if ! command grep -E "^[a-zA-Z_]+\(\)" one-click-setup.sh | sort | uniq -d | command grep -q .; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} - Found duplicate functions"
    FAILURES=$((FAILURES + 1))
fi
TESTS=$((TESTS + 1))

# Check for hardcoded /home/joe paths
echo -n "• No hardcoded paths: "
if ! command grep -r "/home/joe" --include="*.sh" . 2>/dev/null | command grep -v "^Binary" | command grep -v "test-essential.sh" | command grep -q .; then
    echo -e "${GREEN}PASS${NC}"
else
    echo -e "${RED}FAIL${NC} - Found hardcoded /home/joe paths"
    FAILURES=$((FAILURES + 1))
fi
TESTS=$((TESTS + 1))

# Summary
echo -e "\n${BLUE}Summary:${NC}"
echo "========"
echo "Total tests: $TESTS"
echo -e "Passed: ${GREEN}$((TESTS - FAILURES))${NC}"
echo -e "Failed: ${RED}$FAILURES${NC}"

if [[ $FAILURES -eq 0 ]]; then
    echo -e "\n${GREEN}✅ All essential tests passed!${NC}"
    echo -e "${GREEN}The codebase is stable and ready for deployment.${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    echo -e "${YELLOW}Please fix the issues before proceeding.${NC}"
    exit 1
fi