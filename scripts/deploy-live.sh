#!/bin/bash

#############################################################################
# One-Command Deploy to Live beppesarrstack.net
# Your "set it and forget it" deployment solution
#############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploying to https://beppesarrstack.net${NC}"
echo "=============================================="

# Navigate to script directory, then project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Build site
echo -e "${BLUE}📦 Building VitePress site...${NC}"
npm --prefix docs run docs:build

# Deploy with wrangler
echo -e "${BLUE}🌐 Deploying to Cloudflare Pages...${NC}"
export CLOUDFLARE_API_TOKEN="00dn9TadjjAavQ6CSGVQZ7idnmziICSMowU9Nu-P"
wrangler pages deploy docs/.vitepress/dist --project-name=beppesarrstack-net --commit-dirty=true

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo -e "${BLUE}🌐 Your site is live at: https://beppesarrstack.net${NC}"
echo -e "${YELLOW}⏱️  DNS propagation may take 1-2 minutes for the custom domain${NC}"
echo ""
echo -e "${BLUE}📋 For automatic deployments on every git push:${NC}"
echo "1. Go to: https://github.com/Aristoddle/usenet-media-stack/settings/secrets/actions"
echo "2. Add secret: CLOUDFLARE_API_TOKEN = 00dn9TadjjAavQ6CSGVQZ7idnmziICSMowU9Nu-P"
echo "3. Push any change to main branch = automatic deployment!"