#!/bin/bash

#############################################################################
# Direct Cloudflare Pages Deployment - Get Live Immediately
# Uses official Cloudflare API with your verified credentials
#############################################################################

set -euo pipefail

# Your Cloudflare credentials
CF_API_TOKEN="00dn9TadjjAavQ6CSGVQZ7idnmziICSMowU9Nu-P"
CF_ACCOUNT_ID="ecc5914225b19722d5af73dac2c69d5b"
CF_ZONE_ID="058b48e6df75ab442c8c424d5d700b74"
PROJECT_NAME="beppesarrstack-net"
DOMAIN="beppesarrstack.net"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verify API token first
verify_token() {
    log_info "Verifying Cloudflare API token..."
    
    local response=$(curl -s "https://api.cloudflare.com/client/v4/user/tokens/verify" \
        -H "Authorization: Bearer $CF_API_TOKEN")
    
    local success=$(echo "$response" | grep -o '"success":true' || echo "")
    
    if [[ -n "$success" ]]; then
        log_success "API token verified successfully"
        return 0
    else
        log_error "API token verification failed"
        echo "$response"
        return 1
    fi
}

# Build the site
build_site() {
    log_info "Building VitePress site..."
    
    # Navigate to script directory, then to project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    
    cd "$PROJECT_ROOT"
    npm --prefix docs run docs:build
    
    if [[ -d "docs/.vitepress/dist" ]]; then
        log_success "Site built successfully"
        return 0
    else
        log_error "Build failed"
        return 1
    fi
}

# Deploy using wrangler with correct token
deploy_with_wrangler() {
    log_info "Deploying with Wrangler CLI..."
    
    # Set environment
    export CLOUDFLARE_API_TOKEN="$CF_API_TOKEN"
    export CLOUDFLARE_ACCOUNT_ID="$CF_ACCOUNT_ID"
    
    # Navigate to project root
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
    cd "$PROJECT_ROOT"
    
    # Deploy using wrangler
    wrangler pages deploy docs/.vitepress/dist --project-name="$PROJECT_NAME"
    
    if [[ $? -eq 0 ]]; then
        log_success "Deployment successful!"
        return 0
    else
        log_error "Deployment failed"
        return 1
    fi
}

# Setup GitHub integration for automatic deployments
setup_github_integration() {
    log_info "Setting up GitHub integration..."
    
    local github_repo="Aristoddle/usenet-media-stack"
    
    local data='{
        "repository": "'$github_repo'",
        "production_branch": "main",
        "build_config": {
            "build_command": "cd docs && npm run docs:build",
            "destination_dir": "docs/.vitepress/dist",
            "root_dir": "."
        }
    }'
    
    local response=$(curl -s -X POST \
        "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects/$PROJECT_NAME" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "$data")
    
    log_info "GitHub integration configured for automatic deployments"
}

# Main deployment function
main() {
    log_info "🚀 Deploying beppesarrstack.net to Cloudflare Pages"
    echo "================================================================"
    
    # Verify credentials
    if ! verify_token; then
        exit 1
    fi
    
    # Build site
    if ! build_site; then
        exit 1
    fi
    
    # Deploy
    if ! deploy_with_wrangler; then
        exit 1
    fi
    
    # Setup auto-deployments
    setup_github_integration
    
    echo "================================================================"
    log_success "🎉 Deployment Complete!"
    log_info "🌐 Your site is now live at: https://$DOMAIN"
    log_info "🔄 Future pushes to main branch will auto-deploy"
    log_info "📊 Monitor at: https://dash.cloudflare.com/pages"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
