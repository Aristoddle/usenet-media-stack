# Session State - Media Stack Infrastructure Overhaul
## Date: 2025-12-30 (Updated: 14:45 EST)

This document captures the complete state after a major infrastructure session.
Use this to continue work post-context-compaction.

---

## Session Update: 2025-12-30

### Active Transcodes (Direct FFmpeg - Bypassing Tdarr Queue Issues)

3 parallel SVT-AV1 transcodes running at load average ~47:
- **Dogma (1999)**: 24GB -> AV1, ~8 hours runtime, near completion
- **A Bug's Life (1998)**: 40GB ISO extract -> AV1, ~8 hours runtime, near completion
- **A Haunting in Venice (2023)**: 32GB ISO extract -> AV1, ~8 hours runtime, near completion

Estimated completion: Imminent (8+ hours elapsed, CPU-limited by design for maximum compression).

### Git-Tracked Tdarr Configuration (COMPLETE)

Created portable, git-tracked Tdarr config structure:
- `config/tdarr/flows/` - 4 SVT-AV1 flow definitions (JSON)
- `config/tdarr/libraries/` - 7 library configurations
- `config/tdarr/tdarr-config-sync.sh` - Export/import script

**Commit**: `e7be722` - Pushed to origin/main

### ROM Acquisition Agent Completed

6 NZBs prepared for download:
- SMT V Vengeance (NSW): 15.29 GB
- Vagrant Story (PSX): 167.7 MB
- Legend of Mana (PSX): 455 MB
- Mega Man Legends 1 & 2 (PSX): 568 MB total
- Suikoden II BugFix (PSX): 392 MB

**Location**: `/var/mnt/fast8tb/Local/downloads/roms/nzbs/`
**Status**: Awaiting manual SABnzbd UI upload (6 files pending)

### Tdarr Queue System Issue (Deferred)

Root cause identified: Tdarr's in-memory queue state doesn't sync properly with SQLite database. Files show in database but not in API/queue. Workaround: Direct FFmpeg transcodes until Tdarr issue resolved.

---

## Executive Summary

Major infrastructure overhaul completed:
- Fixed dual MergerFS conflict (was causing race conditions)
- Restructured pool to clean `/pool/{movies,tv,anime-movies,anime-tv,christmas-movies,christmas-tv}`
- Fixed Tdarr to use FFmpeg/VAAPI (GPU) instead of HandBrake (CPU)
- **Fixed Tdarr schedule override that was forcing CPU workers**
- **Fixed docker-compose.yml defaults that fell back to CPU workers**
- **Reset 1,600+ error files back to Queued for reprocessing**
- **Killed runaway 1Password process consuming 110% CPU for 3 days**
- Refactored docker-compose for DRY/portability (.env variables)
- Created monitoring tools: `sysinfo-snapshot`, `metrics-collector`
- Wired Transmission to Radarr/Sonarr (was disabled)
- **Created STRATEGIC_ROADMAP.md with 5-tier action plan**
- **Created docs/INDEX.md with comprehensive navigation**
- **Archived stale docs to docs/archive/**
- **Completed EOL/deprecated tools audit** (Readarr RETIRED)
- **Fixed Prowlarr category sync for Mylar** (7030->7000)

---

## Current System State

### CPU-Dominant SVT-AV1 Mode (Active - 2025-12-29 14:00)

Tdarr switched from GPU encoding to **CPU-based SVT-AV1** for maximum compression:
- SVT-AV1 produces ~3x smaller files than GPU encoding
- Estimated 9-14TB savings on 28TB library
- "Let it cook" strategy - slower but much more storage-efficient

```bash
# Current CPU-dominant settings in .env
TDARR_TRANSCODE_GPU_WORKERS=1      # Keep 1 GPU for quick wins
TDARR_TRANSCODE_CPU_WORKERS=4      # Main CPU workload
TDARR_HEALTHCHECK_GPU_WORKERS=2    # GPU file validation (fast)
TDARR_HEALTHCHECK_CPU_WORKERS=0

# Secondary node - all CPU
TDARR_NODE_TRANSCODE_GPU_WORKERS=0
TDARR_NODE_TRANSCODE_CPU_WORKERS=4
TDARR_NODE_HEALTHCHECK_GPU_WORKERS=2
TDARR_NODE_HEALTHCHECK_CPU_WORKERS=0
```

### MergerFS RAM Caching (Fixed - 2025-12-29 13:45)

MergerFS CPU usage fixed from **286% to 0-34%** by enabling aggressive caching:

```bash
# Before (BAD): cache.files=off, dropcacheonclose=true
# After (GOOD): cache.files=auto-full, dropcacheonclose=false
MOUNT_OPTS="defaults,allow_other,use_ino,cache.files=auto-full,dropcacheonclose=false,category.create=mfs,moveonenospc=true,minfreespace=50G,fsname=mergerfs-pool"
```

### Tailscale Remote Access (Configured - 2025-12-29 13:30)

Tailscale enabled for stable remote access despite ISP IP rotation:
- Server Tailscale IP: `100.115.21.9`
- Access all services via Tailscale from anywhere
- More secure than port forwarding (no internet exposure)

### File Queue Status (as of 03:15)
- **Queued**: 2,252 files ready for processing
- **Success**: 1,473 already completed
- **Hold**: Unknown
- **Errors**: 2,140 (NEW: analyzed - see Tdarr Error Analysis below)

---

## Critical Findings

### Readarr is RETIRED (June 27, 2025)

**Status**: Container not running (disabled). Security auth issue now moot.
**Recommendation**: Migrate to Bookshelf fork when CPU frees up
- GitHub repository archived and read-only
- LinuxServer.io deprecated the image
- Current version `develop-0.4.18.2805-ls157` receives NO security updates
- Documented in `docs/decisions/2025-12-29-stack-health-audit.md`

### USB Drive Content Discovery (COMPLETE - 1.6TB Importable)

Five USB drives connected with valuable legacy content:

| Drive | Type | Size | Content | Status |
|-------|------|------|---------|--------|
| `Slow_3TB_HD` | Spinning HDD | 2.8TB | 129GB Music (235 artists), Bookz (Audiobooks, Calibre, Comics, eBooks, Readarr/) | **Lidarr bootstrap candidate** |
| `Slow_4TB_2` | USB SSD | 3.7TB | 1.7TB Movies (555 films) | **Radarr import candidate** |
| `Slow_2TB_2` | USB SSD | 1.9TB | 854GB Anime (64 series) | **Sonarr import candidate** |
| `Slow_2TB_1` | USB SSD | 1.9TB | Emulation/ROMs backup | Keep separate |
| `JoeTerabyte` | NVMe thumb | 1TB | Mostly empty/junk | Wipe & repurpose |

**Dedup Analysis Complete**:
- 117 monitored-missing movies identified
- 257 unique movies total
- 23 unique anime series
- **1.6TB importable content ready**

**Architecture Decision**: Do NOT integrate slow drives into fast NVMe pool. Use as "inform & import" - scan, copy to pool, repurpose drives.

**Mounted at**: `/run/media/deck/Slow_*`

### Plex CPU Optimizations Applied (02:25 EST)

| Setting | Before | After | Effect |
|---------|--------|-------|--------|
| `ScannerLowPriority` | `0` | `1` | Plex yields to Tdarr |
| `BackgroundPreset` | `veryslow` | `fast` | 5x faster thumbnails |
| `LoudnessAnalysisBehavior` | `asap` | `scheduled` | Batches analysis |
| `MusicAnalysisBehavior` | `asap` | `scheduled` | Batches analysis |

**Result**: GPU utilization doubled (10% -> 19%), thermals dropped 84C -> 83C

### Doctor Who Collection Needs Reorganization

**Identified Issues**:
- Classic (1963) episodes mixed into Modern (2005) folders
- Wrong episode numbering (E04, E09, E21, E30 - not sequential)
- German dubbed versions mixed with English
- Files in release folders instead of flat structure
- Missing episodes throughout both series

**Action Required**: Manual curation using TheTVDB as reference

### Tdarr Error Analysis (NEW - 03:00 EST)

**2,140 files in Error state** - Analysis complete:

| Error Category | Count | Root Cause | Action |
|----------------|-------|------------|--------|
| FFprobe success but Error state | 2,131 | `TranscodeDecisionMaker = "Not required"` - stuck from timeout | SAFE TO RESET |
| FFprobe failure (Blood Lad) | 9 | German dub files unreadable | INVESTIGATE |

**Library Breakdown**:
- Anime-TV (kX4Xi337e): 2,139 errors
- Christmas-Movies (jdowPE7GQ): 1 error

**Recovery Command** (safe - these are "Not required" files):
```sql
-- Reset 2,131 recoverable errors
UPDATE filejsondb SET health_check = 'Queued'
WHERE health_check = 'Error'
AND json_extract(json_data, '$.TranscodeDecisionMaker') = 'Not required'
AND json_extract(json_data, '$.scannerReads.ffProbeRead') = 'success';
```

**Blood Lad Issue**: 9 files with German audio (`.German.2013.ANiME.DL.1080p.BluRay`) fail FFprobe - likely corrupt or unusual codec. Need manual inspection.

---

## Current Pool Structure

```
/var/mnt/pool/                    # 41TB MergerFS (30TB used, 11TB free)
├── movies/                       # 691 films (general)
├── tv/                           # 29 shows
├── anime-movies/                 # 25 anime films
├── anime-tv/                     # 75 anime series
├── christmas-movies/             # 26 holiday films (MOVED from symlinks)
├── christmas-tv/                 # Empty, ready for content
├── downloads/                    # SABnzbd/Transmission download location
└── music/                        # Music library
```

---

## Key Configuration Files

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Main stack definition (consolidated from 3 files) |
| `.env` | Machine-specific values (hardware limits, API keys) |
| `.env.example` | Template with hardware documentation |
| `config/tdarr/server/Tdarr/DB2/SQL/database.db` | Tdarr SQLite (libraries, workers, settings) |
| `docs/TDARR_TUNING.md` | Conservative vs aggressive settings guide |
| `docs/SERVICE_LOGS.md` | Log locations for all services |
| `docs/STRATEGIC_ROADMAP.md` | **NEW** - 5-tier prioritized action plan |
| `docs/INDEX.md` | **NEW** - Comprehensive documentation navigation |
| `docs/decisions/2025-12-29-stack-health-audit.md` | **NEW** - EOL tools audit |

---

## Tdarr Configuration

### Libraries (6 total)
All configured with `ffmpeg=true, handbrake=false` for GPU encoding:

| Name | Path (container) | Host Path |
|------|------------------|-----------|
| Movies | /media/movies | /pool/movies |
| TV | /media/tv | /pool/tv |
| Anime Movies | /media/anime-movies | /pool/anime-movies |
| Anime TV | /media/anime-tv | /pool/anime-tv |
| Christmas Movies | /media/christmas-movies | /pool/christmas-movies |
| Christmas TV | /media/christmas-tv | /pool/christmas-tv |

### Worker Configuration (Conservative - Current)
```bash
# Main node - balanced for Plex coexistence
TDARR_TRANSCODE_GPU_WORKERS=4
TDARR_TRANSCODE_CPU_WORKERS=0
TDARR_HEALTHCHECK_GPU_WORKERS=1
TDARR_HEALTHCHECK_CPU_WORKERS=0

# Secondary node
TDARR_NODE_TRANSCODE_GPU_WORKERS=2
TDARR_NODE_TRANSCODE_CPU_WORKERS=0
TDARR_NODE_HEALTHCHECK_GPU_WORKERS=1
TDARR_NODE_HEALTHCHECK_CPU_WORKERS=0
```

---

## Monitoring Tools

### sysinfo-snapshot
Located at `tools/sysinfo-snapshot` - comprehensive system monitoring.

```bash
./tools/sysinfo-snapshot              # Human-readable
./tools/sysinfo-snapshot --json       # JSON for APIs
./tools/sysinfo-snapshot --compact    # Single-line for logs
./tools/sysinfo-snapshot --watch 5    # Continuous monitoring
```

### metrics-collector
Located at `tools/metrics-collector` - SQLite time-series storage.

```bash
./tools/metrics-collector --daemon 30  # Background daemon
./tools/metrics-collector --stats      # View statistics
./tools/metrics-collector --query "1h" # Last hour data
```

Database: `/var/mnt/fast8tb/config/metrics/sysinfo.db`

---

## Hardware Specs (documented in .env)

```
Machine: Steam Deck (Desktop Mode)
CPU: AMD Ryzen 7 7840HS (16 threads) @ 4.6GHz
RAM: 96GB DDR5
GPU: AMD Radeon 780M (RDNA3, 16GB shared, VAAPI support)
Storage: 8TB NVMe (fast8tb) + 41TB MergerFS pool
```

---

## Session Completed Tasks

### Previous Session
- [x] Fix dual mergerfs conflict
- [x] Restructure pool folders (no spaces, flat structure)
- [x] Consolidate docker-compose files
- [x] Fix Tdarr workers not spawning
- [x] Switch Tdarr from HandBrake to FFmpeg/VAAPI
- [x] Wire Transmission to Radarr/Sonarr
- [x] Move Christmas content to dedicated folders
- [x] Fix library ffmpeg/handbrake settings (all 6 libraries)
- [x] Enable GPU health-check workers
- [x] Create sysinfo-snapshot monitoring tool

### This Session (2025-12-29 Night/Early Morning)
- [x] Diagnose Tdarr limbo timeout errors (1,600+ files stuck)
- [x] Identify root cause: Tdarr schedule override forcing CPU workers
- [x] Fix all 24 hour slots in schedule to GPU-only
- [x] Fix docker-compose.yml fallback defaults (were CPU, now GPU)
- [x] Reset all error files to Queued status (twice: 1,600+ then 971)
- [x] Delete 240 orphaned -xpost records from database
- [x] Kill runaway 1Password CLI process (3 days, 110% CPU)
- [x] Create metrics-collector tool with SQLite storage
- [x] Create docs/SERVICE_LOGS.md reference
- [x] Create docs/TDARR_TUNING.md with conservative/aggressive profiles
- [x] Set conservative worker counts while Plex does first-run scan
- [x] Deploy systemd service files for metrics daemon
- [x] Create STRATEGIC_ROADMAP.md with 5-tier action plan
- [x] Create docs/INDEX.md with comprehensive navigation
- [x] Archive stale audit reports to docs/archive/
- [x] Create MANGA_INTEGRATION_STATUS.md with gap analysis
- [x] Complete EOL/deprecated tools audit (found: Readarr RETIRED)
- [x] Fix Prowlarr category for Mylar (7030->7000)
- [x] Analyze Doctor Who collection organization issues
- [x] Create Suwayomi chapter organizer script (tools/suwayomi-organizer.sh)
- [x] Create Readarr -> Bookshelf migration script (tools/migrate-readarr-to-bookshelf.sh)
- [x] Research and document manga collection topology (MANGA_COLLECTION_TOPOLOGY.md)
- [x] Deep thinker adversarial review of topology (COMPLETE - a7452e9)
- [x] Apply Plex CPU optimizations (ScannerLowPriority, BackgroundPreset, AnalysisBehavior)
- [x] Discover and document USB drive content (5 drives, 3TB+ valuable content)
- [x] Create manga pipeline scripts (mylar-post-processor, komga-collection-sync, flatten-manga)
- [x] Deep thinker system optimization analysis (SVT-AV1 vs GPU decision)
- [x] Create SVT-AV1 Production v3 flow with adversarial review fixes
- [x] Fix MergerFS CPU spike (286% -> 0-34%) with RAM caching
- [x] Configure Tailscale for stable remote access (IP: 100.115.21.9)
- [x] Create mergerfs mount script and systemd service
- [x] Update docs/advanced/performance.md with SVT-AV1 and MergerFS sections
- [x] Update docs/networking.md with Tailscale configuration
- [x] Create tdarr-flows/README.md with flow documentation
- [x] USB content deduplication analysis - COMPLETE (1.6TB importable: 117 monitored-missing, 257 unique movies, 23 unique anime)
- [x] Documentation cleanup - COMPLETE (46 files renamed to lowercase-hyphens, commit c858d9c)
- [x] Manga pipeline fixes - COMPLETE (Manga-Weekly dir created, SABnzbd post-processor wired)
- [x] Tdarr config sync - COMPLETE (git-tracked flows/libraries with sync script)
- [ ] Lidarr bootstrap with 235 artists (PENDING)

---

## Overnight Autonomous Work (02:50 - 03:15 EST)

User handed off control for overnight autonomous operation. Directives:
- Be thorough, document as you go
- Push incremental git commits
- Cybernetics-self-sustain; keep identifying valuable work
- Quality over speed

### VAAPI Deep Dive (04:00+ EST)

**Critical Finding**: Deep thinker analysis confirmed Tdarr was using `libx265` (CPU software encoding) instead of `hevc_vaapi` (GPU hardware encoding). This explained the 135+ load average and 100% CPU utilization.

**Verification Steps Completed**:
1. VAAPI is available in Tdarr container (`vainfo` shows AMD 780M with HEVC encode support)
2. DRI devices mounted correctly (`/dev/dri/renderD128` accessible)
3. FFmpeg VAAPI test successful inside container: `hevc_vaapi` encoder works at `4.57x` speed
4. Tdarr node reports `hevc_vaapi-true-true` (encoder enabled AND working)
5. Switched libraries from Flow mode to Plugin mode with `Tdarr_Plugin_00td_action_transcode`
6. Workers not spawning (0 running) despite correct configuration

**Current Blocker**:
- FATAL errors during file scanning: `TypeError: Cannot read properties of undefined (reading 'on')`
- Workers configured correctly (4 GPU transcode, 1 GPU healthcheck per node)
- Libraries show `processLibrary = 1` (enabled)
- Global pause = false, nodes not paused
- **Root Cause Under Investigation**: JavaScript runtime error in `scanFilesInternal`

**System Impact**:
- Load average dropped from **135 -> 43** (Tdarr not transcoding = less CPU)
- Need to fix worker dispatch to utilize VAAPI properly

### Completed During Overnight Session

1. **Created OVERNIGHT_SESSION_2025-12-29.md** - Session planning document
2. **Created USB_CONTENT_INVENTORY.md** - Comprehensive 5-drive inventory:
   - Slow_3TB_HD: 235 artists (129GB), 416GB Books (349GB Comics!)
   - Slow_4TB_2: 555 movies (1.7TB)
   - Slow_2TB_2: 64 anime series (854GB)
   - Slow_2TB_1: Emulation/ROMs backup
   - JoeTerabyte: 465GB trash (repurpose candidate)
3. **Analyzed Tdarr errors** - 2,140 errors diagnosed:
   - 2,131 recoverable (FFprobe success but stuck in Error)
   - 9 Blood Lad files with FFprobe failures (German dubs)
4. **Updated SESSION_STATE.md** with all findings

### Overnight Work Queue (Status)
1. [x] Analyze Tdarr errors - 2,131 recoverable identified
2. [x] Create usb-movie-importer.sh tool - DONE (commit b1e7c1d)
3. [x] Create lidarr-bootstrap.sh tool - DONE (commit b1e7c1d)
4. [x] Create USB_CONTENT_INVENTORY.md - DONE (commit 2911ca9)
5. [x] Commit and push to origin - DONE
6. [ ] Reset 2,131 recoverable Tdarr errors (requires Docker running)
7. [ ] Deep thinker results integration (still processing)

---

## Active Git Commits (This Session)

```
c858d9c docs: rename 46 files to lowercase-hyphens convention
b1e7c1d feat(tools): add USB import tools for Lidarr and Radarr
2911ca9 docs: overnight session - USB inventory and Tdarr error analysis
a7452e9 docs(manga): adversarial review - edge cases, 4-digit padding, migration phases
5af26e2 docs: update SESSION_STATE with manga topology work
77c9a97 docs(manga): researched topology with Komga constraints
53f91fc docs(manga): add collection topology for two-track system
d50fddb feat(tools): add Suwayomi chapter organizer script
73282cf feat(tools): add Readarr to Bookshelf migration script
4a6a7ff audit(stack): EOL tools analysis, Readarr retired, Prowlarr fix
fcba0c4 docs: strategic roadmap, archive stale docs, create INDEX
cd8ac90 fix(tdarr): GPU-only config, monitoring tools, error recovery
```

---

## Next Steps

### Immediate (Priority Order)
1. **Post-transcode**: Move completed AV1 files to pool, start next batch
2. ROM NZBs: Upload 6 files to SABnzbd manually
3. Install mergerfs systemd service for boot persistence:
   ```bash
   sudo cp ~/.local/bin/mergerfs-pool.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable mergerfs-pool.service
   ```

### Short-Term
1. **Bookshelf migration prep** when CPU frees up (Readarr replacement)
2. **USB content import** (1.6TB) - 117 missing movies, 257 unique, 23 anime
3. Reorganize Doctor Who collection (manual curation required)
4. Test Mylar search with new Prowlarr category

### Medium-Term
1. Lidarr bootstrap with 235 artists from USB
2. Run Komf metadata enrichment on manga collection
3. Wire manga-torrent-searcher agent for weekly chapter automation
4. Upgrade Recyclarr to Remux + WEB 2160p profile

### Completed This Session
- [x] Adversarial topology review (23 weaknesses analyzed, addressed)
- [x] 4-digit padding update in suwayomi-organizer.sh
- [x] Edge case naming conventions documented
- [x] USB content dedup analysis (1.6TB importable)
- [x] Documentation cleanup (46 files renamed)
- [x] Manga pipeline fixes (Manga-Weekly, SABnzbd post-processor)
- [x] Tdarr config sync (git-tracked)

---

## Pending Items

### ROM NZBs (6 files awaiting manual upload)
**Location**: `/var/mnt/fast8tb/Local/downloads/roms/nzbs/`
- SMT V Vengeance (NSW): 15.29 GB
- Vagrant Story (PSX): 167.7 MB
- Legend of Mana (PSX): 455 MB
- Mega Man Legends 1 & 2 (PSX): 568 MB total
- Suikoden II BugFix (PSX): 392 MB

### Readarr Status
- Container not running (disabled)
- Security auth issue now moot
- **Recommendation**: Migrate to Bookshelf fork when CPU frees up

---

## Verification Commands

```bash
# Check thermal status
./tools/sysinfo-snapshot --compact

# Check Tdarr file status
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db \
  "SELECT health_check, COUNT(*) FROM filejsondb GROUP BY health_check;"

# Restart Tdarr with new settings
sudo docker compose up -d tdarr tdarr-node --force-recreate

# Check pool health
df -h /var/mnt/pool

# Verify Readarr replacement needed
docker ps | grep readarr
```
