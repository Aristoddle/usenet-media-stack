# Media Server Post-Migration Plan

**Version**: 1.0.0
**Created**: 2025-12-24
**Status**: Production Ready
**Host**: Minisforum SER7 Pro (Bazzite Linux)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Hardware Topology](#2-hardware-topology)
3. [Pre-Migration Checklist](#3-pre-migration-checklist)
4. [Phase 1: Drive Rename](#4-phase-1-drive-rename)
5. [Phase 2: mergerfs Installation](#5-phase-2-mergerfs-installation)
6. [Phase 3: Pool Configuration](#6-phase-3-pool-configuration)
7. [Phase 4: Symlink Setup](#7-phase-4-symlink-setup)
8. [Phase 5: Docker Integration](#8-phase-5-docker-integration)
9. [Phase 6: *arr Stack Reconfiguration](#9-phase-6-arr-stack-reconfiguration)
10. [Phase 7: Plex Configuration](#10-phase-7-plex-configuration)
11. [Phase 8: Validation Testing](#11-phase-8-validation-testing)
12. [Phase 9: Media Remediation](#12-phase-9-media-remediation)
13. [Rollback Procedures](#13-rollback-procedures)
14. [Maintenance Runbook](#14-maintenance-runbook)
15. [References](#15-references)

---

## 1. Executive Summary

### What We Are Building

A unified media server infrastructure using **mergerfs** to pool 8 external NVMe drives (across two OWC Thunderbolt 3 bays) into a single logical mount at `/mnt/pool/`. The internal 8TB drive remains the primary orchestration point, with symlinks providing transparent access to the pooled storage.

### Why This Architecture

| Decision | Rationale |
|----------|-----------|
| **mergerfs over btrfs RAID** | Hot-swap safe, no single-drive blast radius, 100% usable capacity |
| **No backups for media** | Re-acquire strategy via Usenet; configs backed up separately |
| **Internal symlinks to pool** | Docker containers see stable paths; pool membership can change |
| **epmfs policy** | Keeps TV series together on same drive; fills most-free-space first |
| **Individual btrfs per drive** | Per-drive compression, integrity checking, easy replacement |

### Key Benefits

- **Graceful degradation**: One drive failure affects only that drive's content
- **Hot-swap capable**: Replace drives without rebuilding arrays
- **Full capacity**: No RAID overhead; 48TB raw = 48TB usable
- **Path stability**: Applications reference `/var/mnt/fast8tb/Local/media/*` regardless of pool changes

---

## 2. Hardware Topology

### System Overview

```
+------------------------------------------------------------------+
|                    MINISFORUM SER7 PRO                           |
|                  AMD Ryzen 7 7840HS | 96GB RAM                   |
|                      Bazzite Linux (Fedora 43)                   |
+------------------------------------------------------------------+
                               |
            +------------------+------------------+
            |                                     |
    [Internal NVMe]                    [2x Thunderbolt 3 Ports]
            |                                     |
    +---------------+              +--------------+--------------+
    | Fast_8TB_Ser7 |              |                             |
    | 8TB WD Black  |         [OWC Bay 1]                  [OWC Bay 2]
    | SN850X        |         4-slot NVMe                  4-slot NVMe
    | /var/mnt/     |              |                             |
    | fast8tb       |              |                             |
    +---------------+   +----------+----------+     +------------+------------+
                        |    |    |    |      |     |      |      |      |
                      Slot Slot Slot Slot   Slot  Slot   Slot   Slot
                        1    2    3    4      1     2      3      4
                        |    |    |    |      |     |      |      |
                       4TB  8TB  8TB  8TB    4TB   4TB    4TB    4TB
                        |    |    |    |      |     |      |      |
                        v    v    v    v      v     v      v      v
                      +-----------------------------------------+
                      |          /mnt/pool/ (mergerfs)          |
                      |  movies/ | tv/ | anime/ | music/ | ...  |
                      +-----------------------------------------+
```

### Current Drive Inventory

| Label | Size | Location | UUID | Filesystem | Status |
|-------|------|----------|------|------------|--------|
| Fast_8TB_Ser7 | 8TB | Internal | `51629375-7bfb-4838-8b00-640ff252da8c` | btrfs | Primary/Orchestrator |
| Fast_8TB_1 | 8TB | Bay 1, Slot 2 | `343c875a-db0f-4dd1-a518-c788da92dd1d` | btrfs | Pool Member |
| Fast_8TB_2 | 8TB | Bay 1, Slot 3 | `a7887ab8-8746-46b9-9bc8-5e2c0a6660fa` | btrfs | Pool Member |
| Fast_8TB_3 | 8TB | Bay 1, Slot 4 | `f59d7c64-b6ff-4e35-9529-b0dc1f03c47b` | btrfs | Pool Member |
| Fast_4TB_1 | 4TB | Bay 2, Slot 1 | `9DD4-58F0` | exfat | Pending Migration |
| Fast_4TB_2 | 4TB | Bay 2, Slot 2 | `65EF-A474` | exfat | Pending Migration |
| Fast_4TB_3 | 4TB | Bay 1, Slot 1 | `e6eb37fe-788e-4d9d-8e89-dd0911737f4e` | btrfs | Pool Member |
| Fast_4TB_4 | 4TB | Bay 2, Slot 3 | `65EF-A09F` | exfat | Pending Migration |
| Fast_4TB_5 | 4TB | Bay 2, Slot 4 | `E333-31B8` | exfat | Pending Migration |

> **Note**: exFAT drives do not support hardlinks and must be migrated to btrfs before pool integration.

### Post-Migration Rename Mapping

The logical naming follows slot order for intuitive identification:

| Current Physical Location | Target Label |
|---------------------------|--------------|
| Bay 2, Slot 1 | Fast_4TB_1 |
| Bay 2, Slot 2 | Fast_4TB_2 |
| Bay 2, Slot 3 | Fast_4TB_3 |
| Bay 2, Slot 4 | Fast_4TB_4 |
| Bay 1, Slot 1 | Fast_4TB_5 |
| Bay 1, Slot 2 | Fast_8TB_1 |
| Bay 1, Slot 3 | Fast_8TB_2 |
| Bay 1, Slot 4 | Fast_8TB_3 |
| Internal | Fast_8TB_Ser7 (unchanged) |

---

## 3. Pre-Migration Checklist

Complete ALL items before proceeding to Phase 1.

### 3.1 Drive Migration Status

```bash
# Verify all drives are btrfs (required for hardlinks)
lsblk -f | grep -E 'nvme[0-9]n1p[12]' | awk '{print $1, $2}'

# Expected output: all drives should show "btrfs"
# Any showing "exfat" require migration first
```

**Acceptance Criteria**:
- [ ] All 8 external drives formatted as btrfs
- [ ] All drives mounted and accessible
- [ ] No active file transfers in progress

### 3.2 Active Downloads

```bash
# Check SABnzbd queue
curl -s "http://192.168.6.167:8080/api?mode=queue&apikey=YOUR_API_KEY&output=json" | jq '.queue.slots | length'

# Check Transmission
transmission-remote 127.0.0.1:9091 -l | tail -n +2 | head -n -1 | wc -l
```

**Acceptance Criteria**:
- [ ] SABnzbd queue empty OR only completed items
- [ ] Transmission no active torrents OR paused
- [ ] No imports pending in Radarr/Sonarr activity queues

### 3.3 Docker Stack State

```bash
# Save current container state
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" > /tmp/container-state-pre-migration.txt

# Verify all containers healthy
docker ps --filter "health=unhealthy" --format "{{.Names}}"
```

**Acceptance Criteria**:
- [ ] All containers running (except intentionally stopped ones)
- [ ] No unhealthy containers
- [ ] Container state documented

### 3.4 Disk Space Verification

```bash
# Check each drive has sufficient free space for pool operations
for mount in /run/media/deck/Fast_*; do
  echo "=== $mount ==="
  df -h "$mount" | tail -1 | awk '{print "Used: " $3 " / " $2 " (" $5 " full)"}'
done
```

**Acceptance Criteria**:
- [ ] Each pool-member drive has at least 50GB free (for mergerfs minfreespace)
- [ ] Internal drive has at least 100GB free for temporary operations

### 3.5 Backup Verification

```bash
# Verify config backup exists
ls -la /var/mnt/fast8tb/config/

# Check critical configs are backed up to OneDrive
ls -la "/var/mnt/fast8tb/Cloud/OneDrive/Backups/" 2>/dev/null || echo "OneDrive backup location not found"
```

**Acceptance Criteria**:
- [ ] Docker config directory backed up
- [ ] Plex database location known and backed up
- [ ] *arr application databases backed up

---

## 4. Phase 1: Drive Rename

### 4.1 Why Rename Drives

Logical slot-order naming provides:
- Intuitive identification during maintenance
- Consistent labeling regardless of physical cable order
- Clear mapping between bays and drive purposes

### 4.2 Rename Procedure

> **IMPORTANT**: Drives must be unmounted before relabeling. Perform during maintenance window.

```bash
# Step 1: Stop Docker stack
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack
docker compose -p media-main down
docker compose -f docker-compose.reading.yml -p media-reading down

# Step 2: Unmount all external drives
for mount in /run/media/deck/Fast_*; do
  sudo umount "$mount" 2>/dev/null || echo "Already unmounted: $mount"
done

# Step 3: Identify drives by current label (get device paths)
# Example: Find the drive currently labeled Fast_4TB_1
lsblk -o NAME,LABEL,UUID | grep Fast
```

#### Relabel Each btrfs Drive

```bash
# Syntax: btrfs filesystem label <device> <new-label>
# Example for a 4TB drive that should become Fast_4TB_1:

# CRITICAL: Verify you have the correct device before running!
# Double-check UUID against the inventory table above

sudo btrfs filesystem label /dev/nvme8n1p1 "Fast_4TB_1"
sudo btrfs filesystem label /dev/nvme2n1p2 "Fast_4TB_2"
sudo btrfs filesystem label /dev/nvme6n1p2 "Fast_4TB_3"
sudo btrfs filesystem label /dev/nvme7n1p1 "Fast_4TB_4"
sudo btrfs filesystem label /dev/nvme9n1p2 "Fast_4TB_5"
sudo btrfs filesystem label /dev/nvme4n1p2 "Fast_8TB_1"
sudo btrfs filesystem label /dev/nvme5n1p2 "Fast_8TB_2"
sudo btrfs filesystem label /dev/nvme3n1p2 "Fast_8TB_3"
```

### 4.3 Validation

```bash
# Verify all labels applied correctly
blkid | grep -E 'Fast_[48]TB' | sort

# Expected output should show logical naming:
# Fast_4TB_1, Fast_4TB_2, ..., Fast_4TB_5
# Fast_8TB_1, Fast_8TB_2, Fast_8TB_3
# Fast_8TB_Ser7 (internal, unchanged)
```

**Success Criteria**:
- [ ] All 8 external drives relabeled
- [ ] `blkid` output shows correct labels
- [ ] No duplicate labels exist

---

## 5. Phase 2: mergerfs Installation

### 5.1 Why mergerfs

mergerfs is a FUSE-based union filesystem that presents multiple directories as a single merged view. Unlike traditional RAID:

- **No rebuild time**: Drive failures don't trigger rebuilds
- **100% capacity**: No parity overhead
- **Hot-swap**: Add/remove drives without downtime
- **Path preservation**: Files stay on their original drive

Reference: [mergerfs GitHub](https://github.com/trapexit/mergerfs) | [Perfect Media Server Guide](https://perfectmediaserver.com/02-tech-stack/mergerfs/)

### 5.2 Installation on Bazzite (rpm-ostree)

Bazzite uses an immutable filesystem. Packages must be "layered" via rpm-ostree.

Reference: [Bazzite rpm-ostree Documentation](https://docs.bazzite.gg/Installing_and_Managing_Software/rpm-ostree/)

```bash
# Step 1: Install mergerfs (requires reboot)
sudo rpm-ostree install mergerfs

# Step 2: Verify staged for next boot
rpm-ostree status

# Expected: Shows "Staged" with mergerfs in package list
```

### 5.3 Reboot Sequence

```bash
# Step 1: Initiate reboot
sudo systemctl reboot

# After reboot:

# Step 2: Verify mergerfs installed
which mergerfs
mergerfs --version

# Expected output: mergerfs version X.Y.Z
```

### 5.4 Post-Reboot Validation

```bash
# Verify rpm-ostree layer applied
rpm-ostree status | grep -A5 "LayeredPackages"

# Confirm mergerfs binary available
mergerfs -h | head -5
```

**Success Criteria**:
- [ ] mergerfs command available
- [ ] rpm-ostree status shows mergerfs layered
- [ ] No errors during reboot

---

## 6. Phase 3: Pool Configuration

### 6.1 Create Pool Mount Points

```bash
# Create the pool mount point
sudo mkdir -p /mnt/pool

# Create individual drive mount points under /var/mnt
sudo mkdir -p /var/mnt/pool_drives/{Fast_4TB_{1,2,3,4,5},Fast_8TB_{1,2,3}}

# Set ownership (matches PUID/PGID in docker-compose)
sudo chown -R 1000:1000 /mnt/pool
sudo chown -R 1000:1000 /var/mnt/pool_drives
```

### 6.2 Configure /etc/fstab

> **IMPORTANT**: On Bazzite, edit fstab then run `systemctl daemon-reload`.

Add the following entries to `/etc/fstab`:

```bash
# ==============================================================================
# MEDIA POOL DRIVES (Individual btrfs mounts)
# ==============================================================================
# Each drive mounted individually for management, then merged via mergerfs
# Options explained:
#   noatime       - Don't update access time (performance)
#   lazytime      - Lazy inode timestamp updates (SSD lifespan)
#   compress=zstd - Transparent compression (good for media)
#   ssd           - SSD-specific optimizations
#   discard=async - TRIM in background (SSD lifespan)
#   space_cache=v2 - Modern space cache (performance)
#   nofail        - Don't fail boot if drive missing (hot-swap safety)
#   x-systemd.device-timeout=5 - Fast timeout for missing drives
# ==============================================================================

# 4TB Pool Drives
UUID=<Fast_4TB_1_UUID> /var/mnt/pool_drives/Fast_4TB_1 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0
UUID=<Fast_4TB_2_UUID> /var/mnt/pool_drives/Fast_4TB_2 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0
UUID=<Fast_4TB_3_UUID> /var/mnt/pool_drives/Fast_4TB_3 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0
UUID=<Fast_4TB_4_UUID> /var/mnt/pool_drives/Fast_4TB_4 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0
UUID=<Fast_4TB_5_UUID> /var/mnt/pool_drives/Fast_4TB_5 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0

# 8TB Pool Drives
UUID=343c875a-db0f-4dd1-a518-c788da92dd1d /var/mnt/pool_drives/Fast_8TB_1 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0
UUID=a7887ab8-8746-46b9-9bc8-5e2c0a6660fa /var/mnt/pool_drives/Fast_8TB_2 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0
UUID=f59d7c64-b6ff-4e35-9529-b0dc1f03c47b /var/mnt/pool_drives/Fast_8TB_3 btrfs noatime,lazytime,compress=zstd:1,ssd,discard=async,space_cache=v2,nofail,x-systemd.device-timeout=5 0 0

# ==============================================================================
# MERGERFS POOL
# ==============================================================================
# Options explained:
#   allow_other    - Allow non-root users to access (required for Docker)
#   use_ino        - Use inodes from source filesystems (stability)
#   cache.files=partial - Partial file caching (Plex compatibility)
#   dropcacheonclose=true - Free memory when files close
#   category.create=epmfs - Existing Path, Most Free Space (keeps series together)
#   minfreespace=50G - Don't fill drives below 50GB free
#   fsname=media-pool - Friendly name in mount output
#   moveonenospc=true - Auto-migrate when drive full
#   noforget        - Keep directory cache on disappearing drives (hot-swap)
# ==============================================================================
/var/mnt/pool_drives/* /mnt/pool fuse.mergerfs allow_other,use_ino,cache.files=partial,dropcacheonclose=true,category.create=epmfs,minfreespace=50G,fsname=media-pool,moveonenospc=true,noforget 0 0
```

### 6.3 Populate UUIDs

```bash
# Get UUIDs for each drive and update fstab
blkid | grep Fast_4TB | awk '{print $1, $3}'

# Example output:
# /dev/nvme8n1p1: UUID="xxxx-xxxx-xxxx"
# Copy each UUID into the fstab entries above
```

### 6.4 Apply Configuration

```bash
# Reload systemd to pick up fstab changes
sudo systemctl daemon-reload

# Mount all new entries
sudo mount -a

# Verify mounts
mount | grep -E '(pool_drives|media-pool)'
```

### 6.5 Validation

```bash
# Check individual drives mounted
ls -la /var/mnt/pool_drives/

# Check mergerfs pool mounted
ls -la /mnt/pool/

# Verify pool shows combined capacity
df -h /mnt/pool
```

**Success Criteria**:
- [ ] All 8 individual drives mounted under `/var/mnt/pool_drives/`
- [ ] mergerfs pool mounted at `/mnt/pool/`
- [ ] `df -h /mnt/pool` shows combined capacity (~48TB)

---

## 7. Phase 4: Symlink Setup

### 7.1 Architecture Rationale

Docker containers reference paths on the internal drive (`/var/mnt/fast8tb/`). Symlinks redirect media paths to the pool, enabling:

- Stable paths in Docker volume mappings
- Pool membership changes without Docker reconfiguration
- Internal drive for configs/downloads, pool for media storage

### 7.2 Create Pool Directory Structure

```bash
# Create media directories in pool
sudo mkdir -p /mnt/pool/{movies,tv,anime,music,audiobooks}

# Set ownership
sudo chown -R 1000:1000 /mnt/pool
```

### 7.3 Create Symlinks on Internal Drive

```bash
# Navigate to internal media location
cd /var/mnt/fast8tb/Local

# Remove existing directories (ONLY if empty or migrated)
# DANGER: Verify directories are empty first!
ls -la media/
# If not empty, migrate data to pool first!

# Create symlinks
ln -sfn /mnt/pool/movies /var/mnt/fast8tb/Local/media/movies
ln -sfn /mnt/pool/tv /var/mnt/fast8tb/Local/media/tv
ln -sfn /mnt/pool/anime /var/mnt/fast8tb/Local/media/anime
ln -sfn /mnt/pool/music /var/mnt/fast8tb/Local/media/music
```

### 7.4 Validation

```bash
# Verify symlinks created correctly
ls -la /var/mnt/fast8tb/Local/media/

# Expected output shows symlinks:
# movies -> /mnt/pool/movies
# tv -> /mnt/pool/tv
# etc.

# Test write access
touch /var/mnt/fast8tb/Local/media/movies/test-file
ls /mnt/pool/movies/test-file
rm /mnt/pool/movies/test-file
```

**Success Criteria**:
- [ ] All media symlinks created
- [ ] Symlinks resolve correctly (`readlink -f`)
- [ ] Write test passes
- [ ] Ownership correct (1000:1000)

---

## 8. Phase 5: Docker Integration

### 8.1 Update Environment Variables

Edit `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/.env`:

```bash
# Updated paths for pool integration
CONFIG_ROOT=/var/mnt/fast8tb/config
DOWNLOADS_ROOT=/var/mnt/fast8tb/Local/downloads
MEDIA_ROOT=/var/mnt/fast8tb/Local/media

# Books remain on OneDrive-backed storage
BOOKS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books
COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics

# Music through pool symlink
MUSIC_ROOT=/var/mnt/fast8tb/Local/media/music
```

### 8.2 Volume Mapping Strategy

Reference: [TRaSH Guides Docker Setup](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Docker/) | [Servarr Docker Guide](https://wiki.servarr.com/docker-guide)

The docker-compose.yml uses a consistent path structure:

```yaml
# Downloads and media on same filesystem enables hardlinks
volumes:
  - ${DOWNLOADS_ROOT}:/downloads:rw,z
  - ${MEDIA_ROOT}:/media:rw,z
```

Because both `/downloads` and `/media` resolve to paths on the same logical filesystem (via symlinks to pool), hardlinks work correctly.

### 8.3 Restart Docker Stack

```bash
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack

# Start main stack
docker compose -p media-main up -d

# Start reading stack
docker compose -f docker-compose.reading.yml -p media-reading up -d

# Monitor startup
docker compose -p media-main logs -f --tail=50
```

### 8.4 Validation

```bash
# Verify containers can access pool via symlinks
docker exec radarr ls -la /movies/
docker exec sonarr ls -la /tv/
docker exec plex ls -la /media/movies/

# Test hardlink capability (from download to media)
docker exec radarr touch /downloads/test-hardlink
docker exec radarr ln /downloads/test-hardlink /movies/test-hardlink
docker exec radarr ls -la /movies/test-hardlink
docker exec radarr rm /downloads/test-hardlink /movies/test-hardlink
```

**Success Criteria**:
- [ ] All containers start successfully
- [ ] Containers can list files in media directories
- [ ] Hardlink test passes (no "Invalid cross-device link" error)

---

## 9. Phase 6: *arr Stack Reconfiguration

### 9.1 Root Folder Updates

Access each *arr application and update root folders:

#### Radarr (http://localhost:7878)

1. Navigate to: **Settings > Media Management > Root Folders**
2. Remove old root folders
3. Add: `/movies` (maps to `/var/mnt/fast8tb/Local/media/movies` on host)
4. **Save**

#### Sonarr (http://localhost:8989)

1. Navigate to: **Settings > Media Management > Root Folders**
2. Remove old root folders
3. Add: `/tv` (maps to `/var/mnt/fast8tb/Local/media/tv` on host)
4. **Save**

### 9.2 Download Client Paths

SABnzbd (http://192.168.6.167:8080):

1. Navigate to: **Config > Folders**
2. Verify **Completed Download Folder**: `/downloads/complete`
3. Verify **Incomplete Download Folder**: `/downloads/incomplete`

### 9.3 Remote Path Mappings

Reference: [TRaSH Guides Remote Path Mappings](https://trash-guides.info/Radarr/Radarr-remote-path-mapping/)

If containers see the same paths (which they should with our setup), no remote path mappings are needed. Verify by checking:

1. Radarr/Sonarr: **Settings > Download Clients > (your client) > Test**
2. Should show "Connection successful" with no path mapping errors

### 9.4 Test Import Flow

```bash
# Trigger a manual import test
# 1. Download a small file via SABnzbd
# 2. Watch Radarr/Sonarr logs for import
docker logs -f radarr 2>&1 | grep -i import
```

**Success Criteria**:
- [ ] Root folders configured and showing "green" status
- [ ] Download client connection tests pass
- [ ] Test import completes with hardlink (not copy)

---

## 10. Phase 7: Plex Configuration

### 10.1 Disable Auto Empty Trash

Reference: [Plex Empty Trash Documentation](https://support.plex.tv/articles/200289326-emptying-library-trash/)

**CRITICAL**: This setting must be disabled to prevent data loss during drive swaps.

1. Open Plex Web: http://localhost:32400/web
2. Navigate to: **Settings > Server > Library**
3. **DISABLE**: "Empty trash automatically after every scan"
4. **Save Changes**

**Why**: If a pool drive is temporarily unavailable (hot-swap, maintenance), Plex will see files as "missing" and trash them. With auto-empty enabled, metadata is permanently lost.

### 10.2 Update Library Paths

1. **Settings > Manage > Libraries**
2. For each library (Movies, TV Shows, etc.):
   - **Edit Library > Add Folders**
   - Ensure paths point to: `/media/movies`, `/media/tv`, etc.
   - Remove any stale paths pointing to individual drives

### 10.3 Optimize Plex for Pool

1. **Settings > Server > Library**:
   - Enable: "Scan my library periodically" (recommended: 6 hours)
   - Enable: "Run scanner tasks at a lower priority"
   - Enable: "Generate video preview thumbnails" (optional, CPU intensive)

2. **Settings > Server > Scheduled Tasks**:
   - "Time at which to run tasks requiring the library to be up to date": 03:00
   - This runs after potential overnight downloads complete

### 10.4 Validation

```bash
# Force library scan via API
curl "http://localhost:32400/library/sections/all/refresh?X-Plex-Token=YOUR_TOKEN"

# Monitor scan progress
docker logs -f plex 2>&1 | grep -i scan
```

**Success Criteria**:
- [ ] Auto empty trash DISABLED
- [ ] All libraries show correct file counts
- [ ] Library scan completes without errors

---

## 11. Phase 8: Validation Testing

### 11.1 Functional Tests

#### Test 1: Pool Capacity Reporting

```bash
# mergerfs should show total capacity
df -h /mnt/pool

# Individual drives should still be accessible
for d in /var/mnt/pool_drives/Fast_*; do
  echo "=== $(basename $d) ==="
  df -h "$d"
done
```

**Expected**: Pool shows ~48TB, individual drives show correct sizes.

#### Test 2: Write Distribution (epmfs Policy)

```bash
# Create test files and observe distribution
for i in {1..5}; do
  dd if=/dev/zero of=/mnt/pool/test_file_$i bs=1M count=100
done

# Check which drives received files
for d in /var/mnt/pool_drives/Fast_*; do
  echo "=== $(basename $d) ==="
  ls -la "$d"/test_file_* 2>/dev/null || echo "No test files"
done

# Cleanup
rm /mnt/pool/test_file_*
```

**Expected**: Files distributed to drive(s) with most free space.

#### Test 3: Hardlink Verification

```bash
# Create source file in downloads
echo "hardlink test" > /var/mnt/fast8tb/Local/downloads/hardlink-test.txt

# Create hardlink in media (via symlink path)
ln /var/mnt/fast8tb/Local/downloads/hardlink-test.txt \
   /var/mnt/fast8tb/Local/media/movies/hardlink-test.txt

# Verify inode match (hardlink = same inode)
ls -i /var/mnt/fast8tb/Local/downloads/hardlink-test.txt
ls -i /var/mnt/fast8tb/Local/media/movies/hardlink-test.txt

# Cleanup
rm /var/mnt/fast8tb/Local/downloads/hardlink-test.txt
rm /var/mnt/fast8tb/Local/media/movies/hardlink-test.txt
```

**Expected**: Both files show same inode number.

#### Test 4: Docker Container Access

```bash
# Test each major container
for container in radarr sonarr plex sabnzbd; do
  echo "=== $container ==="
  docker exec $container df -h / | head -2
  docker exec $container ls /media/ 2>/dev/null || docker exec $container ls /movies/ 2>/dev/null
done
```

### 11.2 Hot-Swap Simulation

> **WARNING**: Only perform this test with non-critical data or backups available.

```bash
# 1. Note current state
cat /proc/mounts | grep pool

# 2. Simulate drive "disappearing" by unmounting one pool drive
sudo umount /var/mnt/pool_drives/Fast_4TB_1

# 3. Verify pool still functions (degraded)
ls /mnt/pool/
# Should still work, but Fast_4TB_1 content inaccessible

# 4. Remount drive
sudo mount /var/mnt/pool_drives/Fast_4TB_1

# 5. Verify full functionality restored
ls /mnt/pool/
```

### 11.3 Performance Baseline

```bash
# Sequential write test
dd if=/dev/zero of=/mnt/pool/write-test bs=1G count=4 oflag=direct 2>&1 | tail -1

# Sequential read test
dd if=/mnt/pool/write-test of=/dev/null bs=1G count=4 iflag=direct 2>&1 | tail -1

# Cleanup
rm /mnt/pool/write-test
```

**Record these values** for future comparison.

---

## 12. Phase 9: Media Remediation

### 12.1 Tdarr Configuration

Tdarr provides automated transcoding and media optimization.

1. Access: http://localhost:8265
2. **Libraries > Add Library**:
   - Source: `/media/movies` and `/media/tv`
   - Cache: `/temp` (maps to downloads/tdarr_transcode)
3. **Configure Nodes**: Enable the internal node
4. **Flows**: Import or create transcoding flows (H.265, audio normalization)

### 12.2 Recyclarr Setup

Reference: [TRaSH Guides](https://trash-guides.info/) | [Recyclarr GitHub](https://github.com/recyclarr/recyclarr)

Recyclarr syncs TRaSH Guides quality profiles to Radarr/Sonarr.

```bash
# Access recyclarr container
docker exec -it recyclarr sh

# Create initial config
recyclarr config create

# Edit config at /config/recyclarr.yml
# See https://recyclarr.dev/wiki/yaml/configuration-reference/
```

Example minimal config:

```yaml
sonarr:
  main:
    base_url: http://sonarr:8989
    api_key: !env_var SONARR_API_KEY
    quality_definition:
      type: series

radarr:
  main:
    base_url: http://radarr:7878
    api_key: !env_var RADARR_API_KEY
    quality_definition:
      type: movie
```

### 12.3 Duplicate Detection

```bash
# Find potential duplicates by name similarity
find /mnt/pool/movies -type d -name "*" | sort > /tmp/movie-dirs.txt

# Manual review for duplicates
# Consider tools like: rmlint, fdupes, or jdupes for automated detection
```

### 12.4 Media Organization Audit

```bash
# Check for files outside expected structure
find /mnt/pool -maxdepth 1 -type f
# Should return nothing - all files should be in subdirectories

# Check for empty directories
find /mnt/pool -type d -empty

# Check for oversized files (potential samples or extras)
find /mnt/pool -type f -size +50G
```

---

## 13. Rollback Procedures

### 13.1 Phase 1 Rollback (Drive Rename)

```bash
# Relabel drives back to original names using btrfs filesystem label
sudo btrfs filesystem label /dev/nvmeXn1p1 "Original_Label"
```

### 13.2 Phase 2 Rollback (mergerfs)

```bash
# Remove mergerfs layer
sudo rpm-ostree uninstall mergerfs
sudo systemctl reboot
```

### 13.3 Phase 3 Rollback (Pool Configuration)

```bash
# Unmount pool
sudo umount /mnt/pool

# Remove fstab entries
sudo nano /etc/fstab  # Remove mergerfs and pool_drives entries
sudo systemctl daemon-reload

# Revert to GNOME auto-mount
# Drives will appear under /run/media/deck/
```

### 13.4 Phase 4 Rollback (Symlinks)

```bash
# Remove symlinks
rm /var/mnt/fast8tb/Local/media/{movies,tv,anime,music}

# Recreate as directories
mkdir -p /var/mnt/fast8tb/Local/media/{movies,tv,anime,music}

# Move data back from pool if needed
# WARNING: This is a significant data move operation
```

### 13.5 Phase 5-6 Rollback (Docker/arr)

```bash
# Restore .env from backup
cp /var/mnt/fast8tb/config/backups/.env.backup .env

# Recreate containers
docker compose -p media-main down
docker compose -p media-main up -d

# Restore *arr databases from backup if needed
```

### 13.6 Emergency: Single Drive Failure

```bash
# 1. Identify failed drive
dmesg | tail -50 | grep -i error

# 2. Note affected content
# mergerfs logs which drive holds which files

# 3. Remove from pool (update fstab)
sudo nano /etc/fstab  # Comment out failed drive entry

# 4. Remount pool without failed drive
sudo umount /mnt/pool
sudo mount -a

# 5. Re-acquire affected content via *arr apps
# Use Radarr/Sonarr "Wanted > Missing" to re-download
```

---

## 14. Maintenance Runbook

### 14.1 Daily Checks

```bash
# Quick health check script
#!/bin/bash
echo "=== Pool Status ==="
df -h /mnt/pool

echo -e "\n=== Drive Health ==="
for d in /var/mnt/pool_drives/Fast_*; do
  printf "%-20s: " "$(basename $d)"
  if mountpoint -q "$d"; then
    echo "OK"
  else
    echo "NOT MOUNTED"
  fi
done

echo -e "\n=== Docker Containers ==="
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E '(radarr|sonarr|plex|sabnzbd)'
```

### 14.2 Weekly Tasks

- **Check mergerfs logs**: `journalctl -u mnt-pool.mount --since "1 week ago"`
- **Review *arr activity**: Check for failed imports, stuck downloads
- **Monitor disk space**: Alert if any drive below 100GB free

### 14.3 Monthly Tasks

- **SMART health check**:
  ```bash
  for dev in /dev/nvme{0..9}n1; do
    echo "=== $dev ==="
    sudo smartctl -H "$dev" 2>/dev/null | grep -E '(SMART|result)'
  done
  ```
- **btrfs scrub** (data integrity):
  ```bash
  for d in /var/mnt/pool_drives/Fast_*; do
    sudo btrfs scrub start "$d"
  done
  # Check status after ~1 hour
  sudo btrfs scrub status /var/mnt/pool_drives/Fast_8TB_1
  ```

### 14.4 Adding a New Drive

```bash
# 1. Format as btrfs
sudo mkfs.btrfs -L "Fast_XTB_N" /dev/nvmeXn1

# 2. Create mount point
sudo mkdir /var/mnt/pool_drives/Fast_XTB_N

# 3. Add to fstab
# (copy existing entry format, update UUID and mount point)

# 4. Mount
sudo mount /var/mnt/pool_drives/Fast_XTB_N

# 5. mergerfs auto-detects (due to wildcard in fstab)
# Verify with:
df -h /mnt/pool
```

### 14.5 Removing a Drive

```bash
# 1. Migrate data off drive
# Use rsync to move content to other pool drives

# 2. Remove from fstab
sudo nano /etc/fstab  # Comment or remove line

# 3. Unmount
sudo umount /var/mnt/pool_drives/Fast_XTB_N

# 4. Remount pool
sudo umount /mnt/pool
sudo mount -a
```

### 14.6 Rebalancing Data

mergerfs doesn't automatically rebalance. To redistribute data:

```bash
# Option 1: Use mergerfs.balance (recommended)
# https://github.com/trapexit/mergerfs-tools
mergerfs.balance /mnt/pool

# Option 2: Manual rsync between drives
rsync -avP /var/mnt/pool_drives/Fast_8TB_1/movies/A* \
           /var/mnt/pool_drives/Fast_4TB_3/movies/
# Then remove source after verification
```

---

## 15. References

### Official Documentation

- [mergerfs GitHub](https://github.com/trapexit/mergerfs) - FUSE union filesystem
- [mergerfs Man Page](https://manpages.debian.org/testing/mergerfs/mergerfs.1.en.html) - Complete options reference
- [Bazzite rpm-ostree](https://docs.bazzite.gg/Installing_and_Managing_Software/rpm-ostree/) - Package layering
- [Servarr Docker Guide](https://wiki.servarr.com/docker-guide) - *arr container best practices
- [Plex Library Settings](https://support.plex.tv/articles/200289526-library/) - Library configuration

### Community Guides

- [Perfect Media Server - mergerfs](https://perfectmediaserver.com/02-tech-stack/mergerfs/) - Comprehensive setup guide
- [TRaSH Guides - Docker](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Docker/) - Folder structure for hardlinks
- [TRaSH Guides - Hardlinks](https://trash-guides.info/File-and-Folder-Structure/Hardlinks-and-Instant-Moves/) - Why hardlinks matter
- [TRaSH Guides - Remote Path Mappings](https://trash-guides.info/Radarr/Radarr-remote-path-mapping/) - Path troubleshooting

### Tools

- [mergerfs-tools](https://github.com/trapexit/mergerfs-tools) - Balance, dedup, audit utilities
- [Recyclarr](https://github.com/recyclarr/recyclarr) - TRaSH Guides automation

---

## Appendix A: Quick Reference Card

### Common Commands

| Task | Command |
|------|---------|
| Pool capacity | `df -h /mnt/pool` |
| Individual drives | `for d in /var/mnt/pool_drives/*; do df -h "$d"; done` |
| Pool mount status | `mount \| grep mergerfs` |
| Restart Docker stack | `docker compose -p media-main restart` |
| View container logs | `docker logs -f <container>` |
| Check symlinks | `ls -la /var/mnt/fast8tb/Local/media/` |
| btrfs scrub | `sudo btrfs scrub start /var/mnt/pool_drives/Fast_8TB_1` |
| SMART status | `sudo smartctl -H /dev/nvme0n1` |

### Critical Paths

| Purpose | Path |
|---------|------|
| Pool mount | `/mnt/pool/` |
| Individual drives | `/var/mnt/pool_drives/Fast_*` |
| Internal drive | `/var/mnt/fast8tb/` |
| Docker configs | `/var/mnt/fast8tb/config/` |
| Downloads | `/var/mnt/fast8tb/Local/downloads/` |
| Media symlinks | `/var/mnt/fast8tb/Local/media/*` |
| Compose files | `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/` |

### Service Ports

| Service | Port |
|---------|------|
| Plex | 32400 |
| Radarr | 7878 |
| Sonarr | 8989 |
| Prowlarr | 9696 |
| SABnzbd | 8080 (192.168.6.167 only) |
| Transmission | 9091 |
| Tdarr | 8265 |
| Komga | 8081 |
| Overseerr | 5055 |

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-24 | Initial comprehensive plan |

---

*This document was created as a reference for the media server migration project. It incorporates decisions made during planning sessions and best practices from the Servarr and TRaSH Guides communities.*
