# Complete Usenet Media Automation Stack Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture Deep Dive](#architecture-deep-dive)
3. [Services Detailed Breakdown](#services-detailed-breakdown)
4. [Installation & Setup](#installation--setup)
5. [Configuration Management](#configuration-management)
6. [Automation System](#automation-system)
7. [Storage Architecture](#storage-architecture)
8. [Network Architecture](#network-architecture)
9. [Security Considerations](#security-considerations)
10. [Troubleshooting Guide](#troubleshooting-guide)
11. [Advanced Usage](#advanced-usage)
12. [Development Guide](#development-guide)

---

## Project Overview

### What is This?
This is a comprehensive, production-ready media automation stack that combines:
- **Usenet downloading** via SABnzbd
- **Media organization** through Sonarr, Radarr, Lidarr, Readarr, Mylar3
- **Subtitle management** with Bazarr
- **Indexer aggregation** via Prowlarr
- **Media streaming** through Jellyfin
- **Request management** with Overseerr
- **File sharing** via Samba/NFS
- **System monitoring** using Netdata
- **Container orchestration** with Docker Swarm support

### Key Features
- **One-command deployment**: `./one-click-setup.sh`
- **Automated configuration**: All services pre-configured with providers and indexers
- **JBOD support**: Optimized for Just-a-Bunch-Of-Disks storage architecture
- **Multi-device ready**: Docker Swarm support for distributed deployment
- **Passwordless local access**: Convenient for home network use
- **1Password integration**: Secure credential management
- **Modular design**: Easy to extend and customize

### Technology Stack
- **Container Runtime**: Docker & Docker Compose
- **Orchestration**: Docker Swarm (optional)
- **Languages**: Bash, Python
- **Automation**: Custom shell scripts with modular architecture
- **Storage**: JBOD with intelligent tiering (fast/slow drives)
- **Networking**: Overlay networks for service isolation

---

## Architecture Deep Dive

### System Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────────┐
│                        User Interface Layer                          │
├─────────────────┬─────────────────┬─────────────────┬──────────────┤
│    Overseerr    │    Jellyfin     │    Portainer    │   Netdata    │
│  (Request Mgmt) │   (Streaming)   │ (Container Mgmt)│ (Monitoring) │
├─────────────────┴─────────────────┴─────────────────┴──────────────┤
│                     Media Management Layer                           │
├─────────┬─────────┬─────────┬─────────┬─────────┬─────────────────┤
│ Sonarr  │ Radarr  │ Lidarr  │ Readarr │ Mylar3  │     Bazarr      │
│  (TV)   │(Movies) │ (Music) │ (Books) │(Comics) │  (Subtitles)    │
├─────────┴─────────┴─────────┴─────────┴─────────┴─────────────────┤
│                     Indexer Management Layer                         │
├─────────────────────────────┬───────────────────────────────────────┤
│          Prowlarr           │              Jackett                  │
│    (Primary Indexers)       │        (Fallback Indexers)           │
├─────────────────────────────┴───────────────────────────────────────┤
│                      Download Layer                                  │
├─────────────────────────────┬───────────────────────────────────────┤
│          SABnzbd            │           Transmission                │
│     (Usenet Client)         │       (BitTorrent Client)            │
├─────────────────────────────┴───────────────────────────────────────┤
│                    Post-Processing Layer                             │
├─────────────────────────────┬───────────────────────────────────────┤
│         Unpackerr           │          File System                  │
│   (Archive Extraction)      │    (Permissions & Organization)       │
├─────────────────────────────┴───────────────────────────────────────┤
│                      Storage Layer (JBOD)                            │
├─────────────────────────────┬───────────────────────────────────────┤
│       Fast Storage          │          Slow Storage                 │
│  - Fast_8TB_1,2,3          │     - Slow_4TB_1,2                   │
│  - Fast_4TB_1,2            │     - Slow_2TB_1,2                   │
├─────────────────────────────┴───────────────────────────────────────┤
│                    File Sharing Layer                                │
├─────────────────────────────┬───────────────────────────────────────┤
│          Samba              │              NFS                      │
│      (SMB/CIFS)             │       (Network File System)          │
└─────────────────────────────┴───────────────────────────────────────┘
```

### Data Flow Architecture
```
1. Content Discovery Flow:
   User → Overseerr → Approval → Sonarr/Radarr → Prowlarr → Indexers

2. Download Flow:
   Indexer Result → SABnzbd → Download → Unpackerr → Extract → Import

3. Media Consumption Flow:
   Imported Media → Jellyfin → Transcoding → Client Device

4. Monitoring Flow:
   All Services → Netdata → Metrics → Dashboard
   Jellyfin → Tautulli → Statistics → Reports
```

### Container Network Architecture
- **media_network** (172.20.0.0/16): Internal service communication
- **sharing_network** (172.21.0.0/16): File sharing services
- **bridge**: Default Docker network for external access

---

## Services Detailed Breakdown

### Core Media Management Services

#### Sonarr (TV Shows)
- **Purpose**: Automated TV show downloading and organization
- **Port**: 8989
- **API Key**: `c0e746db6c604179ac34630df0f2c8fb`
- **Features**:
  - Monitors for new episodes
  - Upgrades quality automatically
  - Renames and organizes files
  - Integrates with Prowlarr for searches
- **Configuration Path**: `/config/sonarr/`
- **Media Path**: `/tv/`

#### Radarr (Movies)
- **Purpose**: Automated movie downloading and organization
- **Port**: 7878
- **API Key**: `5685e1e402944f69ac4e0d01cf64b4a1`
- **Features**:
  - Monitors for new releases
  - Quality profile management
  - Custom formats support
  - Multiple version handling
- **Configuration Path**: `/config/radarr/`
- **Media Path**: `/movies/`

#### Lidarr (Music)
- **Purpose**: Music collection management
- **Port**: 8686
- **API Key**: `da44de6e5e3543e499e8b5b7f44de532`
- **Features**:
  - Artist and album monitoring
  - Metadata enrichment
  - Multiple format support
  - MusicBrainz integration
- **Configuration Path**: `/config/lidarr/`
- **Media Path**: `/music/`

#### Readarr (Books)
- **Purpose**: eBook and audiobook management
- **Port**: 8787
- **API Key**: `0a40ec3436a14bfba4d668f10de96799`
- **Features**:
  - Goodreads integration
  - Multiple format support (epub, mobi, pdf)
  - Series management
  - Metadata fetching
- **Configuration Path**: `/config/readarr/`
- **Media Path**: `/books/`

#### Mylar3 (Comics)
- **Purpose**: Comic book management
- **Port**: 8090
- **API Key**: `22dea46f4bf5c5457e48a13b8063b45e`
- **Features**:
  - ComicVine integration
  - Issue tracking
  - Story arc management
  - CBR/CBZ support
- **Configuration Path**: `/config/mylar/`
- **Media Path**: `/comics/`

#### Bazarr (Subtitles)
- **Purpose**: Subtitle downloading and management
- **Port**: 6767
- **API Key**: `c8e590c4e76e2077ace6071bccf857ec`
- **Features**:
  - Multi-language support
  - Automatic subtitle search
  - Subtitle synchronization
  - Integration with all *arr apps
- **Configuration Path**: `/config/bazarr/`

### Download Infrastructure

#### SABnzbd (Primary Download Client)
- **Purpose**: Usenet binary newsreader
- **Port**: 8080
- **API Key**: `50a40b0a92eb4cc797e7c9443542fca2`
- **Configured Providers**:
  1. **Newshosting**: 30 connections, SSL, Priority 0
  2. **UsenetExpress**: 20 connections, SSL, Priority 1
  3. **Frugalusenet**: 10 connections, SSL, Priority 2
- **Categories**:
  - tv → /downloads/tv
  - movies → /downloads/movies
  - music → /downloads/music
  - books → /downloads/books
  - comics → /downloads/comics
- **Configuration Path**: `/config/sabnzbd/`

#### Transmission (Secondary Download Client)
- **Purpose**: BitTorrent client (for non-Usenet content)
- **Port**: 9092
- **Features**:
  - Web UI and RPC interface
  - Selective downloading
  - Bandwidth scheduling
  - Encryption support
- **Configuration Path**: `/config/transmission/`

### Indexer Management

#### Prowlarr (Primary)
- **Purpose**: Indexer aggregator and management
- **Port**: 9696
- **API Key**: `a770e3976d0a44feada3f38fa3868215`
- **Configured Indexers**:
  1. **NZBgeek**: API Key `SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a`
  2. **NZBFinder**: API Key `14b3d53dbd98adc79fed0d336998536a`
  3. **NZBsu**: API Key `25ba450623c248e2b58a3c0dc54aa019`
  4. **NZBPlanet**: API Key `046863416d824143c79b6725982e293d`
- **Features**:
  - Sync indexers to all *arr apps
  - Indexer statistics
  - Search aggregation
  - Health monitoring

#### Jackett (Fallback)
- **Purpose**: Additional indexer proxy
- **Port**: 9117
- **API Key**: `tjznm2faydz8klwpb4d1095dv23zglp0`
- **Use Cases**:
  - Private trackers
  - Specialized indexers
  - Prowlarr backup

### Media Streaming & Discovery

#### Jellyfin
- **Purpose**: Media streaming server
- **Port**: 8096 (HTTP), 8920 (HTTPS)
- **Features**:
  - Hardware transcoding support
  - Multi-user support
  - Live TV and DVR
  - Mobile sync
  - DLNA server
- **Client Support**:
  - Web browsers
  - Mobile apps (iOS/Android)
  - TV apps (Roku, Android TV, Fire TV)
  - Desktop apps
- **Configuration Path**: `/config/jellyfin/`

#### Overseerr
- **Purpose**: Media request and discovery interface
- **Port**: 5055
- **Features**:
  - User request system
  - Approval workflows
  - Integration with *arr apps
  - Jellyfin integration
  - Mobile-friendly UI
- **Configuration Path**: `/config/overseerr/`

#### Tautulli
- **Purpose**: Media server statistics
- **Port**: 8181
- **Features**:
  - Playback statistics
  - User activity monitoring
  - Notification system
  - Custom newsletters
- **Configuration Path**: `/config/tautulli/`

### Support Services

#### Unpackerr
- **Purpose**: Automated archive extraction
- **Features**:
  - Monitors download folders
  - Extracts RAR/ZIP/7z files
  - Cleans up after import
  - Integrates with all *arr apps
- **No Web UI**: Check logs with `docker logs unpackerr`

#### Whisparr (Optional)
- **Purpose**: Adult content management
- **Port**: 6969
- **API Key**: `ee81309d71ad46c8a914ac0796fc448a`
- **Features**: Similar to Sonarr but for adult content

#### YacReader
- **Purpose**: Comic book server and reader
- **Port**: 8082
- **Features**:
  - Web-based comic reader
  - Library management
  - Mobile apps available
- **Configuration Path**: `/config/yacreader/`

### File Sharing Services

#### Samba
- **Purpose**: SMB/CIFS file sharing
- **Ports**: 139, 445
- **Shares**:
  - Media: Full media library
  - Downloads: Active downloads
  - Config: Configuration backup
- **Access**: `\\<server-ip>\Media`

#### NFS Server
- **Purpose**: Network File System for Unix/Linux
- **Ports**: 2049, 111
- **Exports**: Same as Samba shares
- **Mount**: `mount -t nfs <server-ip>:/media/joe /mnt/media`

### Monitoring & Management

#### Netdata
- **Purpose**: Real-time system monitoring
- **Port**: 19999
- **Monitors**:
  - CPU, RAM, Disk usage
  - Network traffic
  - Container statistics
  - Custom alerts
- **No authentication required**

#### Portainer
- **Purpose**: Docker management UI
- **Ports**: 9000 (HTTP), 8000 (Edge Agent)
- **Features**:
  - Container management
  - Stack deployment
  - Resource monitoring
  - Multi-host support

---

## Installation & Setup

### Prerequisites
- **Operating System**: Linux (Ubuntu 20.04+ recommended)
- **Docker**: Version 20.10+
- **Docker Compose**: Version 2.0+
- **Storage**: Minimum 100GB, recommended 1TB+
- **RAM**: Minimum 8GB, recommended 16GB+
- **CPU**: Minimum 4 cores, recommended 8+
- **Network**: Gigabit ethernet recommended

### Quick Installation
```bash
# Clone the repository (once it's on GitHub)
git clone https://github.com/yourusername/usenet-media-stack.git
cd usenet-media-stack

# Run the automated installer
./install.sh

# Start everything with one command
./one-click-setup.sh
```

### Manual Installation Steps

#### 1. System Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y curl git jq openssl

# Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 2. Storage Setup
```bash
# Create directory structure
mkdir -p /media/joe/{Fast_8TB_1,Fast_8TB_2,Fast_8TB_3,Fast_4TB_1,Fast_4TB_2}
mkdir -p /media/joe/{Slow_4TB_1,Slow_4TB_2,Slow_2TB_1,Slow_2TB_2}
mkdir -p ~/usenet/{config,downloads,media,scripts}

# Set permissions
sudo chown -R $USER:$USER /media/joe
chmod -R 755 /media/joe
```

#### 3. Initial Configuration
```bash
# Copy example configurations
cp config/examples/* config/

# Generate API keys if needed
./scripts/generate-api-keys.sh

# Update drive mounts for your system
./scripts/update-drive-mounts.sh
```

#### 4. Service Deployment
```bash
# Start core services
./manage.sh start

# Wait for services to be ready
./wait-for-services.sh

# Run automated configuration
./setup-all.sh --fresh
```

### Post-Installation Setup

#### Configure Jellyfin
1. Navigate to http://localhost:8096
2. Complete setup wizard
3. Add media libraries pointing to:
   - `/media/library/Fast_8TB_1` for movies
   - `/media/library/Fast_8TB_2` for TV shows
   - etc.

#### Configure Overseerr
1. Navigate to http://localhost:5055
2. Connect to Jellyfin using API key
3. Add Sonarr and Radarr connections
4. Configure request settings

#### Set Up Indexers in Prowlarr
1. Navigate to http://localhost:9696
2. Indexers are pre-configured via automation
3. Test each indexer connection
4. Sync to all *arr applications

---

## Configuration Management

### Environment Variables
All sensitive data is stored in `.env` file:
```env
# Indexer API Keys
NZBGEEK_API_KEY=SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a
NZBFINDER_API_KEY=14b3d53dbd98adc79fed0d336998536a
NZBSU_API_KEY=25ba450623c248e2b58a3c0dc54aa019
NZBPLANET_API_KEY=046863416d824143c79b6725982e293d

# Service API Keys (auto-generated)
PROWLARR_API_KEY=a770e3976d0a44feada3f38fa3868215
SONARR_API_KEY=c0e746db6c604179ac34630df0f2c8fb
RADARR_API_KEY=5685e1e402944f69ac4e0d01cf64b4a1
# ... etc
```

### Configuration Files Structure
```
config/
├── sonarr/config.xml       # Sonarr configuration
├── radarr/config.xml       # Radarr configuration
├── prowlarr/config.xml     # Prowlarr configuration
├── sabnzbd/sabnzbd.ini    # SABnzbd configuration
├── bazarr/config/         # Bazarr configuration
├── jellyfin/              # Jellyfin configuration
└── [service]/             # Other service configs
```

### Backup Strategy
```bash
# Backup all configurations
./manage.sh backup-configs

# Restore from backup
./manage.sh restore-configs backup-2024-01-01.tar.gz

# Automated daily backups (add to crontab)
0 2 * * * /home/joe/usenet/manage.sh backup-configs
```

---

## Automation System

### Module Architecture
```
modules/
├── api.sh          # API interaction functions
├── credentials.sh  # Credential management
└── services.sh     # Service orchestration
```

### Key Automation Scripts

#### one-click-setup.sh
Main entry point for automated deployment:
```bash
#!/bin/bash
# Starts all services
./manage.sh start

# Waits for readiness
./wait-for-services.sh

# Runs configuration
./setup-all.sh --fresh
```

#### setup-all.sh
Orchestrates the entire configuration:
- Loads credentials from 1Password
- Configures SABnzbd providers
- Sets up Prowlarr indexers
- Connects all services
- Tests all connections

#### Module Functions

**modules/api.sh**:
- `sabnzbd_add_server()`: Add Usenet provider
- `prowlarr_add_indexer()`: Add indexer
- `arr_add_download_client()`: Connect download client
- `test_api_connection()`: Verify API access

**modules/credentials.sh**:
- `load_credentials_from_1p()`: 1Password integration
- `extract_api_key_from_config()`: Get service API keys
- `save_credentials_to_env()`: Persist credentials

**modules/services.sh**:
- `wait_for_services()`: Service readiness check
- `configure_sabnzbd_providers()`: Set up Usenet providers
- `configure_prowlarr_indexers()`: Add all indexers
- `test_all_connections()`: Validate setup

### 1Password Integration
```bash
# Helper script for persistent auth
source op-helper.sh

# Extract credentials
op_run item get "NZBgeek" --fields "API Key"

# List all Usenet-related items
op_run item list --format json | jq -r '.[] | select(.urls) | .title' | grep -i usenet
```

---

## Storage Architecture

### JBOD Design Philosophy
- **No RAID**: Each drive operates independently
- **Flexibility**: Add/remove drives without rebuilding arrays
- **Cost-effective**: Use drives of different sizes
- **Simple recovery**: Failed drive only affects its content

### Storage Tiers

#### Fast Storage (Performance Tier)
- **Drives**: Fast_8TB_1, Fast_8TB_2, Fast_8TB_3, Fast_4TB_1, Fast_4TB_2
- **Purpose**: Active downloads, recent media, frequently accessed content
- **Characteristics**: 7200 RPM or SSD, good random I/O
- **Usage**:
  - New TV episodes and movies
  - Currently watching content
  - Download scratch space

#### Slow Storage (Archive Tier)
- **Drives**: Slow_4TB_1, Slow_4TB_2, Slow_2TB_1, Slow_2TB_2
- **Purpose**: Long-term storage, completed series, archived content
- **Characteristics**: 5400 RPM, optimized for capacity
- **Usage**:
  - Completed TV series
  - Older movies
  - Rarely accessed content

### Mount Strategy
```yaml
# Each service gets tiered access
sonarr:
  volumes:
    - /media/joe/Fast_8TB_2:/tv/fast1
    - /media/joe/Fast_4TB_1:/tv/fast2
    - /media/joe/Slow_4TB_1:/tv/archive1
    - /media/joe/Slow_4TB_2:/tv/archive2
```

### Storage Management Scripts
```bash
# Update drive mounts dynamically
./scripts/update-drive-mounts.sh

# Check drive health
./scripts/check-drive-health.sh

# Move content between tiers
./scripts/migrate-to-archive.sh --older-than 180
```

---

## Network Architecture

### Docker Networks

#### media_network (172.20.0.0/16)
- **Type**: Overlay (Swarm) or Bridge (Standalone)
- **Purpose**: Internal service communication
- **Security**: Isolated from host network
- **Services**: All *arr apps, Prowlarr, download clients

#### sharing_network (172.21.0.0/16)
- **Type**: Bridge
- **Purpose**: File sharing services
- **Security**: More permissive for SMB/NFS
- **Services**: Samba, NFS

### Port Management
```yaml
# External ports (accessible from network)
Jellyfin: 8096      # Media streaming
Overseerr: 5055     # Request interface
Prowlarr: 9696      # Indexer management
Sonarr: 8989        # TV management
Radarr: 7878        # Movie management

# Internal ports (Docker network only)
SABnzbd API: 8080   # Download client
Prowlarr Internal: 9696
```

### Reverse Proxy Configuration (Optional)
```nginx
# Nginx example for external access
server {
    server_name media.yourdomain.com;
    
    location /jellyfin {
        proxy_pass http://localhost:8096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    location /overseerr {
        proxy_pass http://localhost:5055;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## Security Considerations

### Authentication Strategy
- **Local Network**: Passwordless access for convenience
- **External Access**: Strong authentication required
- **API Keys**: Randomly generated, stored securely
- **1Password**: Integration for credential management

### Network Security
```bash
# Firewall rules (ufw example)
sudo ufw allow from 192.168.1.0/24 to any port 8096  # Jellyfin from LAN
sudo ufw allow from 192.168.1.0/24 to any port 5055  # Overseerr from LAN
sudo ufw deny 8989  # Block external Sonarr access
```

### Container Security
- **User Mapping**: PUID/PGID set to non-root user (1000)
- **Read-only Mounts**: Media directories mounted read-only where possible
- **Network Isolation**: Services can only communicate as needed
- **Resource Limits**: CPU/Memory limits prevent resource exhaustion

### Backup Security
```bash
# Encrypted backups
./manage.sh backup-configs --encrypt --password-file /secure/location/password

# Secure credential storage
chmod 600 .env
chmod 700 config/
```

---

## Troubleshooting Guide

### Common Issues

#### Service Won't Start
```bash
# Check logs
docker logs [service_name] --tail 50

# Check compose syntax
docker compose config

# Verify ports available
sudo netstat -tulpn | grep [port]
```

#### Permission Errors
```bash
# Fix ownership
sudo chown -R 1000:1000 /path/to/config

# Fix permissions
chmod -R 755 /path/to/media
```

#### SABnzbd Wizard Loop
```bash
# Bypass wizard
./scripts/init-sabnzbd.sh

# Restart service
docker compose restart sabnzbd
```

#### API Connection Failures
```bash
# Test API key
curl -H "X-Api-Key: [api_key]" http://localhost:8989/api/v3/system/status

# Regenerate API keys
./scripts/generate-api-keys.sh
```

### Debug Mode
```bash
# Run setup with verbose output
./setup-all.sh --verbose --dry-run

# Enable debug logging
docker compose logs -f [service_name]
```

### Health Checks
```bash
# Overall system health
./scripts/test-setup.sh

# Media services health
./test-media-services.sh

# Network connectivity
./scripts/test-network.sh
```

---

## Advanced Usage

### Docker Swarm Deployment
```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml usenet-stack

# Scale services
docker service scale usenet-stack_sonarr=2
```

### Custom Quality Profiles
```json
// Sonarr 4K HDR Profile
{
  "name": "4K HDR",
  "cutoff": 2160,
  "items": [
    {"quality": 2160, "allowed": true},
    {"quality": 1080, "allowed": true}
  ],
  "preferredTags": ["HDR", "DV"]
}
```

### Automation Recipes

#### Auto-upgrade Quality
```bash
# Script to upgrade all 720p to 1080p
./scripts/quality-upgrade.sh --from 720p --to 1080p
```

#### Scheduled Maintenance
```cron
# Crontab entries
0 2 * * * /home/joe/usenet/scripts/cleanup-downloads.sh
0 3 * * 0 /home/joe/usenet/scripts/optimize-database.sh
0 4 * * * /home/joe/usenet/scripts/check-drive-health.sh
```

### Performance Tuning

#### SABnzbd Optimization
```ini
# sabnzbd.ini tweaks
download_free = 10G
cache_limit = 1G
par_option = 1  # Parallel PAR2
```

#### Database Optimization
```bash
# Vacuum SQLite databases
for db in config/*/**.db; do
    sqlite3 "$db" "VACUUM;"
done
```

---

## Development Guide

### Project Structure
```
usenet/
├── docker-compose.yml       # Main service definitions
├── docker-compose.media.yml # Additional media services
├── docker-compose.override.yml # Local overrides
├── manage.sh               # Primary management script
├── one-click-setup.sh      # Automated setup entry
├── setup-all.sh           # Configuration orchestrator
├── modules/               # Modular functions
│   ├── api.sh
│   ├── credentials.sh
│   └── services.sh
├── scripts/               # Utility scripts
│   ├── init-sabnzbd.sh
│   ├── generate-api-keys.sh
│   ├── update-drive-mounts.sh
│   └── test-setup.sh
├── config/                # Service configurations
└── downloads/             # Download directories
```

### Adding New Services

#### 1. Update docker-compose.yml
```yaml
new-service:
  image: org/new-service:latest
  container_name: new-service
  networks:
    - media_network
  volumes:
    - new-service_config:/config
  ports:
    - "9999:9999"
  environment:
    - PUID=1000
    - PGID=1000
```

#### 2. Add to Automation
```bash
# In modules/api.sh
new_service_api() {
    local endpoint="$1"
    local api_key="$(get_service_api_key new-service)"
    curl -H "X-Api-Key: $api_key" "http://localhost:9999/api/$endpoint"
}
```

#### 3. Update Documentation
- Add to service list in README.md
- Document API endpoints
- Add troubleshooting section

### Testing Framework
```bash
# Run unit tests
./tests/run-unit-tests.sh

# Integration tests
./tests/run-integration-tests.sh

# Full system test
./tests/full-system-test.sh
```

### Contribution Guidelines
1. **Code Style**: Follow existing patterns
2. **Documentation**: Update docs with changes
3. **Testing**: Add tests for new features
4. **Commits**: Use conventional commits
5. **Reviews**: All changes require review

---

## Appendices

### A. Complete Service List with Ports
| Service | Port | Purpose | API Key |
|---------|------|---------|---------|
| SABnzbd | 8080 | Usenet downloads | 50a40b0a92eb4cc797e7c9443542fca2 |
| Prowlarr | 9696 | Indexer management | a770e3976d0a44feada3f38fa3868215 |
| Sonarr | 8989 | TV shows | c0e746db6c604179ac34630df0f2c8fb |
| Radarr | 7878 | Movies | 5685e1e402944f69ac4e0d01cf64b4a1 |
| Lidarr | 8686 | Music | da44de6e5e3543e499e8b5b7f44de532 |
| Readarr | 8787 | Books | 0a40ec3436a14bfba4d668f10de96799 |
| Bazarr | 6767 | Subtitles | c8e590c4e76e2077ace6071bccf857ec |
| Mylar3 | 8090 | Comics | 22dea46f4bf5c5457e48a13b8063b45e |
| Jellyfin | 8096 | Streaming | Generated on setup |
| Overseerr | 5055 | Requests | None (user accounts) |
| Transmission | 9092 | Torrents | In settings.json |
| Portainer | 9000 | Docker UI | Set on first access |
| Netdata | 19999 | Monitoring | None |
| Jackett | 9117 | Indexers | tjznm2faydz8klwpb4d1095dv23zglp0 |
| Tautulli | 8181 | Stats | Set on setup |
| YACReader | 8082 | Comics | None |
| Whisparr | 6969 | Adult | ee81309d71ad46c8a914ac0796fc448a |

### B. API Endpoint Reference

#### SABnzbd API
```bash
# Check version
curl "http://localhost:8080/sabnzbd/api?mode=version&apikey=API_KEY"

# Add NZB
curl "http://localhost:8080/sabnzbd/api?mode=addurl&name=URL&apikey=API_KEY"

# Pause/Resume
curl "http://localhost:8080/sabnzbd/api?mode=pause&apikey=API_KEY"
```

#### Sonarr/Radarr API
```bash
# System status
curl -H "X-Api-Key: API_KEY" "http://localhost:8989/api/v3/system/status"

# Search for series
curl -H "X-Api-Key: API_KEY" "http://localhost:8989/api/v3/series/lookup?term=breaking+bad"

# Trigger search
curl -X POST -H "X-Api-Key: API_KEY" "http://localhost:8989/api/v3/command" \
  -d '{"name":"SeriesSearch","seriesId":1}'
```

#### Prowlarr API
```bash
# List indexers
curl -H "X-Api-Key: API_KEY" "http://localhost:9696/api/v1/indexer"

# Test indexer
curl -H "X-Api-Key: API_KEY" "http://localhost:9696/api/v1/indexer/test"

# Search
curl -H "X-Api-Key: API_KEY" "http://localhost:9696/api/v1/search?query=ubuntu"
```

### C. Environment Variables Reference
```env
# Required for automation
NZBGEEK_API_KEY=your_key_here
NZBFINDER_API_KEY=your_key_here
NZBSU_API_KEY=your_key_here
NZBPLANET_API_KEY=your_key_here

# Provider credentials
NEWSHOSTING_USERNAME=email@example.com
NEWSHOSTING_PASSWORD=password
USENETEXPRESS_USERNAME=username
USENETEXPRESS_PASSWORD=password
FRUGALUSENET_USERNAME=username
FRUGALUSENET_PASSWORD=password

# Service URLs (internal)
PROWLARR_URL=http://prowlarr:9696
SONARR_URL=http://sonarr:8989
RADARR_URL=http://radarr:7878
```

### D. Useful Commands Cheatsheet
```bash
# Quick status check
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Tail all logs
docker compose logs -f --tail=50

# Restart everything
docker compose restart

# Update all images
docker compose pull && docker compose up -d

# Backup critical data
tar -czf backup-$(date +%Y%m%d).tar.gz config/

# Check disk usage
df -h | grep -E "Filesystem|media"

# Find large files
find /media/joe -type f -size +10G -exec ls -lh {} \;

# Test indexer
curl -H "X-Api-Key: $(grep -oP '(?<=<ApiKey>)[^<]+' config/prowlarr/config.xml)" \
  "http://localhost:9696/api/v1/indexer/test"
```

---

## Conclusion

This documentation covers every aspect of the Usenet Media Automation Stack. The system is designed to be:
- **Automated**: One-command deployment and configuration
- **Scalable**: From single machine to distributed swarm
- **Maintainable**: Modular design with clear separation of concerns
- **Secure**: Proper authentication and network isolation
- **Flexible**: Easy to extend and customize

For questions, issues, or contributions, please refer to the GitHub repository (once created).

Last Updated: $(date)
Version: 2.0.0