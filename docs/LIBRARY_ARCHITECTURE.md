# Media Library Architecture

> **Purpose:** Document the intentional separation and organization of media collections
> **Last Updated:** 2025-12-29

---

## Current Pool Structure

The media pool uses MergerFS to present multiple NVMe drives as a unified filesystem:

```
/var/mnt/pool/
├── movies/              # 691 films (classic, art-house, life-changing)
├── tv/                  # 29 essential TV series
├── anime-movies/        # 25 anime films (Ghibli, standalone)
├── anime-tv/            # 75 anime TV series
├── christmas-movies/    # Seasonal movies
├── christmas-tv/        # Seasonal TV
├── downloads/           # Staging area
└── music/               # Music library (Lidarr)
```

**Total Pool**: 41TB (8 NVMe drives), ~30TB used, ~11TB free

---

## Design Philosophy

### The Multi-Library Split

Media is intentionally separated for audience filtering and sharing:

| Library | Purpose | Plex Library |
|---------|---------|--------------|
| `movies/` | Classic, foundational, life-changing films (non-anime) | Movies |
| `tv/` | Essential TV series (non-anime) | TV Shows |
| `anime-movies/` | Anime films (Ghibli, standalone, collections) | Anime Movies |
| `anime-tv/` | Anime TV series | Anime TV |
| `christmas-*` | Seasonal content for December | Separate Plex libs |

### Rationale

**Why separate anime?**

1. **Audience Filtering** - Not all viewers want anime mixed with classic cinema
2. **Shareability** - Can share the classic film/TV collection without flooding with anime
3. **Curatorial Intent** - The movies/TV libraries represent "art-house AND/OR life-changing" content
4. **Quality Bar** - Anime, while often competitively excellent, serves a different audience

**This is NOT a quality judgment** - anime includes masterworks (Studio Ghibli, Satoshi Kon, etc.). The separation is purely for audience filtering and curation.

---

## Library Definitions

### `/var/mnt/pool/movies/`
**Purpose:** Classic, foundational, art-house, and life-changing films

**Includes:**
- Italian neorealism (Fellini, Antonioni, De Sica)
- French New Wave (Godard, Demy, Truffaut)
- Hollywood classics and modern masterpieces
- Scorsese, Kubrick, Coppola, Tarantino filmographies
- Award-winning international cinema
- Noir, neo-noir, and genre-defining works

**Excludes:**
- Anime films (these go in `anime-movies/`)
- Content that's "good but not life-changing"

### `/var/mnt/pool/tv/`
**Purpose:** Essential TV series that represent television-as-art

**Includes:**
- Golden age TV dramas (The Sopranos, The Wire, Breaking Bad)
- Classic sitcoms (Seinfeld, It's Always Sunny)
- Prestige miniseries
- Documentary series
- Doctor Who (1963 + 2005)

**Excludes:**
- Anime TV series (these go in `anime-tv/`)
- Casual/disposable content

### `/var/mnt/pool/anime-movies/`
**Purpose:** Anime films separate from live-action movies

**Organization:**
```
/var/mnt/pool/anime-movies/
├── Studio Ghibli Films/
│   ├── Spirited Away (2001)/
│   ├── Princess Mononoke (1997)/
│   └── ...
├── One Piece Films/
│   ├── One Piece Film - Red (2022)/
│   └── ...
└── [Standalone Films]/
    └── Akira (1988)/
```

### `/var/mnt/pool/anime-tv/`
**Purpose:** Anime TV series

**Organization:**
```
/var/mnt/pool/anime-tv/
├── Chainsaw Man (2022)/
│   └── Season 01/
├── Attack on Titan (2013)/
│   ├── Season 01/
│   ├── Season 02/
│   └── ...
└── ...
```

---

## Naming Conventions

### TV Series
```
Show Name (Year)/
  Season 01/
    Show Name - S01E01 - Episode Title [Quality].mkv
```

### Movies
```
Movie Name (Year)/
  Movie Name (Year) [Quality].mkv
```

### Anime TV
```
Anime Name (Year)/
  Season 01/
    [ReleaseGroup] Anime Name - S01E01 [Quality].mkv
```

### Anime Film Collections
```
Collection Name/
  Film Name (Year)/
    Film Name (Year) [Quality].mkv
```

---

## Known Contamination Risks

### Cross-library pollution
- **Monster**: Naoki Urasawa anime vs Netflix Dahmer show
- **Doctor Who**: Classic (1963) vs NuWho (2005) - different TVDB IDs
- **House of Cards**: Multiple international versions

### Obfuscated filenames
Some releases use ROT13 encoding (e.g., "Ubhfr bs Pneqf" = "House of Cards")
- These can slip into wrong libraries
- Recommend scanning for non-ASCII patterns periodically

### Anime films in wrong location
- One Piece films -> should be in `/anime-movies/`
- Ghibli films -> should be in `/anime-movies/Studio Ghibli Films/`
- NOT in `/movies/` despite being "movies"

---

## Sonarr/Radarr Configuration

| App | Root Folder | Quality Profile |
|-----|-------------|-----------------|
| Radarr (movies) | `/pool/movies` | Ultra-HD or HD-1080p |
| Radarr (anime) | `/pool/anime-movies` | Anime profile |
| Sonarr (TV) | `/pool/tv` | HD-1080p |
| Sonarr (anime) | `/pool/anime-tv` | Anime profile |

**Note**: Container paths use `/pool/` which maps to host `/var/mnt/pool/`

---

## Maintenance Tasks

### Regular audits
- Check for folders without year in parentheses
- Look for scattered episode folders in library roots
- Verify anime films haven't migrated to movies library
- Scan for duplicate versions (keep best quality)

### Sonarr/Radarr configuration
- Ensure anime series use anime quality profiles
- Keep anime root folders pointed to `anime-*` directories
- Movies root folder -> `/pool/movies` (no anime)

---

## Related Documentation

- [Storage Architecture](./storage/architecture.md) - MergerFS configuration
- [STORAGE_AND_REMOTE_ACCESS.md](./STORAGE_AND_REMOTE_ACCESS.md) - Quick reference

---

## Changelog

| Date | Change |
|------|--------|
| 2025-12-29 | Updated to reflect actual pool structure (anime-movies/anime-tv split) |
| 2025-12-29 | Added current file counts and pool stats |
| 2025-12-27 | Initial architecture documentation |
| 2025-12-27 | Documented anime separation rationale |
| 2025-12-27 | Added contamination cleanup procedures |
