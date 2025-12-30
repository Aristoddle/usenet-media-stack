# Usenet Media Stack TODO

**Last Updated**: 2025-12-30
**Current State**: Major infrastructure overhaul complete; SVT-AV1 transcoding active; USB content discovered; stack running 25 containers

---

## Recent Completion (Context)

### Major Session (2025-12-29)

Extensive infrastructure overhaul completed:

**Infrastructure Fixes**:
- Fixed dual MergerFS conflict causing race conditions
- Restructured pool to clean `/pool/{movies,tv,anime-movies,anime-tv,christmas-movies,christmas-tv}`
- Fixed MergerFS CPU usage (286% -> 0-34%) with RAM caching
- Configured Tailscale for stable remote access (IP: 100.115.21.9)

**Tdarr Overhaul**:
- Fixed Tdarr to use FFmpeg/VAAPI (GPU) instead of HandBrake (CPU)
- Fixed Tdarr schedule override forcing CPU workers
- Fixed docker-compose.yml defaults falling back to CPU workers
- Switched to **CPU-based SVT-AV1** for maximum compression (60-70% reduction)
- Reset 1,600+ error files back to Queued for reprocessing
- Created comprehensive Tdarr documentation (docs/TDARR.md)

**ISO Pipeline**:
- Created ISO_REENCODING_WORKFLOW.md with MakeMKV + Tdarr pipeline
- SVT-AV1 Production v3 flow for Blu-ray ISO transcoding
- MakeMKV container for disc extraction

**USB Content Discovery** (5 drives):
- Slow_3TB_HD: 235 artists (129GB Music), 416GB Books (349GB Comics)
- Slow_4TB_2: 555 movies (1.7TB)
- Slow_2TB_2: 64 anime series (854GB)
- Full inventory in docs/USB_CONTENT_INVENTORY.md

**Tools Created**:
- `tools/sysinfo-snapshot` - System monitoring
- `tools/metrics-collector` - SQLite time-series storage
- `tools/lidarr-bootstrap.sh` - USB music import
- `tools/usb-movie-importer.sh` - USB movie import
- `tools/suwayomi-organizer.sh` - Manga chapter organization
- `tools/migrate-readarr-to-bookshelf.sh` - Readarr replacement migration

**Documentation**:
- Created docs/STRATEGIC_ROADMAP.md with 5-tier action plan
- Created docs/DOCUMENTATION_INDEX.md with comprehensive navigation
- Created docs/TDARR.md consolidating tuning and troubleshooting
- Archived stale docs to docs/archive/
- Completed EOL tools audit (Readarr RETIRED - see below)

**Critical Finding**: Readarr is RETIRED (June 2025) - needs replacement with Bookshelf fork.

### Wave 5-6 (2025-12-21)

Earlier cleanup work:

**Wave 5** - Stack cleanup and API consolidation:
- Created `lib/core/arr-api.zsh` with unified ARR/SABnzbd API wrappers
- Created `lib/python/api_client.py` with typed HTTP clients
- Fixed EBOOKS_ROOT case consistency across all files
- Cleaned 150+ stale VitePress build artifacts from git
- Deleted superseded documentation
- Moved root `.md` files to `docs/`

**Wave 6** - API library adoption:
- Migrated `configure.zsh` to use arr-api.zsh (8 curl calls replaced)
- Refactored `validate-services.py` to import api_client.py
- Added health checks to transmission and prowlarr in docker-compose
- Fixed SELinux labels and security mounts
- Added 12 unit tests for arr-api.zsh
- Deleted superseded `lib/help.sh`

---

## Current System State

### Storage

| Mount | Size | Used | Available | Use% |
|-------|------|------|-----------|------|
| MergerFS Pool | 41TB | 30TB | 11TB | 73% |
| NVMe (fast8tb) | 7.3TB | 3.1TB | 4.3TB | 42% |

### Tdarr Queue (as of 12/29)

- **Queued**: 2,252+ files ready for SVT-AV1 encoding
- **Success**: 1,473 completed
- **Errors**: 2,140 (2,131 recoverable, 9 Blood Lad German dubs)

### Pool Structure

```
/var/mnt/pool/
├── movies/          # 691 films
├── tv/              # 29 shows
├── anime-movies/    # 25 anime films
├── anime-tv/        # 75 anime series
├── christmas-movies/ # 26 holiday films
├── christmas-tv/    # Empty, ready for content
├── downloads/       # SABnzbd/Transmission
└── music/           # Music library
```

---

## Immediate Priorities

### 1. Readarr Replacement (HIGH - SECURITY)

**What**: Replace retired Readarr with Bookshelf fork.

**Why**: Readarr was retired June 27, 2025. Current version receives NO security updates.

**Status**: Migration script created at `tools/migrate-readarr-to-bookshelf.sh`

**Documentation**: `docs/decisions/2025-12-29-stack-health-audit.md`

---

### 2. Reset Recoverable Tdarr Errors (HIGH)

**What**: Reset 2,131 recoverable error files to Queued state.

**Why**: Files stuck from timeout/limbo, not actually corrupt.

**Command**:
```sql
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db "
UPDATE filejsondb SET health_check = 'Queued'
WHERE health_check = 'Error'
AND json_extract(json_data, '$.TranscodeDecisionMaker') = 'Not required'
AND json_extract(json_data, '$.scannerReads.ffProbeRead') = 'success';"
```

---

### 3. USB Content Import (MEDIUM)

**What**: Import valuable content from USB drives to pool.

**Priority**:
1. Music (235 artists) -> Lidarr bootstrap
2. Movies (555 films) -> Radarr dedup check
3. Anime (64 series) -> Sonarr dedup check
4. Comics (349GB) -> Komga integration

**Tools**: `tools/lidarr-bootstrap.sh`, `tools/usb-movie-importer.sh`

---

### 4. Manga Pipeline Completion (MEDIUM)

**What**: Complete end-to-end manga acquisition pipeline.

**Remaining**:
- Fix Prowlarr category sync for Mylar (already fixed: 7030->7000)
- Test Mylar -> Prowlarr -> SABnzbd -> Komga flow
- Run Komf metadata enrichment

**Documentation**: See docs/MANGA_INTEGRATION_STATUS.md

---

### 5. Doctor Who Reorganization (LOW)

**What**: Manual curation of Doctor Who collection.

**Issues**:
- Classic (1963) episodes mixed into Modern (2005) folders
- German dubbed versions mixed with English
- Files in release folders instead of flat structure

**Documentation**: docs/DOCTOR_WHO_ORGANIZATION.md

---

## Future Work Streams

### MCP Server for Stack Operations (DEFERRED)

**What**: Expose stack operations via MCP protocol for Claude Code integration.

**Why**: Would enable natural language control: "check the download queue", "rescan Sonarr library", etc.

**Feasibility**: MODERATE (2-3 days effort)
- Foundation exists in `lib/python/api_client.py`
- Need MCP wrapper with JSON-RPC stdio interface

---

### Manga Remediation Swarm (DEFERRED)

**What**: Multi-agent swarm to remediate manga collection (79 series, ~17k files).

**Status**: Specification complete in `docs/archive/projects/MANGA_REMEDIATION_SWARM.md`

**Scope**:
- 14,956 files need renaming (97%)
- 0 files have ComicInfo.xml (100% need metadata)
- 14 corrupt files need re-acquisition (Blue Box)
- 311 __Panels directories need cleanup (23.4 GB)

---

### k3s Cluster Migration (ASPIRATIONAL)

**What**: Migrate from Docker Compose to k3s cluster with PC + RPi nodes.

**Status**: Planning complete in `docs/vnext-cluster-plan.md`

**Insight**: Don't pursue until compose stack is fully operational and pain points emerge.

---

## Documentation Structure

### Key Documents

| Document | Purpose |
|----------|---------|
| `SESSION_STATE.md` (repo root) | Current session state - authoritative |
| `docs/STRATEGIC_ROADMAP.md` | 5-tier prioritized action plan |
| `docs/DOCUMENTATION_INDEX.md` | Master documentation navigation |
| `docs/TDARR.md` | Tdarr configuration and troubleshooting |
| `docs/ISO_REENCODING_WORKFLOW.md` | ISO to AV1 pipeline |
| `docs/SERVICES.md` | Service registry and ports |

### Archive Structure

```
docs/archive/
├── audits/           # Dated audit reports
├── projects/         # Completed project docs
└── sessions/         # Session notes
```

---

## Quick Reference

### Common Commands

```bash
# System monitoring
./tools/sysinfo-snapshot              # Human-readable
./tools/sysinfo-snapshot --watch 5    # Continuous

# Tdarr queue status
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db \
  "SELECT health_check, COUNT(*) FROM filejsondb GROUP BY health_check;"

# Service management
sudo docker compose up -d
sudo docker compose ps
sudo docker logs sonarr --tail 50

# Pool health
df -h /var/mnt/pool
```

### Key Paths

```
Configuration: /var/mnt/fast8tb/config/
Downloads:     /var/mnt/fast8tb/Local/downloads/
Pool:          /var/mnt/pool/
Comics:        /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/
```

### API Libraries

```zsh
# Zsh - source and use
source lib/core/arr-api.zsh
arr_api_post "$url" "$api_key" "/api/v3/rootfolder" "$json"
sab_api_call "$url" "$api_key" "mode=queue&output=json"
```

```python
# Python - import and use
from lib.python.api_client import ArrClient, SabClient
sonarr = ArrClient("http://localhost:8989", api_key)
if sonarr.is_healthy():
    sonarr.post_json("/api/v3/command", {"name": "RescanSeries"})
```

---

## Session Handoff

**Authoritative Session State**: See `SESSION_STATE.md` in repository root.

This file (SESSION_STATE.md) contains:
- Complete task list with completion status
- Current system configuration (Tdarr workers, MergerFS, etc.)
- USB drive inventory
- Overnight session deliverables
- Next steps and verification commands

**Last Major Session**: 2025-12-29 (overnight autonomous work)

---

*For comprehensive documentation navigation, see docs/DOCUMENTATION_INDEX.md*
*For current priorities, see docs/STRATEGIC_ROADMAP.md*
