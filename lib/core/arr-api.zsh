#!/usr/bin/env zsh
##############################################################################
# File: ./lib/core/arr-api.zsh
# Project: Usenet Media Stack
# Description: Unified API wrappers for ARR services and SABnzbd
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-12-21
# Version: 1.0.0
# License: MIT
#
# This module provides consistent API call patterns for:
# - SABnzbd (form-encoded with apikey param)
# - Prowlarr/Sonarr/Radarr/Lidarr (JSON with X-Api-Key header)
##############################################################################

##############################################################################
#                           ARR API FUNCTIONS                                #
##############################################################################

#=============================================================================
# Function: arr_api_call
# Description: Make an API call to an ARR service (Prowlarr/Sonarr/Radarr/etc)
#
# Arguments:
#   $1 - Service URL (e.g., http://localhost:8989)
#   $2 - API key
#   $3 - HTTP method (GET, POST, PUT, DELETE)
#   $4 - API endpoint (e.g., /api/v3/rootfolder)
#   $5 - JSON data (optional, for POST/PUT)
#
# Returns:
#   0 - Success (response contains "id" or is valid JSON)
#   1 - Failed
#
# Outputs:
#   Response body on stdout
#
# Example:
#   arr_api_call "$SONARR_URL" "$api_key" POST "/api/v3/rootfolder" "$json"
#=============================================================================
arr_api_call() {
    local url=$1
    local api_key=$2
    local method=$3
    local endpoint=$4
    local data=${5:-}

    local -a curl_args=(
        -s
        -X "$method"
        "${url}${endpoint}"
        -H "X-Api-Key: $api_key"
        -H "Content-Type: application/json"
    )

    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi

    curl "${curl_args[@]}"
}

#=============================================================================
# Function: arr_api_post
# Description: Convenience wrapper for POST requests to ARR services
#
# Arguments:
#   $1 - Service URL
#   $2 - API key
#   $3 - API endpoint
#   $4 - JSON data
#
# Returns:
#   0 - Success (response contains "id")
#   1 - Failed
#
# Example:
#   if arr_api_post "$url" "$key" "/api/v3/downloadclient" "$json"; then
#       log_success "Added client"
#   fi
#=============================================================================
arr_api_post() {
    local response
    response=$(arr_api_call "$1" "$2" POST "$3" "$4")

    if echo "$response" | grep -q '"id"'; then
        echo "$response"
        return 0
    else
        echo "$response" >&2
        return 1
    fi
}

#=============================================================================
# Function: arr_api_get
# Description: Convenience wrapper for GET requests to ARR services
#
# Arguments:
#   $1 - Service URL
#   $2 - API key
#   $3 - API endpoint
#
# Returns:
#   0 - Success
#   1 - Failed
#
# Example:
#   arr_api_get "$url" "$key" "/api/v3/system/status"
#=============================================================================
arr_api_get() {
    arr_api_call "$1" "$2" GET "$3"
}

##############################################################################
#                          SABNZBD API FUNCTIONS                             #
##############################################################################

#=============================================================================
# Function: sab_api_call
# Description: Make an API call to SABnzbd
#
# SABnzbd uses form-encoded data with apikey as a parameter.
#
# Arguments:
#   $1 - SABnzbd URL (e.g., http://localhost:8080)
#   $2 - API key
#   $3 - Additional form data (key=value&key=value format)
#
# Returns:
#   0 - Success (response contains "ok")
#   1 - Failed
#
# Outputs:
#   Response body on stdout
#
# Example:
#   sab_api_call "$url" "$key" "mode=addserver&name=provider"
#=============================================================================
sab_api_call() {
    local url=$1
    local api_key=$2
    local data=$3

    curl -s -X POST "${url}/api" \
        -d "apikey=$api_key" \
        -d "$data"
}

#=============================================================================
# Function: sab_api_post
# Description: Convenience wrapper for SABnzbd API with success check
#
# Arguments:
#   $1 - SABnzbd URL
#   $2 - API key
#   $3 - Form data
#
# Returns:
#   0 - Success (response contains "ok")
#   1 - Failed
#
# Example:
#   if sab_api_post "$url" "$key" "mode=set_cat&name=tv"; then
#       log_success "Created category"
#   fi
#=============================================================================
sab_api_post() {
    local response
    response=$(sab_api_call "$1" "$2" "$3")

    if echo "$response" | grep -q "ok"; then
        echo "$response"
        return 0
    else
        echo "$response" >&2
        return 1
    fi
}

##############################################################################
#                         HEALTH CHECK FUNCTIONS                             #
##############################################################################

#=============================================================================
# Function: arr_health_check
# Description: Check if an ARR service is responding
#
# Arguments:
#   $1 - Service URL
#   $2 - API key
#
# Returns:
#   0 - Service is healthy
#   1 - Service is not responding
#
# Example:
#   if arr_health_check "$SONARR_URL" "$api_key"; then
#       log_success "Sonarr is healthy"
#   fi
#=============================================================================
arr_health_check() {
    local url=$1
    local api_key=$2

    local response
    response=$(arr_api_get "$url" "$api_key" "/api/v3/system/status" 2>/dev/null)

    if echo "$response" | grep -q '"version"'; then
        return 0
    else
        return 1
    fi
}

#=============================================================================
# Function: sab_health_check
# Description: Check if SABnzbd is responding
#
# Arguments:
#   $1 - SABnzbd URL
#   $2 - API key
#
# Returns:
#   0 - Service is healthy
#   1 - Service is not responding
#
# Example:
#   if sab_health_check "$SAB_URL" "$api_key"; then
#       log_success "SABnzbd is healthy"
#   fi
#=============================================================================
sab_health_check() {
    local url=$1
    local api_key=$2

    local response
    response=$(sab_api_call "$url" "$api_key" "mode=version" 2>/dev/null)

    if echo "$response" | grep -qE '[0-9]+\.[0-9]+'; then
        return 0
    else
        return 1
    fi
}
