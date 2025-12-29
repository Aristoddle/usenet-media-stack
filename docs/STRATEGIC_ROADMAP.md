# Strategic Roadmap - Media Stack Evolution

**Created**: 2025-12-29
**Status**: Active Strategic Planning Document
**Owner**: Deep-Thinker Agent
**Methodology**: Sequential Analysis (12 thoughts)

---

## Executive Summary

Following major infrastructure work (dual MergerFS fix, Tdarr GPU optimization, docker-compose DRY refactoring), this document provides a prioritized strategic roadmap for the next phase of media stack evolution.

### Current System Health

| Component | Status | Health |
|-----------|--------|--------|
| Tdarr Transcoding | Operational | 3,911 queued, 473 errors, 1,455 success |
| Prowlarr/Indexers | Healthy | 5 indexers wired |
| SABnzbd | Healthy | Primary downloader |
| Transmission | Healthy | VPN-protected torrents |
| Plex | Running | Library analysis complete |
| Komga | Running | Comics/manga library |
| Mylar | Running | Comic acquisition (needs wiring) |
| Suwayomi | Running | Chapter downloads (staging only) |

### Storage Capacity

| Mount | Size | Used | Available | Use% |
|-------|------|------|-----------|------|
| MergerFS Pool | 41TB | 30TB | 11TB | 73% |
| NVMe (fast8tb) | 7.3TB | 3.1TB | 4.3TB | 42% |

---

## Priority Tiers

### TIER 1: Immediate Actions (This Week)

Critical issues and quick wins that unblock other work.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T1.1 | Fix Tdarr 473 error files (diagnose, reset, or hold) | ops | 1h | High - queue health |
| T1.2 | Scale Tdarr to aggressive settings (Plex scan done) | ops | 15m | High - throughput |
| T1.3 | Wire Mylar to Prowlarr for comic acquisition | config | 30m | High - manga pipeline |
| T1.4 | Configure Komf metadata providers (all 6 enabled in env) | config | 20m | Medium - metadata quality |
| T1.5 | Verify Suwayomi staging path works with Komga scan | config | 15m | Medium - chapter pipeline |

**Claimable Tasks:**

```
[ ] T1.1 - Agent can claim: diagnose Tdarr errors, run reset script
[ ] T1.2 - Agent can claim: update .env, restart tdarr containers
[ ] T1.3 - Agent can claim: Prowlarr UI or API wiring
[ ] T1.4 - Agent can claim: verify Komf config and test providers
[ ] T1.5 - Agent can claim: verify paths, trigger Komga scan
```

---

### TIER 2: Manga Pipeline Integration (This Week - Next Week)

Complete end-to-end manga acquisition and organization.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T2.1 | Configure Mylar ComicVine connection (API key in .env) | config | 20m | High |
| T2.2 | Add initial manga series to Mylar for monitoring | config | 30m | High |
| T2.3 | Create Suwayomi -> Komga organizer script | dev | 2h | High |
| T2.4 | Wire manga-torrent-searcher agent to Transmission | config | 1h | Medium |
| T2.5 | Test E2E flow: Request -> Download -> Organize -> Read | testing | 30m | High |

**Architecture Clarification:**

```
Two-Track Manga System (from MANGA_ACQUISITION_PIPELINE.md):

Track 1: Tankobon (Published Volumes)
  Mylar -> Prowlarr -> SABnzbd -> /comics/
  - Official English releases
  - 3-6 month delay after Japan

Track 2: Weekly Chapters (Fan Translations)
  Suwayomi/manga-torrent-searcher -> Transmission -> staging/
  - Same-day to 1-week delay
  - Requires organizer script to move to /comics/
```

**Claimable Tasks:**

```
[ ] T2.1 - Agent: Configure Mylar ComicVine settings
[ ] T2.2 - Agent: Add monitored series via Mylar API
[ ] T2.3 - Agent: Write suwayomi-organizer.sh script
[ ] T2.4 - Agent: Configure Transmission categories for manga
[ ] T2.5 - Agent: Run E2E test with Chainsaw Man chapter
```

---

### TIER 3: Stack Optimization (Next Week)

Performance and reliability improvements.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T3.1 | Upgrade Recyclarr to Remux + WEB 2160p profile | config | 1h | High - quality |
| T3.2 | Enable advanced audio CFs (TrueHD Atmos, DTS-X) | config | 30m | Medium |
| T3.3 | Configure Radarr/Sonarr library import for existing content | config | 2h | High - wiring |
| T3.4 | Add canonical lists (AFI Top 100, Sight & Sound) to Radarr | config | 1h | Medium |
| T3.5 | Create thermal-aware Tdarr worker scaling script | dev | 2h | Medium |
| T3.6 | Deploy metrics-collector systemd service | ops | 15m | Low |

**From COLLECTION_GAP_FILL_STRATEGY.md:**

```yaml
# Recommended Recyclarr upgrade
radarr:
  radarr-4k:
    include:
      - template: radarr-quality-profile-remux-web-2160p  # Upgrade from uhd-bluray-web
      - template: radarr-custom-formats-remux-web-2160p
    custom_formats:
      # Enable advanced audio
      - trash_ids:
          - 496f355514737f7d83bf7aa4d24f8169 # TrueHD Atmos
          - 2f22d89048b01681dde8afe203bf2e95 # DTS X
```

**Claimable Tasks:**

```
[ ] T3.1 - Agent: Update recyclarr.yml, run sync
[ ] T3.2 - Agent: Add trash_ids to recyclarr config
[ ] T3.3 - Agent: Run library import via Sonarr/Radarr API
[ ] T3.4 - Agent: Add IMDb/Trakt lists to Radarr
[ ] T3.5 - Agent: Write thermal-scaling.sh using sysinfo-snapshot
[ ] T3.6 - Agent: Enable media-stack-metrics.service
```

---

### TIER 4: Documentation Cleanup (Ongoing)

Reduce doc sprawl, establish structure.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T4.1 | Create docs/INDEX.md with comprehensive TOC | docs | 1h | High - discoverability |
| T4.2 | Archive stale audit reports to docs/archive/ | docs | 30m | Medium |
| T4.3 | Normalize doc naming (lowercase-with-hyphens) | docs | 30m | Medium |
| T4.4 | Consolidate duplicate info (ops-runbook vs HANDOFF) | docs | 1h | Medium |
| T4.5 | Move node_modules out of docs/ or add to .gitignore | config | 15m | Low |

**Current Documentation Issues:**

```
- 30+ docs at root of docs/ with mixed naming
- node_modules in docs/ (129k package-lock.json)
- Duplicate information across ops-runbook.md, HANDOFF.md, WIRING_NOTES.md
- Stale audit reports mixed with active docs
- No master index for navigation
```

**Proposed Structure:**

```
docs/
  INDEX.md                    # Master navigation
  getting-started/
  runbook/
  architecture/
  decisions/
  archive/
    audits/                   # Dated audit reports
    projects/                 # Completed project docs
  storage/
  hardware/
```

**Claimable Tasks:**

```
[ ] T4.1 - Agent: Create INDEX.md with links to all docs
[ ] T4.2 - Agent: mv stale audits to docs/archive/audits/
[ ] T4.3 - Agent: Rename files to lowercase-with-hyphens.md
[ ] T4.4 - Agent: Merge ops-runbook and HANDOFF content
[ ] T4.5 - Agent: Add docs/node_modules to .gitignore
```

---

### TIER 5: Future Automation (Backlog)

Strategic investments for long-term improvement.

| ID | Task | Owner | Effort | Impact |
|----|------|-------|--------|--------|
| T5.1 | ROM acquisition pipeline (Prowlarr Console categories) | dev | 4h | Medium |
| T5.2 | library-wiring-agent for *arr orphan detection | dev | 3h | High |
| T5.3 | quality-upgrade-agent for cutoff unmet searches | dev | 2h | Medium |
| T5.4 | Traefik routing + DNS-01 TLS | config | 2h | Medium |
| T5.5 | Secret rotation automation (Prowlarr keys, etc.) | security | 2h | Low |
| T5.6 | Git history scrub for leaked credentials | security | 1h | High |

**From MEDIA_ACQUISITION_ARCHITECTURE.md:**

```
ROM Pipeline Status: Building
- emudeck-rom-manager skill: Needs Prowlarr patterns
- rom-acquisition-agent: Not built
- Hash verification: Not built (No-Intro/Redump DATs needed)
```

---

## Dependency Graph

```
T1.1 (Tdarr errors) ────────────┐
                                v
T1.2 (Tdarr aggressive) ────> Faster transcoding
                                │
T1.3 (Mylar-Prowlarr) ──────────┼───> T2.1 (ComicVine) ──> T2.2 (Add series)
                                │                              │
T1.4 (Komf providers) ──────────┤                              v
                                │                         T2.5 (E2E test)
T1.5 (Suwayomi staging) ────────┘                              │
        │                                                      │
        v                                                      v
  T2.3 (Organizer script) ─────────────────────────────> Full manga pipeline
                                                               │
T3.1 (Recyclarr upgrade) ─────────────────────────────> Better quality
                                                               │
T3.3 (Library import) ────────> T3.4 (Lists) ─────────> Automated gap-fill
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

**From SESSION_STATE.md (2025-12-29 01:10 EST):**

- Plex first-run analysis: COMPLETE (can scale Tdarr)
- Tdarr schedule override: FIXED (GPU-only)
- docker-compose defaults: FIXED (GPU workers)
- 1Password runaway process: KILLED
- Conservative worker mode: Active (can upgrade to aggressive)

**Immediate next action:** T1.2 - Scale Tdarr to aggressive settings.

---

## Success Metrics

| Metric | Current | Target | Timeline |
|--------|---------|--------|----------|
| Tdarr queue completion | 25% | 95% | 2 weeks |
| Manga E2E pipeline | Manual | Automated | 1 week |
| *arr library wiring | Partial | 100% | 2 weeks |
| Doc organization | Sprawled | Indexed | 1 week |
| Recyclarr quality | UHD Bluray | Remux | 1 week |

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-29 | 1.0.0 | Initial strategic roadmap |

---

*This document is the authoritative source for strategic planning. Update after each major milestone.*
