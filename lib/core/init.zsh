#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/init.zsh
# Project: Usenet Media Stack
# Description: Proper initialization order - no circular dependencies
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Stan's rule: "Initialize things in the right order, or don't initialize."
# This module ensures proper loading order without circular dependencies.
##############################################################################

#=============================================================================
# Function: load_stack_config
# Description: Load configuration in proper order
#
# This is the ONLY function that should be called to initialize the stack.
# It ensures all dependencies are loaded in the correct order.
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration loaded successfully
#   1 - Configuration failed
#
# Example:
#   load_stack_config || die "Failed to initialize"
#=============================================================================
load_stack_config() {
    # 1. Load .env file first (safe parse; avoid command execution)
    if [[ -f "${PROJECT_ROOT}/.env" ]]; then
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

            # Strip surrounding quotes if present
            value="${value%\"}"
            value="${value#\"}"
            value="${value%\'}"
            value="${value#\'}"

            export "$key=$value"
        done < "${PROJECT_ROOT}/.env"
    fi
    
    # 2. Build service URLs from environment
    typeset -gA SERVICE_URLS=(
        [prowlarr]="http://${PROWLARR_HOST:-localhost}:${PROWLARR_PORT:-9696}"
        [sonarr]="http://${SONARR_HOST:-localhost}:${SONARR_PORT:-8989}"
        [radarr]="http://${RADARR_HOST:-localhost}:${RADARR_PORT:-7878}"
        [lidarr]="http://${LIDARR_HOST:-localhost}:${LIDARR_PORT:-8686}"
        [bazarr]="http://${BAZARR_HOST:-localhost}:${BAZARR_PORT:-6767}"
        [mylar]="http://${MYLAR_HOST:-localhost}:${MYLAR_PORT:-8090}"
        [sabnzbd]="http://${SABNZBD_HOST:-localhost}:${SABNZBD_PORT:-8080}"
        [plex]="http://${PLEX_HOST:-localhost}:${PLEX_PORT:-32400}"
        [overseerr]="http://${OVERSEERR_HOST:-localhost}:${OVERSEERR_PORT:-5055}"
        [portainer]="http://${PORTAINER_HOST:-localhost}:${PORTAINER_PORT:-9000}"
        [tautulli]="http://${TAUTULLI_HOST:-localhost}:${TAUTULLI_PORT:-8181}"
        [netdata]="http://${NETDATA_HOST:-localhost}:${NETDATA_PORT:-19999}"
        [tdarr]="http://${TDARR_HOST:-localhost}:${TDARR_PORT:-8265}"
    )
    
    # 3. Build provider configs from environment
    typeset -gA PROVIDERS=()
    if [[ -n "${NEWSHOSTING_USER:-}" && -n "${NEWSHOSTING_PASS:-}" ]]; then
        PROVIDERS[Newshosting]="${NEWSHOSTING_SERVER:-news.newshosting.com}:${NEWSHOSTING_PORT:-563}:${NEWSHOSTING_USER}:${NEWSHOSTING_PASS}:${NEWSHOSTING_CONNECTIONS:-30}"
    fi
    
    if [[ -n "${USENETEXPRESS_USER:-}" && -n "${USENETEXPRESS_PASS:-}" ]]; then
        PROVIDERS[UsenetExpress]="${USENETEXPRESS_SERVER:-usenetexpress.com}:${USENETEXPRESS_PORT:-563}:${USENETEXPRESS_USER}:${USENETEXPRESS_PASS}:${USENETEXPRESS_CONNECTIONS:-20}"
    fi
    
    if [[ -n "${FRUGAL_USER:-}" && -n "${FRUGAL_PASS:-}" ]]; then
        PROVIDERS[Frugalusenet]="${FRUGAL_SERVER:-newswest.frugalusenet.com}:${FRUGAL_PORT:-563}:${FRUGAL_USER}:${FRUGAL_PASS}:${FRUGAL_CONNECTIONS:-10}"
    fi
    
    # 4. Build indexer configs from environment
    typeset -gA INDEXERS=()
    [[ -n "${NZBGEEK_API:-}" ]] && INDEXERS[NZBgeek]="$NZBGEEK_API"
    [[ -n "${NZBFINDER_API:-}" ]] && INDEXERS[NZBFinder]="$NZBFINDER_API"
    [[ -n "${NZBSU_API:-}" ]] && INDEXERS[NZBsu]="$NZBSU_API"
    [[ -n "${NZBPLANET_API:-}" ]] && INDEXERS[NZBPlanet]="$NZBPLANET_API"
    
    # 5. Validate required configuration
    local errors=0
    
    # Check domain
    if [[ -z "${DOMAIN:-}" ]]; then
        echo "ERROR:" "DOMAIN not set in .env"
        ((errors++))
    fi
    
    # Check essential APIs
    if [[ -z "${NZBGEEK_API:-}" && -z "${NZBFINDER_API:-}" ]]; then
        echo "ERROR:" "At least one indexer API key required"
        ((errors++))
    fi
    
    # Check providers
    if [[ -z "${NEWSHOSTING_USER:-}" || -z "${NEWSHOSTING_PASS:-}" ]]; then
        echo "ERROR:" "Primary Usenet provider not configured (NEWSHOSTING_USER/PASS)"
        ((errors++))
    fi
    
    return $(( errors > 0 ? 1 : 0 ))
}

#=============================================================================
# Function: print_stack_config
# Description: Display configuration safely (mask secrets)
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Example:
#   print_stack_config
#=============================================================================
print_stack_config() {
    print "Stack Configuration"
    print "═══════════════════════════════════════════════════════════════"
    
    print "\nDomain: ${DOMAIN:-not set}"
    
    print "\nProviders:"
    for provider in ${(k)PROVIDERS}; do
        print "  ✓ $provider"
    done
    
    print "\nIndexers:"
    for indexer in ${(k)INDEXERS}; do
        print "  ✓ $indexer"
    done
    
    print "\nService URLs:"
    for service url in ${(kv)SERVICE_URLS}; do
        print "  $service: $url"
    done
}

# Functions available for sourcing

# vim: set ts=4 sw=4 et tw=80:
