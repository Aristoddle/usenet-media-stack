# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive media automation stack using Docker Compose, designed for both single-device and multi-device deployments via Docker Swarm. The system manages media downloads, organization, and file sharing with 20+ integrated services.

## Common Commands

### Quick Start - One-Command Setup
```bash
# Complete automated setup (starts stack, configures all services)
./one-click-setup.sh
```

### Deployment and Management
```bash
# Service management
./manage.sh start                    # Deploy entire stack
./manage.sh stop                     # Stop all services
./manage.sh restart                  # Restart all services
./manage.sh status                   # Check service health
./manage.sh logs [service_name]      # View service logs
./manage.sh restart-service <name>   # Restart specific service
./manage.sh backup-configs          # Backup configurations
./manage.sh system-health           # Resource monitoring

# Automated configuration
./setup-all.sh --fresh              # Complete setup (configure + test)
./setup-all.sh --configure          # Configure all services
./setup-all.sh --test               # Test all connections
./setup-all.sh --health             # Health check all services
./setup-all.sh --update             # Update credentials from 1Password
./setup-all.sh --dry-run            # Preview what would be done
./setup-all.sh --verbose            # Detailed output

# Service readiness check
./wait-for-services.sh              # Wait for all services to be ready
```

### Docker Swarm Operations
```bash
./manage.sh init-swarm              # Initialize swarm manager
./manage.sh join-swarm <token> <ip> # Add worker node
./manage.sh label-nodes             # Configure node placement
./manage.sh update                  # Update all services
```

### Troubleshooting
```bash
# View logs for specific service
docker logs usenet_prowlarr_1 --tail 50 -f
docker logs usenet_sonarr_1 --tail 50 -f

# Access service shell
docker exec -it usenet_prowlarr_1 /bin/bash

# Check API keys
grep -oP '(?<=<ApiKey>)[^<]+' /home/joe/usenet/config/prowlarr/config.xml
grep -oP '(?<=api_key = )[^\s]+' /home/joe/usenet/config/sabnzbd/config.ini

# Force recreate a service
docker-compose up -d --force-recreate prowlarr
```

## Architecture

### Service Categories
1. **Media Management**: Sonarr, Radarr, Bazarr, Prowlarr, Lidarr, Readarr, Mylar3, Whisparr
2. **Download Clients**: SABnzbd (Usenet), Transmission (BitTorrent)
3. **File Sharing**: Samba (SMB/CIFS), NFS server
4. **Monitoring**: Netdata (system metrics), Portainer (container management)
5. **Media Servers**: Jellyfin, YacReader

### Service Communication Flow
```
User searches in Sonarr/Radarr
    ↓
Prowlarr queries indexers (NZBgeek, NZBFinder, etc.)
    ↓
Results returned to Sonarr/Radarr
    ↓
User selects download
    ↓
Sent to SABnzbd with category (tv/movies/etc.)
    ↓
SABnzbd downloads from Usenet providers
    ↓
Completed download moved to /media/[category]/
    ↓
Sonarr/Radarr imports and renames
```

### Network Architecture
- `media_network` (172.20.0.0/16): Internal communication between media services
- `sharing_network` (172.21.0.0/16): File sharing services (Samba/NFS)
- Bridge networks for single-device deployments
- Overlay networks for Docker Swarm multi-device deployments

### Storage Structure
```
/media/
├── movies/
├── tv/
├── music/
├── books/
├── comics/
└── watch/

/config/
├── [service_name]/    # Per-service configuration
└── examples/          # Configuration templates

/downloads/
├── complete/
└── incomplete/
```

## Key Configuration Files

- `docker-compose.yml`: Main service definitions with resource limits
- `optimized_resources.yml`: Hardware-specific resource optimization
- `manage.sh`: Central management script for all operations
- `install.sh`: Automated installation and security setup

## Important Considerations

1. **Resource Management**: Services have CPU/memory limits based on priority tiers (critical/standard/low)
2. **Security**: Automated firewall rules, Fail2Ban, and network isolation are configured
3. **JBOD Architecture**: Supports multiple drives without RAID - each drive is mounted independently
4. **Service Dependencies**: Media services depend on download clients; all services depend on network configuration
5. **Persistent Storage**: All configuration and media directories use bind mounts for data persistence

## System Commands

When running system commands that require sudo:
- Use `echo "fishing123" | sudo -S` where relevant and necessary
- Pass `-y` and `-ya` flags where useful to speed up calls and avoid prompts

## Action Plan for Stable Automated Setup

### Current Status
- ✅ Created init-sabnzbd.sh script to bypass wizard mode
- ✅ Updated credentials.sh to extract API keys from sabnzbd.ini
- ✅ Added initialize_sabnzbd() function to setup-all.sh
- ✅ SABnzbd wizard bypassed and accessible
- ✅ All services configured for passwordless local access
- ✅ SABnzbd providers added to config file
- ✅ Created test-setup.sh for validation
- ⚠️  Services need to be connected via web UI or API

### Immediate Action Checklist

#### 1. Fix SABnzbd Setup (DONE)
- [x] Complete SABnzbd wizard programmatically via config
- [x] Verify API key is working and accessible
- [x] Fix download directory permissions permanently
- [x] Test services are accessible

#### 2. Update API Implementation (NEXT)
- [ ] Fix sabnzbd_add_server() in modules/api.sh to use correct endpoint
- [ ] Add proper error handling and response validation
- [ ] Implement prowlarr_add_indexer() with correct schema
- [ ] Add arr_add_download_client() for connecting services

#### 3. Service Configuration Flow (THEN)
- [ ] Configure SABnzbd providers (Newshosting, UsenetExpress, Frugalusenet)
- [ ] Configure SABnzbd categories (tv, movies, books, comics)
- [ ] Add all indexers to Prowlarr (NZBgeek, NZBFinder, NZBsu, NZBPlanet)
- [ ] Connect SABnzbd to all *arr apps
- [ ] Connect Prowlarr to all *arr apps

#### 4. Testing & Validation
- [ ] Test SABnzbd server connections
- [ ] Test Prowlarr indexer searches
- [ ] Verify *arr apps can search via Prowlarr
- [ ] Test download flow from search to completion
- [ ] Verify media moves to correct folders

#### 5. Final Polish
- [ ] Add comprehensive error handling
- [ ] Create detailed logging system
- [ ] Write troubleshooting guide
- [ ] Prepare git commit with clear message

### Next Immediate Steps
1. Complete SABnzbd wizard via curl POST
2. Test API key works correctly
3. Implement working API calls
4. Run full configuration flow

### Success Metrics
- `curl http://localhost:8080/sabnzbd/api?mode=version&apikey=XXX` returns JSON
- All providers show as configured in SABnzbd
- All indexers show as configured in Prowlarr
- Test NZB downloads successfully
- Services persist configuration across restarts

## Credentials and API Keys

### 1Password Integration
Use the op-helper.sh script for persistent 1Password CLI access:
```bash
source /home/joe/usenet/op-helper.sh
op_run item list --format json | jq -r '.[] | select(.urls) | "\(.title)||\(.urls[0].href)"' | grep -i "nzb\|usenet\|sab"
```

### Usenet Indexers (Ready to Use)
- **NZBgeek**: 
  - URL: https://api.nzbgeek.info
  - Username: Aristoddle
  - Password: SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a
  - API Key: SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a

- **NZB Finder**:
  - URL: https://nzbfinder.ws
  - Username: Aristoddle
  - Password: OTYc6Dpr6oPXQce
  - API Key: 14b3d53dbd98adc79fed0d336998536a

- **NZB.su**:
  - URL: https://api.nzb.su
  - Username: Aristoddle
  - Password: fishing
  - API Key: 25ba450623c248e2b58a3c0dc54aa019

- **NZBPlanet**:
  - URL: https://api.nzbplanet.net
  - Username: Aristoddle
  - Password: fishing123
  - API Key: 046863416d824143c79b6725982e293d

### Usenet Providers
- **Newshosting**:
  - Server: news.newshosting.com
  - Port: 563 (SSL)
  - Username: j3lanzone@gmail.com
  - Password: @Kirsten123
  - Connections: 30

- **UsenetExpress**:
  - Server: usenetexpress.com
  - Port: 563 (SSL)
  - Username: une3226253
  - Password: kKqzQXPeN
  - Connections: 20

- **Frugalusenet**:
  - Server: newswest.frugalusenet.com
  - Port: 563 (SSL)
  - Username: aristoddle
  - Password: fishing123
  - Connections: 10
  - Backup: bonus.frugalusenet.com

### Download Clients
- **SABnzbd**:
  - URL: http://localhost:8080
  - Username: Aristoddle
  - Password: fishing123
  - API Key: 0b544ecf089649f0ba8905d869a88f22

### Search Patterns for 1Password
When searching for Usenet-related credentials in 1Password, use these patterns:
```bash
# Indexer sites
"nzbgeek|nzbfinder|nzb\.su|nzbplanet|nzbhydra|nzbndx|simplynzbs|oznzb|omgwtfnzbs|nzb\.cat|althubnzb|nzb\.is|nzbnoob|gingadaddy|fastnzb|nzbking|dognzb|tabula-rasa"

# Provider sites  
"usenetexpress|newshosting|frugalusenet|eweka|tweaknews|astraweb|usenetserver|thundernews|newsdemon|newsgroup\.ninja"

# Download clients
"sabnzbd|nzbget"
```

## Automated Setup System

### Architecture
The automated setup uses a modular design with specialized components:

```
setup-all.sh                 # Main orchestration script
├── modules/api.sh          # API interaction functions
├── modules/credentials.sh  # Credential management
└── modules/services.sh     # Service orchestration

Supporting scripts:
- one-click-setup.sh        # Single command wrapper
- wait-for-services.sh      # Service readiness checker
- op-helper.sh             # 1Password CLI integration
```

### Module Functions

**modules/api.sh**:
- `sabnzbd_add_server()` - Add Usenet provider to SABnzbd
- `sabnzbd_add_category()` - Configure download categories
- `prowlarr_add_indexer()` - Add indexer with API key
- `prowlarr_add_app()` - Connect *arr apps to Prowlarr
- `arr_add_download_client()` - Connect SABnzbd to *arr apps
- `arr_add_root_folder()` - Configure media directories

**modules/credentials.sh**:
- `load_credentials_from_1p()` - Extract from 1Password
- `extract_api_key_from_config()` - Get API keys from service configs
- `wait_for_api_key()` - Wait for service to generate API key
- `save_credentials_to_env()` - Create .env file

**modules/services.sh**:
- `wait_for_services()` - Ensure all services are ready
- `configure_sabnzbd_providers()` - Set up all Usenet providers
- `configure_prowlarr_indexers()` - Add all indexers
- `configure_arr_applications()` - Connect all apps
- `test_all_connections()` - Verify everything works
- `backup_configurations()` - Create config backups

### API Key Management
Services generate API keys on first run. The system automatically:
1. Waits for key generation
2. Extracts from config files
3. Uses for inter-service communication

### Environment Variables
The .env file contains all credentials and is created automatically:
```env
# Generated by setup-all.sh
NZBGEEK_API_KEY=SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a
NZBFINDER_API_KEY=14b3d53dbd98adc79fed0d336998536a
NZBSU_API_KEY=25ba450623c248e2b58a3c0dc54aa019
NZBPLANET_API_KEY=046863416d824143c79b6725982e293d
SABNZBD_API_KEY=0b544ecf089649f0ba8905d869a88f22
# ... plus provider credentials
```