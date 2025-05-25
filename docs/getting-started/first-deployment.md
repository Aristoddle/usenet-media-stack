# First Deployment

This guide walks you through your first complete deployment of the Usenet Media Stack, from initial clone to a fully functional 19-service media automation system with hardware optimization and storage management.

## Overview

Your first deployment will:

1. **Clone and prepare** the project
2. **Configure environment** with your credentials
3. **Detect hardware** and optimize for your system
4. **Configure storage** for your media files
5. **Deploy all services** with health monitoring
6. **Verify operation** and test key workflows

**Estimated time:** 30-60 minutes (depending on system and internet speed)

## Step 1: Clone and Prepare

### Clone the Repository

```bash
# Clone to your preferred location
cd /opt
sudo git clone https://github.com/Aristoddle/usenet-media-stack.git
sudo chown -R $USER:$USER usenet-media-stack
cd usenet-media-stack

# Verify you have the main files
ls -la
# Expected: usenet, docker-compose.yml, config/, scripts/, etc.
```

### Initial System Check

```bash
# Run built-in system validation
./usenet validate

# This will check:
# - Docker installation and access
# - System resources (CPU, RAM, storage)
# - Network connectivity
# - GPU detection (if available)
# - Required dependencies
```

**Expected output:**
```bash
🔍 SYSTEM VALIDATION REPORT

✅ SYSTEM REQUIREMENTS (6/6 checks passed)
   ✓ OS: Ubuntu 22.04.3 LTS (supported)
   ✓ Docker: 24.0.7 (compatible)
   ✓ RAM: 16GB available (good)
   ✓ Storage: 500GB available (sufficient)
   ✓ Network: Internet connectivity confirmed

✅ HARDWARE CAPABILITIES
   ✓ CPU: AMD Ryzen 7 7840HS (16 threads)
   ✓ GPU: AMD Radeon 780M (VAAPI capable)

📊 Overall Status: Ready for deployment
```

## Step 2: Environment Configuration

### Generate Base Configuration

```bash
# Create initial environment configuration
./usenet config generate
```

This creates `.env` file with default settings and placeholders for your credentials.

### Configure Essential Settings

Edit the `.env` file with your specific settings:

```bash
# Edit environment configuration
nano .env
```

**Key settings to configure:**

```bash
# === BASIC CONFIGURATION ===
# Timezone (important for scheduling)
TZ=America/New_York

# User ID and Group ID (run 'id' to get your values)
PUID=1000
PGID=1000

# === DOMAIN CONFIGURATION (Optional for first deployment) ===
# If you have a domain and want external access
DOMAIN_NAME=yourdomain.com
CLOUDFLARE_API_TOKEN=your_cloudflare_token

# === DOWNLOAD CLIENT CONFIGURATION ===
# Usenet server settings (required for downloads)
SABNZBD_HOST=news.your-provider.com
SABNZBD_PORT=563
SABNZBD_USERNAME=your_username
SABNZBD_PASSWORD=your_password
SABNZBD_SSL=1

# === INDEXER CONFIGURATION (Optional for first deployment) ===
# You can configure these later via the web interfaces
# PROWLARR_API_KEY=will_be_generated
# SONARR_API_KEY=will_be_generated
# RADARR_API_KEY=will_be_generated
```

### Generate API Keys

```bash
# Generate secure API keys for services
./usenet config generate-keys

# This will populate the API key sections in .env
```

## Step 3: Hardware Detection and Optimization

### Detect Your Hardware

```bash
# Comprehensive hardware detection
./usenet hardware list
```

**Example output:**
```bash
🚀 HARDWARE CAPABILITIES DETECTED

🔥 GPU: AMD Radeon RX 7840HS
   • VAAPI/AMF: ✓ Available (HEVC, H.264)
   • Driver: AMDGPU 23.20 ✓ Current
   • Hardware acceleration ready

🧠 CPU: AMD Ryzen 7 7840HS
   • Cores: 16 (8P + 8T)
   • Suitable for: High performance profile

💾 Memory: 16GB DDR5
   • Available: 12GB (75%)
   • Suitable for: High performance profile

💡 RECOMMENDATIONS:
   • Use 'high' performance profile for optimal balance
   • Enable hardware transcoding for 10x performance boost
   • Consider 'balanced' profile if running other applications
```

### Install GPU Drivers (if needed)

```bash
# If GPU drivers aren't installed, install them automatically
./usenet hardware install-drivers

# This will:
# - Detect your GPU vendor (NVIDIA/AMD/Intel)
# - Install optimal drivers for your system
# - Configure Docker GPU access
# - Test the installation
```

### Generate Hardware Optimizations

```bash
# Generate optimized configurations for your hardware
./usenet hardware optimize --auto

# This creates:
# - docker-compose.optimized.yml (resource allocations)
# - Hardware-specific transcoding configurations
# - Performance tuning based on your system
```

## Step 4: Storage Configuration

### Discover Available Storage

```bash
# Discover all available storage devices
./usenet storage list
```

**Example output:**
```bash
🗄️ DISCOVERED STORAGE DEVICES:

System Drives (excluded by default):
  [SYS] /                    EXT4 (200G total, 150G available)

Available Storage:
○ [ 1] /media/external_4tb   HDD (4TB total, 3.8TB available)
○ [ 2] /home/user/Downloads  EXT4 (200G total, 180G available)
○ [ 3] /mnt/nas_share        NFS (8TB total, 6.2TB available)

Legend: ○ Available  ● Active  [SYS] System
```

### Configure Storage Pool

```bash
# Add storage drives to your media pool
./usenet storage add /media/external_4tb

# For multiple drives:
./usenet storage add /media/external_4tb
./usenet storage add /mnt/nas_share

# Interactive selection for complex setups:
./usenet storage add --interactive
```

### Verify Storage Configuration

```bash
# Check your storage pool status
./usenet storage status
```

**Example output:**
```bash
📊 STORAGE POOL STATUS

Active Storage (1 drive, 4TB total):
● /media/external_4tb
  └─ Mounted in services as: /media/storage1
  └─ Available: 3.8TB / 4TB (95%)
  └─ Type: Local HDD, exFAT filesystem

Service Integration:
✓ All 19 services configured for automatic access
✓ docker-compose.storage.yml generated
✓ Ready for deployment
```

## Step 5: Deploy All Services

### Interactive Deployment

```bash
# Start interactive deployment process
./usenet deploy
```

This will guide you through:
1. **Performance profile selection** (light/balanced/high/dedicated)
2. **Storage confirmation** 
3. **Hardware optimization confirmation**
4. **Service startup order**

### Automated Deployment

```bash
# For automated deployment with detected settings
./usenet deploy --auto

# Or with specific profile
./usenet deploy --profile balanced --auto
```

### Monitor Deployment Progress

```bash
# Watch service startup in real-time
./usenet logs deployment --follow

# Or check overall status
./usenet services list
```

**Deployment progress:**
```bash
📦 DEPLOYMENT IN PROGRESS

Phase 1: Pre-deployment validation ✓
Phase 2: Hardware optimization ✓  
Phase 3: Storage configuration ✓
Phase 4: Service deployment...

🔄 Starting core services:
   ✓ prowlarr     (indexer management)
   ✓ sabnzbd      (usenet downloader)
   ✓ transmission (torrent client)

🔄 Starting automation services:
   ✓ sonarr       (TV automation)
   ✓ radarr       (movie automation)
   ✓ bazarr       (subtitle automation)

🔄 Starting media services:
   ✓ jellyfin     (media server)
   ✓ overseerr    (request management)
   ✓ tdarr        (transcoding)

✅ Deployment complete! 19/19 services running
```

## Step 6: Verify Operation

### Check Service Health

```bash
# Comprehensive health check
./usenet services health
```

**Expected healthy output:**
```bash
🏥 SERVICE HEALTH REPORT

✅ Healthy Services (19/19):
   • jellyfin: Responding, GPU transcoding ready
   • overseerr: API accessible, connected to Sonarr/Radarr
   • sonarr: API accessible, ready for series management
   • radarr: API accessible, ready for movie management
   • prowlarr: Indexer management ready
   • sabnzbd: Download client ready
   ... (13 more services)

📊 Overall Health Score: 100% (Excellent)
```

### Access Web Interfaces

**Core services to access:**

| Service | URL | Purpose |
|---------|-----|---------|
| **Jellyfin** | http://localhost:8096 | Media streaming and management |
| **Overseerr** | http://localhost:5055 | Request movies and TV shows |
| **Sonarr** | http://localhost:8989 | TV show automation |
| **Radarr** | http://localhost:7878 | Movie automation |
| **Prowlarr** | http://localhost:9696 | Indexer management |
| **SABnzbd** | http://localhost:8080 | Usenet downloader |
| **Portainer** | http://localhost:9000 | Docker management |

### Initial Service Configuration

#### 1. Configure Prowlarr (Indexer Management)

```bash
# Open Prowlarr
open http://localhost:9696
```

1. Complete the initial setup wizard
2. Add your Usenet indexers (NZBGeek, NZBHydra2, etc.)
3. Configure API sync with Sonarr and Radarr
4. Test indexer connections

#### 2. Configure Sonarr (TV Shows)

```bash
# Open Sonarr
open http://localhost:8989
```

1. Complete initial setup
2. Add root folder: `/media/storage1/tv`
3. Configure download client (SABnzbd should auto-detect)
4. Set quality profiles (HD-1080p recommended for start)
5. Configure indexers (will sync from Prowlarr)

#### 3. Configure Radarr (Movies)

```bash
# Open Radarr  
open http://localhost:7878
```

1. Complete initial setup
2. Add root folder: `/media/storage1/movies`
3. Configure download client (SABnzbd should auto-detect)
4. Set quality profiles and custom formats
5. Configure indexers (will sync from Prowlarr)

#### 4. Configure Jellyfin (Media Server)

```bash
# Open Jellyfin
open http://localhost:8096
```

1. Complete initial setup wizard
2. Create admin user account
3. Add media libraries:
   - Movies: `/media/storage1/movies`
   - TV Shows: `/media/storage1/tv`
4. Enable hardware transcoding (if GPU detected)
5. Configure streaming settings

### Test Key Workflows

#### Test 1: Download Workflow

1. **Search via Overseerr:**
   - Open http://localhost:5055
   - Search for a TV show or movie
   - Request it

2. **Verify Automation:**
   - Check Sonarr/Radarr picked up the request
   - Verify SABnzbd started downloading
   - Watch file move to media folder when complete

#### Test 2: Transcoding (if GPU available)

1. **Start transcoding test:**
   ```bash
   ./usenet hardware benchmark
   ```

2. **Verify GPU usage:**
   ```bash
   # For NVIDIA:
   nvidia-smi
   
   # For AMD:
   radeontop
   ```

#### Test 3: Storage Hot-Swap

1. **Add another drive:**
   ```bash
   ./usenet storage add /path/to/new/drive
   ```

2. **Verify services updated:**
   ```bash
   ./usenet storage status
   ./usenet services logs sonarr | grep "root folder"
   ```

## Step 7: Configure External Access (Optional)

### Set Up Cloudflare Tunnel

If you configured a domain in `.env`:

```bash
# Set up secure external access
./usenet tunnel setup

# This will:
# - Install cloudflared
# - Create tunnel
# - Configure DNS records
# - Set up SSL certificates
```

### Test External Access

```bash
# Check tunnel status
./usenet tunnel status

# Test external URLs
curl -I https://jellyfin.yourdomain.com
curl -I https://overseerr.yourdomain.com
```

## Troubleshooting First Deployment

### Common Issues and Solutions

#### Services Not Starting

```bash
# Check service logs
./usenet services logs <service-name>

# Common causes:
# - Port conflicts: Check if ports are already in use
# - Permission issues: Verify file ownership
# - Resource constraints: Check available RAM/CPU
```

#### GPU Transcoding Not Working

```bash
# Verify GPU access
./usenet hardware list

# Check Jellyfin GPU settings
./usenet services logs jellyfin | grep -i gpu

# Reinstall GPU drivers if needed
./usenet hardware install-drivers --force
```

#### Storage Not Accessible

```bash
# Check storage status
./usenet storage validate

# Verify mount points
mount | grep storage

# Fix permissions if needed
sudo chown -R 1000:1000 /media/storage1
```

#### API Connections Failing

```bash
# Regenerate API keys
./usenet config generate-keys

# Restart services
./usenet services restart sonarr radarr prowlarr

# Check connectivity
./usenet services health --detailed
```

### Getting Help

If you encounter issues:

1. **Check logs:** `./usenet logs <service>`
2. **Run validation:** `./usenet validate --fix`
3. **Generate support bundle:** `./usenet support bundle`
4. **Check documentation:** Review service-specific guides
5. **Community support:** Forum and GitHub issues

## Next Steps

### Immediate Actions

1. **Add content:** Start requesting movies/TV shows via Overseerr
2. **Configure quality:** Set up quality profiles in Sonarr/Radarr
3. **Add indexers:** Configure additional indexers in Prowlarr
4. **Set up monitoring:** Configure Netdata dashboards

### Advanced Configuration

1. **[Performance tuning](../advanced/performance)** - Optimize for your workload
2. **[Custom configurations](../advanced/custom-configs)** - Customize services
3. **[Backup strategies](../advanced/backup-strategies)** - Protect your configuration
4. **[API integration](../advanced/api-integration)** - Automate workflows

### Maintenance Tasks

```bash
# Set up automated backups
./usenet backup schedule --daily --time 03:00

# Configure update notifications
./usenet monitor setup --alerts email

# Schedule regular health checks
echo "0 */6 * * * /opt/usenet-media-stack/usenet validate" | crontab -
```

## Success Checklist

- [ ] All 19 services running and healthy
- [ ] Storage pool configured and accessible
- [ ] Hardware optimization active (GPU transcoding if available)
- [ ] Web interfaces accessible
- [ ] Download workflow tested
- [ ] Media streaming working
- [ ] External access configured (if desired)
- [ ] Backup system enabled

**Congratulations!** You now have a fully functional, professionally configured media automation stack. Your system is ready to automatically download, organize, and serve your media collection with enterprise-grade reliability and performance.

## Related Documentation

- [CLI Reference](../cli/) - Complete command documentation
- [Storage Management](../storage/) - Advanced storage configuration
- [Hardware Optimization](../hardware/) - GPU and performance tuning
- [Service Management](../cli/services) - Managing individual services