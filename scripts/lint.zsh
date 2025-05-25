#!/usr/bin/env zsh
##############################################################################
# File: ./scripts/lint.zsh
# Project: Usenet Media Stack
# Description: Stan's Commandment #1 - Run lint frequently
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Implements Stan Eisenstat's first commandment: "Thou shalt run lint
# frequently and study its pronouncements with care, for verily its
# perception and judgement oft exceed thine."
##############################################################################

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#=============================================================================
# Function: check_shellcheck
# Description: Verify shellcheck is available
#=============================================================================
check_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        echo -e "${RED}Error: shellcheck not found${NC}"
        echo -e "${YELLOW}Install with: sudo apt install shellcheck${NC}"
        echo -e "${YELLOW}Or: brew install shellcheck${NC}"
        return 1
    fi
    
    local version
    version=$(shellcheck --version | grep version: | awk '{print $2}')
    echo -e "${GREEN}✓ ShellCheck $version available${NC}"
    return 0
}

#=============================================================================
# Function: lint_file
# Description: Lint a single shell file
#
# Arguments:
#   $1 - File path to lint
#=============================================================================
lint_file() {
    local file="$1"
    local exit_code=0
    
    echo -e "${BLUE}Linting: $file${NC}"
    
    # Check if it's a zsh file
    if [[ "$file" == *.zsh ]] || head -n1 "$file" | grep -q "zsh"; then
        echo -e "${YELLOW}ZSH file detected - using zsh syntax check${NC}"
        
        # Primary: zsh native syntax checking
        if ! zsh -n "$file" 2>/dev/null; then
            echo -e "${RED}✗ ZSH syntax errors found${NC}"
            zsh -n "$file"
            exit_code=1
        else
            echo -e "${GREEN}✓ ZSH syntax valid${NC}"
        fi
        
        # Optional: ShellCheck for style (if no syntax errors)
        if [[ $exit_code -eq 0 ]] && command -v shellcheck >/dev/null 2>&1; then
            echo -e "${BLUE}Running ShellCheck for style analysis...${NC}"
            # Use lenient settings to avoid bash-specific false positives
            if ! shellcheck \
                --shell=bash \
                --severity=error \
                --exclude=SC1091,SC2034,SC2039,SC2155,SC2163 \
                "$file" 2>/dev/null; then
                echo -e "${YELLOW}⚠ Style suggestions available (non-critical)${NC}"
                # Don't fail on style issues for zsh files
            fi
        fi
    else
        # Regular bash/sh linting with shellcheck
        if ! shellcheck \
            --check-sourced \
            --external-sources \
            --severity=warning \
            --exclude=SC1091,SC2034 \
            "$file"; then
            exit_code=1
        fi
    fi
    
    return $exit_code
}

#=============================================================================
# Function: lint_all
# Description: Lint all shell files in the project
#=============================================================================
lint_all() {
    local total_files=0
    local passed_files=0
    local failed_files=0
    
    echo -e "${BLUE}🔍 Stan's Commandment #1: Running lint frequently${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    
    # Find all shell files
    local files=(
        "$PROJECT_ROOT/usenet"
        "$PROJECT_ROOT"/lib/**/*.zsh
        "$PROJECT_ROOT"/scripts/*.zsh
        "$PROJECT_ROOT"/completions/_usenet
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            ((total_files++))
            if lint_file "$file"; then
                ((passed_files++))
                echo -e "${GREEN}✓ $file${NC}"
            else
                ((failed_files++))
                echo -e "${RED}✗ $file${NC}"
            fi
            echo
        fi
    done
    
    # Summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}Files linted: $total_files${NC}"
    echo -e "${GREEN}Passed: $passed_files${NC}"
    echo -e "${RED}Failed: $failed_files${NC}"
    
    if [[ $failed_files -eq 0 ]]; then
        echo -e "${GREEN}🎉 All files pass lint checks!${NC}"
        echo -e "${GREEN}Stan would be proud.${NC}"
        return 0
    else
        echo -e "${RED}💀 $failed_files files have lint issues${NC}"
        echo -e "${RED}Fix issues and run again${NC}"
        return 1
    fi
}

#=============================================================================
# Function: main
# Description: Main entry point
#=============================================================================
main() {
    local file="${1:-}"
    
    # Check if shellcheck is available
    if ! check_shellcheck; then
        return 1
    fi
    
    if [[ -n "$file" ]]; then
        # Lint specific file
        if [[ -f "$file" ]]; then
            lint_file "$file"
        else
            echo -e "${RED}Error: File not found: $file${NC}"
            return 1
        fi
    else
        # Lint all files
        lint_all
    fi
}

# Run if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80: