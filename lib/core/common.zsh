#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/common.zsh
# Project: Usenet Media Stack
# Description: Common functions and utilities used across all modules
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module provides core functionality used throughout the Usenet Media
# Stack. It includes utility functions, common variables, and shared logic
# that ensures consistency across all commands and operations.
##############################################################################

##############################################################################
#                              GLOBAL SETTINGS                               #
##############################################################################

# Enable strict error handling for all scripts
set -euo pipefail

# Set consistent locale
export LC_ALL=C.UTF-8
export LANG=C.UTF-8

##############################################################################
#                                CONSTANTS                                   #
##############################################################################

# Project paths (all relative to script location)
readonly PROJECT_ROOT="${USENET_ROOT:-${0:A:h:h:h}}"
readonly CONFIG_DIR="${PROJECT_ROOT}/config"
readonly DOWNLOADS_DIR="${PROJECT_ROOT}/downloads"
readonly MEDIA_DIR="${HOME}/media"
readonly BACKUP_DIR="${PROJECT_ROOT}/backups"

# Docker settings
readonly COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
readonly COMPOSE_PROJECT="usenet-media-stack"
readonly NETWORK_NAME="usenet_default"

# Service names
readonly -a CORE_SERVICES=(
    sabnzbd
    prowlarr
    sonarr
    radarr
)

readonly -a ALL_SERVICES=(
    sabnzbd
    prowlarr
    sonarr
    radarr
    lidarr
    readarr
    mylar3
    bazarr
    jellyfin
    overseerr
    tautulli
    unpackerr
)

# Timeouts and retries
readonly DEFAULT_TIMEOUT=300  # 5 minutes
readonly DEFAULT_RETRY_COUNT=3
readonly DEFAULT_RETRY_DELAY=5

##############################################################################
#                              COLOR FUNCTIONS                               #
##############################################################################

#=============================================================================
# Function: setup_colors
# Description: Initialize color variables based on terminal capabilities
#
# Sets up color variables for consistent output formatting across the
# application. Detects if the terminal supports colors and disables them
# if not (e.g., when piping output).
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Side Effects:
#   Sets global color variables
#
# Example:
#   setup_colors
#   print "${COLOR_GREEN}Success!${COLOR_RESET}"
#=============================================================================
setup_colors() {
    if [[ -t 1 ]] && [[ "${TERM:-}" != "dumb" ]]; then
        # Terminal supports colors
        COLOR_RED=$'\033[0;31m'
        COLOR_GREEN=$'\033[0;32m'
        COLOR_YELLOW=$'\033[1;33m'
        COLOR_BLUE=$'\033[0;34m'
        COLOR_MAGENTA=$'\033[0;35m'
        COLOR_CYAN=$'\033[0;36m'
        COLOR_BOLD=$'\033[1m'
        COLOR_DIM=$'\033[2m'
        COLOR_RESET=$'\033[0m'
    else
        # No color support
        COLOR_RED=""
        COLOR_GREEN=""
        COLOR_YELLOW=""
        COLOR_BLUE=""
        COLOR_MAGENTA=""
        COLOR_CYAN=""
        COLOR_BOLD=""
        COLOR_DIM=""
        COLOR_RESET=""
    fi
    
    # Export for use in subshells
    export COLOR_{RED,GREEN,YELLOW,BLUE,MAGENTA,CYAN,BOLD,DIM,RESET}
}

# Initialize colors on load
setup_colors

##############################################################################
#                            OUTPUT FUNCTIONS                                #
##############################################################################

#=============================================================================
# Function: log
# Description: Print formatted log message with timestamp
#
# Outputs a timestamped log message to stdout. Used for general information
# that should be captured in logs.
#
# Arguments:
#   $@ - Message to log
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   log "Starting deployment process"
#=============================================================================
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    print "[${timestamp}] $*"
}

#=============================================================================
# Function: info
# Description: Print informational message
#
# Outputs an informational message in blue color to make it stand out
# from regular output.
#
# Arguments:
#   $@ - Message to display
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   info "Checking system requirements"
#=============================================================================
info() {
    print "${COLOR_BLUE}ℹ ${*}${COLOR_RESET}"
}

#=============================================================================
# Function: success
# Description: Print success message
#
# Outputs a success message in green with a checkmark symbol.
#
# Arguments:
#   $@ - Success message
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   success "All services started successfully"
#=============================================================================
success() {
    print "${COLOR_GREEN}✓ ${*}${COLOR_RESET}"
}

#=============================================================================
# Function: warning
# Description: Print warning message
#
# Outputs a warning message in yellow to stderr to ensure it's visible
# even when stdout is redirected.
#
# Arguments:
#   $@ - Warning message
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   warning "Low disk space detected"
#=============================================================================
warning() {
    print -u2 "${COLOR_YELLOW}⚠ ${*}${COLOR_RESET}"
}

#=============================================================================
# Function: error
# Description: Print error message
#
# Outputs an error message in red to stderr. Does not exit - calling code
# should handle the error appropriately.
#
# Arguments:
#   $@ - Error message
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   error "Failed to connect to database"
#=============================================================================
error() {
    print -u2 "${COLOR_RED}✗ ${*}${COLOR_RESET}"
}

#=============================================================================
# Function: die
# Description: Print error message and exit
#
# Outputs an error message and immediately exits the script with the
# specified exit code. Use for unrecoverable errors.
#
# Arguments:
#   $1 - Exit code
#   $2+ - Error message
#
# Returns:
#   Never returns (exits script)
#
# Example:
#   die 1 "Configuration file not found"
#=============================================================================
die() {
    local exit_code=$1
    shift
    error "$@"
    exit $exit_code
}

##############################################################################
#                           VALIDATION FUNCTIONS                             #
##############################################################################

#=============================================================================
# Function: require_command
# Description: Verify a command exists or exit
#
# Checks if a command is available in PATH. If not, prints an error message
# with installation instructions and exits.
#
# Arguments:
#   $1 - Command name to check
#   $2 - Installation hint (optional)
#
# Returns:
#   0 - Command exists
#   Exits with code 1 if command not found
#
# Example:
#   require_command docker "Install from https://docker.com"
#   require_command jq "sudo apt install jq"
#=============================================================================
require_command() {
    local cmd=$1
    local install_hint=${2:-"Please install $cmd"}
    
    if ! command -v "$cmd" &>/dev/null; then
        error "Required command not found: $cmd"
        error "$install_hint"
        exit 1
    fi
}

#=============================================================================
# Function: require_file
# Description: Verify a file exists or exit
#
# Checks if a file exists and is readable. If not, prints an error and exits.
#
# Arguments:
#   $1 - File path to check
#   $2 - Error message (optional)
#
# Returns:
#   0 - File exists and is readable
#   Exits with code 1 if file not found
#
# Example:
#   require_file "$CONFIG_FILE" "Configuration not found"
#=============================================================================
require_file() {
    local file=$1
    local error_msg=${2:-"Required file not found: $file"}
    
    if [[ ! -f "$file" ]] || [[ ! -r "$file" ]]; then
        die 1 "$error_msg"
    fi
}

#=============================================================================
# Function: require_directory
# Description: Verify a directory exists or create it
#
# Checks if a directory exists. If not, attempts to create it with proper
# permissions. Exits on failure.
#
# Arguments:
#   $1 - Directory path
#   $2 - Permissions (optional, default: 755)
#
# Returns:
#   0 - Directory exists or was created
#   Exits with code 1 on failure
#
# Example:
#   require_directory "$BACKUP_DIR"
#   require_directory "$CONFIG_DIR" 700
#=============================================================================
require_directory() {
    local dir=$1
    local perms=${2:-755}
    
    if [[ ! -d "$dir" ]]; then
        info "Creating directory: $dir"
        if ! mkdir -p "$dir"; then
            die 1 "Failed to create directory: $dir"
        fi
        chmod "$perms" "$dir"
    fi
}

##############################################################################
#                            UTILITY FUNCTIONS                               #
##############################################################################

#=============================================================================
# Function: confirm
# Description: Ask user for confirmation
#
# Prompts the user with a yes/no question and returns their response.
# Defaults to 'no' if no response is given.
#
# Arguments:
#   $1 - Question to ask
#   $2 - Default answer (y/n, optional, default: n)
#
# Returns:
#   0 - User confirmed (yes)
#   1 - User declined (no)
#
# Example:
#   if confirm "Continue with deployment?" y; then
#       deploy_stack
#   fi
#=============================================================================
confirm() {
    local question=$1
    local default=${2:-n}
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="$question [Y/n] "
    else
        prompt="$question [y/N] "
    fi
    
    local response
    read -r "response?$prompt"
    
    # Default if empty
    [[ -z "$response" ]] && response=$default
    
    # Check response
    [[ "$response" =~ ^[Yy] ]]
}

#=============================================================================
# Function: is_running_in_docker
# Description: Check if we're running inside a Docker container
#
# Detects if the current process is running inside a Docker container by
# checking for Docker-specific files and cgroup entries.
#
# Arguments:
#   None
#
# Returns:
#   0 - Running in Docker
#   1 - Not running in Docker
#
# Example:
#   if is_running_in_docker; then
#       warning "Running inside Docker container"
#   fi
#=============================================================================
is_running_in_docker() {
    [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null
}

#=============================================================================
# Function: get_script_dir
# Description: Get the directory of the current script
#
# Returns the absolute path to the directory containing the current script,
# handling symlinks correctly.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   Absolute path to script directory
#
# Example:
#   local script_dir=$(get_script_dir)
#=============================================================================
get_script_dir() {
    print "${0:A:h}"
}

# Export all functions for use in subshells
typeset -f | grep '^[a-z_]* ()' | cut -d' ' -f1 | while read func; do
    export -f "$func" 2>/dev/null || true
done

# vim: set ts=4 sw=4 et tw=80: