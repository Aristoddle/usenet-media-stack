# Reading Stack (Comics, Ebooks, Audiobooks)

> **Updated**: 2026-01-04
> **Architecture**: Portable-first with travel downloads support

## Overview

The reading stack operates independently of the external drive pool, making it perfect for travel. All services run from the internal 8TB NVMe drive.

| Service | Purpose | Port | Always Available |
|---------|---------|------|------------------|
| **Komga** | Comics/Manga server | 8081 | ✓ |
| **Kavita** | eBooks/Comics reader | 5000 | ✓ |
| **Komf** | Metadata fetcher | 8085 | ✓ |
| **Audiobookshelf** | Audiobook streaming | 13378 | ✓ |
| **Suwayomi** | Manga downloader | 4567 | ✓ |
| **Prowlarr** | Indexer manager | 9696 | ✓ |
| **Readarr** | eBook management | 8787 | ✓ |
| **Mylar** | Comics management | 8090 | ✓ |
| **SABnzbd-Portable** | Usenet downloads | 8180 | ✓ (NEW) |
| **Transmission-Portable** | Torrent fallback | 9092 | ✓ (NEW) |

## Quick Start

```bash
# Start the reading stack
docker compose -f docker-compose.reading.yml up -d

# Or use smart-start.sh which auto-detects available storage
./scripts/smart-start.sh up
```

## Architecture

### Storage Paths (via `.env`)

```bash
# Internal NVMe paths (always available)
COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
EBOOKS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/eBooks
AUDIOBOOKS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks
CONFIG_ROOT=/var/mnt/fast8tb/config

# Travel downloads (internal, not pool)
DOWNLOADS_ROOT_PORTABLE=/var/mnt/fast8tb/Local/downloads
SUWAYOMI_DOWNLOADS_PORTABLE=/var/mnt/fast8tb/Local/downloads/suwayomi-chapters
```

### Compose Files

| File | Purpose | Pool Required |
|------|---------|---------------|
| `docker-compose.reading.yml` | Reading stack + travel downloads | **No** |
| `docker-compose.yml` | Full media stack (Plex, *arr, Tdarr) | Yes |

### Mode Detection

The `smart-start.sh` script automatically detects which mode to use:

```
Travel Mode (no external bays)    Full Mode (bays connected)
─────────────────────────────     ─────────────────────────
/var/mnt/fast8tb ✓                /var/mnt/fast8tb ✓
/var/mnt/pool ✗                   /var/mnt/pool ✓
        ↓                                 ↓
docker-compose.reading.yml        + docker-compose.yml
(10 services)                     (30+ services)
```

## Travel Downloads (NEW)

While traveling, you can still download content:

### SABnzbd-Portable (Port 8180)
- Downloads to `/var/mnt/fast8tb/Local/downloads`
- Separate config from full-stack SABnzbd
- Configure Prowlarr to use `http://sabnzbd-portable:8080` or `localhost:8180`

### Transmission-Portable (Port 9092)
- Torrent fallback when usenet misses
- Uses Flood web UI
- Configure Prowlarr to use `http://transmission-portable:9091` or `localhost:9092`

### When You Return Home

```bash
# 1. Move travel downloads to pool
mv /var/mnt/fast8tb/Local/downloads/complete/* /var/mnt/pool/downloads/complete/

# 2. Use Sonarr/Radarr manual import
# Web UI → Wanted → Manual Import → Select moved files
```

## OPDS Endpoints

| Service | OPDS URL | Clients |
|---------|----------|---------|
| Komga | `http://<host>:8081/opds/v1.2` | Panels, Chunky |
| Kavita | `http://<host>:5000/opds` | Moon Reader, Marvin |
| Audiobookshelf | Web only (native apps available) | ABS app |

## Service Details

### Komga (Comics/Manga)
- **Image**: `ghcr.io/gotson/komga:1.23.6`
- **Library path**: `/comics` → `${COMICS_ROOT}`
- **Web UI**: Komelia at port 8081
- **Memory**: 4-8GB heap (`-Xms4g -Xmx8g`)
- **Scans**: Hourly cron

### Kavita (eBooks)
- **Image**: `jvmilazz0/kavita:latest`
- **Library paths**: `/books`, `/comics`
- **Config**: `${CONFIG_ROOT}/kavita`

### Komf (Metadata)
- **Image**: `sndxr/komf:1.3.0`
- **Integrates with**: Komga + Kavita
- **Sources**: MangaUpdates, AniList, MAL, ComicVine, MangaDex
- **Requires**: API keys in `.env`

### Audiobookshelf
- **Image**: `ghcr.io/advplyr/audiobookshelf:latest`
- **Paths**: `/audiobooks`, `/ebooks`, `/downloads`
- **Port**: 13378 (maps to internal 80)

### Suwayomi (Manga Sources)
- **Image**: `ghcr.io/suwayomi/suwayomi-server:stable`
- **Downloads to**: `${SUWAYOMI_DOWNLOADS_PORTABLE}`
- **Purpose**: Read manga from source sites, download chapters

## Capability Matrix

| Capability | Travel Mode | Full Mode |
|------------|-------------|-----------|
| Read Comics/Manga | ✓ Komga | ✓ Komga |
| Read eBooks | ✓ Kavita | ✓ Kavita |
| Listen Audiobooks | ✓ ABS | ✓ ABS |
| Browse/Search | ✓ Prowlarr | ✓ Prowlarr |
| One-off Downloads | ✓ SABnzbd-Portable | ✓ SABnzbd |
| Manga Chapter Sync | ✓ Suwayomi | ✓ Suwayomi |
| TV/Movie Management | ✗ | ✓ Sonarr/Radarr |
| Plex Streaming | ✗ | ✓ |
| Transcoding | ✗ | ✓ Tdarr |

## Health Checks

```bash
# Check reading stack status
./scripts/smart-start.sh status

# Or directly
docker compose -f docker-compose.reading.yml ps
```

## Troubleshooting

### Komga shows "Library not found"
```bash
# Verify comics path is mounted
ls -la /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics

# Check container logs
docker logs komga
```

### Komf metadata not fetching
```bash
# Verify API keys in .env
grep KOMF_ .env

# Check komf logs
docker logs komf
```

### Downloads failing in travel mode
```bash
# Verify portable downloads directory exists
mkdir -p /var/mnt/fast8tb/Local/downloads/{complete,incomplete}

# Check SABnzbd-portable logs
docker logs sabnzbd-portable
```

## Related Documentation

- [Storage Architecture](./storage/architecture.md) - mergerfs pool design
- [Boot and Launchers](./BOOT_AND_LAUNCHERS.md) - systemd integration
- [Manga Acquisition](./manga-acquisition-pipeline.md) - Suwayomi workflows
