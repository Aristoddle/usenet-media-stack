---
title: Storage Management
layout: doc
---

# Storage Management

*[Implemented: see main/lib/commands/storage.zsh]*

The storage subsystem manages JBOD (Just a Bunch of Disks) storage pools for the Usenet Media Stack. It provides comprehensive drive management, health monitoring, and automatic Docker Compose integration.

## Overview

The storage CLI handles:
- **Drive Discovery**: Scan and list all mounted storage devices
- **Pool Management**: Add/remove drives from the media storage pool
- **Health Monitoring**: Check disk health with SMART diagnostics
- **Configuration**: Generate Docker Compose bind mounts automatically
- **Interactive Setup**: TUI-driven drive selection interface

## Usage

```bash
usenet storage <action> [options]
```

## Actions

### Core Actions

#### `status`
Show current storage pool configuration and health overview.

```bash
$ usenet storage status
```

**Output includes:**
- Drive count and paths
- Individual drive usage (size, used, available)
- Total pool capacity and utilization
- Media directory mount status
- Health indicators (✓/✗ for each drive)

#### `list`
Discover and catalog all mounted storage devices on the system.

```bash
$ usenet storage list
```

**Features:**
- Filters out system/virtual filesystems
- Identifies drive types (NVMe, SSD, HDD)
- Shows size, filesystem, and availability
- Indicates current pool membership status
- Provides next-step guidance

#### `select`
Interactive TUI for drive pool selection with real-time configuration.

```bash
$ usenet storage select
```

**Interface:**
- Full-screen terminal UI
- Toggle individual drives (1-N)
- Bulk operations (select all/none)
- Live configuration preview
- Automatic service restart option

#### `add <path>`
Add a single drive to the storage pool.

```bash
$ usenet storage add /mnt/disk2
```

**Validation:**
- Verifies directory exists and is accessible
- Checks mount point status (warns if not mounted)
- Prevents duplicate entries
- Updates Docker Compose configuration

#### `remove <path>`
Remove drive from pool (preserves data on disk).

```bash
$ usenet storage remove /mnt/disk2
```

**Safety:**
- Confirms removal operation
- Data remains intact on physical drive
- Updates compose configuration
- Suggests rebalancing remaining drives

#### `health`
Comprehensive health check of all pool drives.

```bash
$ usenet storage health
```

**Diagnostics:**
- Mount point accessibility (read/write)
- SMART status via `smartctl` (if available)
- Drive availability and responsiveness
- Summary health report

#### `apply`
Apply storage configuration changes and restart services.

```bash
$ usenet storage apply
```

**Operations:**
- Regenerates Docker Compose overrides
- Restarts media services with new mounts
- Validates configuration integrity

### Legacy Actions

#### `discover` (deprecated)
Legacy alias for `list`. Displays deprecation warning.

```bash
$ usenet storage discover  # Use 'list' instead
```

### Planned Actions (Not Yet Implemented)

#### `balance`
Rebalance data distribution across available drives.

#### `mount` / `unmount`
Managed mounting/unmounting of all configured drives.

## Options

### Global Options

- `--force, -f`: Force operation without confirmation prompts
- `--verbose, -v`: Show detailed output and diagnostics
- `--dry-run, -n`: Preview changes without executing

*Note: Option support varies by action. Use `--help` with specific actions.*

## Key Workflows

### Initial Storage Setup

1. **Discover available drives:**
   ```bash
   usenet storage list
   ```

2. **Interactive selection (recommended):**
   ```bash
   usenet storage select
   ```
   - Select drives in TUI interface
   - Save and apply configuration
   - Restart services automatically

3. **Verify configuration:**
   ```bash
   usenet storage status
   ```

### Manual Drive Management

1. **Add individual drives:**
   ```bash
   usenet storage add /mnt/disk3
   usenet storage add /mnt/disk4
   ```

2. **Apply configuration:**
   ```bash
   usenet storage apply
   ```

3. **Monitor health:**
   ```bash
   usenet storage health
   ```

### Health Monitoring Routine

```bash
# Quick status check
usenet storage status

# Detailed health analysis
usenet storage health

# Full system discovery (periodic)
usenet storage list
```

## JBOD Architecture

### Storage Pool Concept

The system implements a JBOD (Just a Bunch of Disks) approach:

- **No RAID**: Each drive operates independently
- **Parallel Access**: Media services access all drives simultaneously
- **Content Distribution**: Manual or automatic content spreading
- **Fault Tolerance**: Single drive failure affects only content on that drive

### Mount Point Strategy

**Configuration Pattern:**
```yaml
services:
  sonarr:
    volumes:
      - /mnt/disk1:/tv/drive1:rw
      - /mnt/disk2:/tv/drive2:rw
      - /mnt/disk3:/tv/drive3:rw
  jellyfin:
    volumes:
      - /mnt/disk1:/media/drive1:rw
      - /mnt/disk2:/media/drive2:rw
      - /mnt/disk3:/media/drive3:rw
```

**Service Integration:**
- **Sonarr/Radarr**: Separate `/tv/driveN` and `/movies/driveN` paths
- **Jellyfin**: Unified `/media/driveN` access
- **Tdarr**: All drives available for transcoding
- **Sharing**: Samba/NFS export all pool drives

### Configuration Files

#### `config/storage.conf`
Plain text list of drive paths:
```
# Usenet Media Stack Storage Configuration
# Each line represents a drive in the JBOD pool
/mnt/disk1
/mnt/disk2
/mnt/disk3
```

#### `docker-compose.storage.yml`
Auto-generated Docker Compose override:
```yaml
# Auto-generated JBOD Storage Configuration
services:
  sonarr:
    volumes:
      - /mnt/disk1:/tv/drive1:rw
      - /mnt/disk2:/tv/drive2:rw
  # ... additional services
```

## Examples

### Fresh Installation Setup

```bash
# Discover what's available
$ usenet storage list
○ [1] /mnt/disk1     HDD (ext4) - 4TB total, 3.2TB available
○ [2] /mnt/disk2     HDD (ext4) - 8TB total, 7.9TB available
○ [3] /              SSD (ext4) - 500GB total, 200GB available

# Use interactive selection
$ usenet storage select
# [TUI interface - select disk1 and disk2, skip root]

# Verify configuration
$ usenet storage status
```

### Adding New Drive

```bash
# Mount new drive first (outside of CLI)
sudo mount /dev/sdd1 /mnt/disk4

# Add to pool
$ usenet storage add /mnt/disk4
✓ Added drive to storage pool: /mnt/disk4

# Apply changes
$ usenet storage apply
✓ Services restarted with new storage configuration
```

### Health Check Routine

```bash
$ usenet storage health
Checking: /mnt/disk1
  ✓ Mount point accessible
  ✓ SMART status: PASSED

Checking: /mnt/disk2
  ✓ Mount point accessible
  ⚠ SMART status: CAUTION

✓ 2 of 2 drives operational (1 has warnings)
```

### Removing Failed Drive

```bash
# Remove from pool (data remains on physical drive)
$ usenet storage remove /mnt/disk3
⚠ Removing drive from storage pool: /mnt/disk3
⚠ This will NOT delete data on the drive
Continue with removal? [y/N] y
✓ Removed drive from storage pool: /mnt/disk3

# Restart services
$ usenet storage apply
```

## Important Notes & Caveats

### Prerequisites

- **Pre-mounted drives**: All drives must be mounted before adding to pool
- **Mount point location**: Drives should be in `/mnt/` directory
- **Filesystem compatibility**: ext4, xfs, btrfs, NTFS supported
- **Permissions**: User must have read/write access to mount points

### Limitations

- **No automatic mounting**: System doesn't handle drive mounting
- **No RAID functionality**: Pure JBOD implementation only
- **Balance feature pending**: Content rebalancing not yet implemented
- **Single failure impact**: Failed drive affects only its content

### Best Practices

1. **Regular health checks**: Run `usenet storage health` weekly
2. **SMART monitoring**: Install `smartmontools` for disk health
3. **Backup critical content**: JBOD offers no redundancy
4. **Consistent naming**: Use `/mnt/diskN` pattern for clarity
5. **Test restores**: Verify data accessibility after configuration changes

### Performance Considerations

- **Parallel I/O**: Multiple drives enable concurrent access
- **Drive speed mixing**: Fast drives don't slow down slow ones
- **Network sharing**: All drives available via Samba/NFS
- **Transcoding load**: Tdarr can utilize all drives simultaneously

### Troubleshooting

**Drive not detected:**
- Verify mount status: `mountpoint /mnt/diskN`
- Check permissions: `ls -la /mnt/diskN`
- Review system mounts: `mount | grep /mnt`

**SMART errors:**
- Install smartmontools: `sudo apt install smartmontools`
- Manual check: `sudo smartctl -H /dev/sdX`
- View detailed info: `sudo smartctl -a /dev/sdX`

**Configuration not applying:**
- Check Docker Compose files exist
- Verify service restart: `docker ps`
- Review logs: `docker-compose logs sonarr`

## Related Documentation

- [Hardware Setup](../hardware/): Physical drive configuration
- [Docker Architecture](../architecture/docker.md): Container volume strategy
- [Service Configuration](../getting-started/services.md): Media service setup
