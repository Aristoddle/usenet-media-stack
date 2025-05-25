# Backup Command

The `backup` command provides intelligent configuration backup and restore capabilities with JSON metadata, atomic operations, and disaster recovery features. Backups are config-only by default to prevent massive file sizes.

## Usage

```bash
usenet backup <action> [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `create` | Create new backup with metadata | `usenet backup create` |
| `list` | Show all available backups | `usenet backup list` |
| `show` | Display backup contents and metadata | `usenet backup show backup.tar.gz` |
| `restore` | Restore from backup with verification | `usenet backup restore backup.tar.gz` |
| `verify` | Validate backup integrity | `usenet backup verify backup.tar.gz` |
| `cleanup` | Remove old backups based on policy | `usenet backup cleanup` |

## Creating Backups

### Basic Backup Creation

```bash
# Create backup with auto-generated filename
usenet backup create

# Create backup with custom name
usenet backup create --name "pre-upgrade-backup"

# Create to specific location
usenet backup create --output /path/to/backup.tar.gz
```

**Example output:**
```bash
📦 Creating configuration backup...

🔍 Scanning configuration:
   ✓ .env file (credentials and settings)
   ✓ docker-compose.yml files (3 files)
   ✓ config/ directory (19 service configs)
   ✓ scripts/ directory (management tools)
   ✓ Generated files (storage.conf, hardware_profile.conf)

📊 Backup statistics:
   • Files: 247 configuration files
   • Size: 4.2MB compressed
   • Excluded: Media files, downloads, logs (saved 1.2TB)

💾 Creating backup archive:
   ✓ Compressing configuration files
   ✓ Generating JSON metadata
   ✓ Calculating checksums
   ✓ Creating atomic backup

✅ Backup created: backups/usenet-stack-2024-01-15_143022.tar.gz

📋 Backup metadata:
   • Created: 2024-01-15 14:30:22 UTC
   • System: AMD Ryzen 7 7840HS, 30GB RAM
   • Services: 19 running (sonarr, radarr, jellyfin, ...)
   • Storage: 2 drives (12TB total)
   • Git: main@91f4c34 (clean)
```

### Backup Options

```bash
# Include media metadata (but not files)
usenet backup create --include-metadata

# Create compressed backup (default)
usenet backup create --compress

# Create uncompressed backup
usenet backup create --no-compress

# Include service logs
usenet backup create --include-logs

# Full backup including downloads (WARNING: Large!)
usenet backup create --include-media --include-downloads
```

## Listing Backups

### Show All Backups

```bash
usenet backup list
```

**Example output:**
```bash
📋 AVAILABLE BACKUPS

Recent backups:
● usenet-stack-2024-01-15_143022.tar.gz (4.2MB)
  └─ Created: 2024-01-15 14:30:22 UTC (2 hours ago)
  └─ System: AMD Ryzen 7 7840HS, 30GB RAM  
  └─ Services: 19 running, GPU optimized
  └─ Git: main@91f4c34 (clean)

● usenet-stack-2024-01-14_092156.tar.gz (3.8MB)
  └─ Created: 2024-01-14 09:21:56 UTC (1 day ago)
  └─ System: AMD Ryzen 7 7840HS, 30GB RAM
  └─ Services: 17 running, validation passed
  └─ Git: main@ac38576 (clean)

● usenet-stack-2024-01-10_201543.tar.gz (3.1MB)
  └─ Created: 2024-01-10 20:15:43 UTC (5 days ago)
  └─ System: AMD Ryzen 7 7840HS, 30GB RAM
  └─ Services: 15 running, basic config
  └─ Git: feature/cli-refactor@efdfae9 (modified)

Legend: ● Valid backup  ⚠ Warning  ❌ Corrupted
```

### Backup Details

```bash
# Show detailed backup information
usenet backup list --detailed

# Filter by date range
usenet backup list --since "7 days ago"

# Show backup sizes
usenet backup list --show-size

# Sort by creation date
usenet backup list --sort date
```

## Viewing Backup Contents

### Show Backup Metadata

```bash
usenet backup show backups/usenet-stack-2024-01-15_143022.tar.gz
```

**Example output:**
```bash
📦 BACKUP DETAILS: usenet-stack-2024-01-15_143022.tar.gz

📊 Backup Information:
   • Created: 2024-01-15 14:30:22 UTC
   • Size: 4.2MB compressed, 18.7MB uncompressed
   • Compression: gzip (77% reduction)
   • Checksum: sha256:a1b2c3d4e5f6...

🖥️ System Information:
   • OS: Ubuntu 22.04.3 LTS
   • Kernel: 6.5.0-41-generic
   • CPU: AMD Ryzen 7 7840HS (16 threads)
   • RAM: 30GB total, 24GB available
   • GPU: AMD Radeon 780M (VAAPI)

🐳 Docker Environment:
   • Docker: 24.0.7
   • Compose: 2.21.0
   • Runtime: runc
   • Storage Driver: overlay2

📂 Backup Contents (247 files):
   ✓ .env (credentials and configuration)
   ✓ docker-compose.yml (base configuration)
   ✓ docker-compose.optimized.yml (hardware config)
   ✓ docker-compose.storage.yml (storage mounts)
   ✓ config/ (19 service configurations)
     ├─ sonarr/ (quality profiles, indexers)
     ├─ radarr/ (custom formats, lists)
     ├─ prowlarr/ (indexer configurations)
     ├─ jellyfin/ (transcoding settings)
     └─ ... (15 more services)
   ✓ scripts/ (management and utility scripts)
   ✓ completions/ (CLI completion files)

🔧 Services Configuration (19 services):
   ✓ sonarr: Running, API configured, 3 root folders
   ✓ radarr: Running, API configured, 2 root folders  
   ✓ jellyfin: Running, GPU transcoding enabled
   ✓ prowlarr: Running, 12 indexers configured
   ✓ tdarr: Running, GPU acceleration enabled
   ... (14 more services)

💾 Storage Configuration:
   ✓ Pool: 2 drives (12TB total, 8.4TB available)
   ✓ /media/external_4tb (Movies, TV)
   ✓ /mnt/nas_media (Archive, Books)

🔗 Git Repository:
   • Branch: main
   • Commit: 91f4c34 (Add intelligent resource optimization)
   • Status: Clean working directory
   • Remote: origin (authenticated)

🔐 Security:
   • API Keys: ✓ Present (redacted in backup)
   • Certificates: ✓ Present
   • SSH Keys: ✗ Not included (security)
```

### List Backup Contents

```bash
# List all files in backup
usenet backup show backup.tar.gz --list-files

# Show configuration diff
usenet backup show backup.tar.gz --diff

# Extract specific file
usenet backup show backup.tar.gz --extract config/sonarr/config.xml
```

## Restoring Backups

### Basic Restore

```bash
# Restore latest backup
usenet backup restore

# Restore specific backup
usenet backup restore backups/usenet-stack-2024-01-15_143022.tar.gz

# Restore with confirmation prompts
usenet backup restore backup.tar.gz --interactive
```

**Example restore process:**
```bash
🔄 RESTORING BACKUP: usenet-stack-2024-01-15_143022.tar.gz

⚠️  Pre-restore safety checks:
   • Current configuration will be backed up
   • Services will be stopped during restore
   • Restore is atomic (all-or-nothing)

🔍 Backup verification:
   ✓ Backup integrity verified (checksum match)
   ✓ Compatible with current system
   ✓ All required files present

💾 Creating safety backup:
   ✓ Current config saved: backups/pre-restore-2024-01-15_143545.tar.gz

🛑 Stopping services:
   ✓ Stopping 19 services gracefully
   ✓ All containers stopped

🔄 Restoring configuration:
   ✓ Extracting backup archive
   ✓ Restoring .env file
   ✓ Restoring docker-compose files
   ✓ Restoring service configurations
   ✓ Restoring scripts and completions
   ✓ Setting proper permissions

🔧 Post-restore validation:
   ✓ Configuration syntax valid
   ✓ Service definitions correct
   ✓ Storage paths accessible
   ✓ All dependencies satisfied

🚀 Starting services:
   ✓ Starting 19 services
   ✓ Waiting for health checks
   ✓ All services running healthy

✅ Restore completed successfully!

📊 Restore summary:
   • Files restored: 247
   • Services: 19/19 running
   • Total time: 3m 42s
   • Rollback available: pre-restore-2024-01-15_143545.tar.gz
```

### Restore Options

```bash
# Dry run (show what would be restored)
usenet backup restore backup.tar.gz --dry-run

# Restore only specific components
usenet backup restore backup.tar.gz --only config,scripts

# Skip service restart
usenet backup restore backup.tar.gz --no-restart

# Force restore (skip compatibility checks)
usenet backup restore backup.tar.gz --force
```

### Selective Restore

```bash
# Restore only service configurations
usenet backup restore backup.tar.gz --services sonarr,radarr

# Restore environment but keep current service configs
usenet backup restore backup.tar.gz --env-only

# Restore scripts and completions only
usenet backup restore backup.tar.gz --scripts-only
```

## Backup Verification

### Verify Backup Integrity

```bash
usenet backup verify backup.tar.gz
```

**Verification checks:**
- Archive integrity (no corruption)
- Checksum validation
- Required files present
- Configuration syntax valid
- Compatibility with current system

### Automated Verification

```bash
# Verify all backups
usenet backup verify --all

# Verify and repair if possible
usenet backup verify backup.tar.gz --repair

# Schedule automatic verification
usenet backup verify --schedule daily
```

## Backup Management

### Cleanup Old Backups

```bash
# Remove backups older than 30 days
usenet backup cleanup --older-than 30d

# Keep only latest 10 backups
usenet backup cleanup --keep 10

# Interactive cleanup
usenet backup cleanup --interactive
```

### Backup Policies

```bash
# Set automatic backup schedule
usenet backup schedule --daily --time 02:00

# Set retention policy
usenet backup policy --keep-daily 7 --keep-weekly 4 --keep-monthly 12

# Disable automatic backups
usenet backup schedule --disable
```

## Advanced Features

### Backup Encryption

```bash
# Create encrypted backup
usenet backup create --encrypt --password-file /path/to/key

# Restore encrypted backup
usenet backup restore backup.tar.gz.enc --decrypt
```

### Remote Backup Storage

```bash
# Backup to cloud storage
usenet backup create --remote s3://my-bucket/backups/

# Backup to network location
usenet backup create --remote user@server:/backups/

# List remote backups
usenet backup list --remote s3://my-bucket/backups/
```

### Differential Backups

```bash
# Create incremental backup
usenet backup create --incremental --base backup-full.tar.gz

# Create differential backup
usenet backup create --differential --since "7 days ago"
```

## Backup Metadata

### JSON Metadata Format

Each backup includes detailed metadata:

```json
{
  "backup": {
    "version": "2.0",
    "created": "2024-01-15T14:30:22.123Z",
    "name": "usenet-stack-2024-01-15_143022",
    "size": {
      "compressed": 4426752,
      "uncompressed": 19612160,
      "compression_ratio": 0.77
    },
    "checksum": {
      "algorithm": "sha256",
      "value": "a1b2c3d4e5f6789..."
    }
  },
  "system": {
    "os": "Ubuntu 22.04.3 LTS",
    "kernel": "6.5.0-41-generic",
    "architecture": "x86_64",
    "cpu": "AMD Ryzen 7 7840HS",
    "memory": "30GB",
    "gpu": "AMD Radeon 780M"
  },
  "docker": {
    "version": "24.0.7",
    "compose_version": "2.21.0",
    "storage_driver": "overlay2"
  },
  "services": {
    "total": 19,
    "running": 19,
    "services": [
      {"name": "sonarr", "status": "running", "version": "3.0.10"},
      {"name": "radarr", "status": "running", "version": "4.7.5"}
    ]
  },
  "storage": {
    "drives": 2,
    "total_capacity": "12TB",
    "available": "8.4TB"
  },
  "git": {
    "branch": "main",
    "commit": "91f4c34",
    "status": "clean",
    "remote": "origin"
  }
}
```

## Examples

::: code-group

```bash [Regular Backup Workflow]
# Create daily backup
usenet backup create --name "daily-$(date +%Y%m%d)"

# List recent backups
usenet backup list --since "7 days ago"

# Verify backup integrity
usenet backup verify latest

# Cleanup old backups
usenet backup cleanup --keep 30
```

```bash [Pre-Upgrade Backup]
# Create backup before major changes
usenet backup create --name "pre-hardware-upgrade" \
  --include-metadata \
  --compress

# Show backup details
usenet backup show pre-hardware-upgrade.tar.gz

# After upgrade, restore if needed
usenet backup restore pre-hardware-upgrade.tar.gz
```

```bash [Disaster Recovery]
# Create full disaster recovery backup
usenet backup create --name "disaster-recovery" \
  --include-logs \
  --include-metadata \
  --encrypt

# Store in multiple locations
cp backup.tar.gz.enc /mnt/backup/
scp backup.tar.gz.enc user@remote:/backups/

# Test restore process
usenet backup restore disaster-recovery.tar.gz.enc --dry-run
```

```bash [Automated Backup System]
# Set up daily automated backups
usenet backup schedule --daily --time 02:00

# Configure retention policy
usenet backup policy \
  --keep-daily 7 \
  --keep-weekly 4 \
  --keep-monthly 12

# Set up remote storage
usenet backup configure --remote s3://my-backup-bucket/

# Test automation
usenet backup schedule --test
```

:::

## Troubleshooting

### Common Issues

**Backup too large:**
```bash
# Check what's being included
usenet backup create --dry-run --verbose

# Exclude large directories
usenet backup create --exclude downloads,media

# Use config-only backup
usenet backup create --config-only
```

**Restore failures:**
```bash
# Check backup integrity
usenet backup verify backup.tar.gz

# Try selective restore
usenet backup restore backup.tar.gz --env-only

# Force restore with warnings
usenet backup restore backup.tar.gz --force
```

**Permission issues:**
```bash
# Fix backup permissions
sudo chown -R $USER:$USER backups/

# Restore with sudo if needed
sudo usenet backup restore backup.tar.gz
```

### Backup Logs

```bash
# View backup operation logs
usenet logs backup

# Debug backup creation
usenet backup create --verbose --debug

# Monitor backup progress
usenet backup create --progress
```

## Security Considerations

### What's Included

**✅ Included in backups:**
- Service configurations
- Docker Compose files
- Environment variables (credentials)
- Generated optimization files
- Scripts and completions
- Git repository metadata

**❌ Excluded by default:**
- Media files (movies, TV shows, music)
- Download files (incomplete/complete)
- Service logs (can be included with `--include-logs`)
- Docker images and containers
- Temporary files and caches

### Credential Handling

```bash
# Backups include API keys and passwords
# Store backups securely!

# Create encrypted backup for sensitive data
usenet backup create --encrypt

# Redact credentials from backup listing
usenet backup show backup.tar.gz --redact-secrets
```

## Related Commands

- [`deploy`](./deploy) - Deploy from backup configuration
- [`validate`](./validate) - Validate backup integrity
- [`services`](./services) - Service management during backup/restore