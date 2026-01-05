# Media Stack Boot System and Desktop Launchers

## Overview

The media stack supports three boot modes to handle the Steam Deck's detachable external drive bay:

| Mode | Use Case | Services | Pool Required |
|------|----------|----------|---------------|
| **Full Stack** | Normal operation, all drives connected | All 30+ services | Yes |
| **Local Stack** | Portable mode, no external drives | 10 services (books/comics) | No |
| **Gaming Mode** | Free resources for gaming | Pauses heavy services | N/A |

## Desktop Launchers

### Installation

```bash
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack
./desktop/install-launchers.sh
```

This installs three launchers to `~/.local/share/applications/`:

### 1. Media Stack - Full

**Icon**: server-database
**Script**: `scripts/stack-up-full.sh`

Starts the complete media stack with safety checks:

1. Verifies internal NVMe is mounted (`/var/mnt/fast8tb`)
2. Checks if external drives are attached (USB dock detection)
3. Checks if external drives are mounted
4. Verifies MergerFS pool is active
5. If pool unavailable, offers fallback to local stack

**Right-click actions**:
- **Start (Skip Checks)**: Force start without safety checks (dangerous)
- **Check Storage Only**: Run storage checks without starting services

### 2. Media Stack - Local

**Icon**: folder-documents
**Script**: `scripts/stack-up-local.sh`

Starts only services that work with internal NVMe:

| Service | Purpose | Port |
|---------|---------|------|
| Komga | Comics reader | 8081 |
| Kavita | Books/comics | 5000 |
| Audiobookshelf | Audiobooks | 13378 |
| Komf | Metadata | 8085 |
| Suwayomi | Manga sources | 4567 |
| Portainer | Docker mgmt | 9000 |
| Netdata | Monitoring | 19999 |
| Uptime-Kuma | Health checks | 3001 |
| Prowlarr | Indexers (browse-only) | 9696 |
| Overseerr | Requests (browse-only) | 5055 |

**Right-click actions**:
- **Show Status**: Check which services are running
- **Upgrade to Full Stack**: If pool becomes available, switch to full mode

### 3. Media Stack - Stop

**Icon**: system-shutdown
**Script**: `scripts/stack-down.sh`

Gracefully shuts down with job awareness:

- Detects active Tdarr transcodes
- Detects active downloads (SABnzbd, Transmission)
- Detects active Plex sessions
- Offers options: wait, kill, or graceful stop

**Right-click actions**:
- **Quick Stop**: 30s timeout, pause jobs first
- **Force Stop**: Kill everything immediately (emergency only)
- **Check Active Jobs**: Show what's running without stopping

## Service Categorization

### Pool-Dependent Services

These mount from `/var/mnt/pool` (the MergerFS union of external drives):

```
sonarr, radarr, lidarr, bazarr, readarr (⚠️ DEPRECATED), whisparr, mylar
tdarr, tdarr-node
plex, tautulli, stash
sabnzbd, transmission, aria2
makemkv
samba
```

**Why pool-dependent?**
- Store media on the 41TB pool (external drives)
- Downloads go to `/var/mnt/pool/downloads` for instant hardlinking
- Transcoding reads/writes to pool

### Local-Only Services

These work entirely from `/var/mnt/fast8tb` (internal 8TB NVMe):

```
komga, kavita, komf, audiobookshelf, suwayomi
portainer, netdata, uptime-kuma
prowlarr, overseerr (config-only)
```

**Why local-only?**
- Comics/books stored on OneDrive-synced NVMe folder
- Config-only services don't need media storage
- Monitoring works without media access

### Infrastructure Services

Always available regardless of storage:

```
portainer     - Docker management UI
netdata       - System monitoring
uptime-kuma   - Service health checks
```

## Boot Flow Diagram

```
                    ┌─────────────────────┐
                    │   System Boot       │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  User clicks        │
                    │  desktop launcher   │
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
     ┌────────▼────────┐  ┌────▼────┐  ┌───────▼───────┐
     │  Full Stack     │  │  Local  │  │    Stop       │
     └────────┬────────┘  └────┬────┘  └───────┬───────┘
              │                │                │
     ┌────────▼────────┐       │       ┌───────▼───────┐
     │ Check NVMe      │       │       │ Check active  │
     │ (fast8tb)       │       │       │ jobs          │
     └────────┬────────┘       │       └───────┬───────┘
              │                │                │
     ┌────────▼────────┐       │       ┌───────▼───────┐
     │ Check external  │       │       │ Offer: wait,  │
     │ drives attached │       │       │ kill, stop    │
     └────────┬────────┘       │       └───────────────┘
              │                │
     ┌────────▼────────┐       │
     │ Drives attached?│       │
     └────────┬────────┘       │
         YES  │   NO           │
              │    │           │
     ┌────────▼────┴───────┐   │
     │ Check drives mounted│   │
     └────────┬────────────┘   │
              │                │
     ┌────────▼────────┐       │
     │ Check MergerFS  │       │
     │ pool mounted    │       │
     └────────┬────────┘       │
        YES   │   NO           │
              │    │           │
     ┌────────▼────┴───────┐   │
     │ Start full stack    │   │
     └─────────────────────┘   │
                               │
                    ┌──────────▼──────────┐
                    │ Offer: start local  │
                    │ or retry            │
                    └─────────────────────┘
```

## Safe Boot Scenarios

### Scenario 1: Normal Boot (All Drives Connected)

1. User clicks "Media Stack - Full"
2. Script checks: NVMe OK, drives attached, drives mounted, pool OK
3. Full stack starts (all 30+ services)
4. User has access to everything

### Scenario 2: Portable Mode (No External Drives)

1. User clicks "Media Stack - Full"
2. Script detects: NVMe OK, drives NOT attached
3. Prompt: "Pool unavailable. Start local stack?"
4. User selects yes
5. Local stack starts (10 services)
6. Comics, books, audiobooks available

**Or** user can directly click "Media Stack - Local" to skip the check.

### Scenario 3: Drives Attached But Not Mounted

1. User clicks "Media Stack - Full"
2. Script detects: NVMe OK, drives attached, drives NOT mounted
3. Script attempts: `systemctl start mergerfs-pool.service`
4. If successful: full stack starts
5. If failed: offer local stack fallback

### Scenario 4: Gaming Session

1. User runs `gaming-mode.sh enable`
2. Tdarr nodes pause (current transcodes complete)
3. MakeMKV stops
4. 14 CPU cores + 36GB RAM freed
5. After gaming: `gaming-mode.sh disable`

### Scenario 5: Graceful Shutdown

1. User clicks "Media Stack - Stop"
2. Script detects: 2 active transcodes, 1 download
3. User selects "Wait for transcodes"
4. Tdarr nodes pause, SABnzbd pauses
5. Wait up to 10 minutes for transcodes
6. Clean shutdown, no data loss

## Storage Detection Logic

### How We Detect "Drives Not Attached"

Check `/dev/disk/by-label/` for drive labels:

```bash
# Expected labels (from mergerfs-pool.service)
Fast_4TB_1, Fast_4TB_2, Fast_4TB_3, Fast_4TB_4, Fast_4TB_5
Fast_8TB_1, Fast_8TB_2, Fast_8TB_3
```

If block devices don't exist, the USB dock is disconnected.

### How We Detect "Drives Attached But Not Mounted"

```bash
# Block device exists but mountpoint check fails
[[ -e /dev/disk/by-label/Fast_4TB_1 ]] && ! mountpoint -q /var/mnt/Fast_4TB_1
```

This means systemd hasn't mounted the drives yet (common after suspend/resume).

### How We Detect "Pool Not Mounted"

```bash
# MergerFS-specific check
mount | grep -q "mergerfs.*on /var/mnt/pool"
```

Drives could be mounted but MergerFS union not created.

## Auto-Recovery Actions

| Detection | Auto-Action |
|-----------|-------------|
| Drives attached but unmounted | Try `systemctl start mergerfs-pool.service` |
| Pool mount fails | Offer local stack fallback |
| Service has stale FUSE mount | Restart via `restart-pool-containers.sh` |
| NVMe unmounted | FAIL - cannot proceed (critical) |

## Integration with Existing Infrastructure

### mergerfs-pool.service

The systemd service handles pool mounting:

```ini
[Unit]
After=var-mnt-Fast_4TB_1.mount var-mnt-Fast_4TB_2.mount ...
Wants=var-mnt-Fast_4TB_1.mount var-mnt-Fast_4TB_2.mount ...

[Service]
ExecStart=/usr/bin/mergerfs -o ... /var/mnt/Fast_*:/var/mnt/pool
ExecStartPost=/path/to/restart-pool-containers.sh
```

### gaming-mode.sh

Complements the launcher system:

```bash
# Before gaming
gaming-mode.sh enable    # Pause Tdarr, stop MakeMKV

# After gaming
gaming-mode.sh disable   # Resume all services
```

### restart-pool-containers.sh

Called by mergerfs-pool.service after mount:

- Restarts containers with stale FUSE references
- Verifies mount health inside containers
- Reports any failures

### pool-health-monitor.sh (NEW: 2026-01-04)

Runtime monitoring for hot-unplug detection. Runs as a daemon to protect data during drive disconnection.

**Purpose**: Detect when external drive bays are disconnected and gracefully stop full-stack services before I/O errors or data corruption occur.

**Enable the service**:
```bash
# Install and start the monitor
sudo cp systemd/pool-health-monitor.service /etc/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now pool-health-monitor.service

# Check status
systemctl --user status pool-health-monitor.service
```

**Modes**:
```bash
# One-shot health check
./scripts/pool-health-monitor.sh --check

# Show current status
./scripts/pool-health-monitor.sh --status

# Daemon mode (for systemd)
./scripts/pool-health-monitor.sh --daemon
```

**How it works**:
1. Polls every 10 seconds (configurable via `POLL_INTERVAL`)
2. Checks if drives are attached (`/dev/disk/by-label/Fast_*`)
3. Checks if drives are mounted (`/var/mnt/Fast_*`)
4. Checks if pool is responsive (`timeout 5s ls /var/mnt/pool`)
5. On state change, takes action:

| State Change | Action |
|--------------|--------|
| healthy → unmounted | **Graceful drain** → Stop full stack, notify user |
| healthy → stale | **Graceful drain** → Stop full stack (I/O timeout detected) |
| healthy → degraded | Log warning, continue |
| unmounted → healthy | **Auto-upgrade** to full mode (if enabled) |

**Auto-upgrade behavior** (NEW):
- When pool recovers from `unmounted` → `healthy`
- If currently in portable/local mode
- Automatically starts full stack via `smart-start.sh`
- Controlled by `AUTO_UPGRADE_ON_RECOVERY=true` (default: enabled)
- Disable with: `AUTO_UPGRADE_ON_RECOVERY=false` in systemd environment

**Graceful drain sequence** (protects active downloads/transcodes):
1. Pause SABnzbd queue (via API)
2. Pause Transmission (set speed limit to 0)
3. Stop Tdarr node (prevent new transcodes)
4. Wait up to 10s for I/O to settle (`sync`)
5. Stop containers with 30s timeout
6. Force kill only as last resort

**State files** (in `/tmp/media-stack/`):
```
pool-state        # Current: healthy, degraded, stale, unmounted
pool-health.log   # Event log for debugging
pool-degraded     # Timestamp of last degradation event
```

**Desktop notifications**: Uses `notify-send` if available.

## Troubleshooting

### Launcher doesn't appear in menu

```bash
# Rebuild KDE cache
kbuildsycoca5

# Or log out and back in
```

### "Cannot access Docker daemon" error

```bash
# Check Docker service
sudo systemctl status docker

# Add user to docker group (if not using rootless)
sudo usermod -aG docker $USER
```

### Pool mount fails after suspend

```bash
# Check if drives are detected
ls /dev/disk/by-label/Fast*

# Try manual remount
sudo systemctl restart mergerfs-pool.service

# Check for stale mounts
./scripts/restart-pool-containers.sh --check
```

### Services have stale FUSE mounts

```bash
# Force restart all pool-dependent containers
./scripts/restart-pool-containers.sh
```

## State Files

The launcher scripts track state in `/tmp/media-stack/`:

| File | Content |
|------|---------|
| `stack-mode` | Current mode: "full" or "local" |
| `stack-started` | Unix timestamp of last start |

These are cleared on shutdown and don't persist across reboots.

## Command Reference

```bash
# Full stack (with safety checks)
./scripts/stack-up-full.sh

# Full stack (skip checks - dangerous)
./scripts/stack-up-full.sh --force

# Full stack (auto-fallback to local if pool unavailable)
./scripts/stack-up-full.sh --local-on-fail

# Storage check only
./scripts/stack-up-full.sh --check-only

# Local stack only
./scripts/stack-up-local.sh

# Local stack status
./scripts/stack-up-local.sh --status

# Graceful shutdown
./scripts/stack-down.sh

# Quick shutdown (30s timeout)
./scripts/stack-down.sh --quick

# Force shutdown (emergency)
./scripts/stack-down.sh --force

# Check active jobs
./scripts/stack-down.sh --status

# Gaming mode
./scripts/gaming-mode.sh enable
./scripts/gaming-mode.sh disable
./scripts/gaming-mode.sh status

# Systemd autostart
systemctl --user start media-stack-autostart   # Manual trigger
systemctl --user stop media-stack-autostart    # Stop stack
systemctl --user disable media-stack-autostart # Disable on boot
```

## Systemd Auto-Start Service

The `media-stack-autostart.service` automatically detects boot mode and starts the appropriate stack.

### Installation

```bash
# Copy service file
mkdir -p ~/.config/systemd/user/
cp systemd/media-stack-autostart.service ~/.config/systemd/user/

# Enable service
systemctl --user daemon-reload
systemctl --user enable media-stack-autostart.service
```

### Boot Detection Logic

The service runs `scripts/stack-autostart.sh` which:

1. Checks for Docker daemon availability
2. Counts attached external drives (by label in `/dev/disk/by-label/`)
3. Counts mounted drives (at `/var/mnt/Fast_*`)
4. Checks MergerFS pool status

**Decision Matrix:**

| Drives Attached | Drives Mounted | Pool Status | Boot Mode |
|-----------------|----------------|-------------|-----------|
| 0               | -              | -           | LOCAL     |
| 1-2             | -              | -           | LOCAL     |
| 3+              | <3             | -           | LOCAL     |
| 3+              | 3+             | Not mounted | LOCAL     |
| 3+              | 3+             | Mounted     | **FULL**  |

### State Files

After boot, check the detected mode:

```bash
cat /tmp/media-stack/stack-mode    # "full" or "local"
cat /tmp/media-stack/start-method  # "autostart" or "manual"
cat /tmp/media-stack/autostart.log # Full decision log
```

### Why This Design?

The Steam Deck is primarily a gaming device. The autostart system follows these principles:

1. **Never block boot** - Failures are logged but don't prevent graphical session
2. **Default to minimal** - If uncertain, start LOCAL mode (fewer services, less RAM)
3. **Gaming-first** - Quick boot without heavy containers when undocked
4. **Transparent decisions** - All logic logged to `/tmp/media-stack/autostart.log`

---

## 2026-01-04 Updates

### Race Condition Fix

The `media-stack-autostart.service` now includes proper systemd ordering:

```ini
# Added to [Unit] section
After=mergerfs-pool.service
```

This ensures:
- systemd waits for mergerfs to mount before starting media stack
- USB drive enumeration (5-15 seconds) completes first
- No more incorrect LOCAL mode detection when bays are connected

Additionally, `stack-autostart.sh` now waits up to 30 seconds (6 attempts × 5s) for mergerfs.

### Travel Downloads (NEW)

The reading stack (`docker-compose.reading.yml`) now includes download clients:

| Service | Port | Purpose |
|---------|------|---------|
| sabnzbd-portable | 8180 | Usenet downloads to internal drive |
| transmission-portable | 9092 | Torrent fallback to internal drive |

Configure Prowlarr to use these for one-off downloads while traveling:
- Usenet: `http://sabnzbd-portable:8080` or `localhost:8180`
- Torrents: `http://transmission-portable:9091` or `localhost:9092`

### Capability Matrix

| Capability | Travel Mode | Full Mode |
|------------|-------------|-----------|
| Read Comics/Manga | ✓ Komga | ✓ Komga |
| Read eBooks | ✓ Kavita | ✓ Kavita |
| Listen Audiobooks | ✓ ABS | ✓ ABS |
| Browse/Search | ✓ Prowlarr | ✓ Prowlarr |
| One-off Downloads | ✓ SABnzbd-Portable | ✓ SABnzbd |
| TV/Movie Management | ✗ | ✓ Sonarr/Radarr |
| Plex Streaming | ✗ | ✓ |
| Transcoding | ✗ | ✓ Tdarr |

### Alternative: smart-start.sh

A newer, simpler script is available:

```bash
# Compose-file based startup (recommended)
./scripts/smart-start.sh up      # Auto-detect and start
./scripts/smart-start.sh down    # Stop all
./scripts/smart-start.sh status  # Show storage + containers
./scripts/smart-start.sh detect  # Just show detected profile
```

This uses Docker Compose files directly instead of service-by-service:
- `docker-compose.reading.yml` for travel mode
- `docker-compose.yml` for full mode (adds to reading stack)

---

## Bazzite-Specific Configuration

### Docker Group on rpm-ostree

On Bazzite (Fedora rpm-ostree), the docker group is defined in `/usr/lib/group` (immutable).
Standard `usermod` doesn't work. Instead:

```bash
# Add override to /etc/group (writable overlay)
echo "docker:x:956:deck" | sudo tee -a /etc/group

# Verify
getent group docker
# Should show: docker:x:956:deck

# Requires logout/login to take effect
# Until then, use: sudo docker ...
```

### Why This Matters

- Docker socket is owned by `root:docker` with 660 permissions
- User must be in `docker` group for socket access without sudo
- On immutable systems, group modifications require the overlay approach
