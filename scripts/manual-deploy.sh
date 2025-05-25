#!/bin/bash

#############################################################################
# Manual Deployment Script for beppesarrstack.net
# Builds and provides instructions for manual Cloudflare Pages deployment
#############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 Building beppesarrstack.net for deployment${NC}"
echo "================================================="

# Navigate to docs directory and build
echo -e "${BLUE}📦 Building VitePress site...${NC}"
cd docs
npm run docs:build

# Check if build succeeded
if [[ -d ".vitepress/dist" ]]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    
    # Display build info
    BUILD_SIZE=$(du -sh .vitepress/dist | cut -f1)
    FILE_COUNT=$(find .vitepress/dist -type f | wc -l)
    
    echo -e "${BLUE}📊 Build Statistics:${NC}"
    echo "   Size: $BUILD_SIZE"
    echo "   Files: $FILE_COUNT"
    echo "   Location: $(pwd)/.vitepress/dist"
    
    echo ""
    echo -e "${YELLOW}🌐 DEPLOYMENT OPTIONS:${NC}"
    echo ""
    echo "OPTION 1: Cloudflare Pages Dashboard (Recommended)"
    echo "1. Go to https://dash.cloudflare.com/pages"
    echo "2. Click 'Create a project'"
    echo "3. Choose 'Upload assets'"
    echo "4. Drag and drop the entire contents of: $(pwd)/.vitepress/dist"
    echo "5. Set project name: beppesarrstack-net"
    echo "6. Set custom domain: beppesarrstack.net"
    echo ""
    echo "OPTION 2: GitHub Actions (Automated)"
    echo "1. Add CLOUDFLARE_API_TOKEN to GitHub Secrets"
    echo "2. Push changes to main branch"
    echo "3. GitHub Actions will auto-deploy"
    echo ""
    echo "OPTION 3: Wrangler CLI (Advanced)"
    echo "1. Create enhanced API token with Pages permissions"
    echo "2. Run: wrangler pages deploy .vitepress/dist --project-name=beppesarrstack-net"
    echo ""
    echo -e "${GREEN}🎉 Ready for deployment!${NC}"
    echo -e "${BLUE}📝 Next: Choose one of the options above to deploy${NC}"
    
else
    echo -e "${RED}❌ Build failed - .vitepress/dist directory not found${NC}"
    exit 1
fi