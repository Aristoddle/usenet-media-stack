# Media Acquisition Architecture

> **North Star Document** - Unified vision for all media acquisition pipelines on Bazzite.
>
> Last Updated: 2025-12-18
> Status: Living document - update as systems evolve

---

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    MEDIA ACQUISITION PIPELINES                          │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌────────────────────────┐    ┌────────────────────────┐               │
│  │    MANGA PIPELINE      │    │     ROM PIPELINE       │               │
│  │    (✅ Production)     │    │    (🔧 Building)       │               │
│  └───────────┬────────────┘    └───────────┬────────────┘               │
│              │                             │                             │
│              ▼                             ▼                             │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    PROWLARR (Search Layer)                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │   │
│  │  │ Comics: 7030 │  │ Console:1000 │  │ Ebooks: 7020 │            │   │
│  │  │ NZBPlanet    │  │ NZBgeek      │  │ NZB.su       │            │   │
│  │  └──────────────┘  └──────────────┘  └──────────────┘            │   │
│  └─────────────────────────────┬────────────────────────────────────┘   │
│                                │                                         │
│              ┌─────────────────┼─────────────────┐                      │
│              ▼                 ▼                 ▼                      │
│  ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐        │
│  │    SABnzbd       │ │   Transmission   │ │     aria2c       │        │
│  │  (Usenet DL)     │ │   (Torrent DL)   │ │  (HTTP/Archive)  │        │
│  └────────┬─────────┘ └────────┬─────────┘ └────────┬─────────┘        │
│           │                    │                    │                   │
│           └────────────────────┼────────────────────┘                   │
│                                ▼                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    STAGING + VERIFICATION                         │   │
│  │  /var/mnt/fast8tb/Local/downloads/staging/                       │   │
│  │  - Hash verify (No-Intro/Redump for ROMs)                        │   │
│  │  - Size/quality check (manga)                                     │   │
│  └─────────────────────────────┬────────────────────────────────────┘   │
│                                ▼                                         │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    ORGANIZER AGENTS                               │   │
│  │  manga-download-organizer → Books/Comics/                         │   │
│  │  rom-download-organizer   → Emudeck/Emulation/roms/               │   │
│  │  mod-download-organizer   → Emudeck/Emulation/mods/               │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Platform Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                    User Request                              │
│               "Download [content]"                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   detect_platform()                          │
└─────────────────────────────────────────────────────────────┘
           │                  │                    │
           ▼                  ▼                    ▼
      [bazzite]          [mac-home]          [mac-remote]
           │                  │                    │
           ▼                  ▼                    ▼
    ┌──────────┐       ┌──────────┐         ┌──────────┐
    │ Usenet   │       │ Usenet   │         │ Torrent  │
    │ (local)  │       │ (remote) │         │ (local)  │
    └──────────┘       └──────────┘         └──────────┘
           │                  │                    │
    [if fails]         [if fails]                  │
           │                  │                    │
           ▼                  ▼                    │
    ┌──────────┐       ┌──────────┐                │
    │ Torrent  │       │ Torrent  │                │
    │ (local)  │       │ (remote) │                │
    └──────────┘       └──────────┘                │
           │                  │                    │
           └──────────────────┴────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Download Complete                         │
│                  → Verify → Organize                         │
└─────────────────────────────────────────────────────────────┘
```

| Platform | Primary | Fallback | Stack |
|----------|---------|----------|-------|
| `bazzite` | Usenet (Prowlarr→SABnzbd) | Torrent (Transmission) | Full local |
| `mac-home` | Usenet via server API | Torrent via server API | Remote calls |
| `mac-remote` | Torrent (local Transmission) | Manual | No usenet |

---

## Content Types & Sources

| Content | Prowlarr Cat | Primary Source | Fallback | Verification |
|---------|--------------|----------------|----------|--------------|
| **Manga/Comics** | 7030 | Usenet | Nyaa torrents | File size, quality |
| **ROMs** | 1000 | Usenet | Archive.org, Nyaa | No-Intro/Redump hash |
| **Switch** | 101040 | Usenet | Nyaa | Title ID verify |
| **PS2** | 101100 | Usenet | Archive.org | Redump hash |
| **Wii** | 101030 | Usenet | Archive.org | Redump hash |
| **Ebooks** | 7020 | Usenet | LibGen | - |
| **Audiobooks** | 3030 | Usenet | - | - |
| **Romhacks/Mods** | - | romhacking.net | GitHub | Patch checksum |
| **Texture Packs** | - | Dolphin forums | GitHub | Manual QA |
| **Shaders** | - | libretro/slang-shaders | - | Visual test |

---

## Key API Patterns

### Prowlarr Search → Grab (CORRECT)

```bash
# 1. Search
curl -sL "$PROWLARR_URL/api/v1/search?query=QUERY&categories=CATEGORY" \
  -H "X-Api-Key: $PROWLARR_API_KEY"

# 2. Grab (send to download client)
curl -sL -X POST "$PROWLARR_URL/api/v1/search" \
  -H "X-Api-Key: $PROWLARR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"guid":"GUID","indexerId":INDEXER_ID,"downloadClientId":CLIENT_ID}'
```

**Download Client IDs:**
- SABnzbd: 3
- Transmission: 4
- Aria2: 6

### API Key Management

```bash
# NEVER hardcode - always read live from configs
PROWLARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_ROOT/prowlarr/config.xml")
SABNZBD_API_KEY=$(grep -oP '(?<=^api_key = ).+' "$CONFIG_ROOT/sabnzbd/sabnzbd.ini")
```

---

## Directory Structure

```
/var/mnt/fast8tb/
├── config/                          # Container configs
│   ├── prowlarr/config.xml
│   ├── sabnzbd/sabnzbd.ini
│   └── transmission/settings.json
├── Local/downloads/                 # Download staging
│   ├── sabnzbd/complete/
│   ├── transmission/complete/
│   └── staging/                     # Verification staging
├── Cloud/OneDrive/Books/Comics/     # Manga collection (712GB)
└── Emudeck/Emulation/
    ├── roms/                        # ROM collection (1.3TB)
    │   ├── switch/   (399GB)
    │   ├── wiiu/     (221GB)
    │   ├── ps2/      (120GB)
    │   └── [system]/
    ├── bios/
    ├── mods/                        # Romhacks, patches
    ├── textures/                    # HD texture packs
    └── shaders/                     # RetroArch shaders
```

---

## Pipeline Status

### Manga Pipeline ✅

| Component | Status | Notes |
|-----------|--------|-------|
| manga-acquisition skill | ✅ Production | Usenet-first, platform-aware |
| manga-torrent-searcher agent | ✅ Production | Multi-tracker, usenet fallback |
| manga-download-organizer agent | ✅ Production | Platform-aware paths |
| E2E tested | ✅ | CSM 223 via Prowlarr→SABnzbd |

### ROM Pipeline 🔧

| Component | Status | Notes |
|-----------|--------|-------|
| emudeck-rom-manager skill | 🔧 Needs update | Add Prowlarr patterns |
| rom-acquisition-agent | ❌ Not built | Need to create |
| Hash verification | ❌ Not built | No-Intro/Redump DATs |
| E2E tested | ❌ | Need test case |

### Mod/Enhancement Pipeline 📋

| Component | Status | Notes |
|-----------|--------|-------|
| mod-acquisition-agent | 📋 Planned | romhacking.net, GitHub |
| texture-pack-fetcher | 📋 Planned | Dolphin HD packs |
| shader-sync | 📋 Planned | libretro slang-shaders |

---

## Related Documentation

- **Dotfiles**: `~/.local/share/chezmoi/dot_claude/skills/`
- **Usenet Stack**: `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/`
- **Platform Strategy**: `dot_claude/skills/manga-acquisition/PLATFORM_STRATEGY.md`

---

## Changelog

| Date | Change |
|------|--------|
| 2025-12-18 | Initial architecture doc |
| 2025-12-18 | Manga pipeline hardened with correct Prowlarr API |
| 2025-12-18 | Discovered Console categories on usenet indexers |
