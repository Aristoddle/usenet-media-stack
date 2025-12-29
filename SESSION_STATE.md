# Session State - Media Stack Infrastructure Overhaul
## Date: 2025-12-29 (Updated: 01:10 EST)

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

### File Queue Status
- **Queued**: 4,144 files ready for processing
- **Success**: 1,455 already completed
- **Hold**: 26 on hold
- **Errors**: 0 (all reset)

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
| `docs/TDARR_TUNING.md` | **NEW** - Conservative vs aggressive settings guide |
| `docs/SERVICE_LOGS.md` | **NEW** - Log locations for all services |

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

### Critical Fix Applied: Schedule Override

Tdarr's **24-hour schedule** was overriding workerLimits with CPU workers. Fixed all 24 hour slots to GPU-only:

```bash
# Verify schedule is GPU-only
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db \
  "SELECT json_extract(json_data, '$.schedule[0]') FROM nodejsondb WHERE id='MainNode';"
# Should show: healthcheckcpu=0, transcodecpu=0
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

### Systemd Service (Optional)
```bash
sudo cp tools/systemd/media-stack-metrics.service /etc/systemd/system/
sudo systemctl enable --now media-stack-metrics.service
```

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

### This Session (2025-12-29 Night)
- [x] Diagnose Tdarr limbo timeout errors (1,600+ files stuck)
- [x] Identify root cause: Tdarr schedule override forcing CPU workers
- [x] Fix all 24 hour slots in schedule to GPU-only
- [x] Fix docker-compose.yml fallback defaults (were CPU, now GPU)
- [x] Reset all error files to Queued status
- [x] Delete 240 orphaned -xpost records from database
- [x] Kill runaway 1Password CLI process (3 days, 110% CPU)
- [x] Create metrics-collector tool with SQLite storage
- [x] Create docs/SERVICE_LOGS.md reference
- [x] Create docs/TDARR_TUNING.md with conservative/aggressive profiles
- [x] Set conservative worker counts while Plex does first-run scan
- [x] Deploy systemd service files for metrics daemon

---

## Next Steps

### Immediate (After Plex Finishes First-Run)
1. Monitor thermals until Plex library analysis completes
2. Scale Tdarr to aggressive settings (see TDARR_TUNING.md)
3. Verify queue is processing smoothly

### Documentation Cleanup (Phase 1)
1. Archive stale audit reports to `docs/archive/`
2. Create `docs/INDEX.md` with comprehensive TOC
3. Normalize doc naming (lowercase with hyphens)

### Future Improvements
1. Rolling stats analysis with time-window aggregation
2. Get/set wrapper tooling for easy queryability
3. Automated thermal-aware worker scaling
4. Import Christmas movies to Radarr

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
```
