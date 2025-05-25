# Hot-Swap Workflows

> **Advanced hot-swappable JBOD workflows for dynamic storage management without service interruption.**

## Overview

The hot-swap system allows you to add/remove drives while services continue running, perfect for:
- Portable camping setups with external drives
- Expanding storage capacity on demand  
- Rotating archive drives for off-site backup
- Testing different storage configurations

## Quick Hot-Swap Workflow

```bash
# 1. Plug in new drive (auto-detected)
./usenet storage list

# 2. Add to pool
./usenet storage add /media/external-drive

# 3. Update service APIs
./usenet storage sync

# 4. Verify access
./usenet storage status
```

Services continue running throughout this process with zero downtime.

## Advanced Workflows

### Camping/Travel Setup
```bash
# Before trip: prepare portable drive
./usenet storage prepare /media/camping-drive --profile travel

# At campsite: plug in and activate
./usenet storage add /media/camping-drive --temporary
./usenet storage sync --fast
```

### Archive Rotation
```bash
# Monthly archive process
./usenet storage archive --older-than 6months /media/archive-drive
./usenet storage remove /media/old-archive --safe-eject
```

## API Integration

The hot-swap system automatically updates:
- Sonarr root folders
- Radarr movie paths
- Readarr book libraries
- Jellyfin media libraries
- YACReader comic paths

All services receive real-time updates about storage changes.