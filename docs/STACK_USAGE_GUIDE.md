# Media Stack Usage Guide

**Last Updated**: 2025-12-28

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

Tdarr transcodes media to HEVC (H.265) to save 30-50% storage. With 28TB of media and only 12TB free, this is critical.

### Initial Setup (Required - UI Only)

Tdarr libraries and workers must be configured via the web UI at http://localhost:8265.

#### Step 1: Create Libraries

1. Click **Libraries** in sidebar
2. Click **+ Library** for each:

| Library | Source Folder | Transcode Cache |
|---------|---------------|-----------------|
| Movies | `/media/movies` | `/temp` |
| TV | `/media/tv` | `/temp` |
| Anime | `/media/anime` | `/temp` |

3. For each library, enable:
   - ✅ Transcode
   - ✅ Health check
   - ✅ Scan on start

#### Step 2: Enable Workers

1. Click **Nodes** in sidebar
2. For **MainNode**:
   - Set **Transcode GPU**: `2`
   - Set **Health Check CPU**: `1`
3. For **SecondaryNode**:
   - Set **Transcode GPU**: `2`
   - Set **Health Check CPU**: `1`

#### Step 3: Add Transcode Plugin

1. Go to **Libraries** → select a library → **Transcode options**
2. Click **+ Add plugin**
3. Search for: `Tdarr_Plugin_MC93_Migz1FFMPEG` or `Tdarr_Plugin_00td_action_re_encode_to_hevc_ffmpeg`
4. Configure:
   - Target codec: **HEVC/H.265**
   - Hardware: **VAAPI** (for AMD GPU)

#### VAAPI Settings for AMD Radeon 780M

When configuring HEVC encoding, use these FFmpeg arguments:
```
-vaapi_device /dev/dri/renderD128 -vf 'format=nv12,hwupload' -c:v hevc_vaapi -qp 22
```

**Important**: Use `-qp` or `-global_quality`, NOT `-crf` (VAAPI doesn't support CRF).

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

### Needs Setup

| Tool | What's Missing |
|------|----------------|
| **Tdarr** | Libraries not created, workers at 0 |

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

**Priority action**: Configure Tdarr libraries and workers at http://localhost:8265 to start saving storage space!
