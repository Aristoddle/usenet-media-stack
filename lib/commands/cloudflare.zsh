#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/cloudflare.zsh
# Project: Usenet Media Stack
# Description: Cloudflare tunnel management for beppesarrstack.net
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Manages Cloudflare tunnel setup and DNS records for secure external access
# to the Usenet Media Stack at beppesarrstack.net
##############################################################################

# Load core functions
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"  # Go up two levels from lib/commands to root
source "${SCRIPT_DIR:h}/core/common.zsh"
source "${SCRIPT_DIR:h}/core/init.zsh"

# Ensure config is loaded
load_stack_config || die 1 "Failed to load configuration"


##############################################################################
#                         CLOUDFLARE API FUNCTIONS                           #
##############################################################################

#=============================================================================
# Function: cf_api_call
# Description: Make authenticated Cloudflare API call
#
# Arguments:
#   $1 - HTTP method (GET, POST, PUT, DELETE)
#   $2 - API endpoint
#   $3 - JSON data (optional)
#
# Returns:
#   0 - API call successful
#   1 - API call failed
#
# Example:
#   cf_api_call GET "zones" | jq '.result'
#=============================================================================
cf_api_call() {
    local method=$1
    local endpoint=$2
    local data="${3:-}"
    
    local url="https://api.cloudflare.com/client/v4/$endpoint"
    local headers=(
        "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
        "Content-Type: application/json"
    )
    
    if [[ -n "$data" ]]; then
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "$url" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN"
    fi
}

#=============================================================================
# Function: get_zone_id
# Description: Get Cloudflare zone ID for domain
#
# Arguments:
#   None (uses $DOMAIN from config)
#
# Returns:
#   0 - Zone ID found (prints ID)
#   1 - Zone not found
#
# Example:
#   local zone_id=$(get_zone_id)
#=============================================================================
get_zone_id() {
    local response=$(cf_api_call GET "zones?name=$DOMAIN")
    local zone_id=$(echo "$response" | jq -r '.result[0].id // empty')
    
    if [[ -n "$zone_id" && "$zone_id" != "null" ]]; then
        print "$zone_id"
        return 0
    else
        return 1
    fi
}

##############################################################################
#                           TUNNEL MANAGEMENT                                #
##############################################################################

#=============================================================================
# Function: create_tunnel
# Description: Create Cloudflare tunnel for the domain
#
# Arguments:
#   None
#
# Returns:
#   0 - Tunnel created successfully
#   1 - Tunnel creation failed
#
# Example:
#   create_tunnel
#=============================================================================
create_tunnel() {
    info "Creating Cloudflare tunnel for $DOMAIN..."
    
    local tunnel_name="usenet-media-stack"
    local tunnel_data=$(cat <<EOF
{
  "name": "$tunnel_name",
  "tunnel_secret": "$(openssl rand -base64 32)"
}
EOF
)
    
    local response=$(cf_api_call POST "accounts/$(get_account_id)/cfd_tunnel" "$tunnel_data")
    local tunnel_id=$(echo "$response" | jq -r '.result.id // empty')
    
    if [[ -n "$tunnel_id" && "$tunnel_id" != "null" ]]; then
        success "Tunnel created: $tunnel_id"
        
        # Save tunnel ID to .env
        echo "TUNNEL_ID=$tunnel_id" >> .env
        
        return 0
    else
        error "Failed to create tunnel"
        print "Response: $response"
        return 1
    fi
}

#=============================================================================
# Function: setup_dns_records
# Description: Create DNS records for all services
#
# Arguments:
#   None
#
# Returns:
#   0 - DNS records created
#   1 - DNS setup failed
#
# Example:
#   setup_dns_records
#=============================================================================
setup_dns_records() {
    info "Setting up DNS records for $DOMAIN..."
    
    local zone_id=$(get_zone_id)
    if [[ -z "$zone_id" ]]; then
        error "Could not find zone for $DOMAIN"
        return 1
    fi
    
    # Service subdomain mappings
    local -A service_subdomains=(
        [sonarr]="tv"
        [radarr]="movies"
        [prowlarr]="indexers"
        [sabnzbd]="downloads"
        [jellyfin]="watch"
        [overseerr]="requests"
        [lidarr]="music"
        [bazarr]="subtitles"
        [mylar3]="comics"
    )
    
    # Create CNAME records
    for service subdomain in ${(kv)service_subdomains}; do
        local record_data=$(cat <<EOF
{
  "type": "CNAME",
  "name": "$subdomain",
  "content": "$DOMAIN",
  "ttl": 1,
  "proxied": true
}
EOF
)
        
        local response=$(cf_api_call POST "zones/$zone_id/dns_records" "$record_data")
        local record_id=$(echo "$response" | jq -r '.result.id // empty')
        
        if [[ -n "$record_id" && "$record_id" != "null" ]]; then
            success "Created DNS record: $subdomain.$DOMAIN → $service"
        else
            log_warning "Failed to create DNS record for $subdomain"
        fi
    done
}

##############################################################################
#                         CONFIGURATION GENERATION                           #
##############################################################################

#=============================================================================
# Function: generate_tunnel_config
# Description: Generate cloudflared configuration
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration generated
#   1 - Generation failed
#
# Example:
#   generate_tunnel_config
#=============================================================================
generate_tunnel_config() {
    info "Generating tunnel configuration..."
    
    mkdir -p "$CONFIG_DIR/cloudflared"
    
    cat > "$CONFIG_DIR/cloudflared/config.yml" << EOF
# Cloudflare Tunnel Configuration for $DOMAIN
# Generated: $(date)

tunnel: \${TUNNEL_ID}
credentials-file: /etc/cloudflared/credentials.json

ingress:
  # TV Shows
  - hostname: tv.$DOMAIN
    service: ${SERVICE_URLS[sonarr]}
    
  # Movies  
  - hostname: movies.$DOMAIN
    service: ${SERVICE_URLS[radarr]}
    
  # Downloads
  - hostname: downloads.$DOMAIN
    service: ${SERVICE_URLS[sabnzbd]}
    
  # Indexers
  - hostname: indexers.$DOMAIN
    service: ${SERVICE_URLS[prowlarr]}
    
  # Media Streaming
  - hostname: watch.$DOMAIN
    service: ${SERVICE_URLS[jellyfin]}
    
  # Requests
  - hostname: requests.$DOMAIN
    service: ${SERVICE_URLS[overseerr]}
    
  # Music
  - hostname: music.$DOMAIN
    service: ${SERVICE_URLS[lidarr]}
    
  # Subtitles
  - hostname: subtitles.$DOMAIN
    service: ${SERVICE_URLS[bazarr]}
    
  # Comics
  - hostname: comics.$DOMAIN
    service: ${SERVICE_URLS[mylar3]}
    
  # Catch-all
  - service: http_status:404
EOF
    
    success "Tunnel configuration generated: $CONFIG_DIR/cloudflared/config.yml"
}

##############################################################################
#                             MAIN COMMANDS                                  #
##############################################################################

#=============================================================================
# Function: setup_full_tunnel
# Description: Complete tunnel setup process
#
# Arguments:
#   None
#
# Returns:
#   0 - Setup completed
#   1 - Setup failed
#
# Example:
#   setup_full_tunnel
#=============================================================================
setup_full_tunnel() {
    info "Setting up complete Cloudflare tunnel for $DOMAIN"
    
    # Check API token
    if [[ -z "$CLOUDFLARE_API_TOKEN" ]]; then
        error "CLOUDFLARE_API_TOKEN not set in .env"
        return 1
    fi
    
    # Verify domain access
    local zone_id=$(get_zone_id)
    if [[ -z "$zone_id" ]]; then
        error "Cannot access zone for $DOMAIN"
        info "Verify API token has zone permissions"
        return 1
    fi
    
    success "Verified access to $DOMAIN (Zone: $zone_id)"
    
    # Setup DNS records
    setup_dns_records || return 1
    
    # Generate tunnel config
    generate_tunnel_config || return 1
    
    success "Cloudflare tunnel setup complete!"
    info "Your services will be available at:"
    info "  TV Shows: https://tv.$DOMAIN"
    info "  Movies: https://movies.$DOMAIN"
    info "  Downloads: https://downloads.$DOMAIN"
    info "  Watch: https://watch.$DOMAIN"
    
    return 0
}

##############################################################################
#                              HELPERS                                       #
##############################################################################

get_account_id() {
    cf_api_call GET "accounts" | jq -r '.result[0].id // empty'
}

show_cloudflare_help() {
    cat <<'HELP'
CLOUDFLARE COMMAND

Usage: usenet cloudflare <action>

Manage Cloudflare tunnel for beppesarrstack.net

ACTIONS
    setup              Complete tunnel and DNS setup
    dns                Setup DNS records only
    config             Generate tunnel configuration
    test               Test API connectivity

EXAMPLES
    Complete setup:
        $ usenet cloudflare setup
        
    Test API access:
        $ usenet cloudflare test

HELP
}

##############################################################################
#                               MAIN                                         #
##############################################################################

main() {
    local action="${1:-help}"
    
    case "$action" in
        setup)
            setup_full_tunnel
            ;;
        dns)
            setup_dns_records
            ;;
        config)
            generate_tunnel_config
            ;;
        test)
            local zone_id=$(get_zone_id)
            if [[ -n "$zone_id" ]]; then
                success "API access verified for $DOMAIN"
                print "Zone ID: $zone_id"
            else
                error "Cannot access $DOMAIN zone"
            fi
            ;;
        help|--help|-h)
            show_cloudflare_help
            ;;
        *)
            error "Unknown action: $action"
            show_cloudflare_help
            return 1
            ;;
    esac
}

# Run if called directly (zsh compatible)
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80:
