# Strategic Roadmap - Media Stack Evolution

**Created**: 2025-12-29
**Last Updated**: 2025-12-30
**Status**: Active Strategic Planning Document
**Owner**: Deep-Thinker Agent
**Methodology**: Sequential Analysis (12 thoughts)

---

## Executive Summary

Following major infrastructure work (dual MergerFS fix, Tdarr SVT-AV1 migration, docker-compose DRY refactoring, USB content discovery), this document provides a prioritized strategic roadmap for the next phase of media stack evolution.

### Current System Health

| Component | Status | Health |
|-----------|--------|--------|
| Tdarr Transcoding | SVT-AV1 Mode | 2,252 queued, 2,140 errors (2,131 recoverable), 1,473 success |
| Prowlarr/Indexers | Healthy | 5 indexers wired |
| SABnzbd | Healthy | Primary downloader |
| Transmission | Healthy | VPN-protected torrents |
| Plex | Running | Library analysis complete, CPU optimizations applied |
| Komga | Running | Comics/manga library |
| Mylar | Running | Comic acquisition, Prowlarr category fixed (7000) |
| Suwayomi | Running | Chapter downloads (staging only) |
| Readarr | RETIRED | Security risk - needs replacement with Bookshelf |

### Storage Capacity

| Mount | Size | Used | Available | Use% |
|-------|------|------|-----------|------|
| MergerFS Pool | 41TB | 30TB | 11TB | 73% |
| NVMe (fast8tb) | 7.3TB | 3.1TB | 4.3TB | 42% |

### USB Drives Discovered (2025-12-29)

| Drive | Content | Size | Import Priority |
|-------|---------|------|-----------------|
| Slow_3TB_HD | Music (235 artists), Books (349GB Comics) | 545GB | HIGH |
| Slow_4TB_2 | Movies (555 films) | 1.7TB | HIGH |
| Slow_2TB_2 | Anime (64 series) | 854GB | MEDIUM |
| Slow_2TB_1 | ROMs/Emulation backup | - | SEPARATE |
| JoeTerabyte | Trash (repurpose) | 465GB | LOW |

---

## Completed Tasks (2025-12-29 Session)

### TIER 1 Progress

- [x] T1.1 - Tdarr errors diagnosed: 2,131 recoverable (timeout artifacts), 9 actual failures
- [x] T1.3 - Prowlarr category fixed for Mylar (7030 -> 7000)
- [x] Switched Tdarr to CPU-based SVT-AV1 for 60-70% compression
- [x] Fixed MergerFS CPU usage (286% -> 0-34%) with RAM caching
- [x] Configured Tailscale for stable remote access

### TIER 2 Progress

- [x] T2.3 - Created suwayomi-organizer.sh script
- [x] Manga collection topology documented (MANGA_COLLECTION_TOPOLOGY.md)
- [x] Adversarial review completed

### TIER 4 Progress

- [x] T4.1 - Created DOCUMENTATION_INDEX.md with comprehensive navigation
- [x] T4.2 - Archived stale docs to docs/archive/

---

## Priority Tiers

### TIER 1: Immediate Actions (This Week)

Critical issues and quick wins that unblock other work.

| ID | Task | Owner | Effort | Impact | Status |
|----|------|-------|--------|--------|--------|
| T1.1 | Reset 2,131 recoverable Tdarr error files | ops | 15m | High | READY |
| T1.2 | Verify SVT-AV1 encoding producing expected compression | ops | 30m | High | PENDING |
| T1.4 | Configure Komf metadata providers | config | 20m | Medium | PENDING |
| T1.5 | Verify Suwayomi staging path works with Komga scan | config | 15m | Medium | PENDING |
| T1.6 | **NEW** Replace retired Readarr with Bookshelf | security | 1h | HIGH | CRITICAL |

**Reset Command for T1.1:**
```sql
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db "
UPDATE filejsondb SET health_check = 'Queued'
WHERE health_check = 'Error'
AND json_extract(json_data, '$.TranscodeDecisionMaker') = 'Not required'
AND json_extract(json_data, '$.scannerReads.ffProbeRead') = 'success';"
```

---

### TIER 2: USB Content Import (This Week - Next Week)

Import valuable content from discovered USB drives.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T2.6 | Run lidarr-bootstrap.sh for 235 artists | ops | 2h | High |
| T2.7 | Run usb-movie-importer.sh for 555 movies | ops | 2h | High |
| T2.8 | Analyze anime collection for quality upgrades | ops | 1h | Medium |
| T2.9 | Import 349GB Comics to Komga | ops | 1h | High |

**Tools Available:**
- `tools/lidarr-bootstrap.sh` - USB music import
- `tools/usb-movie-importer.sh` - USB movie import with Radarr dedup

---

### TIER 3: Manga Pipeline Integration

Complete end-to-end manga acquisition and organization.

| ID | Task | Owner | Effort | Impact | Status |
|----|------|-------|--------|--------|--------|
| T2.1 | Configure Mylar ComicVine connection | config | 20m | High | PENDING |
| T2.2 | Add initial manga series to Mylar for monitoring | config | 30m | High | PENDING |
| T2.4 | Wire manga-torrent-searcher agent to Transmission | config | 1h | Medium | PENDING |
| T2.5 | Test E2E flow: Request -> Download -> Organize -> Read | testing | 30m | High | PENDING |

**Architecture:**

```
Two-Track Manga System (from MANGA_ACQUISITION_PIPELINE.md):

Track 1: Tankobon (Published Volumes)
  Mylar -> Prowlarr (category 7000) -> SABnzbd -> /comics/
  - Official English releases
  - 3-6 month delay after Japan

Track 2: Weekly Chapters (Fan Translations)
  Suwayomi/manga-torrent-searcher -> Transmission -> staging/
  - Same-day to 1-week delay
  - Requires suwayomi-organizer.sh to move to /comics/
```

---

### TIER 4: Stack Optimization (Next Week)

Performance and reliability improvements.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T3.1 | Upgrade Recyclarr to Remux + WEB 2160p profile | config | 1h | High |
| T3.2 | Enable advanced audio CFs (TrueHD Atmos, DTS-X) | config | 30m | Medium |
| T3.3 | Configure Radarr/Sonarr library import for existing content | config | 2h | High |
| T3.4 | Add canonical lists (AFI Top 100, Sight & Sound) to Radarr | config | 1h | Medium |
| T3.5 | Install mergerfs systemd service for boot persistence | ops | 15m | High |
| T3.6 | Configure Plex network settings for Tailscale | config | 30m | Medium |

---

### TIER 5: Documentation Cleanup (Ongoing)

Reduce doc sprawl, establish structure.

| ID | Task | Owner | Effort | Impact | Status |
|----|------|-------|--------|--------|--------|
| T4.1 | Create docs/INDEX.md with comprehensive TOC | docs | 1h | High | DONE |
| T4.2 | Archive stale audit reports to docs/archive/ | docs | 30m | Medium | DONE |
| T4.3 | Normalize doc naming (lowercase-with-hyphens) | docs | 30m | Medium | PENDING |
| T4.4 | Consolidate duplicate info (ops-runbook vs HANDOFF) | docs | 1h | Medium | PENDING |
| T4.5 | Move node_modules out of docs/ or add to .gitignore | config | 15m | Low | PENDING |

---

### TIER 6: Future Automation (Backlog)

Strategic investments for long-term improvement.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T5.1 | ROM acquisition pipeline (Prowlarr Console categories) | dev | 4h | Medium |
| T5.2 | library-wiring-agent for *arr orphan detection | dev | 3h | High |
| T5.3 | quality-upgrade-agent for cutoff unmet searches | dev | 2h | Medium |
| T5.4 | Traefik routing + DNS-01 TLS | config | 2h | Medium |
| T5.5 | Secret rotation automation (Prowlarr keys, etc.) | security | 2h | Low |
| T5.6 | Git history scrub for leaked credentials | security | 1h | High |

---

## Dependency Graph

```
T1.1 (Reset Tdarr errors) ────> T1.2 (Verify SVT-AV1) ────> Faster transcoding
                                                                    │
T1.6 (Replace Readarr) ─────────────────────────────────> Security fix
                                                                    │
T2.6-T2.9 (USB Import) ─────────────────────────────────> Library expansion
                                                                    │
T2.1 (ComicVine) ──> T2.2 (Add series) ──> T2.5 (E2E test) ──> Full manga pipeline
                                                                    │
T3.1 (Recyclarr upgrade) ──> T3.3 (Library import) ──> Better quality
```

---

## Quick Reference: Key Endpoints

| Service | Port | API Key Location | Test Command |
|---------|------|------------------|--------------|
| Prowlarr | 9696 | .env: PROWLARR_API_KEY | `curl -s http://localhost:9696/api/v1/indexer -H "X-Api-Key: $KEY"` |
| Sonarr | 8989 | .env: SONARR_API_KEY | `curl -s http://localhost:8989/api/v3/series -H "X-Api-Key: $KEY"` |
| Radarr | 7878 | .env: RADARR_API_KEY | `curl -s http://localhost:7878/api/v3/movie -H "X-Api-Key: $KEY"` |
| Mylar | 8090 | .env: MYLAR_API_KEY | `curl "http://localhost:8090/api?apikey=$KEY&cmd=getIndex"` |
| Komga | 8081 | .env: KOMGA_USERNAME/PASSWORD | `curl -u $USER:$PASS http://localhost:8081/api/v1/libraries` |
| SABnzbd | 8080 | .env: SABNZBD_API_KEY | `curl "http://192.168.6.167:8080/api?mode=version&apikey=$KEY"` |
| Tdarr | 8265 | N/A | `curl http://localhost:8265/api/v2/status` |

---

## Session State Integration

**From SESSION_STATE.md (2025-12-29 14:15 EST):**

- SVT-AV1 encoding: ACTIVE (CPU-dominant mode)
- MergerFS caching: FIXED (286% -> 0-34% CPU)
- Tailscale: CONFIGURED (IP: 100.115.21.9)
- Plex CPU optimizations: APPLIED
- USB content: DISCOVERED (5 drives, 3TB+ valuable content)
- Readarr: RETIRED (security risk, migration script ready)

**Immediate next action:** T1.1 - Reset recoverable Tdarr errors, then T1.6 - Replace Readarr.

---

## Success Metrics

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Tdarr queue completion | 30% | 95% | 2 weeks |
| Readarr replacement | Retired | Bookshelf | THIS WEEK |
| USB content import | Discovered | Imported | 1 week |
| Manga E2E pipeline | Manual | Automated | 1 week |
| *arr library wiring | Partial | 100% | 2 weeks |
| Doc organization | Indexed | Normalized | 1 week |

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-29 | 1.0.0 | Initial strategic roadmap |
| 2025-12-30 | 1.1.0 | Updated with 12/29 session completion, USB import tier, Readarr retirement |

---

*This document is the authoritative source for strategic planning. Update after each major milestone.*
