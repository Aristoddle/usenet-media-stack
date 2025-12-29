# USB Content Inventory

**Created**: 2025-12-29 02:45 EST
**Purpose**: Comprehensive inventory of USB drive content for deduplication and import planning
**Status**: Initial Scan Complete

---

## Executive Summary

| Drive | Content Type | Size | Items | Import Priority |
|-------|--------------|------|-------|-----------------|
| Slow_3TB_HD | Music + Books | 545GB | 235 artists, 416GB books | HIGH - Lidarr bootstrap |
| Slow_4TB_2 | Movies | 1.7TB | 555 films | HIGH - Radarr import |
| Slow_2TB_2 | Anime TV | 854GB | 64 series | MEDIUM - quality compare |
| Slow_2TB_1 | Emulation/ROMs | TBD | Batocera backup | LOW - separate workflow |
| JoeTerabyte | Empty (Trash) | 465GB | .Trashes only | CLEANUP - repurpose |

**Total Unique Content**: ~3.1TB across 5 drives
**Estimated Overlap**: 30-40% with current pool (needs verification)

---

## Drive 1: Slow_3TB_HD (High Priority)

### Music Collection
- **Path**: `/run/media/deck/Slow_3TB_HD/Music/`
- **Size**: 129GB
- **Artist Count**: 235

**Notable Artists** (sample):
- ABBA, Arctic Monkeys, Audioslave
- The Beatles, Billie Eilish, Bruce Springsteen
- Coldplay, Daft Punk, Dire Straits
- Elton John, Eric Clapton, Frank Sinatra
- Gorillaz, Green Day, Guns N' Roses
- Jimi Hendrix, Led Zeppelin, MGMT
- Oasis, Phoenix, Queen of the Stone Age
- Red Hot Chili Peppers, The Rolling Stones
- The Who, Van Halen, ZZ Top

**Import Strategy**:
1. Add all artists to Lidarr as monitored
2. Lidarr will match with MusicBrainz
3. Use as existing library (import, don't re-download)
4. Quality: Likely mixed (MP3/FLAC) - Lidarr will upgrade

### Books Collection
- **Path**: `/run/media/deck/Slow_3TB_HD/Bookz/`
- **Total Size**: 416GB

| Subfolder | Size | Content |
|-----------|------|---------|
| Audiobooks | 30GB | Audio narrations |
| Audiobooks 2 | ~5GB | Additional audiobooks |
| Calibre | 7.3GB | Calibre library export |
| Comics | 349GB | CBR/CBZ comics collection |
| eBooks | ~256KB | Nearly empty |
| Readarr | ~10GB | Readarr downloads folder |
| Spoken | Unknown | Spoken word content |

**Notable Book Authors** (from folder):
- J.R.R. Tolkien (Complete History of Middle-Earth, LOTR extras)
- Terry Pratchett (Discworld complete, Long Earth series)

**Import Strategy**:
1. **Comics (349GB)**: Scan for Komga import
   - Compare with existing Comics library
   - May contain significant unique content
2. **Audiobooks (35GB)**: Configure Audiobookshelf
3. **Calibre (7.3GB)**: Preserve as-is or merge with main library

---

## Drive 2: Slow_4TB_2 (High Priority)

### Movies Collection
- **Path**: `/run/media/deck/Slow_4TB_2/Movies/`
- **Size**: 1.7TB
- **Film Count**: 555

**Notable Films** (sample A-D):
- 2001: A Space Odyssey (1968)
- A Clockwork Orange (1971)
- Akira (1988)
- Apocalypse Now (1979)
- Avengers series (complete MCU likely)
- Barbie (2023)
- Batman Begins (2005)
- Being John Malkovich (1999)
- Birdman (2014)
- Blazing Saddles (1974)
- Casino (1995), Casino Royale (2006)
- Castle in the Sky (1986) - Ghibli
- Catch Me If You Can (2002)
- Citizen Kane (1941)
- Clerks I, II, III
- Cool Hand Luke (1967)
- Cowboy Bebop: The Movie (2001)
- Dallas Buyers Club (2013)

**Quality Assessment Needed**:
- Check resolution (1080p vs 4K)
- Check codec (x264 vs x265)
- Compare with pool versions

**Import Strategy**:
1. Create tool to query Radarr API
2. Identify films not in pool
3. Quality comparison for duplicates
4. Import unique content to pool

---

## Drive 3: Slow_2TB_2 (Medium Priority)

### Anime TV Collection
- **Path**: `/run/media/deck/Slow_2TB_2/Anime/`
- **Size**: 854GB
- **Series Count**: 64

**Complete Series List**:
1. Assassination Classroom
2. Astro Boy (Original, 1980, 2003)
3. Attack on Titan
4. Bakuman
5. Bleach
6. Blood Lad
7. Bocchi the Rock!
8. Chainsaw Man
9. Code Geass - Lelouch of the Rebellion
10. Cowboy Bebop
11. Cyberpunk Edgerunners (2 versions?)
12. Demon Slayer - Kimetsu no Yaiba
13. Dragon Ball
14. Fate/Grand Order - Babylonia
15. Fate/Stay Night - Unlimited Blade Works
16. Fist of the North Star
17. FLCL
18. Fullmetal Alchemist - Brotherhood
19. Gintama
20. Goblin Slayer
21. Great Teacher Onizuka
22. Gurren Lagann
23. Haikyu!!
24. Hajime no Ippo
25. Hunter x Hunter (Original + 2011)
26. JoJo's Bizarre Adventure (2012)
27. Jujutsu Kaisen
28. Kaguya-sama - Love Is War
29. Kaiji
30. K-ON!
31. KonoSuba
32. Legend of the Galactic Heroes
33. Lord El-Melloi II Case Files
34. Made in Abyss
35. Monogatari
36. Monster
37. Naruto
38. Neon Genesis Evangelion
39. Nichijou - My Ordinary Life
40. Noragami
41. ODDTAXI
42. One Piece
43. One-Punch Man
44. Oshi no Ko
45. Ping Pong The Animation
46. Psycho-Pass
47. Samurai Champloo
48. Samurai Flamenco
49. Slam Dunk
50. SPY x FAMILY
51. Steins;Gate
52. The Melancholy of Haruhi Suzumiya
53. The Tatami Galaxy
54. Today's Menu for the Emiya Family
55. Tokyo Ghoul
56. Tomorrow's Joe
57. Vinland Saga
58. Violet Evergarden

**Duplicates with Pool (Known)**:
- Blood Lad (causing Tdarr errors - German dubs)
- Bleach
- Haikyu!!
- (Compare full list with Sonarr)

**Import Strategy**:
1. Query Sonarr for existing anime
2. Check /pool/anime-tv/ overlap
3. Quality/completeness comparison
4. Import missing series or episodes

---

## Drive 4: Slow_2TB_1 (Low Priority)

### Emulation/ROMs Backup
- **Path**: `/run/media/deck/Slow_2TB_1/`
- **Content**: Batocera_Share_Bak, Emulation, ROMS_TO_SORT

**Purpose**: ROM backup from previous emulation setup
**Integration**: Separate from media stack (EmuDeck workflow)
**Action**: Document but defer to emulation session

---

## Drive 5: JoeTerabyte (Cleanup)

### Status: Empty/Trash
- **Path**: `/run/media/deck/JoeTerabyte/`
- **Content**: 465GB in .Trashes (deleted files)
- **Useful Content**: None

**Action Required**:
1. Empty trash: `rm -rf /run/media/deck/JoeTerabyte/.Trashes/*`
2. Format if needed
3. Repurpose as:
   - Tdarr working directory
   - Backup destination
   - Download staging area

---

## Deduplication Analysis

### Pool Current Content
```
/var/mnt/pool/
├── movies/        # 691 films
├── tv/            # 29 shows
├── anime-movies/  # 25 anime films
├── anime-tv/      # 75 anime series
├── christmas-movies/
├── christmas-tv/
├── downloads/
└── music/         # Unknown state
```

### Overlap Estimation

| USB Source | Pool Target | Estimated Overlap |
|------------|-------------|-------------------|
| Slow_4TB_2/Movies (555) | movies (691) | ~40% (200-250 films) |
| Slow_2TB_2/Anime (64) | anime-tv (75) | ~50% (30-35 series) |
| Slow_3TB_HD/Music (235) | music | Unknown |
| Slow_3TB_HD/Bookz/Comics | N/A | 0% (new content) |

### Quality Upgrade Opportunities

Many USB files may be lower quality than pool:
- USB: 1080p x264 vs Pool: 4K x265
- USB: Stereo vs Pool: TrueHD Atmos
- USB: Subbed vs Pool: Dual Audio

**Recommendation**: Keep higher quality version, delete lower.

---

## Import Tools Needed

### 1. usb-movie-importer.sh
```bash
# Features:
# - Scan USB movie folder
# - Query Radarr for matches (TMDB ID or title)
# - Report: unique films, duplicates, quality comparison
# - Optional: move/link unique content to pool
```

### 2. lidarr-bootstrap.sh
```bash
# Features:
# - Scan USB artist folders
# - Add artists to Lidarr monitoring
# - Import existing files as library
# - Report missing albums per artist
```

### 3. usb-anime-importer.sh
```bash
# Features:
# - Scan USB anime folder
# - Query Sonarr for matches (TVDB ID or title)
# - Report: unique series, missing episodes
# - Quality comparison with existing
```

### 4. komga-comics-scanner.sh
```bash
# Features:
# - Scan USB Comics folder
# - Compare with existing Komga library
# - Report unique comics/series
# - Optional: import to Komga library
```

---

## Recommended Import Order

### Phase 1: Quick Wins (Day 1)
1. Empty JoeTerabyte trash (free 465GB)
2. Create lidarr-bootstrap.sh
3. Import Music collection to Lidarr

### Phase 2: High Value (Day 2-3)
4. Create usb-movie-importer.sh
5. Analyze movie duplicates
6. Import unique movies to Radarr/pool

### Phase 3: Anime Cleanup (Day 4)
7. Create usb-anime-importer.sh
8. Fix Blood Lad Tdarr errors (German dubs)
9. Import unique anime series

### Phase 4: Comics Integration (Day 5+)
10. Scan Comics folder for Komga
11. Integrate with existing Komga library
12. Configure Audiobookshelf for audiobooks

---

## Notes

### Tdarr Error Analysis

The Anime-TV library has 2,139 files in Error state. Analysis shows:
- ALL errors have `TranscodeDecisionMaker = "Not required"`
- 9 files have FFprobe failures (Blood Lad German dubs)
- 2,131 files have `scannerReads.ffProbeRead = "success"`

**Root Cause**: Files marked as not needing transcoding but stuck in Error state from previous timeout issues.

**Fix**: Reset error files to Queued (safe operation):
```sql
UPDATE filejsondb SET health_check = 'Queued'
WHERE health_check = 'Error'
AND json_extract(json_data, '$.TranscodeDecisionMaker') = 'Not required';
```

---

*Last Updated: 2025-12-29 03:00 EST*
