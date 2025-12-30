# Manga Ecosystem Deep Analysis

**Generated:** 2025-12-29
**Analysis Scope:** Complete collection audit + infrastructure assessment
**Collection Path:** `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/`

---

## Executive Summary

The manga collection infrastructure is well-established with comprehensive documentation in `MANGA_PROJECT_DOCS/`. The December 2025 migration to NAMING_STANDARD_V2 achieved 100% compliance on 78 official series, but **81 parallel year-only folders from Mylar3** remain as metadata stubs (series.json + cvinfo only).

**Key Findings:**
- 78 series follow the standard `Series Name (Publisher) [EN]` pattern
- 81 folders follow `Series Name (YYYY)` pattern - these are Mylar3 metadata stubs
- 33 duplicate pairs exist (same series, both naming patterns)
- The duplicate YEAR_ONLY folders contain only metadata (0 CBZ files)
- Suwayomi downloads folder exists but is empty
- Total collection: ~160+ series, 78 with actual content

---

## Collection Structure Analysis

### Pattern Distribution

| Pattern Type | Count | Percentage | Description |
|--------------|-------|------------|-------------|
| STANDARD | 78 | 49.1% | `Series (Publisher) [EN]` - Primary content |
| YEAR_ONLY | 81 | 50.9% | `Series (YYYY)` - Mylar3 metadata stubs |
| **Total** | 159 | 100% | Unique series folders |

### Publisher Distribution (Standard naming only)

| Publisher | Series Count | Notable Series |
|-----------|-------------|----------------|
| **Viz** | 47 | One Piece, Naruto, Chainsaw Man, JoJo, Dragon Ball |
| **Yen Press** | 7 | Claymore, Dungeon Meshi, Soul Eater, Kakegurui |
| **Seven Seas** | 5 | Made in Abyss, Oshi no Ko, Dai Dark, Spirit Circle |
| **Dark Horse** | 4 | Berserk, Gantz, Blade of the Immortal, Hellsing |
| **Kodansha Comics** | 4 | Vinland Saga, GTO, A Silent Voice, Hajime no Ippo |
| **Kodansha** | 4 | Akira, Blue Lock, Blue Period, GACHIAKUTA |
| **Pantheon** | 2 | Sunny, Tekkonkinkreet |
| **Other** | 5 | Marvel (Deadpool), Denpa (Kaiji), Square Enix, WebToon |

### Duplicate Analysis (33 series with parallel folders)

These series have BOTH a standard folder with content AND a Mylar3 metadata stub:

| Base Series | STANDARD Folder | YEAR_ONLY Folder |
|-------------|-----------------|------------------|
| Chainsaw Man | 6.61GB, 244 CBZ | 0 files (metadata only) |
| Dandadan | 4.73GB, 106 CBZ | 0 files (metadata only) |
| Jujutsu Kaisen | 10.41GB, 84 CBZ | 0 files (metadata only) |
| Berserk | 20.34GB, 42 CBZ | 0 files (metadata only) |
| Akane-banashi | Has content | 0 files (metadata only) |
| Assassination Classroom | Has content | 0 files (metadata only) |
| ... 27 more pairs | ... | ... |

**Recommendation:** The YEAR_ONLY folders are vestigial Mylar3 metadata and can be safely removed. The actual content exists in the STANDARD folders.

---

## Infrastructure Assessment

### Active Tools

| Tool | Status | Purpose | Integration |
|------|--------|---------|-------------|
| **Komga** | Active (port 8081) | Library + OPDS server | Hourly scan via cron |
| **Komf** | Active (port 8085) | Metadata enrichment | Points to Komga |
| **Mylar3** | Partial | Comic acquisition | Creates YEAR_ONLY folders |
| **Suwayomi** | Configured | Tachidesk alternative | Empty downloads folder |
| **Prowlarr** | Active (port 9696) | Indexer aggregation | Routes to SABnzbd/Transmission |
| **SABnzbd** | Active (port 8080) | Usenet downloads | Category: comics (7030) |
| **Transmission** | Active (port 9091) | Torrent fallback | Manual adds |

### Key Paths

```
CONFIG_ROOT=/var/mnt/fast8tb/config
DOWNLOADS_ROOT=/var/mnt/fast8tb/Local/downloads
COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
SUWAYOMI_DOWNLOADS=$COMICS_ROOT/Manga  (empty)
```

### Existing Automation

| Script | Location | Purpose |
|--------|----------|---------|
| `komga-corrupt-scan.sh` | scripts/ | Detect/quarantine corrupt CBZ files |
| `books-inventory.sh` | scripts/ | Generate collection stats |
| `komga-gap-report.py` | scripts/ | Find missing chapters/volumes |
| `manga-audit-check.sh` | ~/.local/share/chezmoi/ | Standardization compliance check |

### Missing Automation (Gaps)

1. **No naming enforcement script** - Migration was manual
2. **No Suwayomi-to-Komga pipeline** - Downloads folder empty
3. **No post-download processor** - Files land raw
4. **No duplicate detector** - 81 stub folders remain

---

## Naming Standard Compliance

### NAMING_STANDARD_V2 (Current)

The collection follows a 4-tier naming system documented in `MANGA_PROJECT_DOCS/NAMING_STANDARD_V2.md`:

```
{Series Name} ({Publisher}) [{Language}]/
├── [N]. {Content Name} {Tags} ({Dates})/
│   ├── Volumes/
│   └── Chapters/
├── Extras/
└── {series}.webp
```

**Tier System:**
- **Tier 1:** Simple series - `Volumes/` only
- **Tier 2:** Format variants - `1. Volumes/` + `1c. Volumes [Colored]/`
- **Tier 3:** Related works - `[Prequel]`, `[Sequel]` tags
- **Tier 4:** Multi-part sagas - Numbered parts (Baki, JoJo)

### Compliance Status

| Category | Count | Compliance |
|----------|-------|------------|
| Standard folders | 78 | 100% migrated |
| Internal structure | Variable | Tier 1-4 applied |
| YEAR_ONLY stubs | 81 | Non-standard (legacy) |

---

## Content Quality Assessment

### Corrupt Files (Quarantined)

Per `docs/komga-corrupt-cbz.md`, these were quarantined on Dec 18, 2025:
- Blue Box v01-v18 (17 volumes) - 1r0n releases
- Sand Land (2003) - BlurPixel-Empire release

**Status:** Files moved to `/var/mnt/fast8tb/Local/quarantine/komga`

### Release Group Quality Tiers

| Group | Quality | Notes |
|-------|---------|-------|
| **1r0n** | Excellent | Official digital rips, x1350+ resolution |
| **danke-Empire** | High | High-quality volumes |
| **Rillant** | Good | Weekly chapter releases |
| **aKraa** | Good | Complete series archives |

---

## Suwayomi Integration Status

### Current State

```
/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/Manga/
├── (empty)
```

Suwayomi is configured but not actively used. Downloads are handled via:
1. Prowlarr -> SABnzbd (usenet primary)
2. Prowlarr -> Transmission (torrent fallback)
3. Manual nyaa.si searches

### Pipeline Gap

There is no automated pipeline from:
- Suwayomi downloads -> naming standardization -> Komga library

This creates friction for using Suwayomi as a chapter source.

---

## Recommendations

### Immediate Actions

1. **Remove YEAR_ONLY stub folders** (81 folders, metadata only)
   - These are Mylar3 vestigial data with no content
   - Will declutter Komga library

2. **Re-acquire Blue Box volumes**
   - 17 volumes quarantined as corrupt
   - Search 1r0n releases on usenet

3. **Create naming enforcement script**
   - Audit mode: report non-compliant folders
   - Fix mode: apply standard with dry-run option

### Infrastructure Improvements

1. **Suwayomi-to-Komga pipeline**
   - Post-download script to rename/move files
   - Apply NAMING_STANDARD_V2 automatically

2. **Metadata enrichment workflow**
   - Batch Komf enrichment for missing covers
   - Prioritize: no cover > no description > no genres

3. **Gap reporting automation**
   - Weekly `komga-gap-report.py` execution
   - Output to MANGA_PROJECT_DOCS/ACTIVE/

### Collection Expansion

Based on existing taste profile (action, seinen, well-crafted art):
- Complete ongoing series (Kagurabachi, Sakamoto Days)
- Fill verified gaps (Hunter x Hunter v38)
- Upgrade fan scans to official releases

---

## Taste Profile Analysis

### Strong Preferences (High Volume)

Based on collection composition:

| Genre/Style | Series Examples | Confidence |
|-------------|----------------|------------|
| **Battle Shounen** | JoJo, Baki, Dragon Ball, Naruto | Very High |
| **Dark Action/Seinen** | Berserk, Chainsaw Man, Gantz, Tokyo Ghoul | Very High |
| **Sports Drama** | Blue Lock, Haikyu!!, Slam Dunk, Hajime no Ippo | High |
| **Psychological** | Death Note, Monster, Liar Game, Kaiji | High |
| **Comedy/Gag** | One-Punch Man, Mob Psycho 100, GTO | High |
| **Fantasy Adventure** | Made in Abyss, Dungeon Meshi, Frieren | High |

### Author Follows

| Author | Series in Collection |
|--------|---------------------|
| Tatsuki Fujimoto | Chainsaw Man, Fire Punch, Look Back, Goodbye Eri |
| Naoki Urasawa | Monster, 20th Century Boys, Pluto, Billy Bat |
| Hirohiko Araki | JoJo's Bizarre Adventure (all parts) |
| ONE | One-Punch Man, Mob Psycho 100 |
| Sui Ishida | Tokyo Ghoul, Choujin X |
| Junji Ito | (Not in collection - potential gap) |
| Tsutomu Nihei | BLAME! Master Edition |

---

## Technical Appendix

### Collection Statistics

```
Total series folders: 159
Standard naming: 78 (49.1%)
Year-only (Mylar3): 81 (50.9%)

Major series by size:
- One Piece: 75.86GB (2,312 CBZ)
- Berserk: 20.34GB (42 CBZ)
- Jujutsu Kaisen: 10.41GB (84 CBZ)
- Chainsaw Man: 6.61GB (244 CBZ)
- Dandadan: 4.73GB (106 CBZ)
```

### Internal Structure Patterns

Sample analysis of 30 series:
- 11 have subfolders (`1. Volumes/`, `__Panels/`, etc.)
- 12 are flat (CBZ files directly in folder)
- Common subfolders: `__Panels`, `1. Volumes`, `2. Chapters`, `Extras`

### API Keys Location

```bash
PROWLARR_API_KEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$CONFIG_ROOT/prowlarr/config.xml")
SABNZBD_API_KEY=$(grep -oP '(?<=^api_key = ).+' "$CONFIG_ROOT/sabnzbd/sabnzbd.ini")
```

---

## Version History

| Date | Change |
|------|--------|
| 2025-12-29 | Initial deep ecosystem analysis |

---

**Related Documentation:**
- `MANGA_PROJECT_DOCS/NAMING_STANDARD_V2.md` - Naming convention spec
- `MANGA_PROJECT_DOCS/MIGRATION_PLAN.md` - Migration commands
- `MANGA_PROJECT_DOCS/STATE_OF_THE_UNION.md` - Current status
- `docs/komga.md` - Komga/Komf setup
- `docs/suwayomi-setup.md` - Suwayomi configuration
