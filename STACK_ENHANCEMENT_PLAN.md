# Media Stack Enhancement Plan

**Date**: 2025-12-28
**Research Source**: Deep analysis of TRaSH Guides, Tdarr docs, community forums

---

## Current Stack

| Component | Purpose | Status |
|-----------|---------|--------|
| Radarr | Movie acquisition | ✅ Running |
| Sonarr | TV acquisition | ✅ Running |
| Prowlarr | Indexer management | ✅ Running |
| SABnzbd | Usenet downloads | ✅ Running |
| Plex | Media serving | ✅ Running |
| Tdarr | Transcoding | ✅ Running (libraries need cleanup) |

---

## Tier 1 - Essential Additions

### 1. Recyclarr (TRaSH Guides Sync)

**Purpose**: Automatically syncs TRaSH Guides quality profiles to Radarr/Sonarr

```yaml
# Add to docker-compose.yml
recyclarr:
  image: ghcr.io/recyclarr/recyclarr:latest
  container_name: recyclarr
  restart: unless-stopped
  networks:
    - media_network
  volumes:
    - ./config/recyclarr:/config:z
  environment:
    - TZ=America/Los_Angeles
    - CRON_SCHEDULE=@daily
```

**Why**: Set-and-forget quality profile management. Keeps your *arr apps aligned with community best practices.

### 2. Unpackerr (Archive Extraction)

**Purpose**: Extracts rar-packed downloads for *arr import

```yaml
unpackerr:
  image: ghcr.io/unpackerr/unpackerr:latest
  container_name: unpackerr
  restart: unless-stopped
  networks:
    - media_network
  volumes:
    - ./config/unpackerr:/config:z
    - /var/mnt/pool/downloads:/downloads:z
  environment:
    - TZ=America/Los_Angeles
    - UN_SONARR_0_URL=http://192.168.6.167:8989
    - UN_SONARR_0_API_KEY=4da8f9d97b0449ad8cfc7dcca2362287
    - UN_RADARR_0_URL=http://192.168.6.167:7878
    - UN_RADARR_0_API_KEY=e2c1b4e03d0749bb822409d59ef2de07
```

**Why**: Essential if any indexers provide rar-packed content.

### 3. Bazarr (Subtitle Management)

**Purpose**: Automated subtitle downloads with deep *arr integration

```yaml
bazarr:
  image: lscr.io/linuxserver/bazarr:latest
  container_name: bazarr
  restart: unless-stopped
  networks:
    - media_network
  ports:
    - 6767:6767
  volumes:
    - ./config/bazarr:/config:z
    - /var/mnt/pool/movies:/movies:z
    - /var/mnt/pool/tv:/tv:z
    - /var/mnt/pool/anime:/anime:z
  environment:
    - TZ=America/Los_Angeles
    - PUID=1000
    - PGID=1000
```

**Why**: De facto standard for subtitles. Supports 20+ providers.

---

## Tier 2 - Highly Recommended

### 4. Jellyseerr (Request Management)

**Purpose**: Beautiful request UI for users to request movies/shows

```yaml
jellyseerr:
  image: fallenbagel/jellyseerr:latest
  container_name: jellyseerr
  restart: unless-stopped
  networks:
    - media_network
  ports:
    - 5055:5055
  volumes:
    - ./config/jellyseerr:/app/config:z
  environment:
    - TZ=America/Los_Angeles
```

**Why**: Works with Plex despite the name. Modern UI, active development, OAuth support.

### 5. Homarr (Dashboard)

**Purpose**: Unified dashboard with *arr calendar and Docker control

```yaml
homarr:
  image: ghcr.io/ajnart/homarr:latest
  container_name: homarr
  restart: unless-stopped
  networks:
    - media_network
  ports:
    - 7575:7575
  volumes:
    - ./config/homarr:/app/data/configs:z
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - TZ=America/Los_Angeles
```

**Why**: Native integrations with Sonarr, Radarr, Plex. Calendar for upcoming shows.

### 6. Checkrr (Corrupt File Detection)

**Purpose**: Scans library for corrupt media, auto-replaces via *arr

```yaml
checkrr:
  image: aetaric/checkrr:latest
  container_name: checkrr
  restart: unless-stopped
  networks:
    - media_network
  volumes:
    - ./config/checkrr:/config:z
    - /var/mnt/pool/movies:/movies:z
    - /var/mnt/pool/tv:/tv:z
    - /var/mnt/pool/anime:/anime:z
  environment:
    - TZ=America/Los_Angeles
```

**Why**: Proactive integrity verification. Auto-requests replacements when corruption detected.

### 7. Tautulli (Plex Analytics)

**Purpose**: Detailed Plex usage statistics and history

```yaml
tautulli:
  image: lscr.io/linuxserver/tautulli:latest
  container_name: tautulli
  restart: unless-stopped
  networks:
    - media_network
  ports:
    - 8181:8181
  volumes:
    - ./config/tautulli:/config:z
  environment:
    - TZ=America/Los_Angeles
    - PUID=1000
    - PGID=1000
```

**Why**: Gold standard for Plex analytics. Who's watching what, when.

---

## Tier 3 - Nice to Have

### 8. Kometa (Plex Collections)

**Purpose**: Auto-builds beautiful collections and adds rating overlays

```yaml
kometa:
  image: kometateam/kometa:latest
  container_name: kometa
  restart: unless-stopped
  networks:
    - media_network
  volumes:
    - ./config/kometa:/config:z
  environment:
    - TZ=America/Los_Angeles
    - KOMETA_RUN=true
```

**Why**: Creates themed collections (MCU, Star Wars, Trending). Adds IMDb/RT overlays to posters.

### 9. Notifiarr (Rich Notifications)

**Purpose**: Discord-focused notifications with *arr-aware formatting

```yaml
notifiarr:
  image: golift/notifiarr:latest
  container_name: notifiarr
  restart: unless-stopped
  networks:
    - media_network
  ports:
    - 5454:5454
  volumes:
    - ./config/notifiarr:/config:z
    - /var/run/docker.sock:/var/run/docker.sock:ro
  environment:
    - TZ=America/Los_Angeles
```

**Why**: Created by an *arr developer. Deep integration and beautiful Discord notifications.

---

## Tdarr Configuration Recommendations

### Current Issue: Duplicate Libraries

The API-created libraries duplicated existing ones. **Fix via UI**:
1. Go to http://localhost:8265
2. Libraries tab → Delete duplicates
3. Keep: Movies, TV, Anime (one of each)

### AMD VAAPI Critical Notes

**Compression Reality Check**: AMD hardware encoders produce 5-10% larger files than software encoders for equivalent quality. Consider:
- Hardware for speed (large backlog)
- Software for archival quality (critical content)

### Quality Settings (using `-global_quality`)

| Content | Value | Rationale |
|---------|-------|-----------|
| Movies 4K | 18-20 | Preserve UHD quality |
| Movies 1080p | 20-22 | High quality compression |
| TV Shows | 22-24 | Good balance |
| Anime | 18-20 | Preserve line art, grain |

### Anime-Specific Settings

- **Do NOT use** `animation` tune for complex anime
- Use 10-bit encoding always
- Set deblock to `-1:-1` to preserve grain
- Use `aq-mode=3` for dark scene handling

### *arr Integration

1. Add **Notify Radarr/Sonarr** plugin to Tdarr flows
2. Configure Radarr/Sonarr custom scripts to call `tdarr_autoscan`
3. Add Plex Refresh plugin for immediate library updates

---

## Implementation Priority

### Phase 1 (Do Now)
1. ✅ Tdarr running
2. Fix Tdarr duplicate libraries via UI
3. Add Recyclarr (TRaSH Guides sync)
4. Add Bazarr (subtitles)

### Phase 2 (This Week)
5. Add Unpackerr (archive extraction)
6. Add Tautulli (Plex analytics)
7. Configure Tdarr → Radarr/Sonarr notifications

### Phase 3 (When Ready)
8. Add Jellyseerr (request management)
9. Add Homarr (dashboard)
10. Add Kometa (Plex collections)

---

## Notes

- **Watchtower deprecated** (Dec 2025): Consider Diun for container update notifications
- **FlareSolverr broken** as of late 2025: Cloudflare bypass non-functional
- **SQLite on local storage only**: Never mount *arr /config on network drives

---

## Sources

- TRaSH Guides: https://trash-guides.info/
- Tdarr Docs: https://docs.tdarr.io/
- Servarr Wiki: https://wiki.servarr.com/
- Community: r/selfhosted, r/PleX, ServerBuilds forums
