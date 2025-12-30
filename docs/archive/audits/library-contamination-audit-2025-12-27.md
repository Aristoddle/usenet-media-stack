# Library Contamination Audit

> **Generated:** 2025-12-27
> **Status:** Living document - tracking cleanup progress

---

## Executive Summary

Comprehensive scan of `/var/mnt/pool` media libraries found **22 major contamination categories** affecting movies, TV, and anime libraries.

### Key Issues by Category

| Issue Type | Count | Examples |
|------------|-------|----------|
| Scattered episodes/seasons | 8 shows | Futurama, Seinfeld, IASIP, Bleach |
| Duplicate versions | 5 films | Batman, Anastasia, Godzilla variants |
| Folder naming issues | 7 shows | House of Cards variants, missing years |
| Films in wrong library | 2 issues | One Piece films, Akira |
| Multiple release groups | 4 shows | KonoSuba, JoJo's, Bleach |

---

## Completed Fixes

### Doctor Who Consolidation ✅
**Date:** 2025-12-27
**Issue:** 30+ scattered folders contaminating NuWho and Classic Who
**Fix:**
- Moved Classic Who seasons (15-26) from `Doctor Who (2005)` to `Doctor Who (1963)`
- Merged duplicate season folders (Season 1 → Season 01)
- Moved bare `Doctor Who` folder content to Classic
- Cleared scattered episode folders to trash, then deleted (119GB freed)
**Result:** Clean structure with 15 NuWho seasons + 21 Classic Who seasons

### Monster Contamination ✅
**Date:** 2025-12-27
**Issue:** Netflix "Monster: The Jeffrey Dahmer Story" mixed with Naoki Urasawa's Monster anime
**Fix:** Moved 5 Dahmer files to separate TV folder, then deleted (unwanted content)

---

## Pending Fixes

### Priority 1: Anime Library

#### Bleach Thousand-Year Blood War
**Location:** `/var/mnt/pool/anime/`
**Issue:** 10+ individual S17 episode folders scattered in root
- `[LostYears].Bleach.Thousand-Year.Blood.War.-.S17E14...`
- `[ToonsHub] BLEACH Thousand-Year Blood War-S17E15/E17/E18/E22/E25/E26...`
**Fix:** Consolidate into `Bleach/Season 17/`

#### One Piece Films in TV Folder
**Location:** `/var/mnt/pool/anime/`
**Issue:** 4+ One Piece films mixed with TV series
- `One.Piece.Film.Gold.2016...`
- `One.Piece.3D2Y.Overcome.Aces.Death...`
**Fix:** Move to `/var/mnt/pool/movies/` or anime films location

#### Dragon Ball Scattered Episodes
**Issue:** Sokudo release episodes S01E01-E08+ in root
**Fix:** Move to `Dragon Ball/Season 01/`

### Priority 2: TV Library

#### Futurama Seasons
**Issue:** 6 season folders as release folders instead of consolidated
**Fix:** Move content to `Futurama/Season XX/`

#### Seinfeld Episodes
**Issue:** ~20 individual episodes from S03-S09 scattered
**Fix:** Organize into `Seinfeld/Season XX/`

#### It's Always Sunny
**Issue:** S06 episodes + S11 folder scattered
**Fix:** Consolidate to main folder

#### House of Cards
**Issue:** 3 folder variants (2013, US, (US)) + 6 season folders
**Fix:** Consolidate to `House of Cards (2013)`

### Priority 3: Movies Library

#### Batman Duplicates
**Issue:** 2 versions each of Batman 1989 and Returns
**Fix:** Keep 4K UHD versions, delete duplicates

#### Godzilla International Titles
**Issue:** Italian titles mixed with English
**Fix:** Standardize to English with years

---

## Naming Standards Reference

### TV Shows
```
Show Name (Year)/
  Season 01/
    Show Name - S01E01 - Episode Title.mkv
```

### Movies
```
Movie Name (Year)/
  Movie Name (Year).mkv
```

### Anime (TV)
```
Anime Name (Year)/
  Season 01/
    [ReleaseGroup] Anime Name - S01E01.mkv
```

---

## Cleanup Commands Reference

### Safe Move Pattern
```bash
# Move scattered episodes to proper location
src="/var/mnt/pool/anime/[Release] Show S01E01..."
dest="/var/mnt/pool/anime/Show Name/Season 01/"
mkdir -p "$dest"
mv "$src" "$dest/"
```

### Trash Before Delete
```bash
mkdir -p /var/mnt/pool/.trash/cleanup_$(date +%Y%m%d)
mv "$folder" /var/mnt/pool/.trash/cleanup_$(date +%Y%m%d)/
# Verify, then clear: rm -rf /var/mnt/pool/.trash/*
```

---

## Changelog

| Date | Action |
|------|--------|
| 2025-12-27 | Initial audit - 22 issues found |
| 2025-12-27 | Doctor Who consolidated (119GB trash cleared) |
| 2025-12-27 | Monster contamination resolved |
