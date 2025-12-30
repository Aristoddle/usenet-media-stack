# Books & Audiobooks Serving Stack Guide

> **Purpose**: Comprehensive guide to the books/audiobooks serving architecture, naming conventions, metadata enrichment, and acquisition workflows.
>
> **Last Updated**: 2025-12-29
> **Version**: 1.0.0

---

## Architecture Overview

```
                    +-------------------+
                    |   Prowlarr        |
                    |   (Indexer Hub)   |
                    |   :9696           |
                    +--------+----------+
                             |
              +--------------+--------------+
              |              |              |
        +-----v----+   +-----v----+   +-----v----+
        | SABnzbd  |   | Mylar3   |   | Readarr  |
        | :8080    |   | :8090    |   | :8787    |
        +-----+----+   +-----+----+   +-----+----+
              |              |              |
              v              v              v
        /downloads/    /downloads/    /downloads/

              |              |              |
              v              v              v
    +---------+---------+----+----+---------+---------+
    |                   |         |                   |
+---v---+         +-----v-----+   |   +-------v-------+
| Komga |         |   Kavita  |   |   | Audiobookshelf|
| :8081 |         |   :5000   |   |   |    :13378     |
+---+---+         +-----+-----+   |   +-------+-------+
    |                   |         |           |
+---v---+               |         |           |
| Komf  |               |         |           |
| :8085 |               |         |           |
+-------+               |         |           |
    |                   |         |           |
    v                   v         v           v
/Comics/            /eBooks/    (manga)   /Audiobooks/
```

---

## Service Details

### Komga (Comics/Manga Reader)
- **Port**: 8081 (external) -> 25600 (internal)
- **Image**: `ghcr.io/gotson/komga:1.23.6`
- **Purpose**: Serves comics and manga in CBZ/CBR/PDF format
- **Root Path**: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- **Config**: `/var/mnt/fast8tb/config/komga`
- **Best For**: Visual reading with page-turn interface

### Komf (Metadata Enrichment)
- **Port**: 8085
- **Image**: `sndxr/komf:1.3.0`
- **Purpose**: Fetches metadata for Komga libraries
- **Sources Configured**:
  - ComicVine (API key in .env)
  - MyAnimeList (client ID in .env)
  - MangaUpdates
  - MangaDex
  - AniList

### Kavita (eBooks/Manga Reader)
- **Port**: 5000
- **Image**: `jvmilazz0/kavita:latest`
- **Purpose**: Serves eBooks (EPUB, PDF) and manga
- **Root Paths**:
  - Books: `/var/mnt/fast8tb/Cloud/OneDrive/Books/eBooks`
  - Comics: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- **Config**: `/var/mnt/fast8tb/config/kavita`
- **Best For**: eBook reading with bookmarks, progress tracking

### Audiobookshelf
- **Port**: 13378 (external) -> 80 (internal)
- **Image**: `ghcr.io/advplyr/audiobookshelf:latest`
- **Purpose**: Audiobook streaming with chapter support
- **Root Path**: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks`
- **Config**: `/var/mnt/fast8tb/config/audiobookshelf`
- **Features**:
  - Mobile apps (iOS/Android)
  - Chapter navigation
  - Sleep timer
  - Playback speed control
  - Audible metadata matching

### Mylar3 (Comics Automation)
- **Port**: 8090
- **Image**: `linuxserver/mylar3:latest`
- **Purpose**: Comic/manga acquisition automation
- **Root Path**: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics`
- **Config**: `/var/mnt/fast8tb/config/mylar`

### Readarr (eBooks Automation)
- **Port**: 8787
- **Image**: `linuxserver/readarr:develop`
- **Purpose**: eBook acquisition automation
- **Root Paths**:
  - Books: `/var/mnt/fast8tb/Cloud/OneDrive/Books/eBooks`
  - All Books: `/var/mnt/fast8tb/Cloud/OneDrive/Books`
- **Config**: `/var/mnt/fast8tb/config/readarr`

### Suwayomi (Manga Downloader)
- **Port**: 4567
- **Image**: `ghcr.io/suwayomi/suwayomi-server:stable`
- **Purpose**: Download manga from online sources
- **Downloads**: `/srv/usenet/downloads/suwayomi-chapters`
- **Note**: Downloads to staging, requires reorganizer script

---

## Storage Structure

```
/var/mnt/fast8tb/Cloud/OneDrive/Books/
|
+-- Comics/                    # Komga primary library (718 GB)
|   +-- Series Name (Publisher) [EN]/
|   |   +-- Series Name v01 (Year).cbz
|   |   +-- Series Name v02 (Year).cbz
|   +-- Chainsaw Man (Viz) [EN]/
|   +-- Berserk (Dark Horse) [EN]/
|   +-- ...
|
+-- eBooks/                    # Kavita library (4.7 GB)
|   +-- Author Name/
|   |   +-- Title/
|   |   |   +-- Author - Title.epub
|   +-- Terry Pratchett/
|   +-- Ron Chernow/
|   +-- ...
|
+-- Audiobooks/                # Audiobookshelf library (25 GB)
    +-- Author Name/
    |   +-- Book Title/
    |   |   +-- audiofiles.m4b (or .mp3)
    +-- Discworld/
    |   +-- Book 01 - The Colour of Magic/
    |   +-- Book 02 - The Light Fantastic/
    |   +-- ... (all 41 novels)
    +-- Terry Pratchett/
    |   +-- Good Omens/
    |   +-- Dragons at Crumbling Castle/
    +-- Douglas Adams/
    +-- Ron Chernow/
    +-- ...
```

---

## Naming Conventions

### Comics/Manga

**Format**: `Series Name (Publisher) [Language]/Series Name vXX (Year).cbz`

**Examples**:
```
Chainsaw Man (Viz) [EN]/Chainsaw Man v01 (2020).cbz
Berserk (Dark Horse) [EN]/Berserk v01 (2011).cbz
20th Century Boys (Viz) [EN]/20th Century Boys v01 (2018).cbz
```

**Rules**:
- Use publisher name in parentheses
- Language tag in brackets (EN for English)
- Volume numbers with leading zeros (v01, v02)
- Year of publication/release in parentheses
- CBZ preferred over CBR (ZIP vs RAR compression)

### eBooks

**Format**: `Author/Series/Author - Series XX - Title.epub`

**Examples**:
```
Terry Pratchett/Discworld/Terry Pratchett - Discworld 01 - The Colour of Magic.epub
Ron Chernow/Terry Pratchett - Washington A Life.epub
Douglas Adams/Hitchhiker's Guide/Douglas Adams - Hitchhiker's Guide 01 - The Hitchhiker's Guide to the Galaxy.epub
```

**Rules**:
- Author folder at top level
- Series subfolder if applicable
- Author name prefix in filename
- Series number if part of series
- EPUB preferred over MOBI/AZW3

### Audiobooks

**Format**: `Author/Series (optional)/Book Title/{files}.m4b`

**Examples**:
```
Terry Pratchett/Discworld/Book 01 - The Colour of Magic/The Colour of Magic.m4b
Douglas Adams/The Hitchhiker's Guide to the Galaxy/audiobook.m4b
Ron Chernow/Alexander Hamilton/Alexander Hamilton.m4b
```

**Rules**:
- Author folder at top level
- Series folder if applicable (with book numbering for order)
- Book title folder
- M4B preferred (single file with chapters) over MP3s
- If MP3: number files with leading zeros

---

## Metadata Enrichment

### Komf for Comics/Manga

**Configuration** (`/var/mnt/fast8tb/config/komf/application.yml`):
```yaml
komga:
  baseUri: http://komga:25600
  user: ${KOMF_KOMGA_USER}
  password: ${KOMF_KOMGA_PASSWORD}

kavita:
  baseUri: http://kavita:5000
  apiKey: ${KOMF_KAVITA_API_KEY}

metadataProviders:
  mal:
    clientId: ${KOMF_MAL_CLIENT_ID}
  comicVine:
    apiKey: ${KOMF_COMICVINE_API_KEY}
```

**Triggering Enrichment**:
1. Open Komga web UI (http://localhost:8081)
2. Navigate to series needing metadata
3. Click "Edit" -> "Identify"
4. Or use Komf UI (http://localhost:8085)

### Audiobookshelf Metadata

**Automatic Sources**:
- Audible (primary)
- iTunes
- Google Books
- OpenLibrary

**Manual Matching**:
1. Open Audiobookshelf (http://localhost:13378)
2. Navigate to book
3. Click "Match" button
4. Search Audible or other sources
5. Select correct match

---

## Acquisition Workflows

### Audiobook Acquisition

```bash
# 1. Search via Prowlarr UI or API
# Navigate to http://localhost:9696
# Search for audiobook title

# 2. Add to SABnzbd with correct category
# Category: audiobooks
# Downloads to: /downloads/complete/audiobooks/

# 3. Move to correct location
mv "/downloads/complete/audiobooks/Book Title" \
   "/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks/Author/Book Title/"

# 4. Audiobookshelf auto-scans (or trigger manual scan)
# Settings -> Libraries -> Scan Library
```

### Comic/Manga Acquisition

**Via Mylar3 (Automated)**:
1. Add series in Mylar3 UI (http://localhost:8090)
2. Configure ComicVine ID
3. Mylar monitors for new releases
4. Downloads via SABnzbd
5. Post-processes to Comics folder
6. Komga auto-scans

**Manual**:
```bash
# 1. Search Prowlarr
# 2. Download via SABnzbd (category: comics)
# 3. Move to Comics folder
mv "/downloads/complete/comics/Series Name" \
   "/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/Series Name (Publisher) [EN]/"
# 4. Trigger Komga scan or wait for scheduled scan
```

### eBook Acquisition

**Via Readarr (Automated)**:
1. Add author/book in Readarr UI (http://localhost:8787)
2. Configure quality profile
3. Readarr searches and downloads
4. Post-processes to eBooks folder
5. Kavita auto-scans

---

## Optimal Settings

### Komga

**Library Settings**:
- Scan interval: Hourly (`0 0 * * * *` cron)
- CORS allowed: localhost:8085, 127.0.0.1:8085, LAN IP:8085

**Memory**:
- JVM: `-Xms4g -Xmx8g` (set in docker-compose)

### Kavita

**Library Settings**:
- Auto-scan enabled
- Cover generation: On

### Audiobookshelf

**Library Settings**:
- Scan interval: Every 6 hours
- Metadata providers: Audible, iTunes
- Prefer .m4b format

---

## Troubleshooting

### Komga Not Showing Files

1. Check file permissions (PUID/PGID 1000)
2. Verify CBZ files are not corrupted:
   ```bash
   unzip -t file.cbz
   ```
3. Check Komga logs:
   ```bash
   docker logs komga
   ```

### Audiobookshelf Missing Chapters

1. Verify M4B has embedded chapters
2. Use mp4chaps to add chapters if missing
3. Re-scan book in library

### Komf Not Enriching

1. Verify API keys in .env
2. Check CORS settings in Komga
3. Test API connectivity:
   ```bash
   curl http://localhost:8085/api/health
   ```

---

## Quick Reference

| Service | Port | URL |
|---------|------|-----|
| Komga | 8081 | http://localhost:8081 |
| Komf | 8085 | http://localhost:8085 |
| Kavita | 5000 | http://localhost:5000 |
| Audiobookshelf | 13378 | http://localhost:13378 |
| Mylar3 | 8090 | http://localhost:8090 |
| Readarr | 8787 | http://localhost:8787 |
| Prowlarr | 9696 | http://localhost:9696 |
| SABnzbd | 8080 | http://192.168.6.167:8080 |

---

## Related Documentation

- [BOOKS_ACQUISITION_PLAN.md](./BOOKS_ACQUISITION_PLAN.md) - Prioritized acquisition list
- [MANGA_COLLECTION_TOPOLOGY.md](./MANGA_COLLECTION_TOPOLOGY.md) - Manga-specific details
- [USER_TASTE_PROFILE.md](./USER_TASTE_PROFILE.md) - Acquisition decision guide

---

## Document Maintenance

**Update when**:
- Service configuration changes
- New services added
- Workflow improvements discovered

**Changelog**:
- v1.0.0 (2025-12-29): Initial creation from deep audit
