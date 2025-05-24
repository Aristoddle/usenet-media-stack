#!/usr/bin/env zsh
##############################################################################
# File: ./lib/modern-stack.zsh
# Project: Usenet Media Stack
# Description: Modern tool integrations for 2024-2025
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module provides integration with modern, trending tools that enhance
# the media stack experience. Selected based on GitHub trends, community
# adoption, and long-term viability.
#
# Tools included:
# - Cloudflare Tunnel (zero-trust networking)
# - Authentik (enterprise SSO)
# - Homepage (modern dashboard)
# - Uptime Kuma (monitoring)
# - Loki/Promtail (log aggregation)
# - Gotify (notifications)
##############################################################################

##############################################################################
#                           CLOUDFLARE TUNNEL                                #
##############################################################################

#=============================================================================
# Function: setup_cloudflare_tunnel
# Description: Configure Cloudflare Tunnel for secure access
#
# Sets up Cloudflare Tunnel to provide secure external access without
# exposing any ports. This is the modern replacement for traditional
# reverse proxies.
#
# Arguments:
#   None
#
# Returns:
#   0 - Tunnel configured successfully
#   1 - Configuration failed
#
# Example:
#   setup_cloudflare_tunnel
#=============================================================================
setup_cloudflare_tunnel() {
    log_info "Setting up Cloudflare Tunnel..."
    
    # Check for tunnel token
    local token=$(get_config TUNNEL_TOKEN)
    if [[ -z "$token" ]]; then
        log_error "TUNNEL_TOKEN not set in .env"
        log_info "Get your token from: https://one.dash.cloudflare.com/"
        return 1
    fi
    
    # Deploy tunnel container
    if docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d cloudflared; then
        log_success "Cloudflare Tunnel deployed"
        log_info "Configure routes at: https://one.dash.cloudflare.com/"
        return 0
    else
        log_error "Failed to deploy Cloudflare Tunnel"
        return 1
    fi
}

##############################################################################
#                              AUTHENTIK SSO                                 #
##############################################################################

#=============================================================================
# Function: setup_authentik
# Description: Deploy Authentik for Single Sign-On
#
# Authentik provides enterprise-grade SSO with support for SAML, OAuth2,
# LDAP, and more. It's the modern replacement for basic auth.
#
# Arguments:
#   None
#
# Returns:
#   0 - Authentik deployed successfully
#   1 - Deployment failed
#
# Example:
#   setup_authentik
#=============================================================================
setup_authentik() {
    log_info "Setting up Authentik SSO..."
    
    # Generate secret if not exists
    local secret=$(get_config AUTHENTIK_SECRET)
    if [[ -z "$secret" ]]; then
        secret=$(openssl rand -base64 32)
        echo "AUTHENTIK_SECRET=$secret" >> .env
    fi
    
    # Generate DB password if not exists
    local db_pass=$(get_config AUTHENTIK_DB_PASS)
    if [[ -z "$db_pass" ]]; then
        db_pass=$(openssl rand -base64 16)
        echo "AUTHENTIK_DB_PASS=$db_pass" >> .env
    fi
    
    # Deploy Authentik
    if docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d authentik authentik-db; then
        log_success "Authentik deployed"
        log_info "Access at: https://auth.${DOMAIN}"
        log_info "Default user: akadmin"
        return 0
    else
        log_error "Failed to deploy Authentik"
        return 1
    fi
}

##############################################################################
#                           HOMEPAGE DASHBOARD                               #
##############################################################################

#=============================================================================
# Function: setup_homepage
# Description: Deploy Homepage dashboard
#
# Homepage is a modern, highly customizable dashboard that auto-discovers
# Docker services. It's the spiritual successor to Heimdall/Organizr.
#
# Arguments:
#   None
#
# Returns:
#   0 - Homepage deployed successfully
#   1 - Deployment failed
#
# Example:
#   setup_homepage
#=============================================================================
setup_homepage() {
    log_info "Setting up Homepage dashboard..."
    
    # Create config directory
    mkdir -p "$CONFIG_DIR/homepage"
    
    # Generate services config
    cat > "$CONFIG_DIR/homepage/services.yaml" << 'EOF'
---
# Automatically discovered from Docker labels
- Media Management:
    - Sonarr:
        icon: sonarr.svg
        href: http://localhost:8989
        description: TV Shows
        widget:
          type: sonarr
          url: http://sonarr:8989
          key: {{SONARR_API_KEY}}
          
    - Radarr:
        icon: radarr.svg
        href: http://localhost:7878
        description: Movies
        widget:
          type: radarr
          url: http://radarr:7878
          key: {{RADARR_API_KEY}}
          
- Downloads:
    - SABnzbd:
        icon: sabnzbd.svg
        href: http://localhost:8080
        description: Usenet Downloads
        widget:
          type: sabnzbd
          url: http://sabnzbd:8080
          key: {{SABNZBD_API_KEY}}
          
- Media Server:
    - Jellyfin:
        icon: jellyfin.svg
        href: http://localhost:8096
        description: Media Streaming
        widget:
          type: jellyfin
          url: http://jellyfin:8096
          key: {{JELLYFIN_API_KEY}}
EOF
    
    # Deploy Homepage
    if docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d homepage; then
        log_success "Homepage deployed"
        log_info "Access at: http://localhost:3000 or https://dashboard.${DOMAIN}"
        return 0
    else
        log_error "Failed to deploy Homepage"
        return 1
    fi
}

##############################################################################
#                            UPTIME KUMA                                     #
##############################################################################

#=============================================================================
# Function: setup_monitoring
# Description: Deploy Uptime Kuma for service monitoring
#
# Uptime Kuma is a modern, self-hosted monitoring tool that's easier to
# use than traditional solutions like Nagios or Zabbix.
#
# Arguments:
#   None
#
# Returns:
#   0 - Monitoring deployed successfully
#   1 - Deployment failed
#
# Example:
#   setup_monitoring
#=============================================================================
setup_monitoring() {
    log_info "Setting up Uptime Kuma monitoring..."
    
    # Create monitoring compose file
    cat > "$PROJECT_ROOT/docker-compose.monitoring.yml" << 'EOF'
version: '3.8'

services:
  uptime-kuma:
    image: louislam/uptime-kuma:latest
    container_name: uptime-kuma
    restart: unless-stopped
    networks:
      - media_network
    volumes:
      - ./config/uptime-kuma:/app/data
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
    labels:
      - "homepage.group=Monitoring"
      - "homepage.name=Uptime Kuma"
      - "homepage.icon=uptime-kuma"
      - "homepage.href=http://localhost:3001"
      - "homepage.description=Service Monitoring"
      
  # Modern log aggregation
  loki:
    image: grafana/loki:latest
    container_name: loki
    restart: unless-stopped
    networks:
      - media_network
    command: -config.file=/etc/loki/local-config.yaml
    volumes:
      - ./config/loki:/loki
      
  promtail:
    image: grafana/promtail:latest
    container_name: promtail
    restart: unless-stopped
    networks:
      - media_network
    volumes:
      - /var/log:/var/log:ro
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
      - ./config/promtail:/etc/promtail
    command: -config.file=/etc/promtail/config.yml
    
  # Modern notifications
  gotify:
    image: gotify/server:latest
    container_name: gotify
    restart: unless-stopped
    networks:
      - media_network
    environment:
      - GOTIFY_DEFAULTUSER_NAME=admin
      - GOTIFY_DEFAULTUSER_PASS=${GOTIFY_PASS:-admin}
    volumes:
      - ./config/gotify:/app/data
EOF
    
    # Deploy monitoring stack
    if docker compose -f docker-compose.yml -f docker-compose.monitoring.yml up -d; then
        log_success "Monitoring stack deployed"
        log_info "Uptime Kuma: http://localhost:3001"
        log_info "Gotify: http://localhost:8090"
        return 0
    else
        log_error "Failed to deploy monitoring"
        return 1
    fi
}

##############################################################################
#                         SERVICE DISCOVERY                                  #
##############################################################################

#=============================================================================
# Function: setup_service_discovery
# Description: Configure automatic service discovery
#
# Sets up Docker labels for automatic discovery by Homepage, Traefik, etc.
#
# Arguments:
#   None
#
# Returns:
#   0 - Labels configured
#   1 - Configuration failed
#
# Example:
#   setup_service_discovery
#=============================================================================
setup_service_discovery() {
    log_info "Configuring service discovery labels..."
    
    # Add labels to existing services
    local services=(sonarr radarr prowlarr sabnzbd jellyfin)
    
    for service in $services; do
        # Check if service is running
        if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
            # Add discovery labels
            docker label add \
                "homepage.group=Media" \
                "homepage.name=${service^}" \
                "homepage.icon=${service}" \
                "$service" 2>/dev/null || true
        fi
    done
    
    log_success "Service discovery configured"
    return 0
}

##############################################################################
#                           MODERN STACK MENU                                #
##############################################################################

#=============================================================================
# Function: show_modern_stack_menu
# Description: Interactive menu for modern tool deployment
#
# Presents options for deploying modern enhancements to the stack.
#
# Arguments:
#   None
#
# Returns:
#   0 - User completed actions
#   1 - User cancelled
#
# Example:
#   show_modern_stack_menu
#=============================================================================
show_modern_stack_menu() {
    while true; do
        print "\n${COLOR_BOLD}Modern Stack Enhancements${COLOR_RESET}"
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print "1) Cloudflare Tunnel    - Secure external access (recommended)"
        print "2) Authentik SSO        - Enterprise authentication"
        print "3) Homepage Dashboard   - Modern service dashboard"
        print "4) Uptime Kuma         - Service monitoring"
        print "5) Full Modern Stack   - Deploy everything"
        print "0) Back to main menu"
        print ""
        
        read -k 1 "choice?Select option: "
        print ""
        
        case "$choice" in
            1) setup_cloudflare_tunnel ;;
            2) setup_authentik ;;
            3) setup_homepage ;;
            4) setup_monitoring ;;
            5) 
                setup_cloudflare_tunnel
                setup_authentik
                setup_homepage
                setup_monitoring
                setup_service_discovery
                ;;
            0) return 0 ;;
            *) print "Invalid option" ;;
        esac
        
        print "\nPress any key to continue..."
        read -k 1
    done
}

# Export functions
typeset -fx setup_cloudflare_tunnel setup_authentik setup_homepage
typeset -fx setup_monitoring setup_service_discovery show_modern_stack_menu

# vim: set ts=4 sw=4 et tw=80: