# Complete Usenet Stack Setup Guide

## Overview
This guide will help you set up your complete Usenet automation stack with all the credentials we've extracted from 1Password.

## Current Credentials Status

### ✅ Ready to Use (API Keys Available)
- **NZBgeek**: API Key `SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a`
- **NZB Finder**: API Key `14b3d53dbd98adc79fed0d336998536a`
- **NZB.su**: API Key `25ba450623c248e2b58a3c0dc54aa019`
- **NZBPlanet**: API Key `046863416d824143c79b6725982e293d`
- **SABnzbd**: API Key `0b544ecf089649f0ba8905d869a88f22`

### ⚠️ Need Manual API Key Retrieval
- **UsenetExpress**: Login required to get server details
- **Newshosting**: Login required to get server details
- **Frugalusenet**: Login required to get server details

## Step-by-Step Setup

### 1. Start the Stack
```bash
cd /home/joe/usenet
./manage.sh start
```

Wait for all services to initialize (about 30-60 seconds).

### 2. Retrieve Missing API Keys
Run the helper script to get instructions for missing API keys:
```bash
./update-api-keys.sh
```

For each provider without an API key:
1. Login to their control panel
2. Navigate to account/server settings
3. Copy the API key or server details
4. The script will update 1Password automatically

### 3. Configure SABnzbd
Access SABnzbd at http://localhost:8080

#### Add Usenet Providers:
1. **Newshosting** (Primary)
   - Server: `news.newshosting.com`
   - Port: `563` (SSL)
   - Username: `j3lanzone@gmail.com`
   - Password: `@Kirsten123`
   - Connections: `30`

2. **UsenetExpress** (Secondary)
   - Server: `usenetexpress.com`
   - Port: `563` (SSL)
   - Username: `une3226253`
   - Password: `kKqzQXPeN`
   - Connections: `20`

3. **Frugalusenet** (Backup)
   - Server: `newswest.frugalusenet.com`
   - Port: `563` (SSL)
   - Username: `aristoddle`
   - Password: `fishing123`
   - Connections: `10`
   - Backup Server: `bonus.frugalusenet.com`

#### Configure Categories:
- `tv` → `/downloads/tv`
- `movies` → `/downloads/movies`
- `books` → `/downloads/books`
- `comics` → `/downloads/comics`

### 4. Configure Prowlarr
Access Prowlarr at http://localhost:9696

Run the automated configuration:
```bash
./configure-prowlarr.sh
```

This will:
- Add all indexers with their API keys
- Show you how to connect apps
- Provide download client settings

### 5. Connect Apps to Prowlarr
In Prowlarr, go to Settings > Apps and add:

- **Sonarr** (TV Shows)
  - URL: `http://sonarr:8989`
  - Get API key from Sonarr Settings
  
- **Radarr** (Movies)
  - URL: `http://radarr:7878`
  - Get API key from Radarr Settings

- **Readarr** (Books)
  - URL: `http://readarr:8787`
  - Get API key from Readarr Settings

- **Mylar3** (Comics)
  - URL: `http://mylar3:8090`
  - Get API key from Mylar3 Settings

### 6. Configure Each *arr App
For each app (Sonarr, Radarr, etc.):

1. Add root folder:
   - Sonarr: `/tv`
   - Radarr: `/movies`
   - Readarr: `/books`
   - Mylar3: `/comics`

2. Add download client:
   - Host: `sabnzbd`
   - Port: `8080`
   - API Key: `0b544ecf089649f0ba8905d869a88f22`

3. Configure quality profiles as needed

### 7. Test the Setup
1. In Prowlarr, test each indexer connection
2. Search for something to verify results
3. In each *arr app, search for content
4. Monitor downloads in SABnzbd

## Quick Reference

### Service URLs
- **Prowlarr**: http://localhost:9696
- **Sonarr**: http://localhost:8989
- **Radarr**: http://localhost:7878
- **Readarr**: http://localhost:8787
- **Mylar3**: http://localhost:8090
- **SABnzbd**: http://localhost:8080
- **Bazarr**: http://localhost:6767

### API Keys
```bash
# View all credentials
cat /home/joe/usenet/usenet-credentials.txt

# Extract specific API key
/home/joe/usenet/op-helper.sh item get "NZBgeek" --fields "API Key"
```

### Management Commands
```bash
# Check service status
./manage.sh status

# View logs
./manage.sh logs [service-name]

# Restart a service
./manage.sh restart-service [service-name]

# Backup configurations
./manage.sh backup-configs
```

## Troubleshooting

### Services can't communicate
- Check Docker networks: `docker network ls`
- Ensure services use hostnames, not localhost
- Verify firewall rules aren't blocking

### Indexer connection fails
- Verify API key is correct
- Check if indexer requires specific categories
- Ensure your account is active

### Downloads not moving to media folders
- Check permissions on directories
- Verify category mappings in SABnzbd
- Ensure *arr apps have correct root folders

## Next Steps
1. Import existing media libraries
2. Set up quality profiles
3. Configure release profiles
4. Add notification services
5. Set up automated backups

## Scripts Created
- `/home/joe/usenet/op-helper.sh` - 1Password CLI wrapper
- `/home/joe/usenet/extract-usenet-creds.sh` - Extract all credentials
- `/home/joe/usenet/update-api-keys.sh` - Update missing API keys
- `/home/joe/usenet/configure-prowlarr.sh` - Automated Prowlarr setup
- `/home/joe/usenet/usenet-credentials.txt` - Full credential dump