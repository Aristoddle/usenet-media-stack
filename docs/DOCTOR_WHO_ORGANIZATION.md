# Doctor Who Definitive Organization Guide

> **Purpose:** The canonical reference for organizing Doctor Who content in Plex
> **Last Updated:** 2025-12-29
> **Status:** Active reference document

---

## Overview

Doctor Who is uniquely complex to organize due to:
- 60+ years of content (1963-present)
- Multiple distinct series with the same name
- Lost episodes, reconstructions, colorizations
- Multi-part serial format (Classic) vs single episodes (NuWho)
- International dubs and versions
- Spin-offs and specials

This document provides the DEFINITIVE structure for Plex organization.

---

## Series Identification

### TVDB IDs (Critical for Sonarr)

| Series | TVDB ID | Years | Episodes |
|--------|---------|-------|----------|
| Doctor Who (1963) | 76107 | 1963-1989 | 695 episodes, 26 seasons |
| Doctor Who (2005) | 78804 | 2005-2022 | ~165 episodes, 13 seasons |
| Doctor Who (2023) | 436992 | 2023+ | Disney+ era, new numbering |

**CRITICAL:** These are THREE SEPARATE SERIES in Sonarr/Plex. Do not mix them.

---

## Correct Folder Structure

### Classic Who (1963)

```
/tv/Doctor Who (1963)/
├── Season 01/
│   ├── Doctor Who (1963) - S01E01 - An Unearthly Child.mkv
│   ├── Doctor Who (1963) - S01E02 - The Cave of Skulls.mkv
│   └── ...
├── Season 02/
├── ...
└── Season 26/
```

**Key Points:**
- TVDB uses sequential episode numbering within seasons
- Multi-part stories are individual episodes (Part 1, Part 2, etc.)
- Season 1 = William Hartnell's first season (1963-1964)
- Season 26 = Sylvester McCoy's final season (1989)

### NuWho (2005)

```
/tv/Doctor Who (2005)/
├── Season 01/
│   ├── Doctor Who (2005) - S01E01 - Rose.mkv
│   ├── Doctor Who (2005) - S01E02 - The End of the World.mkv
│   └── ...
├── Season 02/
├── ...
├── Season 13/
│   ├── Doctor Who (2005) - S13E01 - Chapter One - The Halloween Apocalypse.mkv
│   └── ...
└── Specials/
    ├── Doctor Who (2005) - S00E01 - The Christmas Invasion.mkv
    ├── Doctor Who (2005) - S00E02 - Attack of the Graske.mkv
    └── ...
```

**Key Points:**
- Season 01 = Christopher Eccleston (2005)
- Season 13 = Jodie Whittaker's final season (2021-2022)
- Specials go in Season 00 (S00E01, S00E02, etc.)
- Christmas/New Year specials are in Specials, NOT in regular seasons

### Disney+ Era (2023)

```
/tv/Doctor Who (2023)/
├── Season 01/
│   ├── Doctor Who (2023) - S01E01 - The Church on Ruby Road.mkv
│   ├── Doctor Who (2023) - S01E02 - Space Babies.mkv
│   └── ...
└── Specials/
    ├── Doctor Who (2023) - S00E01 - The Star Beast.mkv
    ├── Doctor Who (2023) - S00E02 - Wild Blue Yonder.mkv
    └── ...
```

**Key Points:**
- This is a NEW series starting 2023
- Ncuti Gatwa is the new Doctor
- The 60th Anniversary specials may be in Specials or NuWho depending on TVDB

---

## Episode Naming Format

### Plex Standard Format
```
Series Name (Year) - SXXEXX - Episode Title.ext
```

### Examples

**Correct:**
```
Doctor Who (1963) - S12E11 - Genesis of the Daleks Part One.mkv
Doctor Who (2005) - S04E01 - Partners in Crime.mkv
Doctor Who (2023) - S01E05 - 73 Yards.mkv
```

**Incorrect:**
```
Doctor.Who.S12E11.Genesis.of.the.Daleks.Part.One.1080p.BluRay.x264-OUIJA.mkv
Doctor Who S01E01 Rose 1080p.mkv
[RELEASE-GROUP] Doctor Who 1963 S12E11.mkv
```

---

## Quality Tiers and Preferences

### Classic Who (1963)
| Priority | Source | Notes |
|----------|--------|-------|
| 1 | 1080p BluRay | Available for later seasons |
| 2 | DVD Rip (proper) | Best available for many early seasons |
| 3 | Reconstruction | For missing episodes |
| 4 | Colorized | Nice to have, not essential |

**Avoid:** German-only dubs (unless dual-audio), low-quality VHS rips

### NuWho (2005)
| Priority | Source | Notes |
|----------|--------|-------|
| 1 | 1080p BluRay | Best quality |
| 2 | 1080p WEB-DL | Good streaming quality |
| 3 | 720p BluRay | Acceptable |
| 4 | 720p WEB | Upgrade candidate |

---

## Common Issues and Solutions

### Issue 1: German/Italian Dubs Mixed In

**Symptoms:**
- Episode titles in German (e.g., "Das Urteil", "Die rastlosen Toten")
- Files with "GERMAN DUBBED" or "ITA" in filename

**Solution:**
1. Keep only if dual-audio (has English track)
2. Delete German/Italian-only files
3. Re-download English versions

**Detection:**
```bash
find "/var/mnt/pool/tv/Doctor Who"* -name "*GERMAN*" -o -name "*German*" -o -name "*ITA*" -o -name "*Italian*"
```

### Issue 2: Nested Folder Structure

**Symptoms:**
- Episode folders inside season folders
- Multi-level nesting like `/Season 03/Doctor.Who.S03E04.../file.mkv`

**Solution:**
1. Move .mkv files directly into Season folder
2. Delete empty nested folders
3. Let Plex rescan

**Flatten Command:**
```bash
# Move all mkv files to parent season folder
find "/var/mnt/pool/tv/Doctor Who (1963)/Season XX" -name "*.mkv" -exec mv {} "/var/mnt/pool/tv/Doctor Who (1963)/Season XX/" \;
# Remove empty directories
find "/var/mnt/pool/tv/Doctor Who (1963)/Season XX" -type d -empty -delete
```

### Issue 3: Multi-Part Episodes Named Wrong

**Symptoms:**
- Files named "The Daleks, Episode One" instead of episode number
- TVDB episode numbers don't match filenames

**Solution:**
1. Reference TVDB for correct numbering
2. Rename using Plex format: `S01E02` not story titles
3. Keep episode titles in the actual filename after the number

### Issue 4: Season Number Confusion

**Symptoms:**
- NuWho Season 1 files in Classic Who folder
- Disney+ files mixed with NuWho

**Solution:**
1. Verify year in filename/content
2. Move to correct series folder
3. Re-scan in Sonarr

---

## Migration Checklist

### For Classic Who (1963)

- [ ] Verify all 26 season folders exist
- [ ] Flatten nested episode folders
- [ ] Remove German/Italian-only content
- [ ] Rename files to Plex format
- [ ] Check for duplicate episodes
- [ ] Identify missing episodes (acceptable for lost content)
- [ ] Remove .nzb, .txt, .jpg files

### For NuWho (2005)

- [ ] Verify seasons 1-13 exist
- [ ] Create/verify Specials folder
- [ ] Move Christmas/Anniversary specials to Specials
- [ ] Remove foreign-only dubs
- [ ] Rename files to Plex format
- [ ] Check for Season 14 confusion with Disney+ era

### For Disney+ Era (2023)

- [ ] Create separate series folder
- [ ] Add to Sonarr as TVDB 436992
- [ ] Move any misplaced content from NuWho
- [ ] Verify 60th specials are in correct location

---

## Specials Organization

### Classic Who Specials
Classic Who doesn't have traditional specials. Anniversary episodes are numbered within their seasons.

### NuWho Specials (S00)

| TVDB S00E | Title | Notes |
|-----------|-------|-------|
| S00E01 | The Christmas Invasion | 2005 Christmas |
| S00E02 | Attack of the Graske | Interactive |
| S00E03 | Tardisode 1 | Deleted/rare |
| ... | ... | ... |
| S00E77 | The Day of the Doctor | 50th Anniversary |
| ... | ... | ... |

**Full list:** Check TVDB for current special numbering

### Where to Put Specials

1. Christmas Specials -> `/Doctor Who (2005)/Specials/`
2. Anniversary Specials -> `/Doctor Who (2005)/Specials/`
3. Mini-episodes (Time Crash, etc.) -> `/Doctor Who (2005)/Specials/`
4. Behind-the-scenes (Doctor Who Extra) -> OPTIONAL, can delete
5. Comic-Con panels -> DELETE (not episodes)

---

## Sonarr Configuration

### Adding Classic Who
```
Series: Doctor Who (1963)
TVDB ID: 76107
Root Folder: /tv
Quality Profile: SD/720p (many episodes only exist in SD)
Series Type: Standard
Season Folder: Yes
Monitored: All Episodes (or selected seasons)
```

### Adding NuWho
```
Series: Doctor Who (2005)
TVDB ID: 78804
Root Folder: /tv
Quality Profile: HD-1080p
Series Type: Standard
Season Folder: Yes
Monitored: All Episodes
```

### Adding Disney+ Era
```
Series: Doctor Who (2023)
TVDB ID: 436992
Root Folder: /tv
Quality Profile: HD-1080p
Series Type: Standard
Season Folder: Yes
Monitored: All Episodes
```

---

## Current Library Status

### Classic Who (1963) - /var/mnt/pool/tv/Doctor Who (1963)/

| Status | Details |
|--------|---------|
| Total Size | 426GB |
| Video Files | 442 |
| Seasons Present | 26 (all) |
| Quality Mix | DVDRip, 720p, 1080p BluRay |
| Issues | Nested folders, German dubs, naming |

### NuWho (2005) - /var/mnt/pool/tv/Doctor Who (2005)/

| Status | Details |
|--------|---------|
| Total Size | 251GB |
| Video Files | 136 |
| Seasons Present | 11 (missing 05, 12, 13) |
| Quality Mix | 720p, 1080p |
| Issues | German/Italian dubs, .nzb files, Specials content |

---

## Cleanup Script

```bash
#!/bin/bash
# Doctor Who Cleanup Script
# Run from media-stack directory

WHO_1963="/var/mnt/pool/tv/Doctor Who (1963)"
WHO_2005="/var/mnt/pool/tv/Doctor Who (2005)"

echo "=== Doctor Who Library Cleanup ==="

# Remove .nzb files
echo "Removing .nzb files..."
find "$WHO_1963" "$WHO_2005" -name "*.nzb" -delete

# Find German-only content
echo "German-only content found:"
find "$WHO_1963" "$WHO_2005" -name "*GERMAN*" -not -name "*DL*"

# Find Italian-only content
echo "Italian-only content found:"
find "$WHO_1963" "$WHO_2005" -name "*ITA*" -not -name "*DL*"

# Find empty directories
echo "Empty directories:"
find "$WHO_1963" "$WHO_2005" -type d -empty

# Count files by season
echo "=== Classic Who File Counts ==="
for i in $(seq -w 01 26); do
  count=$(find "$WHO_1963/Season $i" -name "*.mkv" 2>/dev/null | wc -l)
  echo "Season $i: $count files"
done

echo "=== NuWho File Counts ==="
for i in $(seq -w 01 13); do
  count=$(find "$WHO_2005/Season $i" -name "*.mkv" 2>/dev/null | wc -l)
  echo "Season $i: $count files"
done

echo "=== Specials ==="
find "$WHO_2005/Specials" -name "*.mkv" 2>/dev/null | wc -l
```

---

## References

- [TVDB - Doctor Who (1963)](https://thetvdb.com/series/doctor-who-1963)
- [TVDB - Doctor Who (2005)](https://thetvdb.com/series/doctor-who-2005)
- [TVDB - Doctor Who (2023)](https://thetvdb.com/series/doctor-who-2023)
- [Plex Naming Conventions](https://support.plex.tv/articles/naming-and-organizing-your-tv-show-files/)

---

## Changelog

| Date | Change |
|------|--------|
| 2025-12-29 | Initial definitive guide created |
| 2025-12-29 | Current library status documented |
| 2025-12-29 | Cleanup script added |
