# Deploy Command

The `deploy` command orchestrates the complete deployment of your Usenet Media Stack, integrating hardware optimization, storage configuration, and service orchestration into a single workflow.

## Usage

```bash
usenet deploy [options]
```

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--auto` | Fully automated deployment with detected settings | `usenet deploy --auto` |
| `--profile <name>` | Use specific performance profile | `usenet deploy --profile balanced` |
| `--storage-only` | Configure only storage without services | `usenet deploy --storage-only` |
| `--hardware-only` | Configure only hardware optimization | `usenet deploy --hardware-only` |
| `--skip-validation` | Skip pre-deployment checks | `usenet deploy --skip-validation` |
| `--backup-before` | Create backup before deployment | `usenet deploy --backup-before` |

## Interactive Deployment

The default interactive mode guides you through each step:

```bash
usenet deploy
```

**Workflow:**
1. **Pre-flight Validation** - System requirements check
2. **Hardware Detection** - GPU capabilities and driver status  
3. **Storage Discovery** - Available drives and mount points
4. **Performance Profile Selection** - Resource allocation strategy
5. **Service Configuration** - .env file generation
6. **Docker Compose Generation** - Optimized configurations
7. **Service Deployment** - Orchestrated startup with health checks

## Automated Deployment

For scripted deployments or experienced users:

```bash
usenet deploy --auto
```

**Auto-detected settings:**
- Best available performance profile based on hardware
- All mounted storage drives (excludes system drives)
- Optimal GPU drivers and transcoding settings
- Default security configurations

## Performance Profiles

| Profile | CPU % | RAM % | GPU | Use Case |
|---------|-------|-------|-----|----------|
| `light` | 25% | 4GB | Optional | Development/testing |
| `balanced` | 50% | 8GB | Yes | Home server (default) |
| `high` | 75% | 16GB | Yes | Dedicated media server |
| `dedicated` | 100% | All | Yes | Media center appliance |

### Profile Selection

```bash
# Interactive profile selection
usenet deploy

# Specific profile
usenet deploy --profile high

# Let system choose optimal profile
usenet deploy --auto
```

## Deployment Phases

### Phase 1: Validation
```bash
# Pre-deployment checks
✓ Docker and Docker Compose installed
✓ Minimum system requirements met
✓ Required ports available
✓ Storage paths accessible
✓ GPU drivers (if applicable)
```

### Phase 2: Hardware Optimization
```bash
# GPU detection and optimization
🚀 NVIDIA RTX 4090 detected
   • Installing nvidia-docker2
   • Configuring hardware transcoding
   • Generating optimized compose files
```

### Phase 3: Storage Configuration
```bash
# Drive discovery and selection
🗄️ Available Storage:
○ /media/external_4tb (4TB available)
○ /home/user/Dropbox (3TB available)
○ /mnt/nas_share (8TB available)

Which drives should be accessible to media services?
```

### Phase 4: Service Deployment
```bash
# Docker Compose orchestration
📦 Starting services:
   ✓ jellyfin     (GPU transcoding enabled)
   ✓ sonarr       (TRaSH Guide configured)
   ✓ radarr       (Quality profiles loaded)
   ✓ prowlarr     (Indexers ready)
   ✓ sabnzbd      (High-speed configured)
   ... 14 more services
```

## Post-Deployment

After successful deployment:

```bash
🎉 Deployment Complete!

📊 Services Status:
   19/19 services running healthy

🌐 Web Interfaces:
   Jellyfin:  http://localhost:8096
   Overseerr: http://localhost:5055
   Sonarr:    http://localhost:8989
   Radarr:    http://localhost:7878

🔧 Next Steps:
   • Configure indexers in Prowlarr
   • Set up quality profiles in Recyclarr
   • Add media requests via Overseerr
```

## Partial Deployments

### Storage-Only Deployment
Configure storage without affecting running services:

```bash
usenet deploy --storage-only
```

**Use cases:**
- Adding new drives to existing deployment
- Reconfiguring storage layout
- Testing storage configurations

### Hardware-Only Deployment
Update hardware optimization without storage changes:

```bash
usenet deploy --hardware-only
```

**Use cases:**
- Installing new GPU drivers
- Changing performance profiles
- Testing transcoding configurations

## Error Handling

The deployment process includes comprehensive error handling:

```bash
❌ Deployment Failed: Port 8096 already in use

💡 Suggested fixes:
   • Stop conflicting service: sudo systemctl stop jellyfin
   • Use different port: Set JELLYFIN_PORT=8097 in .env
   • Remove conflicting Docker container: docker rm -f jellyfin

🔧 Retry deployment:
   usenet deploy --retry
```

## Configuration Files Generated

Successful deployment creates:

- `.env` - All service configuration and credentials
- `docker-compose.optimized.yml` - Hardware-tuned resource allocations
- `docker-compose.storage.yml` - Dynamic storage mount configurations
- `config/hardware_profile.conf` - Current optimization settings
- `config/storage.conf` - Active drive configuration

## Examples

::: code-group

```bash [Basic Deployment]
# Start interactive deployment
usenet deploy

# Follow prompts for:
# - Hardware detection
# - Storage selection  
# - Performance profile
# - Service configuration
```

```bash [Automated High-Performance]
# Deploy with maximum performance
usenet deploy --auto --profile dedicated

# Results in:
# - All CPU/RAM allocated
# - All drives mounted
# - GPU fully optimized
# - All services enabled
```

```bash [Development Setup]
# Minimal resource deployment
usenet deploy --profile light

# Results in:
# - 25% resource allocation
# - Core services only
# - No GPU requirements
# - Fast startup
```

```bash [Incremental Updates]
# Add new storage without service restart
usenet deploy --storage-only

# Update GPU drivers only
usenet deploy --hardware-only

# Full redeployment with backup
usenet deploy --backup-before
```

:::

## Troubleshooting

### Common Issues

**Port conflicts:**
```bash
Error: Port 8096 already in use
Solution: usenet validate --fix-ports
```

**Storage permissions:**
```bash
Error: Cannot write to /media/drive
Solution: usenet storage fix-permissions
```

**GPU driver issues:**
```bash
Error: NVIDIA drivers not found
Solution: usenet hardware install-drivers
```

### Deployment Logs

Access detailed deployment logs:

```bash
# View last deployment log
usenet logs deployment

# Debug mode deployment
usenet deploy --verbose

# Save deployment log
usenet deploy --auto 2>&1 | tee deployment.log
```

## Related Commands

- [`validate`](./validate) - Pre-deployment checks
- [`storage`](./storage) - Storage management
- [`hardware`](./hardware) - Hardware optimization
- [`backup`](./backup) - Configuration backup/restore