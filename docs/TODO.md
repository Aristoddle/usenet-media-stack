# Usenet Media Stack TODO

**Last Updated**: 2025-12-21
**Current State**: Core infrastructure solid; codebase recently cleaned; ARR services need volume wiring

---

## Recent Completion (Context)

### Wave 5-6 (2025-12-21)

We just completed two significant cleanup waves:

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

The codebase is now clean, with consistent patterns and reusable API libraries.

---

## Immediate Priorities

### 1. ARR Stack Volume Wiring (HIGH)

**What**: Wire source volumes for all ARR services so they can see your media collections.

**Why**: Sonarr, Radarr, Lidarr, etc. need paths to your actual media libraries to manage content. Currently the compose file has placeholders/defaults that don't match your real disk layout.

**Current State**:
- Docker Compose uses `${MEDIA_ROOT:-/srv/usenet/media}` with fallback defaults
- `.env` IS configured with real paths (verified 2025-12-21):
  - `MEDIA_ROOT=/var/mnt/fast8tb/Local/media`
  - `COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- **TODO**: Verify each ARR service has root folders added pointing to container paths

**What Needs to Happen**:
```
1. Inventory your actual media locations:
   - TV shows: /path/to/tv
   - Movies: /path/to/movies
   - Music: /path/to/music
   - Books: /path/to/books

2. Update .env with correct paths:
   MEDIA_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Media
   TV_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Media/TV
   MOVIES_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Media/Movies
   MUSIC_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Media/Music
   BOOKS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books
   COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics

3. Wire Plex to same paths (see Plex section below)

4. Configure root folders in each ARR service via web UI or API:
   - Sonarr: Add /tv as root folder
   - Radarr: Add /movies as root folder
   - Lidarr: Add /music as root folder

5. Verify with: usenet validate (once services running)
```

**Insight**: This is blocking actual media automation. The stack is running but can't find your libraries.

---

### 2. Plex Bring-Up (HIGH)

**What**: Get Plex server running and pointed at your media.

**Why**: Plex is the primary consumption endpoint for TV/Movies/Music.

**Current State**:
- Plex container defined in docker-compose.yml
- Not yet configured with claim token or library paths

**What Needs to Happen**:
```
1. Get Plex claim token from https://plex.tv/claim

2. Set in .env:
   PLEX_CLAIM=claim-xxxxx

3. Bring up Plex:
   docker compose up -d plex

4. Configure libraries via Plex web UI (localhost:32400/web):
   - Add Movies library pointing to /movies
   - Add TV Shows library pointing to /tv
   - Add Music library pointing to /music

5. Optimize settings for your hardware (transcoding, etc.)
```

**Insight**: Plex paths inside container must match what's mounted in compose. The compose mounts `${MEDIA_ROOT}:/media`, so Plex sees `/media/movies`, `/media/tv`, etc.

---

### 3. Additional API Library Migrations (MEDIUM)

**What**: Migrate remaining inline curl calls to use the new API wrappers.

**Why**: Consistency, maintainability, and centralized error handling.

**Files Identified by Deep Analysis**:
| File | Inline Curl Calls | Priority |
|------|------------------|----------|
| `lib/commands/test.zsh` | 6 calls | Medium |
| `lib/test/e2e-test-suite.zsh` | 2 calls | Medium |
| `lib/commands/validate.zsh` | 4 calls | Medium |
| `lib/commands/deploy.zsh` | 1 call | Low |

**How**:
```zsh
# Example migration pattern:
# Before:
curl -s -X POST "${url}/api" -d "apikey=$key" -d "$data"

# After:
source lib/core/arr-api.zsh
sab_api_post "$url" "$key" "$data"
```

---

### 4. Docker Compose Health Checks (MEDIUM)

**What**: Add health checks to remaining services.

**Why**: Enables proper depends_on conditions and container orchestration.

**Current Coverage**:
- WITH health checks: sabnzbd, samba, transmission, prowlarr, docs
- WITHOUT health checks: whisparr, lidarr, mylar, plex, overseerr, tdarr, stash, komga, komf, kavita, suwayomi, aria2, uptime-kuma

**Template**:
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:PORT/ENDPOINT"]
  interval: 30s
  timeout: 10s
  retries: 3
```

---

## Future Work Streams

### MCP Server for Stack Operations (DEFERRED)

**What**: Expose stack operations via MCP protocol for Claude Code integration.

**Why**: Would enable natural language control: "check the download queue", "rescan Sonarr library", etc.

**Feasibility**: MODERATE (2-3 days effort)
- Foundation exists in `lib/python/api_client.py`
- Need MCP wrapper with JSON-RPC stdio interface
- Operations: stack_health, queue_status, library_scan, service_restart

**Insight**: Not blocking anything; pure quality-of-life improvement.

---

### Manga Remediation Swarm (DEFERRED)

**What**: Multi-agent swarm to remediate manga collection (79 series, ~17k files).

**Why**: Collection has naming inconsistencies, missing metadata, corrupt files.

**Status**: Specification complete in `docs/MANGA_REMEDIATION_SWARM.md`

**Scope**:
- 14,956 files need renaming (97%)
- 0 files have ComicInfo.xml (100% need metadata)
- 14 corrupt files need re-acquisition (Blue Box)
- 311 __Panels directories need cleanup (23.4 GB)

**Insight**: This is a large undertaking. The specification is thorough but execution requires dedicated time. Stack wiring is prerequisite (Komga needs to see the collection).

---

### k3s Cluster Migration (ASPIRATIONAL)

**What**: Migrate from Docker Compose to k3s cluster with PC + RPi nodes.

**Why**: Better orchestration, multi-node distribution, proper ingress/TLS.

**Status**: Planning complete in `docs/vnext-cluster-plan.md`

**Dependencies**:
- Current compose stack stable and proven
- RPi5 hardware acquired
- Network infrastructure ready

**Insight**: Don't pursue until compose stack is fully operational and pain points emerge.

---

## Documentation Maintenance

### Files to Keep

| File | Purpose | Status |
|------|---------|--------|
| `docs/TODO.md` | **This file** - canonical TODO | Active |
| `docs/SERVICES.md` | Service registry | Active |
| `docs/reading-stack.md` | Komga/Kavita/Audiobookshelf setup | Active |
| `docs/MANGA_REMEDIATION_SWARM.md` | Manga remediation spec | Deferred |
| `docs/vnext-cluster-plan.md` | k3s cluster planning | Aspirational |

### Files to Archive/Remove

| File | Reason |
|------|--------|
| `docs/TODO-komics-stack.md` | Merged into this file |
| `docs/roadmap.md` | Legacy CLI roadmap, outdated |

---

## Decision Log

### Why These Priorities?

1. **Volume wiring first**: Without correct paths, ARR services can't manage media. Everything else is blocked.

2. **Plex next**: Primary user-facing service. Once media is accessible, Plex makes it consumable.

3. **API migrations deferred**: Codebase works fine with inline curl. Migration is cleanup, not blocking.

4. **Manga remediation deferred**: Large undertaking with its own specification. Stack needs to be stable first.

5. **k3s deferred**: Compose works. Kubernetes adds complexity without solving current problems.

### Key Insights from Deep Analysis

- **API libraries exist but have zero adoption**: Wave 6 started addressing this. More files to migrate.

- **Health checks sparse**: Only 5/28 services have health checks. Not blocking but reduces resilience.

- **Test coverage gaps**: New API libraries have tests; older code doesn't. Technical debt, not urgent.

- **Security posture good**: Credentials properly gitignored, no secrets in history (post-cleanup).

---

## Quick Reference

### Common Commands

```bash
# Bring up full stack
docker compose up -d

# Check service health
./usenet status

# Validate configuration
./usenet validate

# View logs
docker compose logs -f sonarr

# Restart specific service
docker compose restart sonarr
```

### Key Paths

```
Configuration: ${CONFIG_ROOT:-/srv/usenet/config}/
Downloads:     ${DOWNLOADS_ROOT:-/srv/usenet/downloads}/
Media:         ${MEDIA_ROOT:-/srv/usenet/media}/
Books:         ${BOOKS_ROOT:-/srv/usenet/books}/
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

## Session Handoff (2025-12-21)

This section captures everything a new agent needs to pick up where we left off.

### What Just Happened

We completed a comprehensive codebase cleanup in two waves:

1. **Deep Analysis**: Ran 8 parallel agents to audit the entire stack
2. **Wave 5**: Created API libraries, fixed configs, cleaned 150+ stale files
3. **Wave 6**: Adopted API libraries in scripts, added health checks, tests
4. **Documentation**: Consolidated TODOs, archived stale docs, fixed references

**Commits from this session**:
- `bbdbb83` - Wave 5: comprehensive stack cleanup
- `0405273` - Wave 6: API library adoption
- `e2d1821` - Documentation consolidation

### Current System State

**Hardware**: Bazzite (Fedora Atomic) on Steam Deck / gaming PC
**Runtime**: Docker Engine (rootful, requires sudo)
**Storage**: Primary on `/var/mnt/fast8tb/` with OneDrive sync

**Running Services** (24 containers):
```
Prowlarr:9696  Sonarr:8989  Radarr:7878  Lidarr:8686  Whisparr:6969
SABnzbd:8080   Transmission:9091  Aria2:6800
Komga:8081     Komf:8085    Kavita:5000  Mylar:8090  Suwayomi:4567
Plex:32400     Overseerr:5055  Tdarr:8265  Bazarr:6767
Stash:9998     Audiobookshelf:13378
Portainer:9000 Netdata:19999  Uptime-Kuma:3001  Samba:445
```

### Known Path Reality

Your actual content is here (based on prior sessions):
```
/var/mnt/fast8tb/Cloud/OneDrive/
├── Books/
│   ├── Comics/           # Manga collection (79 series, ~17k files)
│   ├── eBooks/           # Ebooks
│   └── Audiobooks/       # Audiobookshelf content
├── Media/
│   ├── TV/               # TV shows (Sonarr target)
│   ├── Movies/           # Movies (Radarr target)
│   └── Music/            # Music (Lidarr target)
└── ...
```

The `.env` file IS populated with real paths. The compose file uses these via
variable substitution (e.g., `${MEDIA_ROOT:-/srv/usenet/media}`).

**Verify mounts match**: Ensure Sonarr/Radarr/Lidarr have root folders pointing
to their mounted paths (`/tv`, `/movies`, `/music` inside containers).

### Current .env State

**Good news**: `.env` already has real paths configured:
```
MEDIA_ROOT=/var/mnt/fast8tb/Local/media
CONFIG_ROOT=/var/mnt/fast8tb/config
DOWNLOADS_ROOT=/var/mnt/fast8tb/Local/downloads
BOOKS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books
COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
```

**Remaining work**: Verify ARR services have root folders configured pointing to these paths.
Each service needs root folders added via web UI or API (e.g., Sonarr needs `/tv`, Radarr needs `/movies`).

### Files You'll Touch Most

| File | Purpose |
|------|---------|
| `.env` | Environment variables (paths, API keys) |
| `docker-compose.yml` | Service definitions |
| `lib/core/arr-api.zsh` | API wrappers for ARR services |
| `lib/python/api_client.py` | Python API clients |
| `docs/TODO.md` | This file - update as you work |

### Git State

```
Branch: main (clean working tree after final commit)
Recent commits: Wave 5, Wave 6, Doc consolidation
Nothing to push (local only)
```

### Pre-Reboot Checklist

Before this reboot, we:
- [x] Cleaned stale docs and files
- [x] Consolidated TODO documentation
- [x] Fixed SECURITY.md stale references
- [x] Committed all changes
- [x] Wrote this handoff section

### Post-Reboot First Steps

1. **Verify Docker is running**: `sudo systemctl status docker`
2. **Check containers**: `sudo docker ps`
3. **If services down**: `cd /path/to/usenet-media-stack && sudo docker compose up -d`
4. **Resume work**: Start with `.env` path configuration

### Quick Commands for New Agent

```bash
# Where we are
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack

# Git status
git log --oneline -5
git status

# See running services
sudo docker ps --format "table {{.Names}}\t{{.Status}}"

# Check service health
sudo docker compose ps

# Read a specific service log
sudo docker logs sonarr --tail 50
```

---

**Next Session**: Start with `.env` audit and volume wiring. Map your actual disk paths to compose variables. Then bring up Plex.
