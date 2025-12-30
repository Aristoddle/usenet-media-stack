# Media Stack Usage Guide

**Last Updated**: 2025-12-28

---

## ⚠️ CRITICAL: Docker Commands Require sudo

**On Bazzite/Fedora, ALL docker commands require sudo:**

```bash
# WRONG - will fail with permission denied
docker compose up -d
docker logs tdarr

# CORRECT - always use sudo
sudo docker compose up -d
sudo docker logs tdarr
sudo docker compose restart tdarr
```

This is a Bazzite/SELinux security requirement, not a misconfiguration.

---

## Stack Hierarchy: What Talks to What

```
┌─────────────────────────────────────────────────────────────────┐
│                        YOU (Daily Use)                          │
├─────────────────────────────────────────────────────────────────┤
│  Overseerr          Plex              Audiobookshelf            │
│  (Request content)  (Watch content)   (Listen to audiobooks)    │
└────────┬────────────────┬─────────────────┬─────────────────────┘
         │                │                 │
         ▼                ▼                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    AUTOMATION LAYER                              │
├─────────────────────────────────────────────────────────────────┤
│  Radarr ←→ Sonarr ←→ Prowlarr    Komga ←→ Kavita               │
│  (Movies)  (TV)      (Indexers)   (Comics)  (Books)             │
│                                                                  │
│  Bazarr (Subtitles)   Tdarr (Transcoding)   Komf (Metadata)     │
└────────┬────────────────┬───────────────────────────────────────┘
         │                │
         ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DOWNLOAD LAYER                                │
├─────────────────────────────────────────────────────────────────┤
│  SABnzbd (Usenet - Primary)     Transmission (Torrents)         │
└─────────────────────────────────────────────────────────────────┘
```

---

## Current Library Stats

| Library | Size | Location |
|---------|------|----------|
| Movies | 16 TB | `/var/mnt/pool/movies` |
| TV Shows | 6.1 TB | `/var/mnt/pool/tv` |
| Anime | 5.9 TB | `/var/mnt/pool/anime` |
| **Total** | **28 TB** | MergerFS Pool (41TB total, 12TB free) |

---

## Daily Workflow: What You Should Actually Use

### For Movies & TV

| Task | Use This | NOT This |
|------|----------|----------|
| **Request new content** | Overseerr | Radarr/Sonarr directly |
| **Watch content** | Plex | - |
| **Check download status** | Overseerr or SABnzbd | - |
| **See what's coming** | Overseerr calendar | Sonarr calendar |

**Why Overseerr?**
- Beautiful UI designed for requesting
- Shows what's already in your library
- Handles both movies AND TV in one place
- Can be shared with family (they can request, you approve)

**When to use Radarr/Sonarr directly?**
- Troubleshooting failed downloads
- Adjusting quality profiles
- Managing exclusions or tags
- Bulk operations

---

### For Manga/Comics

| Task | Use This |
|------|----------|
| **Read manga** | Komga or Kavita |
| **Fix metadata** | Komf GUI (localhost:8085) |
| **Add new series** | Mylar3 or manual add to folder |

---

### For Audiobooks

| Task | Use This |
|------|----------|
| **Listen on desktop** | Audiobookshelf web (localhost:13378) |
| **Listen on iPhone** | **Audiobookshelf app** (App Store) |
| **Add books** | Readarr or manual add |

#### Audiobookshelf Mobile Setup

1. **Download**: Search "Audiobookshelf" on iOS App Store (free, by advplyr)
2. **Server URL**: `http://192.168.6.167:13378`
3. **Login**: Use your Audiobookshelf credentials

**Features:**
- Background playback
- Offline downloads for travel
- Sleep timer & playback speed
- CarPlay support
- Sync progress across devices

---

## Overseerr: The Right Way to Use It

### Your Current Setup

```
Overseerr
├── Radarr (movies → /pool/movies)      ← Should be "Default"
├── Radarr_anime (anime movies → /pool/anime)
└── Sonarr (TV → /pool/tv, Anime → /pool/anime)
```

### The "Default" and "4K" Toggles Explained

| Toggle | What It Means |
|--------|---------------|
| **Default** | Used when user clicks "Request" without specifying |
| **4K** | Used when user explicitly requests 4K version |

### Recommended Configuration

**For Radarr servers:**
- `Radarr` (movies): ✅ Default, ❌ 4K
- `Radarr_anime` (anime): ❌ Default, ❌ 4K

**Why?** Most requests are regular movies. Anime movies are niche - users should explicitly choose "Radarr_anime" from the server dropdown when requesting anime films.

**To fix (if not already set):**
1. Go to http://localhost:5055/settings/services
2. Click on "Radarr" entry
3. Enable "Default Server" toggle
4. Save

---

## Tdarr: Storage Optimization

Tdarr transcodes media to HEVC/AV1 to save 30-50% storage. With 28TB of media and only 12TB free, this is critical.

### Current Status ✅ OPERATIONAL

| Component | Status | Details |
|-----------|--------|---------|
| MainNode | ✅ Active | GPU workers: 2, CPU health: 1 |
| SecondaryNode | ✅ Active | GPU workers: 2, CPU health: 1 |
| Movies | ✅ Configured | ID: `qRHd4dcGk`, `/media/movies` |
| TV | ✅ Configured | ID: `FKnGmlxBT`, `/media/tv` |
| Anime | ✅ Configured | ID: `08QZ-saXn`, `/media/anime` |
| Files Queued | **5,026** | GPU transcoding with HEVC |

### Library Configuration

Libraries are configured with the **Migz1FFMPEG GPU plugin** for hardware-accelerated HEVC encoding:

| Plugin | Status | Purpose |
|--------|--------|---------|
| `MigzImageRemoval` | ✅ | Remove embedded images |
| `Reorder_Streams` | ✅ | Optimize stream order |
| `Migz1FFMPEG_CPU` | ❌ OFF | CPU encoding (disabled) |
| `Migz1FFMPEG` | ✅ ON | **GPU VAAPI encoding** |
| `New_file_size_check` | ✅ | Verify compression worked |

### AMD Radeon 780M VAAPI Configuration

Your GPU uses VCN4 (Video Core Next 4.0) with RDNA3 architecture.

**Optimal FFmpeg flags:**
```bash
# HEVC (recommended for compatibility)
-vaapi_device /dev/dri/renderD128 \
-vf 'format=nv12,hwupload' \
-c:v hevc_vaapi \
-qp 20 \
-profile:v main

# For 10-bit HDR content
-vf 'format=p010,hwupload' \
-profile:v main10

# AV1 (better compression, newer)
-c:v av1_vaapi -qp 24
```

**Quality Settings (QP scale: 0-51, lower = better):**

| Content Type | HEVC QP | AV1 QP | Notes |
|--------------|---------|--------|-------|
| 4K HDR | 18 | 22 | Preserve quality |
| 4K SDR | 20 | 24 | Standard high quality |
| 1080p | 22 | 26 | Good compression |
| 720p/480p | 24 | 28 | Maximum compression |
| Anime | 18 | 22 | Preserve line art |

**CRITICAL**: VAAPI does NOT support CRF mode. Use `-qp` or `-global_quality` only!

### Tdarr API Reference

Libraries must be created via UI (API-created libraries cause `RangeError: interval NaN`), but configuration can be done via API:

```bash
# Get all libraries
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{"data":{"collection":"LibrarySettingsJSONDB","mode":"getAll"}}'

# Update library settings
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "collection": "LibrarySettingsJSONDB",
      "mode": "update",
      "docID": "LIBRARY_ID",
      "obj": {
        "processLibrary": true,
        "processTranscodes": true,
        "processHealthChecks": true
      }
    }
  }'

# Trigger library scan
curl -s -X POST http://localhost:8265/api/v2/scan-files \
  -H "Content-Type: application/json" \
  -d '{"data":{"scanConfig":{"dbID":"LIBRARY_ID","arrayOrPath":"/media/movies","mode":"scanFindNew"}}}'

# Check file queue status
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{"data":{"collection":"FileJSONDB","mode":"getAll"}}' | \
  jq '[.[] | .TranscodeDecisionMaker] | group_by(.) | map({decision: .[0], count: length})'
```

### Initial Setup (UI Only Required)

**⚠️ WARNING**: Libraries MUST be created via the web UI at http://localhost:8265. API-created libraries lack proper `schedule` arrays and cause runtime errors.

#### Step 1: Create Libraries (UI)

1. Click **Libraries** → **+ Library**
2. Create three libraries:

| Library | Source Folder | Cache | Priority |
|---------|---------------|-------|----------|
| Movies | `/media/movies` | `/temp` | Normal |
| TV | `/media/tv` | `/temp` | Normal |
| Anime | `/media/anime` | `/temp` | Normal |

**Note**: Container paths differ from host! Host `/var/mnt/pool/movies` maps to container `/media/movies`.

#### Step 2: Enable Workers (UI or API)

```bash
# Via API - update node worker limits
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "collection": "NodeJSONDB",
      "mode": "update",
      "docID": "NODE_ID",
      "obj": {
        "workerLimits": {
          "transcodegpu": 2,
          "healthcheckcpu": 1,
          "transcodecpu": 0
        }
      }
    }
  }'
```

#### Step 3: Configure Plugins (API)

```bash
# Enable GPU plugin, disable CPU plugin
curl -s -X POST http://localhost:8265/api/v2/cruddb \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "collection": "LibrarySettingsJSONDB",
      "mode": "update",
      "docID": "LIBRARY_ID",
      "obj": {
        "pluginIDs": [
          {"_id": "plugin1", "id": "Tdarr_Plugin_MC93_MigzImageRemoval", "checked": true, "source": "Community", "priority": 0, "InputsDB": {}},
          {"_id": "plugin2", "id": "Tdarr_Plugin_lmg1_Reorder_Streams", "checked": true, "source": "Community", "priority": 1, "InputsDB": {}},
          {"_id": "plugin3", "id": "Tdarr_Plugin_MC93_Migz1FFMPEG_CPU", "checked": false, "source": "Community", "priority": 2, "InputsDB": {}},
          {"_id": "plugin4", "id": "Tdarr_Plugin_MC93_Migz1FFMPEG", "checked": true, "source": "Community", "priority": 3, "InputsDB": {}},
          {"_id": "plugin5", "id": "Tdarr_Plugin_a9he_New_file_size_check", "checked": true, "source": "Community", "priority": 4, "InputsDB": {}}
        ]
      }
    }
  }'
```

---

## What to Bake Into docker-compose vs Manual UI Settings

### ✅ Put in docker-compose.yml

| Setting | Why |
|---------|-----|
| Port mappings | Infrastructure, rarely changes |
| Volume mounts | Infrastructure |
| Environment variables (API keys) | Reproducible deploys |
| Resource limits | Infrastructure |
| Network configuration | Infrastructure |
| CORS settings | Needed before first access |

### ❌ Configure in UI (don't try to automate)

| Setting | Why |
|---------|-----|
| Quality profiles | Complex, UI-dependent, rarely changes |
| Indexer connections | Prowlarr syncs these automatically |
| Download client settings | One-time setup, UI validates |
| Library paths in *arr apps | UI validates paths exist |
| User accounts/permissions | Security-sensitive |
| Notification settings | Personal preference |
| **Tdarr libraries & workers** | No reliable API |

### 🔄 Can Go Either Way

| Setting | Recommendation |
|---------|----------------|
| Metadata providers | UI easier, but komf uses application.yml |
| Scan intervals | UI for Tdarr, docker env for others |
| Theme/appearance | Personal preference |

---

## Integration Status

### Working Now

| Tool | Purpose | Status |
|------|---------|--------|
| Overseerr | Request management | ✅ Connected to Radarr & Sonarr |
| Prowlarr | Indexer management | ✅ 4 Usenet indexers, syncing to all *arrs |
| Bazarr | Subtitles | ✅ Set and forget |
| Tautulli | Plex analytics | ✅ Running at :8181 |
| Komf | Manga metadata | ✅ Connected to Komga & Kavita |
| Audiobookshelf | Audiobooks | ✅ 1 library |
| **Tdarr** | Storage optimization | ✅ **5,026 files queued**, GPU VAAPI active |

### All Core Services Operational ✅

All essential media stack services are now configured and running.

### Worth Adding Later

| Tool | Purpose | Effort | Value |
|------|---------|--------|-------|
| **Recyclarr** | TRaSH Guides sync | Low | Better quality profiles |
| **Notifiarr** | Rich Discord notifications | Medium | Know when stuff downloads |
| **Kometa (PMM)** | Plex collections/overlays | Medium | Pretty poster overlays |

---

## Plex Integrations

### Already Working

| Integration | Status |
|-------------|--------|
| Overseerr ↔ Plex | ✅ Library sync, user auth |
| Tautulli ↔ Plex | ✅ Watch history, stats |

### Available But Optional

| Integration | What It Does | Worth It? |
|-------------|--------------|-----------|
| **Kometa (PMM)** | Auto-create collections, overlays | ✅ If you want pretty posters |
| **PlexTraktSync** | Sync watch history to Trakt | ❌ Unless you use Trakt |
| **Plex Webhooks** | Notify *arrs when playback starts | ❌ Overkill |

---

## Quick Reference: URLs

| Service | URL | Purpose |
|---------|-----|---------|
| **Overseerr** | http://localhost:5055 | Request movies/TV |
| **Plex** | http://localhost:32400/web | Watch content |
| **Radarr** | http://localhost:7878 | Movie management (backend) |
| **Sonarr** | http://localhost:8989 | TV management (backend) |
| **Prowlarr** | http://localhost:9696 | Indexer management |
| **SABnzbd** | http://192.168.6.167:8080 | Download status |
| **Tdarr** | http://localhost:8265 | Transcoding status |
| **Bazarr** | http://localhost:6767 | Subtitle status |
| **Komga** | http://localhost:8081 | Read comics |
| **Kavita** | http://localhost:5000 | Read books/manga |
| **Komf** | http://localhost:8085 | Manga metadata |
| **Audiobookshelf** | http://localhost:13378 | Audiobooks |
| **Tautulli** | http://localhost:8181 | Plex analytics |

---

## TL;DR: Your Daily Tools

1. **Overseerr** - Request anything
2. **Plex** - Watch anything
3. **Komga/Kavita** - Read manga/books
4. **Audiobookshelf** - Listen to audiobooks (iOS app available!)

Everything else is automation that runs in the background. You shouldn't need to touch Radarr/Sonarr/Prowlarr/SABnzbd unless troubleshooting.

**Tdarr Status**: ✅ Active - 5,026 files queued for GPU transcoding. Monitor progress at http://localhost:8265
