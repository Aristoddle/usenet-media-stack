# TV Folder Reorganization - Analysis & Remediation Plan

**Generated:** 2025-01-25
**Location:** /run/media/deck/Fast_4TB_5/TV
**Backup Status:** Currently being copied to swap_drive

---

## Current State Analysis

### Overview
- **Total Items:** 2,326 top-level folders
- **Episode-named Folders:** 2,021 (~87%)
- **Total Video Files:** 5,876
- **Total Size:** 3.5 TB
- **Properly Structured Series:** ~24 (only Atlanta and a few others have Season XX folders)

### Problem Summary
The vast majority of content (2,021 folders) are individual episodes stored as:
```
/TV/Series.Name.S01E01.Quality.Info.Release-Group/
    Series.Name.S01E01.Quality.Info.Release-Group.mkv
```

Instead of the required Plex/Sonarr structure:
```
/TV/Series Name (Year)/
    Season 01/
        Series Name - S01E01 - Episode Title.mkv
```

### Naming Pattern Analysis

From random sample of 100 folders, identified several distinct patterns:

#### Pattern 1: Standard Release Format (Most Common)
```
One.Piece.S12E44.Oars.Moria.The.Most.Heinous.Combination.of.Brains.and.Brawn.1080p.H.265.English.Dub-G
Hunter.x.Hunter.2011.S01E51.German.DL.DTS.1080p.BluRay.x265-ABJ
Seinfeld.S09E16.The.Burning.1080p.AMZN.WEBRip.DD2.0.X264-NTb
```

#### Pattern 2: Fansub/Encoder Tag Prefix
```
[Arid].SteinsGate.2011-S01E08-008-Chaos.Theory.Homeostasis.I.[Bluray-1080p][x265][10bit][FLAC.5.1][EN+JA].[F8D9522F]
[LostYears].Bleach.Thousand-Year.Blood.War.-.S17E23.(WEB.1080p.x264.AAC).[A1E85368]
[smol].Monogatari-S04E03-Monogatari.Series.Second.Season.BD.1080p.HEVC.Opus.[F9216424]
```

#### Pattern 3: Underscores Instead of Dots
```
One_Piece_(1999)_-_S13E57_-_A_Paradise_in_Hell!_Impel_Down_Level_5_5!_[FUNi_HDTV-1080p][8bit][h264][AAC_2_0]-Koten_Gars
Fist_of_the_North_Star_-_S02E11_-_This_is_the_Village_of_Miracles!_A_Fallen_Angel_Has_Arrived!!_-_SDTV_-_x264_AAC_-_Sonarr
```

#### Pattern 4: Classic Doctor Who Multi-Part Episodes
```
Doctor.Who.S07E20.DVDRip.XviD_-_Inferno,_Episode_Two
Doctor.Who.1963.S23E10.Das.Urteil.Vervoid.Terror.Teil.2.German.DD20.Dubbed.DL.720p.FS.BDRiP.x264-OcB
```

#### Pattern 5: Season Packs (Should Already Be Organized)
```
[Cleo]_Haikyuu!!_S1_[Dual_Audio_10bit_BD1080p][x265]
[ENTE]_KonoSuba_-_Gods_Blessing_on_This_Wonderful_World_(2016)_S01_+_OVA_[AV1]_[OPUS]_[BD]_[1080p]
[Trix].Spy.x.Family.S01+02+Movie.[BD.1080p.AV1].[Triple.Audio].[Multi.Subs]-xpost
```

### Top 20 Series by Episode Count

From preliminary analysis:

| Series | Estimated Episodes | Notes |
|--------|-------------------|-------|
| One Piece | 713+ | Multiple naming variants (One.Piece, One_Piece, One_Piece_(1999)) |
| Doctor Who | 198+ | Multiple series (1963, 2005, untagged) |
| Hunter x Hunter 2011 | 116+ | Some variants: Hunter.x.Hunter2011 |
| It's Always Sunny in Philadelphia | 120+ | Multiple case variants |
| Legend of the Galactic Heroes | 76+ | |
| Fist of the North Star | 85+ | Two naming variants (dots vs underscores) |
| Gintama | 47+ | |
| Fullmetal Alchemist Brotherhood | 42+ | |
| Attack on Titan | 39+ | |
| Futurama | 36+ | |
| Dragon Ball | 31+ | |
| Naruto | 30+ | |
| JoJo's Bizarre Adventure (2012) | 29+ | |
| Seinfeld | 27+ | |
| Haikyu | 23+ | |
| Great Teacher Onizuka | 22+ | |
| Noragami | 21+ | |
| Gravity Falls | 20+ | |
| Bleach | 18+ | Separate from Bleach Thousand-Year Blood War |
| The Wire | 17+ | |

**Estimated Total Unique Series:** ~179 (conservative estimate based on naming normalization)

---

## Remediation Options Analysis

### Option A: Sonarr Manual Import
**Description:** Use Sonarr's "Manual Import" feature to recognize and reorganize existing files.

**Pros:**
- Preserves existing quality/versions
- Sonarr handles renaming to its preferred format
- Automatic metadata fetching (episode titles, air dates)
- No re-downloading required
- Can process multiple episodes at once
- Creates proper folder structure automatically

**Cons:**
- **Labor intensive:** Must manually review ~2,021 episodes
- Requires adding all ~179 series to Sonarr first
- Some releases may not match Sonarr's naming expectations (especially fansubs)
- Multi-part Doctor Who episodes may cause confusion
- Must handle duplicate series names (Doctor Who variants, One Piece variants)

**Estimated Effort:**
- Initial setup: 4-6 hours (adding series)
- Manual import review: 40-80 hours (at ~2-4 episodes/minute)
- **Total: 44-86 hours**

**Risk Level:** Low
- Non-destructive (uses moves, not copies)
- Can be done incrementally
- Easy to verify results

---

### Option B: FileBot Automated Reorganization
**Description:** Use FileBot with its automatic TV series matching and renaming engine.

**Pros:**
- Can process entire directory automatically
- Excellent pattern matching for most release types
- Can handle fansub naming conventions
- Supports batch processing with interactive verification
- One-time payment ($6-48 depending on license)
- Much faster than manual import
- Can create Plex/Sonarr-compatible structure

**Cons:**
- Requires purchase/license
- May incorrectly match some episodes (especially Doctor Who multi-part)
- Some fansub releases may need manual intervention
- Still requires verification of results
- Learning curve for AMC (Automated Media Center) scripts
- May not preserve preferred quality indicators in filename

**Estimated Effort:**
- Setup and testing: 2-3 hours
- Running automated batch: 1-2 hours
- Verification and cleanup: 8-12 hours
- **Total: 11-17 hours**

**Risk Level:** Medium
- Automatic matching can make mistakes
- Must verify before final commit
- Can be tested on small subset first
- Dry-run mode available

**FileBot AMC Example:**
```bash
filebot -script fn:amc \
  --output "/run/media/deck/Fast_4TB_5/TV" \
  --action move \
  --conflict auto \
  --def "seriesFormat={n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
  "/run/media/deck/Fast_4TB_5/TV"
```

---

### Option C: Custom Script-Based Reorganization
**Description:** Write Python/Bash scripts using guessit/tvnamer libraries to parse and reorganize.

**Pros:**
- Full control over matching logic
- Can handle edge cases specifically (Doctor Who multi-part, fansub tags)
- No additional software costs
- Can create custom rules per series
- Reusable for future imports

**Cons:**
- **High development time:** 20-30 hours to write, test, debug
- Requires extensive testing to avoid data loss
- Must handle The Movie Database / TVDb API calls
- Rate limiting concerns with API
- Need to handle network failures, retries
- May still miss edge cases

**Estimated Effort:**
- Script development: 20-30 hours
- Testing on samples: 4-6 hours
- Full run and verification: 4-6 hours
- **Total: 28-42 hours**

**Risk Level:** Medium-High
- Custom code introduces bugs
- API matching may fail
- Requires extensive testing
- Hardest to validate comprehensively

**Example Libraries:**
```python
# Using guessit for parsing
from guessit import guessit
guessit("One.Piece.S12E44.1080p.H.265.English.Dub-G")
# Returns: {'title': 'One Piece', 'season': 12, 'episode': 44, ...}

# Using tmdbsimple for metadata
import tmdbsimple as tmdb
tv = tmdb.TV(37854)  # One Piece TMDB ID
episode = tv.Episodes(12, 44).info()
# Returns episode title, air date, etc.
```

---

### Option D: Let Sonarr Re-Download Everything
**Description:** Delete existing files and let Sonarr re-download with proper naming.

**Pros:**
- Guaranteed correct structure
- Sonarr handles everything automatically
- No manual intervention
- Clean slate approach

**Cons:**
- **Extremely wasteful:** Re-downloading 3.5 TB of data
- Many releases may not be available anymore (especially older fansubs)
- Quality/version may not match current collection
- High bandwidth usage
- Time-consuming (days/weeks depending on connection)
- Some releases (especially older anime) may be impossible to find
- Risk of losing German dubs, specific encoder preferences

**Estimated Effort:**
- Setup: 2-3 hours
- Download time: Days to weeks
- **Total: Very high + bandwidth costs**

**Risk Level:** Very High
- Permanent loss of current releases
- May not be able to re-acquire all content
- Bandwidth/ISP concerns
- Indexer/tracker limitations

---

## Recommended Approach

### Hybrid Strategy: FileBot + Sonarr Verification

**Phase 1: Preparation (Day 1)**
1. ✅ Verify backup is complete on swap_drive
2. Create test subset (50 episodes from different series)
3. Install FileBot with license
4. Test FileBot AMC on subset
5. Verify results match expected structure

**Phase 2: Automated Processing (Day 2-3)**
1. Run FileBot on full TV directory with dry-run mode
2. Review FileBot's planned changes (save to log file)
3. Execute FileBot reorganization with move action
4. Verify folder structure created correctly

**Phase 3: Sonarr Integration (Day 4-5)**
1. Add all unique series to Sonarr (use lists from TVDB/TMDB)
2. Configure Sonarr to monitor reorganized folders
3. Run Sonarr's "Import Existing Files" scan
4. Fix any unmatched files manually
5. Let Sonarr manage going forward

**Phase 4: Cleanup (Day 6)**
1. Remove empty folders
2. Verify Plex can see all content
3. Document any remaining issues
4. Update Sonarr quality profiles

### Estimated Timeline
- **Total Time:** 12-20 hours of active work spread over 6 days
- **Automation Time:** FileBot processing (1-2 hours unattended)
- **Risk Level:** Low-Medium
- **Success Rate:** ~95% automatic, ~5% manual intervention

### Why This Approach?

1. **FileBot is proven** for mass TV reorganization
2. **Sonarr verification** catches any FileBot mistakes
3. **Incremental validation** reduces risk
4. **Time-efficient** compared to pure manual or pure scripting
5. **Preserves existing quality** unlike re-downloading
6. **Can handle edge cases** in Phase 3 manually

---

## Special Cases to Handle

### 1. Doctor Who Multi-Series
- Classic Who (1963-1989): Seasons 1-26
- Modern Who (2005+): Separate series
- Must map to correct TVDB entries

### 2. One Piece Naming Variants
- One.Piece
- One_Piece
- One_Piece_(1999)
All should map to same series folder

### 3. It's Always Sunny Capitalization
- Its.Always.Sunny.in.Philadelphia
- Its.Always.Sunny.In.Philadelphia
- its.always.sunny.in.philadelphia
Normalize to consistent format

### 4. Fist of the North Star
- Fist.of.the.North.Star
- Fist_of_the_North_Star
Both are same series

### 5. Monogatari Series Order
Complex airing order vs chronological order
- Recommend using Sonarr's "Anime" ordering from AniDB

### 6. Season Packs
Folders like `[Cleo]_Haikyuu!!_S1_[Dual_Audio_10bit_BD1080p][x265]` likely already contain properly named files inside
- Should verify internal structure first
- May only need to move to proper series folder

---

## FileBot Configuration Recommendations

### Naming Format
```
{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}
```

Example output:
```
One Piece (1999)/Season 12/One Piece - S12E44 - Oars Moria The Most Heinous Combination of Brains and Brawn.mkv
```

### Match Mode
- Use TheTVDB as primary source
- Fallback to TheMovieDB for newer content
- Enable "Anime" mode for Japanese content (uses AniDB)

### Conflict Handling
- Set to "auto" for first pass (skips conflicts)
- Review conflicts manually in second pass

### File Actions
- Use "move" not "copy" (saves space)
- Enable "clean" to remove empty folders after move

---

## Testing Plan

### Test Subset Selection (50 episodes)
Pick variety of patterns:
- 10x One Piece episodes (test volume/variants)
- 5x Doctor Who classic (test multi-part)
- 5x Doctor Who modern (test series separation)
- 5x It's Always Sunny (test capitalization)
- 5x Hunter x Hunter (test anime matching)
- 5x fansub releases with [tags] (test bracket handling)
- 5x underscored names (test delimiter handling)
- 5x episodes with Sonarr tag (test previously processed)
- 5x season packs (test pack extraction)

### Success Criteria
- ✅ Correct series identification (>90%)
- ✅ Proper season/episode numbering (100%)
- ✅ Episode titles fetched correctly (>85%)
- ✅ Year added to series folder (100%)
- ✅ No duplicate series folders (100%)
- ✅ Video files playable after move (100%)

---

## Rollback Plan

If issues occur:

### Immediate Rollback
1. Stop FileBot/script execution
2. Use backup on swap_drive
3. Restore affected files

### Partial Rollback
1. Identify problematic series
2. Restore only those series from backup
3. Reprocess with manual intervention

### Post-Processing Fixes
1. Use Sonarr's "Rename Files" on specific series
2. Manual folder reorganization for edge cases
3. Update Sonarr to re-scan and match

---

## Cost Analysis

| Option | Software Cost | Time Cost @ $50/hr | Total |
|--------|---------------|-------------------|-------|
| A: Sonarr Manual | $0 | $2,200-4,300 | $2,200-4,300 |
| B: FileBot | $48 (lifetime) | $550-850 | $598-898 |
| C: Custom Script | $0 | $1,400-2,100 | $1,400-2,100 |
| D: Re-Download | $0 | Very High + Data | Highest |
| **Recommended (B+A)** | **$48** | **$600-1,000** | **$648-1,048** |

---

## Next Steps

1. **Await user approval** of recommended approach
2. **Verify backup completion** on swap_drive
3. **Purchase FileBot license** (if approved)
4. **Create test subset** and run Phase 1
5. **Report results** before proceeding to Phase 2

---

## Appendix: Sample FileBot Commands

### Dry Run (Test Mode)
```bash
filebot -rename /path/to/test/subset \
  --db TheTVDB \
  --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
  --action test \
  -non-strict
```

### Full Run with Move
```bash
filebot -rename /run/media/deck/Fast_4TB_5/TV \
  --db TheTVDB \
  --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
  --action move \
  --conflict auto \
  -non-strict \
  --log-file /var/home/deck/filebot-reorganization.log
```

### Anime-Specific with AniDB
```bash
filebot -rename /path/to/anime/series \
  --db AniDB \
  --format "{n} ({y})/Season {s.pad(2)}/{n} - {s00e00} - {t}" \
  --action move \
  -non-strict
```

---

**Document Version:** 1.0
**Last Updated:** 2025-01-25
**Status:** Awaiting Approval
