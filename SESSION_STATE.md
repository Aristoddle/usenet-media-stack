# Session State - Media Stack Infrastructure Overhaul
## Date: 2025-12-29 (Updated: 03:15 EST)

This document captures the complete state after a major infrastructure session.
Use this to continue work post-context-compaction.

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
- **Fixed Prowlarr category sync for Mylar** (7030→7000)

---

## Current System State

### Conservative Mode (Active)

Tdarr is running in conservative mode while Plex completes first-run library analysis:
- Plex is generating: chapter thumbnails, intro/outro detection, audio fingerprints
- This is one-time work; after completion, Tdarr can scale up

```bash
# Current conservative settings in .env
TDARR_TRANSCODE_GPU_WORKERS=4
TDARR_HEALTHCHECK_GPU_WORKERS=1

# Aggressive settings for later (documented in docs/TDARR_TUNING.md)
TDARR_TRANSCODE_GPU_WORKERS=6
TDARR_HEALTHCHECK_GPU_WORKERS=2
```

### File Queue Status (as of 03:15)
- **Queued**: 2,252 files ready for processing
- **Success**: 1,473 already completed
- **Hold**: Unknown
- **Errors**: 2,140 (NEW: analyzed - see Tdarr Error Analysis below)

---

## Critical Findings

### Readarr is RETIRED (June 27, 2025)

**Action Required**: Replace with Bookshelf fork
- GitHub repository archived and read-only
- LinuxServer.io deprecated the image
- Current version `develop-0.4.18.2805-ls157` receives NO security updates
- Documented in `docs/decisions/2025-12-29-stack-health-audit.md`

### USB Drive Content Discovery (NEW - 02:30 EST)

Five USB drives connected with valuable legacy content:

| Drive | Type | Size | Content | Status |
|-------|------|------|---------|--------|
| `Slow_3TB_HD` | Spinning HDD | 2.8TB | 129GB Music (235 artists), Bookz (Audiobooks, Calibre, Comics, eBooks, Readarr/) | **Lidarr bootstrap candidate** |
| `Slow_4TB_2` | USB SSD | 3.7TB | 1.7TB Movies (555 films) | **Radarr import candidate** |
| `Slow_2TB_2` | USB SSD | 1.9TB | 854GB Anime (64 series) | **Sonarr import candidate** |
| `Slow_2TB_1` | USB SSD | 1.9TB | Emulation/ROMs backup | Keep separate |
| `JoeTerabyte` | NVMe thumb | 1TB | Mostly empty/junk | Wipe & repurpose |

**Architecture Decision**: Do NOT integrate slow drives into fast NVMe pool. Use as "inform & import" - scan, copy to pool, repurpose drives.

**Mounted at**: `/run/media/deck/Slow_*`

### Plex CPU Optimizations Applied (02:25 EST)

| Setting | Before | After | Effect |
|---------|--------|-------|--------|
| `ScannerLowPriority` | `0` | `1` | Plex yields to Tdarr |
| `BackgroundPreset` | `veryslow` | `fast` | 5x faster thumbnails |
| `LoudnessAnalysisBehavior` | `asap` | `scheduled` | Batches analysis |
| `MusicAnalysisBehavior` | `asap` | `scheduled` | Batches analysis |

**Result**: GPU utilization doubled (10% → 19%), thermals dropped 84°C → 83°C

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
- [x] Fix Prowlarr category for Mylar (7030→7000)
- [x] Analyze Doctor Who collection organization issues
- [x] Create Suwayomi chapter organizer script (tools/suwayomi-organizer.sh)
- [x] Create Readarr → Bookshelf migration script (tools/migrate-readarr-to-bookshelf.sh)
- [x] Research and document manga collection topology (MANGA_COLLECTION_TOPOLOGY.md)
- [x] Deep thinker adversarial review of topology (COMPLETE - a7452e9)
- [x] Apply Plex CPU optimizations (ScannerLowPriority, BackgroundPreset, AnalysisBehavior)
- [x] Discover and document USB drive content (5 drives, 3TB+ valuable content)
- [x] Create manga pipeline scripts (mylar-post-processor, komga-collection-sync, flatten-manga)
- [ ] Deep thinker system optimization analysis (IN PROGRESS)
- [ ] USB content deduplication analysis (PENDING)
- [ ] Lidarr bootstrap with 235 artists (PENDING)

---

## Overnight Autonomous Work (02:50 - 03:15 EST)

User handed off control for overnight autonomous operation. Directives:
- Be thorough, document as you go
- Push incremental git commits
- Cybernetics-self-sustain; keep identifying valuable work
- Quality over speed

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

### Overnight Work Queue (Remaining)
1. [ ] Reset 2,131 recoverable Tdarr errors
2. [ ] Create usb-movie-importer.sh tool
3. [ ] Create lidarr-bootstrap.sh tool
4. [ ] Commit documentation updates
5. [ ] Deep thinker results integration

---

## Active Git Commits (This Session)

```
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
1. Create missing manga pipeline scripts:
   - `mylar-post-processor.sh` - SABnzbd post-processing hook
   - `komga-collection-sync.sh` - Cross-library collection linking
   - `flatten-manga-directories.sh` - Migration helper for nested folders
2. Create Manga-Weekly directory structure for two-library topology
3. Scale Tdarr to aggressive settings (Plex analysis complete)

### Short-Term
1. Replace Readarr with Bookshelf fork (see `docs/decisions/2025-12-29-stack-health-audit.md`)
2. Reorganize Doctor Who collection (manual curation required)
3. Test Mylar search with new Prowlarr category

### Medium-Term
1. Run Komf metadata enrichment on manga collection
2. Wire manga-torrent-searcher agent for weekly chapter automation
3. Upgrade Recyclarr to Remux + WEB 2160p profile

### Completed This Session
- [x] Adversarial topology review (23 weaknesses analyzed, addressed)
- [x] 4-digit padding update in suwayomi-organizer.sh
- [x] Edge case naming conventions documented

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
