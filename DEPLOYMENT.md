# 🚀 Deployment Guide for beppesarrstack.net

## 🎯 Quick Deploy Options

### Option 1: Automated GitHub Actions (Recommended)

**Setup once, deploy automatically on every push!**

1. **Add GitHub Secrets:**
   - Go to: https://github.com/Aristoddle/usenet-media-stack/settings/secrets/actions
   - Click "New repository secret"
   - Add: `CLOUDFLARE_API_TOKEN` = `00dn9TadjjAavQ6CSGVQZ7idnmziICSMowU9Nu-P`

2. **Push to Deploy:**
   ```bash
   git push origin main
   ```
   - GitHub Actions will automatically build and deploy
   - Check progress: https://github.com/Aristoddle/usenet-media-stack/actions

### Option 2: Manual Cloudflare Dashboard

**For immediate deployment or troubleshooting:**

1. **Build the site:**
   ```bash
   ./scripts/manual-deploy.sh
   ```

2. **Upload to Cloudflare:**
   - Go to: https://dash.cloudflare.com/pages
   - Click "Create a project" → "Upload assets"
   - Drag entire contents of: `docs/.vitepress/dist/`
   - Set project name: `beppesarrstack-net`
   - Set custom domain: `beppesarrstack.net`

### Option 3: Enhanced Wrangler CLI

**For developers who want CLI control:**

1. **Create enhanced API token:**
   - Go to: https://dash.cloudflare.com/profile/api-tokens
   - Create token with permissions:
     - Zone:Zone Settings:Edit
     - Zone:Zone:Read  
     - Account:Cloudflare Pages:Edit

2. **Deploy via CLI:**
   ```bash
   export CLOUDFLARE_API_TOKEN="your_enhanced_token"
   wrangler pages deploy docs/.vitepress/dist --project-name=beppesarrstack-net
   ```

## 🔧 CI/CD Configuration

### GitHub Actions Workflow
- **File:** `.github/workflows/deploy.yml`
- **Triggers:** Push to main branch, Pull requests
- **Steps:** Install deps → Build VitePress → Deploy to Cloudflare Pages

### Cloudflare Configuration
- **Headers:** Security headers, CSP, caching policies (`_headers`)
- **Redirects:** SPA routing, HTTPS enforcement (`_redirects`)
- **Project:** Production and dev environments (`wrangler.toml`)

## 📊 Build Information

- **Framework:** VitePress (Vue 3 + Vite)
- **Build Size:** ~67KB (optimized)
- **Build Time:** ~4 seconds
- **Files:** 50 static assets
- **Output:** `docs/.vitepress/dist/`

## 🌐 Live URLs

- **Production:** https://beppesarrstack.net
- **Cloudflare Dashboard:** https://dash.cloudflare.com/pages
- **GitHub Actions:** https://github.com/Aristoddle/usenet-media-stack/actions

## 🔍 Troubleshooting

### Build Issues
```bash
# Clear cache and rebuild
rm -rf docs/.vitepress/cache docs/.vitepress/dist
npm --prefix docs run docs:build
```

### Deployment Issues
```bash
# Check GitHub Actions logs
# https://github.com/Aristoddle/usenet-media-stack/actions

# Check Cloudflare Pages logs
# https://dash.cloudflare.com/pages
```

### DNS Issues
- DNS propagation can take 5-10 minutes
- Check: https://www.whatsmydns.net/#A/beppesarrstack.net
- Cloudflare DNS: 1.1.1.1, 1.0.0.1

## ⚡ Pro Tips

1. **Fastest Deploy:** Push to GitHub (automated)
2. **Instant Deploy:** Use Cloudflare dashboard upload
3. **Development:** Use `npm run docs:dev` for local preview
4. **Testing:** Use `npm run docs:preview` after build

---

*Built with ❤️ using VitePress, deployed on Cloudflare Pages*