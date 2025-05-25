#!/bin/bash

#############################################################################
# Automated Deployment Script for beppesarrstack.net
# Deploys VitePress site to Cloudflare Pages with proper CI/CD
#############################################################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="beppesarrstack-net"
BUILD_DIR="docs/.vitepress/dist"
DOCS_DIR="docs"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    # Check if wrangler is installed, install if not
    if ! command -v wrangler &> /dev/null; then
        log_info "Installing Wrangler CLI..."
        npm install -g wrangler
    fi
    
    log_success "Dependencies checked"
}

load_environment() {
    log_info "Loading environment variables..."
    
    if [[ -f .env ]]; then
        export $(grep -v '^#' .env | xargs)
        log_success "Environment loaded from .env"
    else
        log_warning "No .env file found, using system environment"
    fi
    
    # Check required variables
    if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
        log_error "CLOUDFLARE_API_TOKEN not set"
        exit 1
    fi
    
    if [[ -z "${CLOUDFLARE_EMAIL:-}" ]]; then
        log_error "CLOUDFLARE_EMAIL not set"
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing project dependencies..."
    
    cd "$DOCS_DIR"
    
    if [[ -f package-lock.json ]]; then
        npm ci
    else
        npm install
    fi
    
    cd ..
    log_success "Dependencies installed"
}

build_site() {
    log_info "Building VitePress site..."
    
    cd "$DOCS_DIR"
    npm run docs:build
    cd ..
    
    if [[ -d "$BUILD_DIR" ]]; then
        log_success "Site built successfully"
        log_info "Build directory: $BUILD_DIR"
        log_info "Build size: $(du -sh "$BUILD_DIR" | cut -f1)"
    else
        log_error "Build failed - output directory not found"
        exit 1
    fi
}

deploy_to_cloudflare() {
    log_info "Deploying to Cloudflare Pages..."
    
    # Authenticate with Cloudflare
    export CLOUDFLARE_API_TOKEN
    
    # Deploy using wrangler
    wrangler pages deploy "$BUILD_DIR" \
        --project-name="$PROJECT_NAME" \
        --compatibility-date="2024-05-01"
    
    log_success "Deployment completed!"
    log_info "🚀 Site should be live at: https://beppesarrstack.net"
    log_info "⏱️  DNS propagation may take a few minutes"
}

cleanup() {
    log_info "Cleaning up build artifacts..."
    # Keep the build for debugging, but could remove if needed
    # rm -rf "$BUILD_DIR"
    log_success "Cleanup completed"
}

main() {
    log_info "🚀 Starting deployment process for beppesarrstack.net"
    echo "========================================================"
    
    check_dependencies
    load_environment
    install_dependencies
    build_site
    deploy_to_cloudflare
    cleanup
    
    echo "========================================================"
    log_success "🎉 Deployment completed successfully!"
    log_info "📊 Check deployment status at: https://dash.cloudflare.com"
    log_info "🌐 Visit your site at: https://beppesarrstack.net"
}

# Run if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi