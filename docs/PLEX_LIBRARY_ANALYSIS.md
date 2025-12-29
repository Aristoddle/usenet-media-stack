# Plex Library Comprehensive Analysis

> **Generated:** 2025-12-29
> **Pool:** /var/mnt/pool (41TB MergerFS)
> **Status:** Deep audit complete with actionable findings

---

## Executive Summary

| Category | Count | Size | Health |
|----------|-------|------|--------|
| Movies | 665 folders (520 files) | 16TB | MODERATE - 59 empty folders, duplicates |
| TV Shows | 28 series | 6.1TB | GOOD - Doctor Who needs attention |
| Anime TV | 75 series (5,802 episodes) | 5.9TB | GOOD - Well organized |
| Anime Movies | 25 titles (11 files) | 88GB | MODERATE - Low file count vs folders |
| Christmas Movies | 26 titles | 430GB | GOOD |
| Christmas TV | 0 titles | 0 | EMPTY |
| Downloads (staged) | 404 video files | 919GB | ATTENTION - Orphaned content |

**Total Pool:** 30TB used of 41TB (73% capacity)
**Estimated Reclaimable Space:** ~400GB+ (empty folders, duplicates, staging cleanup)

---

## Detailed Analysis

### Movies Library (/var/mnt/pool/movies/)

**Stats:**
- Total Folders: 665
- Empty Folders: 59 (cleanup candidate)
- Video Files: 520
- Size: 16TB

**Quality Distribution:**
| Quality | Count | Notes |
|---------|-------|-------|
| 4K/UHD/2160p | 239 | Primary target quality |
| 1080p | 249 | Good secondary quality |
| 720p/DVDRip/SD | 17 | Upgrade candidates |
| Unknown | ~160 | Need inspection |

**Issues Found:**

1. **Empty Folders (59)** - Failed downloads or moved content
   - Examples: `MISSION_IMPOSSIBLE_DEAD_RECKONING_PART_ONE_2023_4K_UHD_COMPLETE_BLURAY-MassModz`
   - Examples: `Nosferatu 2024 REPACK3 2160p WEB-DL DDP5 1 Atmos DV HDR H 265-FLUX`
   - **Action:** Delete empty folders

2. **Naming Convention Issues**
   - Italian titles mixed with English (Godzilla series, Bond films)
   - Release group names in folder names vs clean "Movie Name (Year)" format
   - Some folders have special characters that may cause issues

3. **Potential Duplicates** (from previous audit)
   - Batman (1989) - 2 versions
   - Batman Returns (1992) - 2 versions
   - Anastasia (1997) - 3 versions
   - Cars 2 (2011) - 2 versions
   - Blade Runner 2049 (2017) - 2 versions

---

### TV Shows Library (/var/mnt/pool/tv/)

**Stats:**
- Total Series: 28
- Season Folders: 143
- Video Files: 1,994
- Size: 6.1TB

**Series List:**
1. Atlanta
2. Billions
3. Blue Mountain State
4. Columbo
5. Daredevil Born Again
6. Doctor Who (1963) - 426GB, 442 files, 26 seasons
7. Doctor Who (2005) - 251GB, 136 files, 11 seasons
8. Futurama
9. Game of Thrones
10. Gravity Falls
11. House of Cards (2013)
12. It's Always Sunny in Philadelphia
13. Marvels Daredevil
14. Popeye the Sailor
15. Red vs Blue
16. Scooby-Doo, Where Are You!
17. Seinfeld
18. Severance
19. Stranger Things
20. Superman (1941)
21. Ted Lasso
22. The Bear
23. The Flintstones
24. The Jetsons
25. The White Lotus
26. The Wire
27. The Yogi Bear Show
28. True Detective

**Major Issue: Doctor Who Organization**

The Doctor Who collection is extensive but has structural problems:

**Classic Who (1963):**
- 26 seasons
- 442 video files
- 426GB total
- Issues:
  - Episode folders inside Season folders instead of flat structure
  - German dubbed episodes mixed with English
  - DVDRip quality mixed with 1080p BluRay
  - Multi-part episode naming inconsistencies
  - Nested folder structures (e.g., Season 19 has story arc folders)

**NuWho (2005):**
- 11 seasons (missing Season 05, 12, 13)
- 136 video files
- 251GB total
- Issues:
  - German dubbed episodes in Season 01, 02, 03
  - Italian episodes in Season 10
  - Mixed quality (720p, 1080p, WEB-DL)
  - Episode numbering confusion (Disney+ era uses S01 again)
  - Specials folder contains non-special content

---

### Anime TV Library (/var/mnt/pool/anime-tv/)

**Stats:**
- Total Series: 75
- Video Files: 5,802
- Size: 5.9TB

**Well-Organized Series (sample):**
- Attack on Titan (2013)
- Bleach
- Chainsaw Man
- Cowboy Bebop (1998)
- Demon Slayer Kimetsu no Yaiba
- Fullmetal Alchemist Brotherhood
- Hunter X Hunter 2011
- JoJo's Bizarre Adventure
- One Piece
- Steins Gate (2011)

**Naming Observations:**
- Good: Most series have clean names with year disambiguation
- Good: Proper season folder structure
- Minor: Some series missing year (e.g., "Bakuman" vs "Bakuman (2010)")

---

### Anime Movies Library (/var/mnt/pool/anime-movies/)

**Stats:**
- Total Folders: 25
- Video Files: 11
- Size: 88GB

**Issue:** Low file count vs folder count suggests:
- Empty folders from failed downloads
- Content organized in subfolders

**Action:** Audit each folder for actual content

---

### Downloads Staging (/var/mnt/pool/downloads/)

**Stats:**
- Complete: 19GB
- Incomplete: 0 (clean)
- Total video files: 404
- Size: 919GB

**Orphaned Content Found:**
- Assassination Classroom S01E08, S01E09
- Hunter x Hunter 2011 S02E21-E30, S03E03-E08
- It's Always Sunny in Philadelphia S14E07-E09
- Various anime in /complete/anime/

**Action:** Import to proper libraries or delete

---

## Doctor Who Deep Dive

### Classic Who (1963-1989) Organization Reference

The Classic series ran for 26 seasons with a unique structure:
- Each season contains "serials" (multi-part stories)
- TVDB numbers episodes sequentially within seasons
- Many episodes are missing due to BBC tape wiping

**Current State Analysis:**

| Season | Episodes Found | Quality | Issues |
|--------|---------------|---------|--------|
| 01 | Multiple | DVDRip, 1080p | Nested folders |
| 02 | Multiple | Mixed | - |
| 03 | 20+ folders | DVDRip, 1080p | Heavy folder nesting |
| 04 | Multiple | Mixed | Contains wrong content |
| 05 | 12+ folders | Mixed | Multiple release groups |
| 06 | 15+ folders | DVDRip | Multi-part episode names |
| 07 | Unknown | Mixed | - |
| 08 | 5+ folders | DVDRip | - |
| 09 | Present | DVDRip | - |
| 10 | 4+ folders | 1080p, DVDRip | - |
| 11 | 10+ folders | DVDRip | - |
| 12 | 18 folders | 1080p BluRay | BEST quality batch |
| 13 | Present | DVDRip | - |
| 14 | 26 folders | 1080p BluRay | Good quality |
| 15 | 6+ folders | Mixed | Nested "Underworld" folder |
| 16 | 6 folders | DVDRip | - |
| 17 | 15+ folders | DVDRip | - |
| 18 | 12+ folders | Mixed | - |
| 19 | 20+ folders | 1080p, 720p | German dubs, nested folders |
| 20 | 22 folders | DVDRip | - |
| 21 | 15+ folders | Mixed | Alternative versions |
| 22 | 13+ folders | 1080p BluRay | Good quality |
| 23 | 14 folders | 720p German | German dubbed only! |
| 24 | 14 folders | 1080p BluRay | EXTENDED versions |
| 25 | 14+ folders | Mixed | Duplicate releases |
| 26 | Present | Mixed | - |

### NuWho (2005-present) Organization Reference

| Season | Episodes Expected | Episodes Found | Issues |
|--------|------------------|----------------|--------|
| 01 | 13 | 12 | German dubs mixed in |
| 02 | 13 | Present | German dubs |
| 03 | 13 | Present | - |
| 04 | 13 | Present | - |
| 05 | 13 | MISSING | Season folder absent |
| 06 | 13 | Present | - |
| 07 | 13 | Present | - |
| 08 | 12 | Present | - |
| 09 | 12 | Present | - |
| 10 | 12 | Present | Italian dubs, .nzb files |
| 11 | 10 | Present | - |
| 12 | 10 | MISSING | Season folder absent |
| 13 | 6 | MISSING | Season folder absent |
| 14 | 8 | MISSING (or in S01 Disney+) | Numbering confusion |

### Doctor Who Specials

Various specials exist but organization is unclear:
- Christmas Specials
- Anniversary Specials
- Gap Year Specials
- Currently in "Specials" folder: Comic Con Panel, "Extra" content

---

## Quality Tier Summary

### Movies Quality Distribution

| Tier | Count | Action |
|------|-------|--------|
| 4K UHD DV/HDR | ~150 | Keep - Premium |
| 4K UHD HDR | ~90 | Keep - High quality |
| 1080p BluRay REMUX | ~50 | Keep - Best 1080p |
| 1080p BluRay encode | ~150 | Keep - Good quality |
| 1080p WEB-DL | ~50 | Upgrade candidate |
| 720p/SD | ~17 | Priority upgrade |

### TV Quality Distribution

| Series | Quality | Notes |
|--------|---------|-------|
| Doctor Who (1963) | Mixed DVDRip-1080p | Many upgrades available |
| Doctor Who (2005) | Mixed 720p-1080p | BluRay upgrades available |
| Game of Thrones | Unknown | - |
| The Wire | Unknown | - |
| Breaking Bad | Unknown | Not in library |

---

## Recommendations

### Immediate Actions (< 1 hour)

1. **Delete 59 empty movie folders**
   ```bash
   find /var/mnt/pool/movies -maxdepth 1 -type d -empty -delete
   ```

2. **Clean orphaned downloads**
   - Import or delete /var/mnt/pool/downloads/complete/* content

3. **Remove .nzb files from libraries**
   ```bash
   find /var/mnt/pool -name "*.nzb" -delete
   ```

### Short-term Actions (1-4 hours)

1. **Doctor Who Classic Who cleanup**
   - Flatten nested episode folders
   - Remove German-only episodes (keep dual-audio)
   - Standardize naming to Plex format

2. **Doctor Who NuWho gaps**
   - Add missing Seasons 05, 12, 13
   - Remove Italian/German only episodes
   - Organize Disney+ era content correctly

3. **Movie duplicates resolution**
   - Keep highest quality version
   - Move lower quality to .trash for review

### Medium-term Actions (1-2 days)

1. **Quality upgrade campaign**
   - Identify 720p/SD content
   - Queue upgrades in Radarr/Sonarr

2. **Naming standardization**
   - Rename to "Movie Name (Year)" format
   - Remove release group info from folder names

3. **Anime movies audit**
   - Check 25 folders for actual content
   - Consolidate or clean up

---

## Monitoring Metrics

Track these metrics over time:

| Metric | Current | Target |
|--------|---------|--------|
| Empty folders | 59+ | 0 |
| Downloads staging | 919GB | <100GB |
| 720p/SD content | ~20 | 0 |
| German-only episodes | ~50+ | 0 |
| Missing Who seasons | 3 | 0 |

---

## Related Documentation

- [DOCTOR_WHO_ORGANIZATION.md](./DOCTOR_WHO_ORGANIZATION.md) - Definitive Who guide
- [LIBRARY_ARCHITECTURE.md](./LIBRARY_ARCHITECTURE.md) - Library design philosophy
- [TV_REORGANIZATION_PLAN.md](./TV_REORGANIZATION_PLAN.md) - TV cleanup strategies

---

## Changelog

| Date | Change |
|------|--------|
| 2025-12-29 | Initial comprehensive analysis |
| 2025-12-29 | Doctor Who deep dive completed |
| 2025-12-29 | Quality tier assessment added |
