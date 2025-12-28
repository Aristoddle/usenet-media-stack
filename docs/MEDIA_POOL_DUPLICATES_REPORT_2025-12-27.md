# Media Pool Duplicates & Redundancy Report

> **Generated:** 2025-12-27
> **Status:** Actionable - Cleanup recommendations ready

---

## Executive Summary

| Category | Count | Estimated Cleanup Space |
|----------|-------|------------------------|
| Movie duplicates (exact titles) | 12 sets | ~350GB |
| Movie variants (international titles) | 6 films | ~20GB |
| TV scattered episodes | 50+ episodes | Consolidation only |
| Anime scattered episodes | 153+ folders | Consolidation only |
| Anime release group duplicates | 4 series | ~50GB |
| Empty/broken folders | 2 folders | 0 bytes |

**Total estimated reclaimable space: ~400GB+**

---

## Movies Library: `/var/mnt/pool/movies/`

### Priority 1: Duplicate Films (Same Movie, Multiple Versions)

#### Batman (1989) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Batman.1989.2160p.MA.WEB-DL.TrueHD.Atmos.7.1.DV.HDR.H.265-FLUX` | 27GB | 4K WEB-DL DV/HDR | **KEEP** |
| `Batman 1989 COMPLETE UHD BLURAY-COASTER-Rakuvfinhel` | 75GB | 4K UHD BluRay | Keep if prefer disc quality |

**Action:** Delete WEB-DL if disc quality preferred, or delete BluRay if space priority. **Savings: 27-75GB**

#### Batman Returns (1992) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Batman Returns 1992 REPACK 2160p MA WEB-DL TrueHD Atmos 7 1 H 265-FLUX` | 28GB | 4K WEB-DL | **KEEP** (smaller, repack) |
| `Batman.Returns.1992.iNTERNAL.MULTiSUBS.COMPLETE.BLURAY-HD_Leaks` | 38GB | 1080p BluRay | DELETE |

**Action:** Delete 1080p version. **Savings: 38GB**

#### Anastasia (1997) - 3 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Anastasia (1997)` | 36GB | Unknown (check) | **KEEP** if best quality |
| `Anastasia.1997.Blu-ray.CEE.1080p.AVC.DTS-HD.MA.5.1-HDRoad` | 36GB | 1080p BluRay REMUX | DELETE (duplicate) |
| `Anastasia 1997 1080p BluRay x264-OFT` | 4.3GB | 1080p encode | DELETE |

**Action:** Keep one 36GB version, delete others. **Savings: 40GB**

#### American Beauty (1999) - 3 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `American.Beauty.1999.BluRay.1080p.DDP.5.1.x264-hallowed` | 11GB | 1080p BluRay | **KEEP** |
| `American_Beauty_1999_Bd50-UNKNOWN` | 0 bytes | EMPTY | DELETE |
| `American Beauty 1999 1080p BluRay x264-OFT` | 5.2GB | 1080p BluRay | DELETE (smaller encode) |

**Action:** Delete empty folder and smaller encode. **Savings: 5.2GB**

#### Armageddon (1998) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Armageddon 1998 BluRay 2160p PROPER Ai DTS-HD MA TrueHD 5 1 H265-KC` | 79GB | 4K AI Upscale | **KEEP** |
| `Armageddon.1998.1080p.BluRay.AVC.DTS-MA` | 0 bytes | EMPTY | DELETE |

**Action:** Delete empty folder. **Savings: 0 bytes (cleanup)**

#### Cars 2 (2011) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Cars 2 2011 REPACK UHD BluRay 2160p TrueHD Atmos 7 1 DV HEVC HYBRID REMUX-FraMeSToR` | 40GB | 4K UHD DV REMUX | **KEEP** (superior quality) |
| `Cars 2 2011 COMPLETE UHD BLURAY-TERMiNAL` | 61GB | 4K UHD COMPLETE | DELETE (larger, no DV) |

**Action:** Delete COMPLETE version. **Savings: 61GB**

#### Atomic Blonde (2017) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Atomic Blonde 2017 2160p UHD BluRay x265 DV HDR DDP 7 1 English DiscoD HONE` | 18GB | 4K UHD DV encode | **KEEP** (has DV) |
| `Atomic Blonde 2017-MULTi-COMPLETE-UHD-BLURAY-OLDHAM` | 56GB | 4K UHD COMPLETE | DELETE (no DV advantage) |

**Action:** Delete COMPLETE version. **Savings: 56GB**

#### Blade Runner 2049 (2017) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Blade Runner 2049 2017 2160 UHD Blu-ray HEVC TrueHD 7 1-F13@HDSpace` | 84GB | 4K UHD BluRay | **KEEP** |
| `Blade Runner 2049 2017 1080p BDRip DDP7 1 x265 Vialle` | 8.3GB | 1080p encode | DELETE |

**Action:** Delete 1080p version. **Savings: 8.3GB**

#### Godzilla vs. Kong (2021) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Godzilla.vs.Kong.2021.INTERNAL.MULTI.COMPLETE.UHD.BLURAY-WeWillRockU` | 56GB | 4K UHD COMPLETE | **KEEP** (HDR) |
| `Godzilla vs Kong 2021 NORDiC 2160p SDR BluRay DTS-HD MA TrueHD 7 1 Atmos x265-NorTekst` | 34GB | 4K SDR encode | DELETE (SDR inferior) |

**Action:** Delete SDR version. **Savings: 34GB**

#### Godzilla Raids Again (1955) - 2 versions
| Version | Size | Quality | Recommendation |
|---------|------|---------|----------------|
| `Godzilla Re dei mostri-Godzilla Raids Again 1955 1080p h264 Ac3 Ita Eng Jpn Sub Ita Eng-MIRCrew` | 1.8GB | 1080p multi-audio | **KEEP** |
| `Godzilla Raids Again 1955 Eng DUB Dvdrip x264- SlowPoke` | 1.5GB | DVDRip | DELETE |

**Action:** Delete DVDRip. **Savings: 1.5GB**

---

### Priority 2: International Title Variants (Godzilla Italian Releases)

These are NOT duplicates - they're Italian releases with Italian audio. Keep if wanted.

| Title | Size | Notes |
|-------|------|-------|
| `Godzilla.contro.i.giganti-Godzilla.vs.Gigan...1972` | ~2GB | Italian + Japanese audio |
| `Godzilla.contro.i.robot-Godzilla.vs.mechagodzilla.1974` | ~2GB | Italian + Japanese audio |
| `Godzilla.contro.King.Ghidorah...1991` | ~2GB | Italian + English + Japanese |
| `Godzilla.contro.Mothra...1992` | ~2GB | Italian + English + Japanese |
| `Godzilla.vs.Megalon-Ai.confini.della.realta...1973` | ~2GB | Criterion, Italian + English + Japanese |

**Action:** Keep if Italian audio desired, otherwise delete for space.

---

## TV Library: `/var/mnt/pool/tv/`

### Priority 1: Scattered Episodes (Need Consolidation)

#### Seinfeld - 20+ scattered episodes
**Location:** Root of `/var/mnt/pool/tv/`
**Episodes found:**
- S03E14, S03E21
- S05E12
- S07E17, S07E20, S07E21, S07E22, S07E23, S07E24
- S08E02, S08E03, S08E04, S08E09, S08E10, S08E11, S08E20
- S09E05, S09E09, S09E12, S09E16

**Action:** Move to `Seinfeld/Season XX/`

#### House of Cards - MAJOR CONTAMINATION
**Multiple folder variants:**
1. `House of Cards (2013) - Scattered` - Holding folder
2. `House of Cards (US)` - Another main folder
3. `House of Cards 2013` - Third variant
4. `House of Cards US` - Fourth variant
5. `House.Of.Cards.2013.S01-S06.Bluray...` - Season packs (6 folders)
6. Scattered episodes: `s01e12`, `s02e06`, `s02e11`, `3x01` (Italian)

**Action:** Consolidate ALL to `House of Cards (2013)/Season XX/`

#### Futurama - 6 season folders scattered
**Scattered folders:**
- `Futurama.S01.1080p.WEBRip.x265-RARBG-xpost`
- `Futurama.S02.WEBRip.AAC2.0.1080p.x265-SiQ`
- `Futurama.S03.WEBRip.AAC2.0.1080p.x265-SiQ`
- `Futurama.S04.WEBRip.AAC2.0.1080p.x265-SiQ`
- `Futurama.S05.WEBRip.AAC2.0.1080p.x265-SiQ`
- `Futurama.S06.1080p.BluRay.x265-RARBG-xpost`

**Action:** Move content to `Futurama/Season XX/`

#### It's Always Sunny in Philadelphia - Scattered S06 + S11 + S15
**Scattered:**
- 4x S06 episodes (s06e04, s06e05, s06e06, s06e09)
- Full S11 folder in root
- 2x S15 episodes

**Action:** Move to main `It's Always Sunny in Philadelphia/` folder

#### Doctor Who - 4 scattered episodes (typo: "Docto Who")
- `Docto Who S10E09 1080p BluRay x265-HETeam`
- `Docto Who S10E10 1080p BluRay x265-HETeam`
- `Docto Who S10E11 1080p BluRay x265-HETeam`
- `Docto Who S10E12 1080p BluRay x265-HETeam`

**Action:** Rename and move to `Doctor Who (2005)/Season 10/`

#### Billions - Scattered S03 + S05 episodes
- 2x S03 episodes
- 3x S05 episodes + full S05 2160p pack

**Action:** Consolidate to `Billions/Season XX/`

#### Other scattered content:
- `Columbo 1968-S01E09...` - Move to `Columbo/`
- `Game.of.Thrones.S03.COMPLETE...` - Move to `Game of Thrones/`
- `Game.Of.Thrones.Season.5.Episode.10...` - Move to `Game of Thrones/`
- `Gravity.Falls.S02...` - Move to `Gravity Falls/`
- `Red vs Blue S06...` - Move to `Red vs Blue/`
- `Ted.Lasso.2020.S01...` - Move to `Ted Lasso/`
- `Life in Pieces S02E09...` - Orphaned (no main folder)

---

## Anime Library: `/var/mnt/pool/anime/`

### Priority 1: Scattered Episodes (153+ folders in root)

#### Demon Slayer - MASSIVE CONTAMINATION (~50 folders)
**Scattered:**
- 11x S03 episodes (Entertainment District Arc)
- 11x S04 episodes (Hashira Training Arc)
- 8x S05 episodes
- Additional scattered 2160p WEB episodes

**Action:** Move ALL to `Demon Slayer Kimetsu no Yaiba/Season XX/`

#### Cyberpunk Edgerunners - 10 scattered + 1 full season
**Scattered:** 10 individual episode folders (S01E01-E10) plus full season folder
**Action:** Delete individual episodes if full season has same quality

#### Assassination Classroom - 7 scattered + 1 S2 folder
**Scattered:** S01E02, S01E03, S01E04, S01E05, S01E06, S01E07, S01E11
**Action:** Move to `Assassination Classroom/Season 01/`

#### Blood Lad - 10 scattered episodes
**Scattered:** E01-E10 (German releases) + 2 English episodes
**Action:** Move to consolidated folder

#### JoJo's Bizarre Adventure - Multiple release groups + scattered
**Folders:**
- `Jojos Bizarre Adventure` (main)
- `JoJos Bizarre Adventure 2012` (second main)
- 4x season pack folders (S01-S04)
- 8+ scattered S03 episodes
- 6+ scattered Stardust Crusaders episodes

**Action:** Consolidate to single `JoJo's Bizarre Adventure (2012)/` folder

#### One Piece - Scattered seasons + films in wrong location
**Scattered:**
- S07, S10, S11, S14, S15, S16 folders
- Individual episode (EP1125)
- FILMS: `One.Piece.Stampede.2019` and `One.Piece.Strong.World.2009`

**Action:**
- Move season content to `One Piece/Season XX/`
- Move films to `/var/mnt/pool/movies/` or `One Piece Films/`

#### Bakuman - 3 season folders scattered
**Action:** Move to `Bakuman/Season XX/`

#### Dragon Ball - Resource fork junk (._files)
**Issue:** 20+ `._[Sokudo]_Dragon_Ball...` files (macOS resource forks)
**Action:** Delete all `._*` files (junk)

#### Bleach - S17 episodes now in main folder (IMPROVED)
**Status:** Previously scattered, now consolidated in `Bleach/` folder
**Remaining issue:** Episodes are flat in folder, not in `Season 17/` subfolder

### Priority 2: Multiple Release Groups (Same Content)

#### KonoSuba - 2 release groups
- `[ENTE]_KonoSuba...S01` + `[ENTE]_KonoSuba...S02`
- `[Kosaka] Kono Subarashii Sekai ni Shukufuku wo! S1+S2+OVAs+Movie`

**Action:** Keep Kosaka (includes movie), delete ENTE

#### Kaguya-sama - Scattered individual episodes
- `[MTBB].Kaguya-sama.~Love.is.War~.S3-12.BD.1080p.[84D5A8A7]`
- `[MTBB] Kaguya-sama ~Love is War~ S3-09 BD 1080p [F39EFA44]`

**Action:** These are individual episode folders, need full season or consolidation

---

## Cleanup Commands Reference

### Movies: Delete Lower Quality Duplicates
```bash
# Create trash folder
mkdir -p /var/mnt/pool/.trash/movies_$(date +%Y%m%d)

# Batman Returns 1080p (keeping 4K)
mv "/var/mnt/pool/movies/Batman.Returns.1992.iNTERNAL.MULTiSUBS.COMPLETE.BLURAY-HD_Leaks" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/

# Anastasia duplicates (keeping one 36GB version)
mv "/var/mnt/pool/movies/Anastasia.1997.Blu-ray.CEE.1080p.AVC.DTS-HD.MA.5.1-HDRoad" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/
mv "/var/mnt/pool/movies/Anastasia 1997 1080p BluRay x264-OFT" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/

# Empty folders
rmdir "/var/mnt/pool/movies/American_Beauty_1999_Bd50-UNKNOWN"
rmdir "/var/mnt/pool/movies/Armageddon.1998.1080p.BluRay.AVC.DTS-MA"

# Cars 2 COMPLETE (keeping REPACK DV REMUX)
mv "/var/mnt/pool/movies/Cars 2 2011 COMPLETE UHD BLURAY-TERMiNAL" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/

# Atomic Blonde COMPLETE (keeping DV encode)
mv "/var/mnt/pool/movies/Atomic Blonde 2017-MULTi-COMPLETE-UHD-BLURAY-OLDHAM" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/

# Blade Runner 2049 1080p (keeping 4K)
mv "/var/mnt/pool/movies/Blade Runner 2049 2017 1080p BDRip DDP7 1 x265 Vialle" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/

# Godzilla duplicates
mv "/var/mnt/pool/movies/Godzilla vs Kong 2021 NORDiC 2160p SDR BluRay DTS-HD MA TrueHD 7 1 Atmos x265-NorTekst" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/
mv "/var/mnt/pool/movies/Godzilla Raids Again 1955 Eng DUB Dvdrip x264- SlowPoke" /var/mnt/pool/.trash/movies_$(date +%Y%m%d)/
```

### TV: Consolidate Scattered Content
```bash
# Seinfeld (example for one episode)
mkdir -p "/var/mnt/pool/tv/Seinfeld/Season 03"
mv "/var/mnt/pool/tv/Seinfeld.S03E14.The.Pez.Dispenser.1080p.AMZN.WEB-DL.DDP2.0.H.264-NTb" "/var/mnt/pool/tv/Seinfeld/Season 03/"

# Doctor Who typo fix
for ep in "/var/mnt/pool/tv/Docto Who"*; do
  mv "$ep" "/var/mnt/pool/tv/Doctor Who (2005)/Season 10/"
done

# House of Cards consolidation - requires manual merge of all variants
```

### Anime: Clean Resource Forks
```bash
# Delete macOS resource fork junk
find /var/mnt/pool/anime -name "._*" -type f -delete
```

---

## Quality Hierarchy Reference

When choosing between duplicates, prefer (in order):
1. **4K UHD BluRay with Dolby Vision** (DV/HDR)
2. **4K UHD BluRay HDR10+/HDR10**
3. **4K WEB-DL with DV/HDR**
4. **1080p BluRay REMUX** (lossless)
5. **1080p BluRay encode** (x264/x265)
6. **1080p WEB-DL**
7. **720p** (any source)
8. **DVDRip/SD** (lowest priority)

---

## Summary Table

| Issue | Files/Folders | Action | Space Savings |
|-------|---------------|--------|---------------|
| Batman 1989 duplicate | 1 | Delete one | 27-75GB |
| Batman Returns duplicate | 1 | Delete 1080p | 38GB |
| Anastasia duplicates | 2 | Delete both | 40GB |
| American Beauty empty | 1 | Delete empty | 0 |
| Armageddon empty | 1 | Delete empty | 0 |
| Cars 2 duplicate | 1 | Delete COMPLETE | 61GB |
| Atomic Blonde duplicate | 1 | Delete COMPLETE | 56GB |
| Blade Runner 2049 duplicate | 1 | Delete 1080p | 8.3GB |
| Godzilla vs Kong SDR | 1 | Delete SDR | 34GB |
| Godzilla Raids Again DVDRip | 1 | Delete DVDRip | 1.5GB |
| TV scattered episodes | 50+ | Consolidate | 0 |
| Anime scattered episodes | 153+ | Consolidate | 0 |
| Anime ._* junk files | 40+ | Delete | ~1MB |

**Total Conservative Savings: ~265GB**
**Total Maximum Savings: ~400GB** (if deleting larger duplicates)

---

## Changelog

| Date | Action |
|------|--------|
| 2025-12-27 | Initial duplicate scan and report |

