# Plex Library Cleanup Report

**Date:** 2025-12-29
**Performed by:** Claude Code Agent

## Executive Summary

Comprehensive cleanup of Plex media libraries addressing duplicate content, organizational issues, misplaced files, and structural problems across Movies, TV, Anime-TV, and Anime-Movies libraries.

## Library Statistics (Before Cleanup)

| Library | Folders | Video Files |
|---------|---------|-------------|
| Movies | 665 | 4,685 |
| TV | 29 | 2,014 |
| Anime-TV | 77 | 5,807 |
| Anime-Movies | 25 | 11 |
| Christmas Movies | 26 | 26 |
| Christmas TV | - | 0 |

## Priority 1: Doctor Who Consolidation

### Issues Found

1. **Misplaced Classic Who in Doctor Who (2005)**
   - Season 03 contained 5 classic series episodes from "The Daleks' Master Plan" (1965):
     - `Doctor_Who_S03E15_SD_XVID_DVDRip_-_Coronas_of_the_Sun`
     - `Doctor_Who_S03E16_SD_XVID_DVDRip_-_The_Feast_of_Steven`
     - `Doctor_Who_S03E17_SD_XVID_DVDRip_-_Volcano`
     - `Doctor_Who_S03E18_SD_XVID_DVDRip_-_Golden_Death`
     - `Doctor_Who_S03E20_SD_XVID_DVDRip_-_The_Abandoned_Planet`

2. **Misplaced Content in Season 01**
   - "The Power of the Daleks" (1966 animated reconstruction) was incorrectly placed
   - "Doctor Who Extra" bonus content was mixed with episodes

### Actions Taken

- [x] Moved 5 classic episodes to `/var/mnt/pool/tv/Doctor Who (1963)/Season 03/`
- [x] Moved "Power of the Daleks" to `/var/mnt/pool/tv/Doctor Who (1963)/Season 04/`
- [x] Moved "Doctor Who Extra" to Specials folder

### Current Structure

```
Doctor Who (1963)/
  Season 01/ - Season 26/  (Classic series 1963-1989)

Doctor Who (2005)/
  Season 01/ - Season 11/  (Revival series)
  Specials/                 (Specials and extras)
```

### Remaining Notes

- Doctor Who (2005) is missing Season 05 (Matt Smith's first season)
- Mix of English and German dubbed episodes exists (intentional for multilingual support)
- No Torchwood or Sarah Jane Adventures found in library

## Priority 2: Duplicate Detection & Cleanup

### Movies - Duplicates Removed

| Original | Duplicate Removed | Reason |
|----------|-------------------|--------|
| The.Expendables.2.2012.UHD.BluRay (REMUX) | The Expendables 2 2012 2160p iT WEB-DL (1) | Keep higher quality |
| Aziz Ansari Buried Alive 2013 JAWN | Aziz Ansari Buried Alive 2013 YTS MX | Keep original group |
| Clerks III 2022 4K YTS | Clerks III 2022 1080p STZ | Keep 4K version |
| Back.to.the.Future.Part.III 4K WEB-DL | BTTF3 1080p DON | Keep 4K version |

### Movies - Empty Folders Removed

- `A.Good.Day.to.Die.Hard.2013.1080p.BluRay.x264-OFT` (empty)
- `Spirited.Away.2002.1080p.Bluray.EAC3.5.1.x265-PoF` (empty)
- `Charlie.And.The.Chocolate.Factory.2005...` (incomplete download, nested empty folder)

### Movies - Cross-Library Duplicates

| Item | Location 1 | Location 2 | Action |
|------|------------|------------|--------|
| Akira (1988) | movies/ (90GB raw disc) | anime-movies/ (24GB 4K encode) | Removed raw disc, kept encode |

## Priority 3: Weird Folder Cleanup

### Nested Folder Issues Fixed

| Folder | Issue | Action |
|--------|-------|--------|
| Rush Hour 2 2001 | Movie/Movie/file.mkv | Flattened structure |
| Journey.Back.to.Oz.1972 | Movie/Movie/file.mkv | Flattened structure |
| The.Incredible.Hulk.2008 | Movie/Movie/file.mkv | Flattened structure |
| The Silence Of The Lambs 1991 | Movie/MOVIE/file.mkv | Flattened structure |
| The Matrix Resurrections 2021 | Movie/Movie/files + SAMPLE | Flattened, removed sample |

### Garbage Folders Removed

| Folder | Issue | Location |
|--------|-------|----------|
| `brothers-of-usenet info&net-empfehlen-ssl-news-houseofcards-s02e11 Unter Zugzwang-720p` | Usenet provider garbage in folder name | /var/mnt/pool/tv/ |
| `Lord of the Rings` | Contained anime TV episodes (Lord El-Melloi) not LotR movies | /var/mnt/pool/movies/ |

### Miscategorized Content

| Item | Wrong Location | Correct Location | Action |
|------|----------------|------------------|--------|
| Scissione (Italian Severance) | anime-tv/ | tv/Severance (already exists) | Removed (duplicate) |
| Lord El-Melloi Rail Zeppelin | movies/Lord of the Rings/ | anime-tv/ (already exists) | Removed (duplicate) |

### Season Folder Inconsistencies Fixed

**Severance:**
- Had both "Season 01" and "Season 1" folders (same content, different naming)
- Had both "Season 02" and "Season 2" folders
- Action: Removed "Season 1" and "Season 2" (kept "Season 01/02" format)

## Priority 4: Sample File Cleanup

### Sample Files Removed

- `/var/mnt/pool/movies/James.Bond.007.1979.Moonraker.../sample_007.moonraker-fullbr-xorbitant.m2ts`
- `/var/mnt/pool/movies/Blazing Saddles 1974.../Blazing Saddles 1974...sample.m2ts`
- `/var/mnt/pool/movies/Superman II 1980.../sample-superman.ii.1980...m2ts`
- `/var/mnt/pool/movies/Blue Mountain State.../Sample.mkv`
- `/var/mnt/pool/movies/The Matrix Resurrections.../SAMPLE.mkv`

## Trash Folder Contents

All removed items moved to `/var/mnt/pool/.trash/` with dated suffixes for recovery if needed:

```
Akira_rawdisc_20251229/
Aziz_Buried_YTS_duplicate_20251229/
BTTF3_1080p_duplicate_20251229/
Charlie_incomplete_20251229/
ClerksIII_1080p_duplicate_20251229/
Expendables2_WEB_duplicate_20251229/
Lord_of_the_Rings_anime_misplaced_20251229/
Scissione_duplicate_20251229/
Severance_Season1_duplicate_20251229/
Severance_Season2_duplicate_20251229/
usenet_garbage_hoc_20251229/
```

## Recommendations

### Immediate Actions

1. **Run Plex library scan** to update metadata after changes
2. **Review German dubbed episodes** in Doctor Who - may want English versions
3. **Consider acquiring missing Doctor Who (2005) Season 05**

### Future Improvements

1. **Naming Standardization**: Many folders use scene naming (dots, release groups). Consider Plex-style naming: `Movie Name (Year)/Movie Name (Year).mkv`

2. **Duplicate Prevention**:
   - Configure Sonarr/Radarr to prevent duplicate downloads
   - Set up quality upgrade paths

3. **Anime Organization**:
   - Some anime movies could be better organized with Plex-style naming
   - Consider adding AniDB agent for better metadata

4. **Doctor Who Specials**:
   - Specials folder only has Comic Con panel
   - Christmas specials and other specials may need organizing

### Storage Savings Estimate

| Item | Size Recovered |
|------|----------------|
| Akira raw disc | ~90 GB |
| Various duplicates | ~50 GB |
| Sample files | ~500 MB |
| **Total** | **~140 GB** |

Note: Items in `.trash/` can be permanently deleted to recover this space.

## Verification Checklist

- [x] Doctor Who (2005) Season 03 contains only revival series episodes
- [x] Doctor Who (1963) Season 03 now has classic episodes
- [x] No anime content in movies library
- [x] No duplicate season folders in TV shows
- [x] No sample files in movie folders
- [x] Nested folder structures flattened
- [x] Garbage usenet folder removed

---

## Session 2: Deep Library Architect Audit (2025-12-29 15:00+)

### Additional Analysis Performed

A comprehensive deep audit was performed using the newly created health check tooling.

### Health Check Results

| Metric | Value |
|--------|-------|
| Pool Status | 30T used / 41T total (73%) |
| Movies | 657 folders, 520 files |
| TV Series | 28 series, 1,994 files |
| Anime TV | 73 series, 5,802 files |
| Anime Movies | 24 folders, 11 files |

### Additional Cleanup Performed

1. **Empty Movie Folders Deleted:** 58 folders
   - Failed downloads with empty placeholder folders
   - Examples: Mission Impossible Dead Reckoning, Nosferatu 2024, Psycho II/IV

2. **NZB Files Deleted:** 5+ files
   - Download metadata files left in Doctor Who library
   - All .nzb files removed from TV, movies, anime libraries

### Issues Identified for Future Work

| Issue | Count | Priority |
|-------|-------|----------|
| Movie folders without year | 544 | Medium |
| German-only Doctor Who (1963) | 43 | Low |
| Foreign Doctor Who (2005) | 89 | Low |
| Anime movies audit needed | 13 empty? | Low |
| Orphaned downloads | 2 | Low |

### Tools Created

| Tool | Purpose |
|------|---------|
| scripts/plex-health-check.sh | Automated library health monitoring |
| docs/PLEX_LIBRARY_ANALYSIS.md | Comprehensive audit documentation |
| docs/DOCTOR_WHO_ORGANIZATION.md | Definitive Who organization guide |

---

*Original report generated by Claude Code Agent - 2025-12-29*
*Updated with Session 2 audit by Deep Library Architect Agent - 2025-12-29*
