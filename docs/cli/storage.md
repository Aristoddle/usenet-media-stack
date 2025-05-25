# Storage Command

The `storage` command manages hot-swappable JBOD (Just a Bunch of Disks) storage for your media stack. It provides real-time drive detection, dynamic Docker Compose generation, and seamless integration with all 19 services.

## Usage

```bash
usenet storage <action> [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `list` | Discover all available storage devices | `usenet storage list` |
| `add` | Add drive to media pool | `usenet storage add /media/drive` |
| `remove` | Remove drive from pool | `usenet storage remove /media/drive` |
| `sync` | Update service APIs with current pool | `usenet storage sync` |
| `status` | Show current pool configuration | `usenet storage status` |
| `validate` | Check drive health and permissions | `usenet storage validate` |

## Storage Discovery

### List All Available Drives

```bash
usenet storage list
```

**Example output:**
```bash
🗄️ DISCOVERED STORAGE DEVICES:

System Drives (excluded by default):
  [SYS] /                    ZFS (798G total, 598G available)
  [SYS] /boot               EXT4 (512M total, 256M available)

Available Storage:
○ [ 1] /media/external_4tb   HDD (4TB total, 3.8TB available)
○ [ 2] /media/usb_backup     SSD (2TB total, 1.2TB available)
○ [ 3] /home/user/Dropbox    Cloud (3.1TB total, 2.5TB available)
○ [ 4] /home/user/OneDrive   Cloud (2.1TB total, 900GB available)
○ [ 5] /mnt/nas_media        NFS (8TB total, 6.2TB available)
○ [ 6] /srv/jellyfin_cache   ZFS (500GB total, 300GB available)

Current Pool:
● [ACTIVE] /media/external_4tb  (Media storage)
● [ACTIVE] /mnt/nas_media       (Archive storage)

Legend: ○ Available  ● Active  [SYS] System
```

### Supported Storage Types

- **Local drives**: HDD, SSD, NVMe (any filesystem)
- **USB/External**: Hot-pluggable drives with exFAT support
- **Network storage**: NFS, SMB/CIFS, sshfs
- **Cloud mounts**: Dropbox, OneDrive, Google Drive, rclone
- **ZFS/Btrfs**: Advanced filesystem datasets
- **JBOD arrays**: Hardware RAID controllers in JBOD mode

## Managing Storage Pool

### Add Storage to Pool

```bash
# Add single drive
usenet storage add /media/external_4tb

# Add with custom mount point in containers
usenet storage add /media/external_4tb --mount-as /media/storage1

# Add multiple drives interactively
usenet storage add --interactive
```

**Interactive selection:**
```bash
usenet storage add --interactive

🗄️ Select drives to add to media pool:

Available Storage:
○ [ 1] /media/external_4tb   HDD (4TB available)
○ [ 2] /home/user/Dropbox    Cloud (3.1TB available) 
○ [ 3] /mnt/nas_share        NFS (8TB available)

Enter numbers (e.g., 1,3): 1,3

✓ Adding /media/external_4tb to pool
✓ Adding /mnt/nas_share to pool
✓ Generating docker-compose.storage.yml
✓ Updating service configurations
```

### Remove Storage from Pool

```bash
# Remove specific drive
usenet storage remove /media/external_4tb

# Remove with safety check
usenet storage remove /media/external_4tb --check-usage

# Interactive removal
usenet storage remove --interactive
```

## Service Integration

### Sync with Media Services

After changing storage pool, update service APIs:

```bash
usenet storage sync
```

**Services updated:**
- **Sonarr**: Root folders updated with new storage paths
- **Radarr**: Movie libraries updated  
- **Readarr**: Book storage paths configured
- **Jellyfin**: Media libraries rescanned
- **Tdarr**: Transcoding input/output paths updated
- **SABnzbd**: Download directories configured

### Automatic API Updates

Storage changes trigger automatic API synchronization:

```bash
usenet storage add /media/new_drive

🔄 Updating service APIs:
   ✓ Sonarr: Added root folder /media/new_drive/tv
   ✓ Radarr: Added root folder /media/new_drive/movies  
   ✓ Readarr: Added root folder /media/new_drive/books
   ✓ Jellyfin: Scanning new libraries
   ✓ All services updated successfully
```

## Storage Configuration

### Current Pool Status

```bash
usenet storage status
```

**Example output:**
```bash
📊 STORAGE POOL STATUS

Active Storage (2 drives, 12TB total):
● /media/external_4tb
  └─ Mounted in services as: /media/storage1
  └─ Available: 3.8TB / 4TB (95%)
  └─ Usage: Movies, TV Shows
  
● /mnt/nas_media  
  └─ Mounted in services as: /media/storage2
  └─ Available: 6.2TB / 8TB (77%)
  └─ Usage: Archive, Books, Music

Service Integration:
✓ Sonarr: 2 root folders configured
✓ Radarr: 2 root folders configured  
✓ Jellyfin: 4 libraries configured
✓ Tdarr: Input/output paths updated

Generated Files:
✓ docker-compose.storage.yml (2 mounts)
✓ config/storage.conf (current configuration)
```

### Storage Health Check

```bash
usenet storage validate
```

**Validation checks:**
- Drive accessibility and permissions
- Filesystem health and free space
- Service API connectivity
- Docker mount configuration
- Cross-platform compatibility (exFAT)

## Hot-Swap Workflow

### Adding New Drive

1. **Physical connection**: Plug in USB drive or mount network share
2. **Detection**: `usenet storage list` shows new drive
3. **Addition**: `usenet storage add /media/new_drive`
4. **API sync**: Automatic service API updates
5. **Verification**: `usenet storage status` confirms integration

### Removing Drive Safely

1. **Usage check**: `usenet storage remove /path --check-usage`
2. **Service update**: APIs updated to remove references
3. **Docker update**: Mount removed from compose files
4. **Physical removal**: Safe to disconnect drive

## Configuration Files

### Generated Storage Configuration

**docker-compose.storage.yml:**
```yaml
# Auto-generated storage mounts
services:
  sonarr:
    volumes:
      - /media/external_4tb:/media/storage1:rw
      - /mnt/nas_media:/media/storage2:rw
      
  radarr:
    volumes:
      - /media/external_4tb:/media/storage1:rw
      - /mnt/nas_media:/media/storage2:rw
      
  jellyfin:
    volumes:
      - /media/external_4tb:/media/storage1:ro
      - /mnt/nas_media:/media/storage2:ro
```

**config/storage.conf:**
```bash
# Current storage pool configuration
STORAGE_POOL_COUNT=2
STORAGE_1_PATH="/media/external_4tb"
STORAGE_1_MOUNT="/media/storage1" 
STORAGE_1_ACCESS="rw"
STORAGE_2_PATH="/mnt/nas_media"
STORAGE_2_MOUNT="/media/storage2"
STORAGE_2_ACCESS="rw"
```

## Advanced Features

### Custom Mount Points

```bash
# Mount drive at specific container path
usenet storage add /media/drive --mount-as /media/archive

# Multiple mount points for same drive
usenet storage add /media/drive \
  --mount-as /media/tv:/media/drive/tv \
  --mount-as /media/movies:/media/drive/movies
```

### Read-Only Mounts

```bash
# Add drive as read-only for safety
usenet storage add /media/archive --read-only

# Mixed permissions
usenet storage add /media/drive \
  --read-write-for sonarr,radarr \
  --read-only-for jellyfin,tdarr
```

### Cloud Storage Integration

```bash
# Add cloud storage with special handling
usenet storage add /home/user/Dropbox \
  --type cloud \
  --sync-interval 300 \
  --cache-mode minimal
```

## Examples

::: code-group

```bash [Basic Hot-Swap]
# Discover available drives
usenet storage list

# Add external USB drive
usenet storage add /media/usb_4tb

# Services automatically updated
# ✓ All 19 services can access new storage
```

```bash [Multi-Drive Setup]
# Add multiple drives for different purposes
usenet storage add /media/fast_ssd --mount-as /media/cache
usenet storage add /media/archive_hdd --mount-as /media/archive  
usenet storage add /mnt/nas --mount-as /media/network

# Verify configuration
usenet storage status
```

```bash [Cloud Integration]
# Mount cloud storage for backup
rclone mount gdrive: /mnt/gdrive &
usenet storage add /mnt/gdrive --read-only

# Sync APIs with new cloud storage
usenet storage sync
```

```bash [JBOD Array Management]
# Add entire JBOD array
for drive in /media/jbod_{1..8}; do
  usenet storage add "$drive" --mount-as "/media/jbod/$(basename "$drive")"
done

# Validate all drives
usenet storage validate
```

:::

## Troubleshooting

### Common Issues

**Drive not detected:**
```bash
# Check if drive is mounted
lsblk
mount | grep /media

# Refresh detection
usenet storage list --refresh
```

**Permission denied:**
```bash
# Fix permissions for all users
sudo chmod -R 755 /media/external_drive
sudo chown -R 1000:1000 /media/external_drive

# Validate permissions
usenet storage validate
```

**API sync failures:**
```bash
# Check service status
usenet services status sonarr radarr

# Force API resync  
usenet storage sync --force

# Debug API connections
usenet storage sync --verbose
```

### Storage Logs

```bash
# View storage operation logs
usenet logs storage

# Debug storage discovery
usenet storage list --debug

# Monitor hot-swap events
usenet storage monitor
```

## Cross-Platform Compatibility

### ExFAT for Portability

For drives that need to work across Windows/macOS/Linux:

```bash
# Format drive as exFAT
sudo mkfs.exfat /dev/sdX1

# Mount with proper permissions
sudo mount -t exfat /dev/sdX1 /media/portable \
  -o uid=1000,gid=1000,dmask=022,fmask=133
```

### Windows Integration

```bash
# Add SMB/CIFS share
sudo mkdir /mnt/windows_share
sudo mount -t cifs //192.168.1.100/Media /mnt/windows_share \
  -o username=user,password=pass,uid=1000,gid=1000

usenet storage add /mnt/windows_share
```

## Related Commands

- [`deploy`](./deploy) - Include storage configuration in deployment
- [`hardware`](./hardware) - Optimize transcoding with storage layout
- [`backup`](./backup) - Backup storage configuration
- [`validate`](./validate) - Storage health checks