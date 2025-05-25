# Validate Command

The `validate` command performs comprehensive pre-deployment and system health checks with automatic fix suggestions and intelligent troubleshooting to ensure your media stack runs optimally.

## Usage

```bash
usenet validate [options]
```

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--fix` | Automatically fix issues where possible | `usenet validate --fix` |
| `--category <name>` | Validate specific category only | `usenet validate --category hardware` |
| `--service <name>` | Validate specific service | `usenet validate --service jellyfin` |
| `--strict` | Enable strict validation mode | `usenet validate --strict` |
| `--export` | Export validation report | `usenet validate --export report.json` |

## Validation Categories

### System Requirements

```bash
usenet validate --category system
```

**Validation checks:**
- Operating system compatibility
- Minimum hardware requirements  
- Available disk space
- Memory allocation
- CPU capabilities
- Network connectivity

### Docker Environment

```bash
usenet validate --category docker
```

**Validation checks:**
- Docker installation and version
- Docker Compose availability
- Container runtime status
- Image availability
- Registry connectivity
- Volume mount permissions

### Hardware Configuration

```bash
usenet validate --category hardware
```

**Validation checks:**
- GPU detection and drivers
- Hardware acceleration capabilities
- Temperature and thermal throttling
- Power management settings
- Performance optimization status

### Storage Configuration

```bash
usenet validate --category storage
```

**Validation checks:**
- Drive accessibility and permissions
- Filesystem health and compatibility
- Mount point configuration
- Cross-platform compatibility (exFAT)
- Storage pool integrity

### Network Configuration

```bash
usenet validate --category network
```

**Validation checks:**
- Port availability
- Firewall configuration
- DNS resolution
- Cloudflare tunnel status
- SSL certificate validity

### Service Configuration

```bash
usenet validate --category services
```

**Validation checks:**
- Service definitions syntax
- API connectivity
- Configuration file integrity
- Service dependencies
- Quality profiles and indexers

## Comprehensive Validation

### Full System Validation

```bash
usenet validate
```

**Example validation report:**
```bash
🔍 SYSTEM VALIDATION REPORT

📊 Overall Status: 87% (Good) - 3 issues require attention

✅ SYSTEM REQUIREMENTS (6/6 checks passed)
   ✓ OS: Ubuntu 22.04.3 LTS (supported)
   ✓ Kernel: 6.5.0-41-generic (compatible)
   ✓ CPU: AMD Ryzen 7 7840HS (16 threads, adequate)
   ✓ RAM: 30GB total, 24GB available (excellent)
   ✓ Disk: 798GB available on / (sufficient)
   ✓ Network: Internet connectivity confirmed

✅ DOCKER ENVIRONMENT (5/5 checks passed)
   ✓ Docker: 24.0.7 (latest stable)
   ✓ Compose: 2.21.0 (v2 syntax supported)
   ✓ Runtime: runc (healthy)
   ✓ Storage: overlay2 driver (optimal)
   ✓ Registry: hub.docker.com accessible

⚠️  HARDWARE CONFIGURATION (2/3 checks passed)
   ✓ GPU: AMD Radeon 780M detected (VAAPI capable)
   ✓ Drivers: AMDGPU 23.20 installed
   ❌ Hardware acceleration: Not configured for containers
      └─ Fix: usenet hardware optimize --auto

✅ STORAGE CONFIGURATION (4/4 checks passed)
   ✓ Pool: 2 drives accessible (12TB total)
   ✓ Permissions: All drives writable by UID 1000
   ✓ Filesystems: exFAT and ext4 compatible
   ✓ Mount points: Stable and persistent

⚠️  NETWORK CONFIGURATION (3/4 checks passed)
   ✓ Ports: All required ports (8080-9696) available
   ✓ Firewall: UFW configured correctly
   ✓ DNS: Cloudflare DNS responding
   ❌ SSL certificates: Expired certificate for jellyfin.local
      └─ Fix: usenet tunnel setup --renew-certs

⚠️  SERVICE CONFIGURATION (16/17 checks passed)
   ✓ Syntax: All compose files valid
   ✓ Dependencies: Service order correct
   ✓ Environment: All required variables set
   ✓ APIs: 16/17 services responding
   ❌ bazarr: Subtitle provider 'OpenSubtitles' API key invalid
      └─ Fix: Update API key in bazarr web interface

🔧 RECOMMENDED ACTIONS:
   1. Configure hardware acceleration: usenet hardware optimize --auto
   2. Renew SSL certificates: usenet tunnel setup --renew-certs  
   3. Update bazarr API key: http://localhost:6767/settings/providers

💡 OPTIMIZATION OPPORTUNITIES:
   • Enable GPU transcoding for 10x performance improvement
   • Consider upgrading to dedicated performance profile
   • Set up automated SSL certificate renewal
```

## Automatic Fixes

### Fix Common Issues

```bash
usenet validate --fix
```

**Auto-fixable issues:**
- File and directory permissions
- Missing configuration directories
- Default configuration files
- Docker network creation
- Firewall rules
- Environment variable defaults

**Example auto-fix session:**
```bash
🔧 AUTOMATIC FIX MODE ENABLED

Fixing identified issues:

🔐 Fixing permissions:
   ✓ chmod 755 /media/external_4tb
   ✓ chown 1000:1000 /media/external_4tb
   ✓ chmod -R 755 config/

📁 Creating missing directories:
   ✓ mkdir -p config/sonarr
   ✓ mkdir -p config/radarr
   ✓ mkdir -p downloads/complete
   ✓ mkdir -p downloads/incomplete

🔧 Generating default configurations:
   ✓ Created config/jellyfin/system.xml
   ✓ Created config/tdarr/configs.json
   ✓ Generated docker-compose.storage.yml

🌐 Fixing network configuration:
   ✓ Created Docker network 'usenet-stack'
   ✓ Updated firewall rules for required ports

✅ Auto-fix completed: 8/10 issues resolved

❌ Manual intervention required:
   • Update bazarr OpenSubtitles API key
   • Renew SSL certificates (requires Cloudflare access)
```

### Selective Fixes

```bash
# Fix only permission issues
usenet validate --fix --category permissions

# Fix specific service
usenet validate --fix --service jellyfin

# Dry run (show what would be fixed)
usenet validate --fix --dry-run
```

## Service-Specific Validation

### Individual Service Checks

```bash
# Validate Jellyfin configuration
usenet validate --service jellyfin
```

**Jellyfin validation:**
```bash
🎬 JELLYFIN VALIDATION

✅ Configuration (5/5 checks)
   ✓ system.xml present and valid
   ✓ Hardware transcoding configured
   ✓ Media libraries defined
   ✓ User accounts configured
   ✓ Plugin compatibility verified

✅ Hardware Acceleration (3/3 checks)
   ✓ GPU access enabled in container
   ✓ VAAPI drivers available
   ✓ Transcoding profiles optimized

✅ Network Access (3/3 checks)
   ✓ Port 8096 accessible
   ✓ SSL certificate valid
   ✓ External access configured

✅ Storage Access (2/2 checks)
   ✓ Media directories mounted
   ✓ Transcoding cache writable

📊 Jellyfin Health: 100% (Excellent)
```

### Media Service Validation

```bash
# Validate all *arr services
usenet validate --category automation
```

**Automation stack validation:**
```bash
🤖 AUTOMATION SERVICES VALIDATION

✅ Sonarr (8/8 checks)
   ✓ API responding (v3.0.10)
   ✓ Root folders configured (2 paths)
   ✓ Quality profiles loaded (HD-1080p, UHD-2160p)
   ✓ Indexers connected (3 active)
   ✓ Download client configured (sabnzbd)
   ✓ Notifications enabled (Discord)
   ✓ Series monitoring active (47 series)
   ✓ Disk space monitoring enabled

✅ Radarr (8/8 checks)
   ✓ API responding (v4.7.5)
   ✓ Root folders configured (2 paths)
   ✓ Custom formats imported (TRaSH Guide)
   ✓ Quality profiles optimized
   ✓ Indexers synchronized with Prowlarr
   ✓ Download client healthy
   ✓ Movie monitoring active (23 movies)
   ✓ Metadata downloading enabled

⚠️  Bazarr (7/8 checks)
   ✓ API responding (v1.3.1)
   ✓ Language profiles configured (English, Spanish)
   ✓ Sonarr/Radarr integration active
   ✓ Subtitle providers configured (3 active)
   ✓ Episode monitoring enabled
   ✓ Download directory writable
   ✓ Authentication configured
   ❌ OpenSubtitles provider: API limit exceeded
      └─ Recommendation: Upgrade to VIP account or reduce requests
```

## Pre-Deployment Validation

### Deployment Readiness Check

```bash
# Comprehensive pre-deployment validation
usenet validate --pre-deployment
```

**Pre-deployment checklist:**
```bash
🚀 PRE-DEPLOYMENT VALIDATION

📋 Deployment Readiness Checklist:

✅ Environment Configuration
   ✓ .env file present with all required variables
   ✓ Credentials configured (19 API keys)
   ✓ Domain names resolved
   ✓ SSL certificates valid

✅ Infrastructure Requirements
   ✓ Docker daemon running
   ✓ Sufficient disk space (>50GB recommended)
   ✓ Memory requirements met (>8GB available)
   ✓ Network ports available

✅ Hardware Optimization
   ✓ GPU detected and drivers installed
   ✓ Hardware acceleration configured
   ✓ Performance profile selected

✅ Storage Configuration
   ✓ Storage pool configured (2 drives)
   ✓ Media directories accessible
   ✓ Cross-platform compatibility verified

✅ Security Configuration
   ✓ Firewall rules configured
   ✓ Cloudflare tunnel ready
   ✓ API authentication enabled

📊 Deployment Readiness: 100% ✅

🎉 System ready for deployment!
   Run: usenet deploy --auto
```

## Strict Validation Mode

### Enhanced Validation

```bash
usenet validate --strict
```

**Strict mode additional checks:**
- Security best practices compliance
- Performance optimization verification
- Configuration file syntax validation
- API rate limiting compliance
- Resource usage optimization
- Backup system functionality

## Health Monitoring

### Continuous Validation

```bash
# Set up continuous monitoring
usenet validate --monitor --interval 300

# Alert on validation failures
usenet validate --alert --webhook https://hooks.slack.com/...

# Log validation results
usenet validate --log /var/log/usenet-validation.log
```

### Validation Scheduling

```bash
# Schedule daily validation
usenet validate --schedule daily --time 06:00

# Run validation before deployment
usenet validate --pre-hook deployment

# Validate after configuration changes
usenet validate --watch-config
```

## Troubleshooting Assistance

### Issue Resolution

```bash
# Get detailed troubleshooting for specific issue
usenet validate --troubleshoot "port 8096 in use"

# Show resolution steps
usenet validate --help-fix --issue "gpu-not-detected"

# Generate support bundle
usenet validate --support-bundle
```

### Common Issues Database

**Port conflicts:**
```bash
❌ Port 8096 already in use
💡 Solutions:
   • Check existing service: sudo netstat -tlnp | grep 8096
   • Stop conflicting service: sudo systemctl stop jellyfin
   • Change port in .env: JELLYFIN_PORT=8097
   • Use port range: JELLYFIN_PORT=8096-8100
```

**Permission issues:**
```bash
❌ Permission denied: /media/external_drive
💡 Solutions:
   • Fix ownership: sudo chown -R 1000:1000 /media/external_drive
   • Fix permissions: sudo chmod -R 755 /media/external_drive
   • Check mount options: mount | grep external_drive
   • Remount with correct options
```

**GPU not detected:**
```bash
❌ GPU hardware acceleration not available
💡 Solutions:
   • Install drivers: usenet hardware install-drivers
   • Verify installation: nvidia-smi (NVIDIA) or vainfo (AMD)
   • Check Docker integration: docker run --gpus all nvidia/cuda nvidia-smi
   • Update Docker daemon: sudo systemctl restart docker
```

## Validation Reports

### Export Validation Results

```bash
# Export detailed report
usenet validate --export validation-report.json

# Export summary report
usenet validate --export-summary report.txt

# Export with system info
usenet validate --export-full system-report.tar.gz
```

### Report Formats

**JSON format:**
```json
{
  "validation": {
    "timestamp": "2024-01-15T14:30:22Z",
    "version": "2.0",
    "overall_score": 87,
    "status": "good"
  },
  "categories": {
    "system": {"score": 100, "issues": 0},
    "docker": {"score": 100, "issues": 0},
    "hardware": {"score": 67, "issues": 1},
    "storage": {"score": 100, "issues": 0},
    "network": {"score": 75, "issues": 1},
    "services": {"score": 94, "issues": 1}
  },
  "issues": [
    {
      "category": "hardware",
      "severity": "warning",
      "message": "Hardware acceleration not configured",
      "fix": "usenet hardware optimize --auto"
    }
  ]
}
```

## Examples

::: code-group

```bash [Quick Health Check]
# Basic validation
usenet validate

# Check specific issue
usenet validate --category hardware

# Auto-fix simple issues
usenet validate --fix
```

```bash [Pre-Deployment]
# Comprehensive pre-deployment check
usenet validate --pre-deployment --strict

# Fix all auto-fixable issues
usenet validate --fix --all

# Export readiness report
usenet validate --export deployment-readiness.json
```

```bash [Troubleshooting]
# Diagnose service issues
usenet validate --service jellyfin --verbose

# Get troubleshooting help
usenet validate --troubleshoot "transcoding not working"

# Generate support bundle
usenet validate --support-bundle --include-logs
```

```bash [Monitoring Setup]
# Enable continuous monitoring
usenet validate --monitor --interval 300

# Set up alerting
usenet validate --alert --email admin@example.com

# Schedule regular validation
usenet validate --schedule daily --time 06:00
```

:::

## Integration with Other Commands

### Validation in Deployment

```bash
# Deploy with validation
usenet deploy --validate

# Skip validation (not recommended)
usenet deploy --skip-validation

# Validate after deployment
usenet deploy && usenet validate
```

### Validation in Backup/Restore

```bash
# Validate before backup
usenet backup create --validate

# Validate after restore
usenet backup restore backup.tar.gz --validate

# Include validation in backup metadata
usenet backup create --include-validation
```

## Related Commands

- [`deploy`](./deploy) - Deploy with validation checks
- [`hardware`](./hardware) - Hardware optimization validation
- [`storage`](./storage) - Storage configuration validation
- [`services`](./services) - Service health validation
- [`backup`](./backup) - Configuration backup validation