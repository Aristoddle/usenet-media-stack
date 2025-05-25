# Services Command

The `services` command provides comprehensive management of all 19 services in your media automation stack, including health monitoring, log access, API synchronization, and individual service control.

## Usage

```bash
usenet services <action> [service...] [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `list` | Show status of all services | `usenet services list` |
| `start` | Start services | `usenet services start sonarr radarr` |
| `stop` | Stop services | `usenet services stop jellyfin` |
| `restart` | Restart services | `usenet services restart --all` |
| `logs` | View service logs | `usenet services logs sonarr --follow` |
| `health` | Check service health | `usenet services health --detailed` |
| `sync` | Synchronize service APIs | `usenet services sync --storage` |

## Service Overview

### All Available Services

```bash
usenet services list
```

**Example output:**
```bash
📊 SERVICES STATUS (19 total)

🎬 Media Services:
✅ jellyfin      (8096)  ↗ Media streaming with GPU transcoding
✅ overseerr     (5055)  ↗ Request management interface
✅ yacreader     (8082)  ↗ Comic/manga server
✅ tdarr         (8265)  ↗ Automated transcoding (GPU enabled)

🤖 Automation Stack:
✅ sonarr        (8989)  ↗ TV automation (TRaSH Guide optimized)
✅ radarr        (7878)  ↗ Movie automation (custom formats)
✅ readarr       (8787)  ↗ Book/audiobook automation
✅ bazarr        (6767)  ↗ Subtitle automation (40+ languages)
✅ prowlarr      (9696)  ↗ Universal indexer management
✅ recyclarr     ------  ↗ TRaSH Guide auto-optimization
✅ mylar         (8090)  ↗ Comic book automation
✅ whisparr      (6969)  ↗ Adult content automation

📥 Download Clients:
✅ sabnzbd       (8080)  ↗ High-speed Usenet downloader
✅ transmission  (9092)  ↗ BitTorrent client

🔧 Management & Monitoring:
✅ portainer     (9000)  ↗ Docker container management
✅ netdata      (19999)  ↗ Real-time system monitoring
✅ jackett       (9117)  ↗ Legacy indexer proxy

🌐 Network Services:
✅ samba         (445)   ↗ Windows file sharing
✅ nfs-server    (2049)  ↗ Unix/Linux file sharing

Legend: ✅ Running  ⚠ Warning  ❌ Stopped  🔄 Starting  📊 Monitoring
```

### Service Categories

| Category | Services | Purpose |
|----------|----------|---------|
| **Media** | jellyfin, overseerr, yacreader, tdarr | Streaming and transcoding |
| **Automation** | sonarr, radarr, readarr, bazarr, prowlarr, recyclarr, mylar, whisparr | Content automation |
| **Downloads** | sabnzbd, transmission | Download clients |
| **Management** | portainer, netdata, jackett | System management |
| **Network** | samba, nfs-server | File sharing |

## Service Management

### Starting Services

```bash
# Start all services
usenet services start --all

# Start specific services
usenet services start sonarr radarr jellyfin

# Start by category
usenet services start --category media

# Start with dependency resolution
usenet services start jellyfin --with-deps
```

### Stopping Services

```bash
# Stop all services
usenet services stop --all

# Stop specific services
usenet services stop tdarr --graceful

# Stop by category
usenet services stop --category downloads

# Emergency stop (force kill)
usenet services stop jellyfin --force
```

### Restarting Services

```bash
# Restart all services
usenet services restart --all

# Restart specific services
usenet services restart sonarr radarr

# Rolling restart (one at a time)
usenet services restart --rolling --category automation

# Restart with health check
usenet services restart jellyfin --wait-healthy
```

## Health Monitoring

### Service Health Checks

```bash
usenet services health
```

**Example health report:**
```bash
🏥 SERVICE HEALTH REPORT

✅ Healthy Services (17/19):
   • jellyfin: Responding, GPU transcoding active
   • sonarr: API accessible, 3 root folders configured
   • radarr: API accessible, quality profiles loaded
   • prowlarr: 12 indexers operational
   • sabnzbd: Queue processing, 45MB/s average speed
   ... (12 more healthy services)

⚠️  Warning Services (2/19):
   • bazarr: API responding slowly (>2s response time)
     └─ Recommendation: Check subtitle provider connections
   • transmission: High memory usage (>1GB)
     └─ Recommendation: Restart service or increase memory limit

❌ Failed Services (0/19):
   (All services operational)

📊 Overall Health Score: 94% (Excellent)

🔧 Recommendations:
   • Monitor bazarr performance
   • Consider restarting transmission during low-usage period
   • All critical services operational
```

### Detailed Health Checks

```bash
# Detailed health with API tests
usenet services health --detailed

# Test specific service APIs
usenet services health sonarr --test-api

# Health monitoring with alerts
usenet services health --monitor --alert-threshold 80
```

## Log Management

### Viewing Logs

```bash
# View recent logs for service
usenet services logs sonarr

# Follow logs in real-time
usenet services logs jellyfin --follow

# View logs with timestamps
usenet services logs radarr --timestamps

# View logs from specific time
usenet services logs tdarr --since "1 hour ago"
```

### Log Filtering

```bash
# Filter by log level
usenet services logs sonarr --level error

# Search logs for patterns
usenet services logs jellyfin --grep "transcode"

# View last N lines
usenet services logs prowlarr --tail 100

# Multiple services logs
usenet services logs sonarr radarr --merge
```

### Log Export

```bash
# Export logs to file
usenet services logs --all --export logs-$(date +%Y%m%d).tar.gz

# Export specific service logs
usenet services logs jellyfin --export jellyfin-debug.log

# Export with metadata
usenet services logs --all --export --include-metadata
```

## API Synchronization

### Storage Synchronization

```bash
# Sync all services with current storage
usenet services sync --storage

# Sync specific services
usenet services sync sonarr radarr --storage

# Dry run sync (show what would change)
usenet services sync --storage --dry-run
```

**Example storage sync:**
```bash
🔄 SYNCHRONIZING STORAGE WITH SERVICES

📁 Current Storage Pool:
   • /media/external_4tb → /media/storage1 (4TB)
   • /mnt/nas_media → /media/storage2 (8TB)

🔧 Updating Service APIs:

✅ Sonarr (localhost:8989):
   • Added root folder: /media/storage1/tv
   • Added root folder: /media/storage2/tv-archive
   • Updated 3 existing series paths

✅ Radarr (localhost:7878):
   • Added root folder: /media/storage1/movies
   • Added root folder: /media/storage2/movies-archive
   • Updated 5 existing movie paths

✅ Readarr (localhost:8787):
   • Added root folder: /media/storage1/books
   • Added root folder: /media/storage2/audiobooks

✅ Jellyfin (localhost:8096):
   • Updated library: "Movies" → /media/storage1/movies
   • Updated library: "TV Shows" → /media/storage1/tv
   • Added library: "Archive Movies" → /media/storage2/movies-archive
   • Triggered library scan

✅ Tdarr (localhost:8265):
   • Updated input paths: [/media/storage1, /media/storage2]
   • Updated output paths: [/media/storage1/transcoded]
   • Refreshed worker nodes

📊 Sync Summary:
   • Services updated: 5/5
   • Root folders added: 8
   • Libraries updated: 4
   • API calls: 23 successful, 0 failed
```

### Quality Profile Synchronization

```bash
# Sync TRaSH Guide profiles
usenet services sync --quality-profiles

# Update indexers across services
usenet services sync --indexers

# Sync custom formats
usenet services sync --custom-formats
```

## Service Configuration

### Configuration Management

```bash
# Show service configuration
usenet services config sonarr

# Edit service configuration
usenet services config jellyfin --edit

# Reset service to defaults
usenet services config radarr --reset

# Backup service configurations
usenet services config --backup-all
```

### Environment Variables

```bash
# Show service environment
usenet services env jellyfin

# Update environment variable
usenet services env sonarr --set SONARR_API_KEY=newkey

# Reload environment
usenet services env --reload-all
```

## Performance Monitoring

### Resource Usage

```bash
# Show resource usage for all services
usenet services stats

# Monitor specific service
usenet services stats jellyfin --live

# Resource usage over time
usenet services stats --historical --since "24 hours ago"
```

**Example stats output:**
```bash
📊 SERVICE RESOURCE USAGE

High Resource Usage:
🔥 jellyfin:     CPU: 45%  RAM: 2.1GB  GPU: 23%
   └─ Active transcodes: 2 streams (4K→1080p)
🔥 tdarr:        CPU: 67%  RAM: 1.8GB  GPU: 15%
   └─ Processing: movie_file.mkv (HEVC→AV1)

Medium Resource Usage:
🟡 sonarr:       CPU: 8%   RAM: 456MB
🟡 radarr:       CPU: 12%  RAM: 623MB
🟡 prowlarr:     CPU: 5%   RAM: 234MB

Low Resource Usage:
🟢 overseerr:    CPU: 2%   RAM: 145MB
🟢 bazarr:       CPU: 1%   RAM: 89MB
... (12 more services)

📈 Overall System:
   • CPU: 15.2% average (24 cores)
   • RAM: 8.3GB / 30GB (28%)
   • GPU: 38% utilization
   • Disk I/O: 45MB/s read, 23MB/s write
```

### Performance Optimization

```bash
# Optimize service performance
usenet services optimize --auto

# Set resource limits
usenet services limit jellyfin --memory 4GB --cpu 2

# Scale services based on load
usenet services scale tdarr --workers 4
```

## Troubleshooting

### Service Diagnostics

```bash
# Run diagnostics on all services
usenet services diagnose

# Diagnose specific service
usenet services diagnose jellyfin --verbose

# Test network connectivity
usenet services test-network

# Validate configurations
usenet services validate-config
```

### Common Issues Resolution

```bash
# Fix common issues automatically
usenet services fix --auto

# Reset stuck service
usenet services reset sonarr

# Clear service caches
usenet services clear-cache --all

# Rebuild service configurations
usenet services rebuild radarr
```

## Advanced Features

### Service Dependencies

```bash
# Show service dependencies
usenet services deps jellyfin

# Start with dependency chain
usenet services start jellyfin --with-deps

# Check dependency health
usenet services health --check-deps
```

### Service Scaling

```bash
# Scale horizontally scalable services
usenet services scale tdarr-node --replicas 3

# Load balance across nodes
usenet services balance --auto

# Show scaling status
usenet services scale --status
```

### Custom Service Management

```bash
# Add custom service
usenet services add --name custom-app \
  --image myapp:latest \
  --port 8080 \
  --category custom

# Import external service
usenet services import docker-compose.custom.yml

# Remove service
usenet services remove custom-app
```

## Examples

::: code-group

```bash [Daily Operations]
# Check overall health
usenet services health

# View any service issues
usenet services logs --level error --since "1 hour ago"

# Restart problematic services
usenet services restart --unhealthy

# Update storage configuration
usenet services sync --storage
```

```bash [Maintenance Mode]
# Stop all services gracefully
usenet services stop --all --graceful

# Perform system maintenance
sudo apt update && sudo apt upgrade

# Start services with health checks
usenet services start --all --wait-healthy

# Verify everything is working
usenet services health --detailed
```

```bash [Troubleshooting]
# Check service that won't start
usenet services diagnose jellyfin

# View recent error logs
usenet services logs jellyfin --level error --tail 50

# Reset and restart service
usenet services reset jellyfin
usenet services start jellyfin --wait-healthy

# Verify fix
usenet services health jellyfin
```

```bash [Performance Monitoring]
# Monitor resource usage
usenet services stats --live

# Find high CPU usage
usenet services stats --sort cpu --top 5

# Check transcoding performance
usenet services logs tdarr --grep "transcode" --follow

# Optimize based on usage
usenet services optimize --auto
```

:::

## Configuration Files

### Service Definitions

Services are defined in Docker Compose files:

- `docker-compose.yml` - Base service definitions
- `docker-compose.optimized.yml` - Hardware-optimized settings
- `docker-compose.storage.yml` - Dynamic storage mounts

### Service Configuration

Each service has configuration in `config/[service]/`:

```bash
config/
├── sonarr/         # Sonarr configuration
├── radarr/         # Radarr configuration  
├── jellyfin/       # Jellyfin configuration
├── prowlarr/       # Prowlarr configuration
└── ...             # Other service configs
```

## Security Considerations

### API Security

```bash
# Rotate API keys
usenet services rotate-keys --all

# Check API security
usenet services security-audit

# Update passwords
usenet services update-passwords --interactive
```

### Access Control

```bash
# Show service access
usenet services access --show

# Update firewall rules
usenet services firewall --update

# Enable/disable external access
usenet services external-access jellyfin --disable
```

## Related Commands

- [`deploy`](./deploy) - Deploy all services
- [`storage`](./storage) - Configure storage for services
- [`hardware`](./hardware) - Optimize hardware for services
- [`backup`](./backup) - Backup service configurations
- [`validate`](./validate) - Validate service health