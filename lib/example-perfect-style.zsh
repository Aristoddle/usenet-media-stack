#!/usr/bin/env zsh
##############################################################################
# File: ./lib/example-perfect-style.zsh
# Project: Usenet Media Stack
# Description: Example of perfect old-school CS style with proper formatting
# Author: Your Name <your.email@domain.com>
# Created: 2024-01-20
# Modified: 2024-01-20
# Version: 1.0.0
# License: MIT
#
# This file demonstrates the gold standard of code documentation and style
# that would make Kernighan, Ritchie, and Knuth proud.
##############################################################################

##############################################################################
#                                CONSTANTS                                   #
##############################################################################

# Maximum line length for all code and comments
readonly MAX_LINE_LENGTH=80

# System paths - note these are relative to project root
readonly PROJECT_ROOT="${0:A:h:h}"  # Two levels up from lib/
readonly CONFIG_DIR="${PROJECT_ROOT}/config"
readonly LIB_DIR="${PROJECT_ROOT}/lib"

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Ensure we're running in the correct environment
if [[ ! -d "${PROJECT_ROOT}/lib" ]]; then
    print -u2 "ERROR: Cannot find lib directory. Are we installed correctly?"
    exit 1
fi

##############################################################################
#                           UTILITY FUNCTIONS                                #
##############################################################################

#=============================================================================
# Function: check_dependencies
# Description: Verify all required system dependencies are available
# 
# This function checks for the presence of required external commands
# and reports any missing dependencies to the user.
#
# Arguments:
#   None
#
# Returns:
#   0 - All dependencies satisfied
#   1 - One or more dependencies missing
#
# Side Effects:
#   Prints missing dependencies to stderr
#
# Example:
#   if check_dependencies; then
#       echo "System ready"
#   else
#       exit 1
#   fi
#=============================================================================
check_dependencies() {
    local -a required_commands=(
        docker
        docker-compose
        curl
        jq
    )
    
    local missing_count=0
    local cmd
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            print -u2 "ERROR: Required command not found: $cmd"
            (( missing_count++ ))
        fi
    done
    
    return $(( missing_count > 0 ? 1 : 0 ))
}

##############################################################################
#                            DOCKER OPERATIONS                               #
##############################################################################

#=============================================================================
# Function: start_docker_daemon
# Description: Start Docker daemon with platform-specific commands
#
# This function attempts to start the Docker daemon using the appropriate
# method for the current platform. It includes retry logic with exponential
# backoff for reliability.
#
# Arguments:
#   $1 - max_attempts (optional, default: 3)
#        Maximum number of start attempts
#   
#   $2 - quiet (optional, default: false)
#        If "true", suppress output
#
# Returns:
#   0 - Docker daemon started successfully
#   1 - Failed to start after all attempts
#
# Side Effects:
#   - May prompt for sudo password on Linux
#   - Opens Docker.app on macOS
#   - Prints status messages unless quiet=true
#
# Example:
#   if start_docker_daemon 5 true; then
#       echo "Docker ready"
#   fi
#=============================================================================
start_docker_daemon() {
    local max_attempts="${1:-3}"
    local quiet="${2:-false}"
    local attempt=1
    
    # First check if Docker is already running
    if docker info &>/dev/null; then
        [[ "$quiet" != "true" ]] && print "Docker daemon already running"
        return 0
    fi
    
    [[ "$quiet" != "true" ]] && print "Starting Docker daemon..."
    
    # Platform detection
    local platform="$(uname -s)"
    
    while (( attempt <= max_attempts )); do
        case "$platform" in
            Darwin)
                # macOS - use open command
                open -a Docker
                ;;
                
            Linux)
                # Linux - try systemctl first, then service
                if command -v systemctl &>/dev/null; then
                    sudo systemctl start docker 2>/dev/null
                elif command -v service &>/dev/null; then
                    sudo service docker start 2>/dev/null
                else
                    print -u2 "ERROR: No service manager found"
                    return 1
                fi
                ;;
                
            *)
                print -u2 "ERROR: Unsupported platform: $platform"
                return 1
                ;;
        esac
        
        # Wait with exponential backoff
        local wait_time=$(( 2 ** attempt ))
        [[ "$quiet" != "true" ]] && \
            print "Waiting ${wait_time}s for Docker to start..."
        sleep "$wait_time"
        
        # Check if Docker is now running
        if docker info &>/dev/null; then
            [[ "$quiet" != "true" ]] && print "Docker daemon started"
            return 0
        fi
        
        (( attempt++ ))
    done
    
    print -u2 "ERROR: Docker failed to start after $max_attempts attempts"
    return 1
}

##############################################################################
#                              MAIN EXECUTION                                #
##############################################################################

# Only run main if this script is executed directly
if [[ "${ZSH_EVAL_CONTEXT}" == "toplevel" ]]; then
    print "This is a library file and should be sourced, not executed"
    exit 1
fi

# vim: set ts=4 sw=4 et tw=80: