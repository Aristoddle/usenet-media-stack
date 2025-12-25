# Storage Architecture: mergerfs + btrfs for Travel-Ready Media Server

**The complete guide to portable, hot-swappable media storage with hardlink-compatible downloads**

> **Status**: Production-ready design
> **Last Updated**: 2025-12-23
> **Hardware**: 52TB across 9 drives (1 internal + 8 external in 2 OWC bays)

---

## Table of Contents

1. [Current State](#current-state)
2. [Target Architecture](#target-architecture)
3. [Drive Topology](#drive-topology)
4. [mergerfs Configuration](#mergerfs-configuration)
5. [Content Organization](#content-organization)
6. [Service Integration](#service-integration)
7. [Operational Procedures](#operational-procedures)
8. [Troubleshooting](#troubleshooting)
9. [For Future Agents](#for-future-agents)

---

## Current State

### Hardware Inventory

| Drive | Size | Filesystem | Status | Location | Content Type |
|-------|------|------------|--------|----------|--------------|
| **Fast_8TB_Ser7** | 8TB | btrfs | Active | Internal (HTPC) | Docker, EmuDeck, manga, travel content |
| Fast_8TB_1 | 8TB | exfat | Migration 70% | OWC Bay 2 | Movies_1/2/3 |
| Fast_8TB_2 | 8TB | btrfs | Complete | OWC Bay 2 | TV, Music |
| Fast_8TB_3 | 8TB | btrfs | Swap drive | OWC Bay 2 | Staging for migrations |
| Fast_4TB_1 | 4TB | exfat | Pending | OWC Bay 1 | More_Movies |
| Fast_4TB_2 | 4TB | exfat | Pending | OWC Bay 1 | More_TV |
| Fast_4TB_3 | 4TB | exfat | Pending | OWC Bay 1 | More_Movies_3 |
| Fast_4TB_4 | 4TB | exfat | Pending | OWC Bay 2 | More_Movies_2 |
| Fast_4TB_5 | 4TB | exfat | Pending | OWC Bay 1 | TV |

### Physical Layout

```
HTPC (Bazzite Gaming PC)
├── Internal NVMe (Fast_8TB_Ser7) - 8TB btrfs - ALWAYS PRESENT
│   ├── /var/mnt/fast8tb/
│   │   ├── Emudeck/           # ROMs, saves, states
│   │   ├── Cloud/OneDrive/    # Comics, books (cloud-synced)
│   │   └── downloads/         # Active downloads (hardlink source)
│   └── Docker volumes at /srv/usenet/
│
├── OWC Bay 1 (USB-C, ~16TB) - HOME ONLY
│   ├── Fast_4TB_1 → /run/media/deck/Fast_4TB_1
│   ├── Fast_4TB_2 → /run/media/deck/Fast_4TB_2
│   ├── Fast_4TB_3 → /run/media/deck/Fast_4TB_3
│   └── Fast_4TB_5 → /run/media/deck/Fast_4TB_5
│
└── OWC Bay 2 (USB-C, ~28TB) - HOME ONLY
    ├── Fast_8TB_1 → /run/media/deck/Fast_8TB_1
    ├── Fast_8TB_2 → /run/media/deck/Fast_8TB_2
    ├── Fast_8TB_3 → /run/media/deck/Fast_8TB_3 (swap/staging)
    └── Fast_4TB_4 → /run/media/deck/Fast_4TB_4
```

---

## Target Architecture

### Design Goals

1. **Travel mode**: HTPC works with internal drive only; external bays stay home
2. **Single merged view**: One `/mnt/media` path for all content via mergerfs
3. **Hardlinks work**: Downloads and media on same filesystem for instant imports
4. **Hot-swap safe**: External drives can be connected/disconnected gracefully
5. **SQLite safe**: Databases (Sonarr, Radarr, Plex) on native btrfs, NOT mergerfs

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           STORAGE ARCHITECTURE                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  LAYER 3: MERGED VIEW (mergerfs)                                           │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  /mnt/pool                                                           │   │
│  │  ├── tv/         → unified TV library                               │   │
│  │  ├── movies/     → unified movie library                            │   │
│  │  ├── music/      → unified music library                            │   │
│  │  └── downloads/  → completed downloads (hardlink source)            │   │
│  │                                                                      │   │
│  │  Policy: epmfs (existing path, most free space)                     │   │
│  │  - New show season → goes to same drive as existing seasons         │   │
│  │  - New show entirely → goes to drive with most free space           │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                          ▲                                                  │
│  LAYER 2: INDIVIDUAL BTRFS DRIVES                                          │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│  │ Fast_8TB_S7 │ │ Fast_8TB_1  │ │ Fast_8TB_2  │ │ Fast_4TB_*  │           │
│  │ (internal)  │ │ (OWC Bay 2) │ │ (OWC Bay 2) │ │ (OWC Bays)  │           │
│  │             │ │             │ │             │ │             │           │
│  │ /data/      │ │ /data/      │ │ /data/      │ │ /data/      │           │
│  │ ├─ tv/      │ │ ├─ movies/  │ │ ├─ tv/      │ │ ├─ movies/  │           │
│  │ ├─ movies/  │ │ └─ ...      │ │ └─ music/   │ │ └─ tv/      │           │
│  │ ├─ books/   │ │             │ │             │ │             │           │
│  │ └─ downloads│ │             │ │             │ │             │           │
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                                             │
│  LAYER 1: PHYSICAL HARDWARE                                                │
│  ┌──────────────────┐  ┌────────────────────────────────────────────────┐  │
│  │ HTPC Internal    │  │ OWC Thunderbolt Bays (Home Only)               │  │
│  │ (Always Present) │  │ - Can be disconnected for travel               │  │
│  │                  │  │ - Hot-swap supported                           │  │
│  └──────────────────┘  └────────────────────────────────────────────────┘  │
│                                                                             │
│  SERVICES LAYER (NOT on mergerfs)                                          │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │ /srv/usenet/config/ (native btrfs on internal drive)                │   │
│  │ ├─ sonarr/sonarr.db     ← SQLite databases must be on native FS     │   │
│  │ ├─ radarr/radarr.db     ← FUSE + SQLite = corruption risk           │   │
│  │ ├─ plex/                ← Plex database on native btrfs             │   │
│  │ └─ ...                                                               │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Drive Topology

### Logical Pools

#### Home Pool (Full Stack)
When all drives are connected:
```
/mnt/pool → mergerfs union of:
  ├── /var/mnt/fast8tb/data         (internal, always present)
  ├── /run/media/deck/Fast_8TB_1/data
  ├── /run/media/deck/Fast_8TB_2/data
  ├── /run/media/deck/Fast_4TB_1/data
  ├── /run/media/deck/Fast_4TB_2/data
  ├── /run/media/deck/Fast_4TB_3/data
  ├── /run/media/deck/Fast_4TB_4/data
  └── /run/media/deck/Fast_4TB_5/data
```

#### Travel Pool (Internal Only)
When traveling with just the HTPC:
```
/mnt/pool → falls back to internal only:
  └── /var/mnt/fast8tb/data
      ├── books/        (Comics, manga, ebooks)
      ├── emulation/    (ROMs, saves)
      ├── downloads/    (incomplete + complete)
      └── travel-media/ (selected movies/shows for offline)
```

### Content Classification

| Content Type | Location | Travel? | Rationale |
|--------------|----------|---------|-----------|
| Books/Comics | Internal | Yes | Reading on the go, small files |
| ROMs/Emulation | Internal | Yes | Gaming anywhere |
| Manga | Internal | Yes | Reading-focused, synced from OneDrive |
| Movies | External | No | Large files, home viewing |
| TV Shows | External | No | Large files, home viewing |
| Music | External | No | Streaming preferred when traveling |
| Adult | External | No | Home-only content |
| Downloads (active) | Internal | N/A | Fast NVMe for speed, hardlink source |

---

## mergerfs Configuration

### Why mergerfs?

mergerfs is a FUSE-based union filesystem that presents multiple drives as a single directory. Key benefits:

1. **Single path for apps**: Plex, Sonarr, Radarr see one `/mnt/pool/movies` not 8 separate drives
2. **Path preservation (epmfs)**: Related content stays together automatically
3. **Hot-swap friendly**: Drives can come and go without breaking the mount
4. **Hardlinks work**: Files on the same underlying drive can be hardlinked

### Recommended Mount Options

```bash
# /etc/fstab entry for home mode (all drives)
/var/mnt/fast8tb/data:/run/media/deck/Fast_8TB_1/data:/run/media/deck/Fast_8TB_2/data:/run/media/deck/Fast_4TB_1/data:/run/media/deck/Fast_4TB_2/data:/run/media/deck/Fast_4TB_3/data:/run/media/deck/Fast_4TB_4/data:/run/media/deck/Fast_4TB_5/data /mnt/pool fuse.mergerfs defaults,allow_other,use_ino,category.create=epmfs,moveonenospc=true,minfreespace=20G,fsname=mediapool,nonempty 0 0
```

### Option Breakdown

| Option | Value | Purpose |
|--------|-------|---------|
| `allow_other` | (flag) | Let non-root users access the mount |
| `use_ino` | (flag) | Unique inode numbers across branches |
| `category.create` | `epmfs` | Existing Path, Most Free Space for new files |
| `moveonenospc` | `true` | If write fails, try another drive |
| `minfreespace` | `20G` | Don't write to drives with <20GB free |
| `fsname` | `mediapool` | Friendly name in `df` output |
| `nonempty` | (flag) | Allow mounting over non-empty directory |

### Policy Deep Dive: epmfs

The `epmfs` (Existing Path, Most Free Space) policy is critical for media servers:

**Scenario 1: Adding Season 3 of "Breaking Bad"**
- Seasons 1-2 already exist on Fast_8TB_2 at `/data/tv/Breaking Bad/`
- mergerfs sees the path exists on Fast_8TB_2
- Season 3 goes to Fast_8TB_2 (path preservation)
- Result: All seasons on same drive, hardlinks possible

**Scenario 2: Adding new show "The Bear"**
- No existing path on any drive
- mergerfs picks drive with most free space
- If Fast_4TB_3 has 1.2TB free and others have less, it goes there
- Future seasons will follow to Fast_4TB_3

**Scenario 3: Drive is full**
- Fast_8TB_2 has Breaking Bad but only 5GB free
- `minfreespace=20G` excludes it from consideration
- New episode goes to next drive with the path, or most free space
- `moveonenospc=true` handles mid-write failures gracefully

### Hardlinks and mergerfs

**Critical requirement**: Hardlinks only work between files on the SAME underlying filesystem.

For Sonarr/Radarr hardlinks to work:
1. Download client (SABnzbd) saves to `/mnt/pool/downloads/complete/`
2. Sonarr imports to `/mnt/pool/tv/`
3. IF both paths resolve to the same underlying drive, hardlink works
4. IF they resolve to different drives, copy+delete happens instead

**Best practice for hardlinks**:
```
Downloads: /mnt/pool/downloads/
  └── complete/
      ├── tv/        ← Sonarr moves from here
      └── movies/    ← Radarr moves from here

Media: /mnt/pool/
  ├── tv/           ← Sonarr imports to here
  └── movies/       ← Radarr imports to here
```

With `epmfs` policy:
- First download of a show creates path on freest drive
- Subsequent episodes hardlink successfully (same drive)
- New shows may land on different drives (hardlinks work within each show)

### The ignorepponrename Option

If Sonarr/Radarr throw EXDEV errors during imports:
```bash
# Add to mount options:
ignorepponrename=true
```

This makes rename/link operations stay on the same filesystem even with path-preserving policies.

### Disconnected Drive Behavior

**What happens when OWC bay is unplugged:**
1. mergerfs continues working with remaining drives
2. Files on disconnected drives become invisible (not accessible)
3. Attempts to access those files return errors
4. No automatic cleanup or deletion occurs

**Important**: mergerfs is NOT a RAID. It provides no redundancy. Files on a disconnected drive are simply unavailable until reconnection.

---

## Content Organization

### Directory Structure per Drive

Each btrfs drive follows this structure:
```
/data/
├── tv/
│   ├── Show Name (Year)/
│   │   ├── Season 01/
│   │   └── Season 02/
├── movies/
│   └── Movie Name (Year)/
├── music/
│   └── Artist/Album/
└── downloads/        # Only on internal drive
    ├── incomplete/
    └── complete/
        ├── tv/
        └── movies/
```

### Travel Content Preparation

Before traveling, curate content on internal drive:
```bash
# Example: Copy select movies for a trip
rsync -avP "/mnt/pool/movies/Dune (2021)/" "/var/mnt/fast8tb/data/travel-media/movies/Dune (2021)/"

# Or use rclone for progress
rclone copy "/mnt/pool/movies/Dune (2021)/" "/var/mnt/fast8tb/data/travel-media/movies/" --progress
```

### Content That Should NEVER Be on mergerfs

| Content | Correct Location | Why |
|---------|------------------|-----|
| Sonarr database | `/srv/usenet/config/sonarr/` | SQLite + FUSE = corruption |
| Radarr database | `/srv/usenet/config/radarr/` | SQLite + FUSE = corruption |
| Plex database | `/srv/usenet/config/plex/` | SQLite + FUSE = corruption |
| Docker volumes | `/srv/usenet/` | Performance, reliability |
| Active downloads (incomplete) | Internal drive | Speed, no fragmentation |

---

## Service Integration

### Docker Volume Mapping

```yaml
# docker-compose.yml - Correct volume mapping for hardlinks
services:
  sabnzbd:
    volumes:
      - ${CONFIG_ROOT}/sabnzbd:/config              # Native btrfs
      - /mnt/pool/downloads:/downloads              # mergerfs for downloads

  sonarr:
    volumes:
      - ${CONFIG_ROOT}/sonarr:/config               # Native btrfs (SQLite!)
      - /mnt/pool/downloads:/downloads              # Same as sabnzbd
      - /mnt/pool/tv:/tv                            # mergerfs for media

  radarr:
    volumes:
      - ${CONFIG_ROOT}/radarr:/config               # Native btrfs (SQLite!)
      - /mnt/pool/downloads:/downloads              # Same as sabnzbd
      - /mnt/pool/movies:/movies                    # mergerfs for media

  plex:
    volumes:
      - ${CONFIG_ROOT}/plex:/config                 # Native btrfs (SQLite!)
      - /mnt/pool:/media:ro                         # mergerfs read-only for media
```

### Sonarr/Radarr Root Folder Configuration

In Sonarr Settings -> Media Management -> Root Folders:
```
/tv    (maps to /mnt/pool/tv on host)
```

In Radarr Settings -> Media Management -> Root Folders:
```
/movies    (maps to /mnt/pool/movies on host)
```

### Download Client Configuration

SABnzbd Categories:
```
tv      → /downloads/complete/tv
movies  → /downloads/complete/movies
```

This ensures:
1. Downloads go to categorized folders
2. Sonarr/Radarr import from same volume
3. Hardlinks work (when same underlying drive)

### Plex Library Configuration

**Critical Setting**: Disable "Empty trash automatically after every scan"

Why: When external drives are disconnected, Plex sees content as "missing." With auto-trash enabled, Plex would delete all metadata for that content. With it disabled:
- Content shows as unavailable (grayed out)
- Metadata preserved
- When drives reconnect, content reappears with all metadata intact

Plex Libraries:
```
Movies:  /media/movies  (mergerfs mount)
TV:      /media/tv      (mergerfs mount)
Music:   /media/music   (mergerfs mount)
```

### arr Stack Behavior with Disconnected Drives

**Sonarr/Radarr**:
- Continue operating normally for content on connected drives
- Show files on disconnected drives as "missing"
- Will re-download if monitored (BAD - disable monitoring for external content!)
- Best practice: Set quality cutoffs so upgrades aren't aggressive

**Recommended Workflow**:
1. Before disconnecting: Set content on external drives to "unmonitored"
2. Travel with internal drive content monitored
3. On return: Re-monitor external content, run manual scan

---

## Operational Procedures

### Safely Disconnecting External Bays

```bash
#!/bin/bash
# disconnect-external-storage.sh

echo "=== Stopping services that use external storage ==="
docker compose -f /path/to/docker-compose.yml stop plex sonarr radarr

echo "=== Syncing filesystem buffers ==="
sync

echo "=== Unmounting external drives ==="
sudo umount /run/media/deck/Fast_8TB_1
sudo umount /run/media/deck/Fast_8TB_2
sudo umount /run/media/deck/Fast_4TB_*

echo "=== Powering off drives (optional, for OWC bays) ==="
# udisksctl power-off -b /dev/nvmeXn1  # If needed

echo "=== Safe to disconnect OWC bays ==="
echo "Note: mergerfs pool will continue with internal drive only"
```

### Reconnecting External Bays

```bash
#!/bin/bash
# reconnect-external-storage.sh

echo "=== Drives should auto-mount via udisks2 ==="
echo "Waiting for mount points..."
sleep 5

echo "=== Verifying mounts ==="
mount | grep Fast_

echo "=== Refreshing mergerfs (if needed) ==="
# mergerfs auto-detects if using glob patterns
# If using explicit paths, remount:
# sudo umount /mnt/pool && sudo mount /mnt/pool

echo "=== Starting services ==="
docker compose -f /path/to/docker-compose.yml start plex sonarr radarr

echo "=== Triggering Plex library scan ==="
# curl -X POST "http://localhost:32400/library/sections/all/refresh?X-Plex-Token=YOUR_TOKEN"
```

### Travel Mode Activation

```bash
#!/bin/bash
# enter-travel-mode.sh

echo "=== ENTERING TRAVEL MODE ==="

# 1. Stop home-only services
docker compose stop plex sonarr radarr  # Keep running if you want travel content

# 2. Unmonitor home content in *arr apps
echo "Manually set external drive content to unmonitored in Sonarr/Radarr"

# 3. Safely disconnect
./disconnect-external-storage.sh

# 4. Update mergerfs to internal-only (optional - it degrades gracefully)
echo "mergerfs will work with internal drive only"

# 5. Verify travel content is accessible
ls /var/mnt/fast8tb/data/books/
ls /var/mnt/fast8tb/Emudeck/
```

### Recovery from Unexpected Disconnection

If drives are yanked without proper unmount:

```bash
# 1. Check for filesystem errors
sudo btrfs check /dev/nvmeXn1p1  # Read-only check

# 2. If errors found, repair
sudo btrfs check --repair /dev/nvmeXn1p1  # USE WITH CAUTION

# 3. Remount and verify
sudo mount /run/media/deck/Fast_8TB_X
ls /run/media/deck/Fast_8TB_X/

# 4. Run btrfs scrub to verify data integrity
sudo btrfs scrub start /run/media/deck/Fast_8TB_X
sudo btrfs scrub status /run/media/deck/Fast_8TB_X
```

---

## Troubleshooting

### Common Issues

#### 1. "EXDEV: cross-device link" in Sonarr/Radarr

**Cause**: Attempting to hardlink between different underlying drives.

**Solutions**:
- Accept that cross-drive imports will copy (this is expected behavior)
- Add `ignorepponrename=true` to mergerfs options
- Manually organize so show/movie folders are on same drive as downloads

#### 2. Content disappears when external drives disconnected

**Cause**: Normal behavior - mergerfs only shows what's mounted.

**Solution**: This is expected. Content returns when drives are reconnected.

#### 3. Plex shows "unavailable" for content

**Cause**: External drives disconnected, content not accessible.

**Solution**:
- Verify "Empty trash automatically" is DISABLED
- Reconnect drives, run library scan
- Content should reappear with metadata intact

#### 4. SQLite database corruption (Sonarr/Radarr)

**Cause**: Database on mergerfs/FUSE mount.

**Solution**:
- Move `/config` volumes to native btrfs filesystem
- Restore from backup (apps create automatic backups)
- Ensure `direct_io` is NOT in mergerfs mount options

#### 5. New content going to wrong drive

**Cause**: Path doesn't exist on expected drive, or drive is full.

**Solution**:
- Create directory structure on desired drive first
- Check `minfreespace` setting
- Verify drive isn't excluded due to low space

#### 6. Slow performance / high latency

**Causes**: FUSE overhead, spinning up many drives.

**Solutions**:
- Use `cache.files=partial` for better caching
- Consider `async_read=true` for read-heavy workloads
- Only spin up drives when needed (mergerfs does this automatically)

### Diagnostic Commands

```bash
# Check mergerfs mount status
mount | grep mergerfs
cat /proc/mounts | grep mergerfs

# View mergerfs configuration
xattr -l /mnt/pool/.mergerfs

# Check branch order and policies
getfattr -d /mnt/pool/.mergerfs

# See which drive a file is actually on
getfattr -n user.mergerfs.srcmount /mnt/pool/movies/SomeMovie/

# Check drive space per branch
df -h /var/mnt/fast8tb/data /run/media/deck/Fast_*

# Verify btrfs health
sudo btrfs filesystem show
sudo btrfs device stats /run/media/deck/Fast_8TB_2
```

---

## For Future Agents

### Key Decisions and Rationale

| Decision | Choice | Rationale | Reference |
|----------|--------|-----------|-----------|
| Storage pooling | mergerfs (not btrfs RAID) | Hot-swap support, graceful degradation, travel mode | [Design Philosophy](/architecture/design-philosophy) |
| Create policy | epmfs | Keep related content together, use freest space for new | [mergerfs docs](https://github.com/trapexit/mergerfs) |
| Databases location | Native btrfs, not mergerfs | SQLite + FUSE = corruption risk | [TRaSH Guides](https://trash-guides.info/) |
| Hardlink strategy | Same-volume pattern | TRaSH guides folder structure | [Hardlinks Guide](https://trash-guides.info/File-and-Folder-Structure/Hardlinks-and-Instant-Moves/) |
| Plex trash | Disabled auto-empty | Preserve metadata when drives offline | Plex forums |
| Travel content | Internal drive only | Portability, always available | User requirement |

### Configuration Files to Know

| File | Purpose | Location |
|------|---------|----------|
| fstab | mergerfs mount definition | `/etc/fstab` |
| docker-compose.yml | Service volume mappings | Project root |
| sonarr config | Root folders, download client | `/srv/usenet/config/sonarr/` |
| radarr config | Root folders, download client | `/srv/usenet/config/radarr/` |
| plex config | Library paths, trash settings | `/srv/usenet/config/plex/` |

### Maintenance Tasks

**Weekly**:
- Check `df -h` for drive space balance
- Review Sonarr/Radarr import logs for EXDEV errors
- Verify btrfs scrub completed without errors

**Monthly**:
- Run `btrfs scrub` on all drives
- Review mergerfs pool balance
- Clean up completed downloads folder

**Before Travel**:
- Run disconnect script
- Verify travel content accessible
- Set home content to unmonitored

### Emergency Contacts (Resources)

- [mergerfs GitHub Issues](https://github.com/trapexit/mergerfs/issues)
- [TRaSH Guides Discord](https://trash-guides.info/discord)
- [r/selfhosted](https://reddit.com/r/selfhosted)
- [Perfect Media Server](https://perfectmediaserver.com/)

---

## Sources and References

This documentation synthesizes information from:

- [mergerfs - Perfect Media Server](https://perfectmediaserver.com/02-tech-stack/mergerfs/)
- [mergerfs GitHub Documentation](https://github.com/trapexit/mergerfs)
- [TRaSH Guides - Hardlinks and Instant Moves](https://trash-guides.info/File-and-Folder-Structure/Hardlinks-and-Instant-Moves/)
- [TRaSH Guides - Docker Setup](https://trash-guides.info/File-and-Folder-Structure/How-to-set-up/Docker/)
- [Servarr Wiki - Docker Guide](https://wiki.servarr.com/docker-guide)
- [Plex Support - Empty Trash](https://support.plex.tv/articles/)
- [Btrfs Documentation](https://btrfs.readthedocs.io/)
- [mergerfs SQLite Issue #887](https://github.com/trapexit/mergerfs/issues/887)

---

*Built for a gaming HTPC that travels. Designed for home users who accumulate drives over time.*
