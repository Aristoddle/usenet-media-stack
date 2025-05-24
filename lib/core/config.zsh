#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/config.zsh
# Project: Usenet Media Stack
# Description: Central configuration management module
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module provides centralized configuration management following the
# principle of separation of concerns. All configuration is loaded from
# environment variables with proper validation and defaults.
#
# Design principles:
# - Single source of truth for all configuration
# - Fail fast with clear error messages
# - No magic constants in code
# - Type-safe configuration access
##############################################################################

##############################################################################
#                            CONFIGURATION SCHEMA                            #
##############################################################################

# Configuration validation rules
typeset -gA CONFIG_SCHEMA=(
    # Cloudflare Tunnel
    [TUNNEL_TOKEN]="required|string|min:32"
    [DOMAIN]="optional|string|domain"
    
    # Usenet Providers
    [NEWSHOSTING_USER]="required|string"
    [NEWSHOSTING_PASS]="required|string|min:8"
    [USENETEXPRESS_USER]="required|string"
    [USENETEXPRESS_PASS]="required|string|min:8"
    [FRUGAL_USER]="required|string"
    [FRUGAL_PASS]="required|string|min:8"
    
    # Indexer API Keys
    [NZBGEEK_API]="required|string|length:32"
    [NZBFINDER_API]="required|string|length:32"
    [NZBSU_API]="optional|string|length:32"
    [NZBPLANET_API]="optional|string|length:32"
    
    # Paths
    [CONFIG_PATH]="optional|path|default:./config"
    [DOWNLOADS_PATH]="optional|path|default:./downloads"
    [MEDIA_PATH]="optional|path|default:./media"
    
    # System
    [TZ]="optional|string|default:America/New_York"
    [PUID]="optional|integer|default:1000"
    [PGID]="optional|integer|default:1000"
)

# Provider configurations (derived from env vars)
typeset -gA PROVIDERS
typeset -gA INDEXERS
typeset -gA SERVICE_PORTS
typeset -gA SERVICE_URLS

##############################################################################
#                          CONFIGURATION LOADER                              #
##############################################################################

#=============================================================================
# Function: load_config
# Description: Load and validate configuration from environment
#
# Loads configuration from .env file and environment variables, validates
# according to schema, and populates global configuration maps.
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration loaded successfully
#   1 - Configuration validation failed
#
# Example:
#   load_config || die "Failed to load configuration"
#=============================================================================
load_config() {
    local config_file="${PROJECT_ROOT}/.env"
    
    # Load .env if exists
    if [[ -f "$config_file" ]]; then
        # Source .env safely (prevent command execution)
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            
            # Remove quotes if present
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"
            
            # Export to environment
            export "$key=$value"
        done < "$config_file"
    else
        log_warning "No .env file found at $config_file"
        log_info "Using environment variables only"
    fi
    
    # Validate configuration
    if ! validate_config; then
        return 1
    fi
    
    # Build derived configurations
    build_provider_config
    build_indexer_config
    build_service_config
    
    return 0
}

#=============================================================================
# Function: validate_config
# Description: Validate configuration against schema
#
# Checks each configuration value against its schema rules.
#
# Arguments:
#   None
#
# Returns:
#   0 - All validations passed
#   1 - Validation failed
#
# Example:
#   validate_config || die "Invalid configuration"
#=============================================================================
validate_config() {
    local errors=0
    
    for key rules in ${(kv)CONFIG_SCHEMA}; do
        local value="${(P)key}"
        local rule_list=(${(s:|:)rules})
        
        for rule in $rule_list; do
            case "$rule" in
                required)
                    if [[ -z "$value" ]]; then
                        log_error "Required configuration missing: $key"
                        ((errors++))
                    fi
                    ;;
                    
                optional)
                    # No validation needed
                    ;;
                    
                string)
                    if [[ -n "$value" ]] && [[ ! "$value" =~ ^[[:print:]]+$ ]]; then
                        log_error "Invalid string value for $key"
                        ((errors++))
                    fi
                    ;;
                    
                integer)
                    if [[ -n "$value" ]] && [[ ! "$value" =~ ^[0-9]+$ ]]; then
                        log_error "Invalid integer value for $key: $value"
                        ((errors++))
                    fi
                    ;;
                    
                min:*)
                    local min="${rule#min:}"
                    if [[ -n "$value" ]] && (( ${#value} < min )); then
                        log_error "$key must be at least $min characters"
                        ((errors++))
                    fi
                    ;;
                    
                length:*)
                    local len="${rule#length:}"
                    if [[ -n "$value" ]] && (( ${#value} != len )); then
                        log_error "$key must be exactly $len characters"
                        ((errors++))
                    fi
                    ;;
                    
                default:*)
                    if [[ -z "$value" ]]; then
                        local default="${rule#default:}"
                        eval "export $key='$default'"
                    fi
                    ;;
            esac
        done
    done
    
    return $(( errors > 0 ? 1 : 0 ))
}

#=============================================================================
# Function: build_provider_config
# Description: Build provider configuration from environment variables
#
# Constructs the PROVIDERS associative array from individual env vars.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   build_provider_config
#=============================================================================
build_provider_config() {
    # Clear existing
    PROVIDERS=()
    
    # Newshosting
    if [[ -n "$NEWSHOSTING_USER" ]]; then
        PROVIDERS[Newshosting]="${NEWSHOSTING_SERVER:-news.newshosting.com}:${NEWSHOSTING_PORT:-563}:${NEWSHOSTING_USER}:${NEWSHOSTING_PASS}:${NEWSHOSTING_CONNECTIONS:-30}"
    fi
    
    # UsenetExpress
    if [[ -n "$USENETEXPRESS_USER" ]]; then
        PROVIDERS[UsenetExpress]="${USENETEXPRESS_SERVER:-usenetexpress.com}:${USENETEXPRESS_PORT:-563}:${USENETEXPRESS_USER}:${USENETEXPRESS_PASS}:${USENETEXPRESS_CONNECTIONS:-20}"
    fi
    
    # Frugal
    if [[ -n "$FRUGAL_USER" ]]; then
        PROVIDERS[Frugalusenet]="${FRUGAL_SERVER:-newswest.frugalusenet.com}:${FRUGAL_PORT:-563}:${FRUGAL_USER}:${FRUGAL_PASS}:${FRUGAL_CONNECTIONS:-10}"
    fi
}

#=============================================================================
# Function: build_indexer_config
# Description: Build indexer configuration from environment variables
#
# Constructs the INDEXERS associative array from individual env vars.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   build_indexer_config
#=============================================================================
build_indexer_config() {
    # Clear existing
    INDEXERS=()
    
    # Add configured indexers
    [[ -n "$NZBGEEK_API" ]] && INDEXERS[NZBgeek]="$NZBGEEK_API"
    [[ -n "$NZBFINDER_API" ]] && INDEXERS[NZBFinder]="$NZBFINDER_API"
    [[ -n "$NZBSU_API" ]] && INDEXERS[NZBsu]="$NZBSU_API"
    [[ -n "$NZBPLANET_API" ]] && INDEXERS[NZBPlanet]="$NZBPLANET_API"
    [[ -n "$DRUNKENSLUG_API" ]] && INDEXERS[DrunkenSlug]="$DRUNKENSLUG_API"
    [[ -n "$NZBNOOB_API" ]] && INDEXERS[NZBNoob]="$NZBNOOB_API"
}

#=============================================================================
# Function: build_service_config
# Description: Build service configuration
#
# Constructs service URLs and ports arrays.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   build_service_config
#=============================================================================
build_service_config() {
    # Service ports (internal)
    SERVICE_PORTS=(
        [sabnzbd]=8080
        [prowlarr]=9696
        [sonarr]=8989
        [radarr]=7878
        [readarr]=8787
        [lidarr]=8686
        [bazarr]=6767
        [mylar3]=8090
        [jellyfin]=8096
        [overseerr]=5055
        [portainer]=9000
        [netdata]=19999
    )
    
    # Build URLs from ports
    SERVICE_URLS=()
    for service port in ${(kv)SERVICE_PORTS}; do
        SERVICE_URLS[$service]="http://localhost:$port"
    done
}

#=============================================================================
# Function: get_config
# Description: Get configuration value with optional default
#
# Retrieves a configuration value from environment with fallback.
#
# Arguments:
#   $1 - Configuration key
#   $2 - Default value (optional)
#
# Returns:
#   0 - Always (prints value)
#
# Example:
#   local tz=$(get_config TZ "UTC")
#=============================================================================
get_config() {
    local key=$1
    local default="${2:-}"
    local value="${(P)key}"
    
    print "${value:-$default}"
}

#=============================================================================
# Function: require_config
# Description: Get required configuration or die
#
# Retrieves a required configuration value, failing if not set.
#
# Arguments:
#   $1 - Configuration key
#
# Returns:
#   0 - Value exists (prints value)
#   Dies if value not set
#
# Example:
#   local token=$(require_config TUNNEL_TOKEN)
#=============================================================================
require_config() {
    local key=$1
    local value="${(P)key}"
    
    if [[ -z "$value" ]]; then
        die 1 "Required configuration not set: $key"
    fi
    
    print "$value"
}

#=============================================================================
# Function: print_config
# Description: Print current configuration (with secrets masked)
#
# Displays the current configuration for debugging, masking sensitive values.
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   print_config
#=============================================================================
print_config() {
    print "Current Configuration:"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Providers
    print "\nProviders:"
    for provider details in ${(kv)PROVIDERS}; do
        IFS=':' read -r server port user pass conns <<< "$details"
        print "  $provider: $server:$port (${conns} connections)"
    done
    
    # Indexers
    print "\nIndexers:"
    for indexer api in ${(kv)INDEXERS}; do
        print "  $indexer: ${api:0:8}..."
    done
    
    # Paths
    print "\nPaths:"
    print "  Config: $(get_config CONFIG_PATH)"
    print "  Downloads: $(get_config DOWNLOADS_PATH)"
    print "  Media: $(get_config MEDIA_PATH)"
    
    # System
    print "\nSystem:"
    print "  Timezone: $(get_config TZ)"
    print "  PUID: $(get_config PUID)"
    print "  PGID: $(get_config PGID)"
}

# Export functions
typeset -fx load_config validate_config get_config require_config print_config

# vim: set ts=4 sw=4 et tw=80: