#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/configure.zsh
# Project: Usenet Media Stack
# Description: Service configuration management
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module handles all service configuration including API keys, indexers,
# providers, and inter-service connections. It consolidates the functionality
# from configure-prowlarr.sh, configure-services.sh, and setup-all.sh.
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Get script directory and load common functions
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR:h}/core/common.zsh" || {
    print -u2 "ERROR: Cannot load common.zsh"
    exit 1
}

# Load API wrappers
source "${SCRIPT_DIR:h}/core/arr-api.zsh" || {
    print -u2 "ERROR: Cannot load arr-api.zsh"
    exit 1
}

# Load configuration (includes PROVIDERS and INDEXERS from env)
# This is already done in common.zsh which loads config.zsh

##############################################################################
#                            CONFIGURATION DATA                              #
##############################################################################

# Indexer configurations loaded from environment
typeset -gA INDEXERS

# Provider configurations loaded from environment  
typeset -gA PROVIDERS

# Service URLs (loaded from config module)

##############################################################################
#                           API KEY MANAGEMENT                               #
##############################################################################

#=============================================================================
# Function: get_api_key
# Description: Extract API key from service configuration
#
# Attempts to extract the API key from a service's configuration file.
# Handles both XML and INI formats.
#
# Arguments:
#   $1 - Service name
#
# Returns:
#   0 - Success (prints API key)
#   1 - Failed to get API key
#
# Example:
#   local api_key=$(get_api_key prowlarr)
#=============================================================================
get_api_key() {
    local service=$1
    local config_file=""
    local api_key=""
    
    case "$service" in
        prowlarr|sonarr|radarr|lidarr|bazarr)
            config_file="$CONFIG_DIR/$service/config.xml"
            if [[ -f "$config_file" ]]; then
                api_key=$(grep -oP '(?<=<ApiKey>)[^<]+' "$config_file" 2>/dev/null || true)
            fi
            ;;
            
        sabnzbd)
            config_file="$CONFIG_DIR/sabnzbd/sabnzbd.ini"
            if [[ -f "$config_file" ]]; then
                api_key=$(grep "^api_key = " "$config_file" | cut -d' ' -f3 2>/dev/null || true)
            fi
            ;;
            
        mylar3)
            config_file="$CONFIG_DIR/mylar3/config.ini"
            if [[ -f "$config_file" ]]; then
                api_key=$(grep "^api_key = " "$config_file" | cut -d' ' -f3 2>/dev/null || true)
            fi
            ;;
    esac
    
    if [[ -n "$api_key" ]]; then
        print "$api_key"
        return 0
    else
        return 1
    fi
}

#=============================================================================
# Function: wait_for_api_key
# Description: Wait for service to generate API key
#
# Polls service configuration until an API key appears or timeout.
#
# Arguments:
#   $1 - Service name
#   $2 - Timeout in seconds (default: 30)
#
# Returns:
#   0 - Success (prints API key)
#   1 - Timeout waiting for API key
#
# Example:
#   local api_key=$(wait_for_api_key prowlarr 60)
#=============================================================================
wait_for_api_key() {
    local service=$1
    local timeout=${2:-30}
    local elapsed=0
    local api_key=""
    
    log_info "Waiting for $service to generate API key..."
    
    while (( elapsed < timeout )); do
        api_key=$(get_api_key "$service" 2>/dev/null || true)
        if [[ -n "$api_key" ]]; then
            print "$api_key"
            return 0
        fi
        
        sleep 2
        ((elapsed += 2))
    done
    
    return 1
}

##############################################################################
#                         SABNZBD CONFIGURATION                              #
##############################################################################

#=============================================================================
# Function: configure_sabnzbd
# Description: Configure SABnzbd with providers and settings
#
# Sets up SABnzbd with Usenet providers, categories, and optimal settings.
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration successful
#   1 - Configuration failed
#
# Example:
#   configure_sabnzbd
#=============================================================================
configure_sabnzbd() {
    log_info "Configuring SABnzbd..."
    
    # Get API key
    local api_key=$(get_api_key sabnzbd)
    if [[ -z "$api_key" ]]; then
        api_key=$(wait_for_api_key sabnzbd 30)
    fi
    
    if [[ -z "$api_key" ]]; then
        log_error "Failed to get SABnzbd API key"
        return 1
    fi
    
    local url="${SERVICE_URLS[sabnzbd]}"
    
    # Configure each provider
    for provider in ${(k)PROVIDERS}; do
        IFS=':' read -r server port username password connections <<< "${PROVIDERS[$provider]}"
        
        log_info "Adding provider: $provider"
        
        # Add server via API
        local data="mode=addserver&name=$provider"
        data+="&host=$server&port=$port&username=$username"
        data+="&password=$password&connections=$connections"
        data+="&ssl=1&enable=1&priority=0"
        
        if sab_api_post "$url" "$api_key" "$data" >/dev/null 2>&1; then
            log_success "Added $provider"
        else
            log_warning "Failed to add $provider"
        fi
    done
    
    # Configure categories
    configure_sabnzbd_categories "$url" "$api_key"
    
    return 0
}

#=============================================================================
# Function: configure_sabnzbd_categories
# Description: Set up download categories for different media types
#
# Creates categories with appropriate paths for TV, movies, books, etc.
#
# Arguments:
#   $1 - SABnzbd URL
#   $2 - API key
#
# Returns:
#   0 - Categories configured
#   1 - Failed to configure categories
#
# Example:
#   configure_sabnzbd_categories "http://localhost:8080" "abc123"
#=============================================================================
configure_sabnzbd_categories() {
    local url=$1
    local api_key=$2
    
    log_info "Configuring SABnzbd categories..."
    
    local -A categories=(
        [tv]="tv"
        [movies]="movies"
        [books]="books"
        [comics]="comics"
        [music]="music"
    )
    
    for cat path in ${(kv)categories}; do
        local data="mode=set_cat&name=$cat&pp=3&script=None&dir=$path"
        
        if sab_api_post "$url" "$api_key" "$data" >/dev/null 2>&1; then
            log_success "Created category: $cat"
        else
            log_warning "Failed to create category: $cat"
        fi
    done
}

##############################################################################
#                        PROWLARR CONFIGURATION                              #
##############################################################################

#=============================================================================
# Function: configure_prowlarr
# Description: Configure Prowlarr with indexers
#
# Adds all configured indexers to Prowlarr using the API.
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration successful
#   1 - Configuration failed
#
# Example:
#   configure_prowlarr
#=============================================================================
configure_prowlarr() {
    log_info "Configuring Prowlarr..."
    
    # Get API key
    local api_key=$(get_api_key prowlarr)
    if [[ -z "$api_key" ]]; then
        log_error "Prowlarr API key not found"
        log_info "Please complete Prowlarr setup first"
        return 1
    fi
    
    local url="${SERVICE_URLS[prowlarr]}"
    
    # Add each indexer
    for indexer api in ${(kv)INDEXERS}; do
        log_info "Adding indexer: $indexer"
        
        # Prepare indexer JSON
        local json=$(cat <<EOF
{
  "name": "$indexer",
  "fields": [
    {"name": "baseUrl", "value": "https://api.${indexer:l}.com"},
    {"name": "apiKey", "value": "$api"},
    {"name": "categories", "value": [2000,3000,5000,6000,7000,8000]}
  ],
  "configContract": "NewznabSettings",
  "implementation": "Newznab",
  "implementationName": "Newznab",
  "enable": true,
  "protocol": "usenet",
  "priority": 25,
  "appProfileId": 1
}
EOF
)
        
        if arr_api_post "$url" "$api_key" "/api/v1/indexer" "$json" >/dev/null 2>&1; then
            log_success "Added $indexer"
        else
            log_warning "Failed to add $indexer"
        fi
    done
    
    # Configure apps in Prowlarr
    configure_prowlarr_apps "$url" "$api_key"
    
    return 0
}

#=============================================================================
# Function: configure_prowlarr_apps
# Description: Connect Prowlarr to all *arr applications
#
# Sets up Prowlarr to sync indexers with Sonarr, Radarr, etc.
#
# Arguments:
#   $1 - Prowlarr URL
#   $2 - API key
#
# Returns:
#   0 - Apps configured
#   1 - Failed to configure apps
#
# Example:
#   configure_prowlarr_apps "http://localhost:9696" "abc123"
#=============================================================================
configure_prowlarr_apps() {
    local url=$1
    local api_key=$2
    
    log_info "Configuring Prowlarr applications..."
    
    local -a apps=(sonarr radarr lidarr)
    
    for app in $apps; do
        local app_api_key=$(get_api_key "$app")
        if [[ -z "$app_api_key" ]]; then
            log_warning "Skipping $app - no API key found"
            continue
        fi
        
        log_info "Adding $app to Prowlarr"
        
        local json=$(cat <<EOF
{
  "name": "$app",
  "syncLevel": "fullSync",
  "fields": [
    {"name": "prowlarrUrl", "value": "$url"},
    {"name": "baseUrl", "value": "${SERVICE_URLS[$app]}"},
    {"name": "apiKey", "value": "$app_api_key"},
    {"name": "syncCategories", "value": [2000,3000,5000,6000,7000,8000]}
  ],
  "configContract": "${app^}Settings",
  "implementation": "${app^}",
  "implementationName": "${app^}",
  "tags": []
}
EOF
)
        
        if arr_api_post "$url" "$api_key" "/api/v1/applications" "$json" >/dev/null 2>&1; then
            log_success "Added $app"
        else
            log_warning "Failed to add $app"
        fi
    done
}

##############################################################################
#                         ARR APP CONFIGURATION                              #
##############################################################################

#=============================================================================
# Function: configure_arr_apps
# Description: Configure all *arr applications
#
# Sets up Sonarr, Radarr, Lidarr with download client and paths.
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration successful
#   1 - Configuration failed
#
# Example:
#   configure_arr_apps
#=============================================================================
configure_arr_apps() {
    log_info "Configuring *arr applications..."
    
    local -A app_paths=(
        [sonarr]="/tv"
        [radarr]="/movies"
        [lidarr]="/music"
    )
    
    for app path in ${(kv)app_paths}; do
        configure_arr_app "$app" "$path"
    done
}

#=============================================================================
# Function: configure_arr_app
# Description: Configure a single *arr application
#
# Sets up download client, root folder, and basic settings.
#
# Arguments:
#   $1 - App name (sonarr, radarr, etc.)
#   $2 - Root folder path
#
# Returns:
#   0 - Configuration successful
#   1 - Configuration failed
#
# Example:
#   configure_arr_app sonarr /tv
#=============================================================================
configure_arr_app() {
    local app=$1
    local root_path=$2
    
    log_info "Configuring $app..."
    
    local api_key=$(get_api_key "$app")
    if [[ -z "$api_key" ]]; then
        log_warning "Skipping $app - no API key found"
        return 1
    fi
    
    local url="${SERVICE_URLS[$app]}"
    local sab_api_key=$(get_api_key sabnzbd)
    
    # Add SABnzbd as download client
    if [[ -n "$sab_api_key" ]]; then
        log_info "Adding SABnzbd to $app"
        
        local json=$(cat <<EOF
{
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "name": "SABnzbd",
  "fields": [
    {"name": "host", "value": "sabnzbd"},
    {"name": "port", "value": 8080},
    {"name": "apiKey", "value": "$sab_api_key"},
    {"name": "tvCategory", "value": "tv"},
    {"name": "recentTvPriority", "value": -100},
    {"name": "olderTvPriority", "value": -100},
    {"name": "useSsl", "value": false}
  ],
  "configContract": "SabnzbdSettings",
  "implementation": "Sabnzbd",
  "implementationName": "SABnzbd"
}
EOF
)
        
        if arr_api_post "$url" "$api_key" "/api/v3/downloadclient" "$json" >/dev/null 2>&1; then
            log_success "Added SABnzbd to $app"
        else
            log_warning "Failed to add SABnzbd to $app"
        fi
    fi
    
    # Add root folder
    log_info "Setting root folder for $app: $root_path"
    
    local folder_json=$(cat <<EOF
{
  "path": "$root_path",
  "accessible": true,
  "freeSpace": 0,
  "unmappedFolders": []
}
EOF
)
    
    if arr_api_post "$url" "$api_key" "/api/v3/rootfolder" "$folder_json" >/dev/null 2>&1; then
        log_success "Added root folder to $app"
    else
        log_warning "Failed to add root folder to $app"
    fi
}

##############################################################################
#                            MAIN HANDLER                                    #
##############################################################################

#=============================================================================
# Function: show_configure_help
# Description: Display help for configure command
#
# Shows detailed help and usage examples for the configure command.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   show_configure_help
#=============================================================================
show_configure_help() {
    cat <<'HELP'
CONFIGURE COMMAND

Usage: usenet configure [options] [service]

Configure services with API keys, indexers, and connections.

OPTIONS
    --all              Configure all services (default)
    --prowlarr         Configure only Prowlarr
    --sabnzbd          Configure only SABnzbd
    --arr              Configure all *arr apps
    --force            Force reconfiguration
    --help, -h         Show this help

SERVICES
    prowlarr           Indexer management
    sabnzbd            Download client
    sonarr             TV shows
    radarr             Movies
    lidarr             Music
    all                All services

EXAMPLES
    Configure everything:
        $ usenet configure --all
        
    Configure specific service:
        $ usenet configure prowlarr
        
    Force reconfiguration:
        $ usenet configure --force

NOTES
    - Services must be running before configuration
    - Some services require initial web setup first
    - API keys are extracted from config files
    - Credentials are managed via 1Password

HELP
}

#=============================================================================
# Function: main
# Description: Main entry point for configure command
#
# Handles command routing for configuration operations.
#
# Arguments:
#   $@ - Command line arguments
#
# Returns:
#   0 - Configuration successful
#   1 - Configuration failed
#
# Example:
#   main --all
#=============================================================================
main() {
    local target="all"
    local force=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all)
                target="all"
                ;;
            --prowlarr)
                target="prowlarr"
                ;;
            --sabnzbd)
                target="sabnzbd"
                ;;
            --arr)
                target="arr"
                ;;
            --force)
                force=true
                ;;
            --help|-h)
                show_configure_help
                return 0
                ;;
            prowlarr|sabnzbd|sonarr|radarr|lidarr|all)
                target="$1"
                ;;
            *)
                log_error "Unknown option: $1"
                show_configure_help
                return 1
                ;;
        esac
        shift
    done
    
    # Check services are running
    log_info "Checking service availability..."
    local all_running=true
    for service url in ${(kv)SERVICE_URLS}; do
        local api_key=$(get_api_key "$service" 2>/dev/null || true)
        if [[ -n "$api_key" ]] && arr_health_check "$url" "$api_key"; then
            log_success "$service is available"
        elif curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200\|301\|302"; then
            log_success "$service is available"
        else
            log_warning "$service is not accessible"
            all_running=false
        fi
    done
    
    if [[ "$all_running" != "true" ]]; then
        log_error "Some services are not running"
        log_info "Start services with: usenet start"
        return 1
    fi
    
    # Configure based on target
    case "$target" in
        all)
            configure_sabnzbd
            configure_prowlarr
            configure_arr_apps
            ;;
        prowlarr)
            configure_prowlarr
            ;;
        sabnzbd)
            configure_sabnzbd
            ;;
        arr)
            configure_arr_apps
            ;;
        sonarr|radarr|lidarr)
            configure_arr_app "$target" "${app_paths[$target]}"
            ;;
    esac
    
    log_success "Configuration complete!"
    return 0
}

# Run main function
main "$@"

# vim: set ts=4 sw=4 et tw=80:
