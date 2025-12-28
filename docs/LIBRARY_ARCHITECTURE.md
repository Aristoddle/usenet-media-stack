# Media Library Architecture

> **Purpose:** Document the intentional separation and organization of media collections
> **Last Updated:** 2025-12-27

---

## Design Philosophy

### The Three-Library Split

The media pool is intentionally organized into three distinct libraries:

```
/var/mnt/pool/
├── movies/     # Classic, foundational, life-changing films (non-anime)
├── tv/         # Essential TV series (non-anime)
└── anime/      # All anime content (films AND TV series)
```

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
- Anime films (even Ghibli - these go in `/anime/`)
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
- Anime TV series (these go in `/anime/`)
- Casual/disposable content

### `/var/mnt/pool/anime/`
**Purpose:** ALL anime content - films AND TV series

**Organization:**
```
/var/mnt/pool/anime/
├── [Series Name]/
│   ├── Season 01/
│   ├── Season 02/
│   └── ...
├── [Film Collection Name]/          # e.g., "One Piece Films"
│   ├── Film 1/
│   ├── Film 2/
│   └── ...
├── Studio Ghibli Films/             # Collected Ghibli works
│   ├── Spirited Away (2001)/
│   ├── Princess Mononoke (1997)/
│   └── ...
└── [Standalone Films]/              # Individual anime films
```

**Collections Strategy:**
- Group related films into collections (One Piece Films, Dragon Ball Movies)
- Keep Studio Ghibli as a distinct collection (brand recognition)
- Standalone films remain at top level with proper (Year) naming

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
Anime Name (Year)/               # Or Anime Name if year is unknown
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
- One Piece films → should be in `/anime/One Piece Films/`
- Ghibli films → should be in `/anime/Studio Ghibli Films/`
- NOT in `/movies/` despite being "movies"

---

## Maintenance Tasks

### Regular audits
- Check for folders without year in parentheses
- Look for scattered episode folders in library roots
- Verify anime films haven't migrated to movies library
- Scan for duplicate versions (keep best quality)

### Sonarr/Radarr configuration
- Ensure anime series use anime quality profiles
- Keep anime root folder pointed to `/anime/`
- Movies root folder → `/movies/` (no anime)

---

## Changelog

| Date | Change |
|------|--------|
| 2025-12-27 | Initial architecture documentation |
| 2025-12-27 | Documented anime separation rationale |
| 2025-12-27 | Added contamination cleanup procedures |
