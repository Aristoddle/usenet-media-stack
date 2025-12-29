# Stack Optimization Audit Checklist

**Created**: 2025-12-28
**Purpose**: Systematic audit of every service in the usenet-media-stack for hardware-aware, research-grounded, optimal configuration.

---

## Audit Methodology (Proven with Tdarr)

For each service, apply this process:

1. **Discovery**: Inventory current config, API endpoints, capabilities
2. **Research**: Web search for 2024-2025 best practices, TRaSH Guides, hardware optimization
3. **Hardware Audit**: Check CPU/GPU/RAM utilization, optimize for AMD Ryzen 7 7840HS + Radeon 780M
4. **Configuration**: Apply optimal settings via API or config files
5. **Validation**: Test functionality, verify integrations
6. **Documentation**: Update STACK_USAGE_GUIDE.md with operational status and API reference
7. **Commit**: Git commit with learnings

---

## Hardware Context

| Component | Spec | Optimization Notes |
|-----------|------|-------------------|
| CPU | AMD Ryzen 7 7840HS (8C/16T, 5.1GHz) | Favor parallel processing |
| GPU | AMD Radeon 780M (VCN4, RDNA3) | VAAPI for transcoding |
| RAM | 96GB DDR5 | Can run aggressive caching |
| Storage | 52TB NVMe pool (MergerFS) | Fast I/O, no HDD spinup concerns |
| Network | Gigabit LAN | Local streaming optimized |

---

## Service Categories

### Tier 1: Core Automation (*arr Stack)
These are the brain of the operation - highest priority.

| Service | Port | Status | Audit Date | Notes |
|---------|------|--------|------------|-------|
| Prowlarr | 9696 | ✅ Complete | 2025-12-28 | Priorities staggered, fullSync verified |
| Radarr | 7878 | ✅ Complete | 2025-12-28 | 35 CF via Recyclarr, UHD+WEB profile |
| Sonarr | 8989 | ✅ Complete | 2025-12-28 | 33 CF via Recyclarr, WEB-2160p profile |
| Lidarr | 8686 | ⬜ Pending | - | Music management |
| Readarr | 8787 | ⬜ Pending | - | eBooks/audiobooks |
| Whisparr | 6969 | ⬜ Pending | - | Adult content automation |
| Mylar | 8090 | ⬜ Pending | - | Comics/manga |

### Tier 2: Download Clients
The hands that grab content.

| Service | Port | Status | Audit Date | Notes |
|---------|------|--------|------------|-------|
| SABnzbd | 8080 | ✅ Complete | 2025-12-28 | par2-turbo 16T, 4 servers, direct_unpack |
| Transmission | 9091 | ⬜ Pending | - | Torrent fallback, seeding ratios |
| Aria2 | 6800 | ⬜ Pending | - | Direct downloads, metalink support |

### Tier 3: Media Servers & Readers
User-facing services.

| Service | Port | Status | Audit Date | Notes |
|---------|------|--------|------------|-------|
| Plex | 32400 | ⬜ Pending | - | Primary media server, hardware transcode |
| Audiobookshelf | 13378 | ⬜ Pending | - | Audiobooks + podcasts |
| Komga | 8081 | ⬜ Pending | - | Comics/manga reader |
| Kavita | 5000 | ⬜ Pending | - | eBooks/manga reader |
| Stash | 9999 | ⬜ Pending | - | Adult content organization |
| Suwayomi | 4567 | ⬜ Pending | - | Manga source aggregation |

### Tier 4: Enhancement Services
Improve the core experience.

| Service | Port | Status | Audit Date | Notes |
|---------|------|--------|------------|-------|
| Tdarr | 8265 | ✅ Complete | 2025-12-28 | GPU VAAPI transcoding, 5699 files queued |
| Bazarr | 6767 | ⬜ Pending | - | Subtitle management |
| Tautulli | 8181 | ⬜ Pending | - | Plex analytics |
| Komf | 8085 | ⬜ Pending | - | Manga metadata enrichment |
| Recyclarr | - | ⬜ Pending | - | TRaSH Guides sync |
| Overseerr | 5055 | ⬜ Pending | - | Request management |

### Tier 5: Infrastructure
Keep everything running.

| Service | Port | Status | Audit Date | Notes |
|---------|------|--------|------------|-------|
| Portainer | 9000 | ⬜ Pending | - | Container management |
| Netdata | 19999 | ⬜ Pending | - | System monitoring |
| Uptime Kuma | 3001 | ⬜ Pending | - | Service health checks |
| Samba | 445 | ⬜ Pending | - | Network shares |

---

## Detailed Audit Checklists

### Prowlarr Audit
```
[ ] Research: TRaSH Guides indexer recommendations 2025
[ ] Research: Usenet vs torrent indexer priority
[ ] Research: Rate limiting and API call optimization
[ ] Config: Verify sync to all *arr apps working
[ ] Config: Optimize indexer priorities
[ ] Config: Set appropriate grab limits
[ ] API: Document indexer management endpoints
[ ] Hardware: N/A (network-bound)
[ ] Test: Trigger search, verify results propagate
[ ] Docs: Update STACK_USAGE_GUIDE.md
[ ] Commit: Git commit with findings
```

### Radarr Audit
```
[ ] Research: TRaSH Guides custom formats 2025
[ ] Research: Quality profile recommendations (1080p, 4K, Anime)
[ ] Research: Preferred words and scoring
[ ] Config: Import TRaSH custom formats
[ ] Config: Create optimal quality profiles
[ ] Config: Configure naming conventions
[ ] Config: Set up recycling bin / failed download handling
[ ] API: Document movie management endpoints
[ ] Hardware: Check indexing performance
[ ] Integration: Verify Overseerr → Radarr flow
[ ] Integration: Verify Radarr → SABnzbd/Transmission flow
[ ] Test: Request movie, verify full pipeline
[ ] Docs: Update with quality profile settings
[ ] Commit: Git commit with findings
```

### Sonarr Audit
```
[ ] Research: TRaSH Guides TV quality profiles 2025
[ ] Research: Anime-specific profiles (absolute vs standard numbering)
[ ] Research: Season pack vs single episode preferences
[ ] Config: Import TRaSH custom formats
[ ] Config: Create TV and Anime quality profiles
[ ] Config: Configure release profiles
[ ] Config: Set up series type detection
[ ] API: Document series management endpoints
[ ] Hardware: Check indexing performance
[ ] Integration: Verify Overseerr → Sonarr flow
[ ] Test: Request series, verify episode grab
[ ] Docs: Update with anime setup specifics
[ ] Commit: Git commit with findings
```

### SABnzbd Audit
```
[ ] Research: Par2 multicore optimization
[ ] Research: Unrar threading settings
[ ] Research: NZB queue prioritization
[ ] Research: Category folder mapping best practices
[ ] Config: Optimize par2 repair threads (8-16 for 7840HS)
[ ] Config: Optimize unrar threads
[ ] Config: Set up categories for each *arr app
[ ] Config: Configure post-processing scripts
[ ] Config: Set bandwidth scheduling if needed
[ ] API: Document queue management endpoints
[ ] Hardware: Benchmark par2/unrar performance
[ ] Test: Queue large NZB, measure throughput
[ ] Docs: Update with performance settings
[ ] Commit: Git commit with findings
```

### Plex Audit
```
[ ] Research: Hardware transcoding on AMD 780M (VAAPI)
[ ] Research: Optimal transcoder settings
[ ] Research: Library scan optimization
[ ] Research: Intro/credits detection settings
[ ] Config: Enable hardware transcoding
[ ] Config: Optimize library scan intervals
[ ] Config: Configure remote access if needed
[ ] Config: Set up collections/smart playlists
[ ] API: Document library management endpoints
[ ] Hardware: Test VAAPI transcoding quality
[ ] Hardware: Measure GPU utilization during transcode
[ ] Integration: Verify Tautulli connection
[ ] Test: Stream with forced transcode, check quality
[ ] Docs: Update with transcoding settings
[ ] Commit: Git commit with findings
```

### Bazarr Audit
```
[ ] Research: Best subtitle providers 2025
[ ] Research: Subtitle scoring algorithms
[ ] Research: Hearing impaired / foreign parts handling
[ ] Config: Configure subtitle providers (OpenSubtitles, Subscene, etc)
[ ] Config: Set language priorities
[ ] Config: Configure anti-captcha if needed
[ ] Config: Set up subtitle sync (ffsubsync/alass)
[ ] API: Document subtitle management endpoints
[ ] Integration: Verify Radarr/Sonarr connection
[ ] Test: Trigger subtitle search, verify quality
[ ] Docs: Update with provider recommendations
[ ] Commit: Git commit with findings
```

### Recyclarr Audit
```
[ ] Research: TRaSH Guides sync configuration 2025
[ ] Research: Custom format import strategies
[ ] Config: Set up recyclarr.yml with quality definitions
[ ] Config: Configure Radarr sync settings
[ ] Config: Configure Sonarr sync settings
[ ] Config: Set sync schedule (daily recommended)
[ ] Test: Run sync, verify custom formats imported
[ ] Docs: Update with recyclarr usage
[ ] Commit: Git commit with findings
```

### Komga Audit
```
[ ] Research: CBZ/CBR handling optimization
[ ] Research: Metadata scraping sources
[ ] Research: OPDS feed configuration
[ ] Config: Set up library scan schedule
[ ] Config: Configure metadata providers
[ ] Config: Optimize thumbnail generation (GPU?)
[ ] API: Document library management endpoints
[ ] Integration: Verify Komf metadata enrichment
[ ] Test: Import series, check metadata quality
[ ] Docs: Update with library structure
[ ] Commit: Git commit with findings
```

### Kavita Audit
```
[ ] Research: eBook format support optimization
[ ] Research: Manga library organization
[ ] Research: OPDS configuration
[ ] Config: Set up library structure
[ ] Config: Configure metadata sources
[ ] Config: Set scan intervals
[ ] API: Document library endpoints
[ ] Integration: Verify Komf connection
[ ] Test: Import ebook collection, check parsing
[ ] Docs: Update with format recommendations
[ ] Commit: Git commit with findings
```

### Audiobookshelf Audit
```
[ ] Research: Metadata sources (Audible, Goodreads, etc)
[ ] Research: Chapter detection optimization
[ ] Research: Mobile app configuration
[ ] Config: Configure metadata providers
[ ] Config: Set up library scan schedule
[ ] Config: Configure backup settings
[ ] API: Document library management endpoints
[ ] Hardware: Check transcoding settings
[ ] Test: Import audiobook, verify metadata + chapters
[ ] Docs: Update with mobile setup guide
[ ] Commit: Git commit with findings
```

### Overseerr Audit
```
[ ] Research: Request management best practices
[ ] Research: User permission tiers
[ ] Research: Discovery recommendations tuning
[ ] Config: Verify Radarr/Sonarr connections
[ ] Config: Configure default servers
[ ] Config: Set up request limits per user
[ ] Config: Configure notifications
[ ] API: Document request management endpoints
[ ] Integration: Test full request → download → notify pipeline
[ ] Test: Make request, verify end-to-end
[ ] Docs: Update with user setup guide
[ ] Commit: Git commit with findings
```

### Tautulli Audit
```
[ ] Research: Notification configuration
[ ] Research: Newsletter feature
[ ] Research: Statistics retention settings
[ ] Config: Verify Plex connection
[ ] Config: Configure notifications (Discord/email)
[ ] Config: Set up watched history exports
[ ] API: Document statistics endpoints
[ ] Test: Trigger playback, verify tracking
[ ] Docs: Update with notification setup
[ ] Commit: Git commit with findings
```

---

## Priority Order

Based on user impact and complexity:

### Phase 1: Core Pipeline (High Impact)
1. ✅ **Prowlarr** - Indexer health affects everything downstream
2. ✅ **SABnzbd** - Download performance critical
3. ✅ **Radarr** - Movie quality profiles (via Recyclarr)
4. ✅ **Sonarr** - TV/Anime quality profiles (via Recyclarr)
5. ✅ **Recyclarr** - TRaSH Guides sync verified

### Phase 2: User Experience (Medium Impact)
6. ⬜ **Plex** - Hardware transcoding
7. ⬜ **Overseerr** - Request flow
8. ⬜ **Bazarr** - Subtitles
9. ⬜ **Tautulli** - Analytics

### Phase 3: Reading Stack (Medium Impact)
10. ⬜ **Komga** - Comics
11. ⬜ **Kavita** - eBooks
12. ⬜ **Komf** - Metadata
13. ⬜ **Audiobookshelf** - Audiobooks
14. ⬜ **Mylar** - Comic automation

### Phase 4: Secondary Services (Lower Impact)
15. ⬜ **Lidarr** - Music
16. ⬜ **Readarr** - Books
17. ⬜ **Transmission** - Torrent fallback
18. ⬜ **Aria2** - Direct downloads

### Phase 5: Infrastructure (Maintenance)
19. ⬜ **Stash** - Adult content
20. ⬜ **Whisparr** - Adult automation
21. ⬜ **Suwayomi** - Manga sources
22. ⬜ **Portainer** - Container management
23. ⬜ **Netdata** - Monitoring
24. ⬜ **Uptime Kuma** - Health checks
25. ⬜ **Samba** - Network shares

---

## Completed Audits

### Prowlarr (2025-12-28) ✅
- **Status**: Fully operational
- **Indexers**: 4 Usenet (NZBgeek, NZBPlanet, NZBFinder, NZB.su)
- **Configuration**: Staggered priorities (10/15/20/25), fullSync to 5 apps
- **Optimizations Applied**:
  - Priority staggering: NZBgeek=10, NZBPlanet=15, NZBFinder=20, NZB.su=25
  - Equal priority causes first-added indexer to always win tiebreakers
- **Learnings**:
  - API: GET/PUT `/api/v1/indexer/{id}` for indexer management
  - Full Sync recommended over Add and Remove Only
  - 4 indexers is optimal for coverage
  - Priority affects tiebreaker scenarios only

### SABnzbd (2025-12-28) ✅
- **Status**: Fully operational (1,826 items queued, 20.6 TB)
- **Servers**: 4 (Newshosting, UsenetExpress, Frugal x2) with 85 connections
- **Configuration**: par2-turbo 16 threads, direct_unpack enabled
- **Correct Variable Names** (in sabnzbd.ini):
  ```ini
  par_option = -t+           # NOT extra_par2_parameters
  cache_limit = 4G           # NOT article_cache_limit
  direct_unpack = 1
  direct_unpack_threads = 3
  ```
- **API Configuration** (correct approach):
  ```bash
  # Use mode=set_config (NOT set_config_default)
  curl "http://192.168.6.167:8080/api?apikey=KEY&mode=set_config&section=misc&keyword=par_option&value=-t%2B&output=json"
  curl "http://192.168.6.167:8080/api?apikey=KEY&mode=set_config&section=misc&keyword=cache_limit&value=4G&output=json"
  ```
- **Verified Settings**:
  - par2cmdline-turbo with 16-thread detection
  - 4 servers with proper priority (0, 0, 2, 3)
  - Categories: movies, tv, comics, audio, software, whisparr, books
- **Learnings**:
  - Article cache max is 4G (hard-coded limit)
  - Unrar is single-threaded (disk I/O bound)
  - par2 `-t+` enables full multicore on Linux
  - `set_config_default` RESETS to defaults; use `set_config` to SET values
  - Variable names differ from UI labels (par_option vs "Extra PAR2 Parameters")
- **Persistence**: ✅ Verified survives container restart

### Radarr (2025-12-28) ✅
- **Status**: Fully operational via Recyclarr sync
- **Custom Formats**: 35 (TRaSH Guides complete set)
- **Quality Profiles**: UHD Bluray + WEB (AV1 +100, HEVC +50)
- **Root Folders**: /pool/movies, /pool/anime (11.3 TB free)
- **Verified**: No health issues, Prowlarr sync working

### Sonarr (2025-12-28) ✅
- **Status**: Fully operational via Recyclarr sync
- **Custom Formats**: 33 (TRaSH Guides complete set)
- **Quality Profiles**: WEB-2160p, Anime (with dual audio preference)
- **Configuration**: AV1 preferred (+100), HEVC fallback (+50)
- **Minor Issue**: NZB.su transient failures (indexer still enabled)

### Recyclarr (2025-12-28) ✅
- **Status**: Syncing successfully to Radarr and Sonarr
- **Templates**: TRaSH Guides UHD Bluray + WEB, Anime profiles
- **Configuration**: recyclarr.yml with AV1/HEVC scoring
- **Verified**: "All custom formats are already up to date!"

### Tdarr (2025-12-28) ✅
- **Status**: Fully operational
- **Files Queued**: 5,699
- **Configuration**: GPU VAAPI (hevc_vaapi -qp 20)
- **Learnings**:
  - Libraries must be created via UI (API causes RangeError)
  - VAAPI uses -qp not -crf
  - Container paths differ from host paths
  - API: POST /api/v2/cruddb with collection/mode/docID pattern
- **Commit**: 051dfa0

---

## Research Sources

- [TRaSH Guides](https://trash-guides.info/) - Quality profiles, custom formats
- [Servarr Wiki](https://wiki.servarr.com/) - Official *arr documentation
- [r/usenet](https://reddit.com/r/usenet) - Community best practices
- [r/PleX](https://reddit.com/r/PleX) - Plex optimization
- [LinuxServer.io](https://docs.linuxserver.io/) - Container documentation
- Hardware-specific searches for AMD Ryzen 7840HS / Radeon 780M

---

## Notes

- **sudo docker**: All docker commands require sudo on Bazzite/Fedora
- **Session continuity**: Use this file to resume audits across sessions
- **Agent delegation**: Spawn research agents for deep dives on each service
- **Parallel execution**: Services in same tier can be audited in parallel
