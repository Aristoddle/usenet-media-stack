#!/bin/bash
###############################################################################
# common.sh - Common variables and functions for all scripts
###############################################################################

# Get the real script directory (handles symlinks and relative paths)
get_script_dir() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

# Set script directory - works even if sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    SCRIPT_DIR="$(get_script_dir)"
else
    # Script is being executed
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
fi

# Project root is one level up from modules/
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

# Standard directories
CONFIG_DIR="$PROJECT_ROOT/config"
DOWNLOADS_DIR="$PROJECT_ROOT/downloads"
SCRIPTS_DIR="$PROJECT_ROOT/scripts"
MODULES_DIR="$PROJECT_ROOT/modules"

# Media directory - use $HOME/media by default but allow override
MEDIA_DIR="${MEDIA_DIR:-$HOME/media}"

# Color definitions
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export BOLD='\033[1m'
export NC='\033[0m'

# Common functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
}

warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

info() {
    echo -e "${CYAN}$1${NC}"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Export all variables for use in scripts
export SCRIPT_DIR PROJECT_ROOT CONFIG_DIR DOWNLOADS_DIR SCRIPTS_DIR MODULES_DIR MEDIA_DIR