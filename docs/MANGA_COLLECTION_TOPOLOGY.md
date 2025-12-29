# Manga Collection Topology

A carefully considered approach to organizing manga across two acquisition tracks for optimal Komga/Komf serving.

**Decision Date**: 2025-12-29
**Last Updated**: 2025-12-29 (Post-Adversarial Review)
**Research Sources**: [Komga Libraries Docs](https://komga.org/docs/guides/libraries/), [Komga Discussion #1295](https://github.com/gotson/komga/discussions/1295), [Daiz Manga Naming Scheme](https://github.com/Daiz/manga-naming-scheme), [Komf GitHub](https://github.com/Snd-R/komf)
**Review Document**: [decisions/2025-12-29-manga-topology-adversarial-review.md](./decisions/2025-12-29-manga-topology-adversarial-review.md)

---

## The Problem

We have two fundamentally different manga acquisition tracks:

| Track | Source | Format | Delay | Use Case |
|-------|--------|--------|-------|----------|
| **Tankobon** | Mylar -> Usenet | Official volumes | 3-6 months | Archival, rereading |
| **Weeklies** | Suwayomi | Scanlation chapters | Same-day | Staying current |

Mixing these in one folder creates problems:
- `v01.cbz` and `c125.cbz` sort weirdly together
- Different quality/source expectations
- Different update frequencies
- Confusing reading experience

---

## Komga Constraints (From Research)

1. **No nested series**: Subfolders within a series folder become separate series
2. **Flat is best**: Files directly in series folder, not in `Volumes/` or `Chapters/`
3. **No official structure**: Komga doesn't mandate organization
4. **Collections for grouping**: Use Komga Collections to link related content

---

## Recommended Architecture

### Two Separate Komga Libraries

```
/var/mnt/fast8tb/Cloud/OneDrive/Books/
|-- Comics/                    # Existing manga collection (tankobon)
|   |-- Chainsaw Man (Viz) [EN]/
|   |   |-- Chainsaw Man v01.cbz
|   |   |-- Chainsaw Man v02.cbz
|   |-- One Piece (Viz) [EN]/
|       |-- ...
|
|-- Manga-Weekly/              # NEW: Scanlation chapters
    |-- Chainsaw Man/
    |   |-- Chainsaw Man c0125.cbz
    |   |-- Chainsaw Man c0126.cbz
    |-- Kagurabachi/
        |-- ...
```

### Komga Configuration

| Library Name | Root Path | Scan Frequency | Description |
|--------------|-----------|----------------|-------------|
| `Manga (Collected)` | `/comics/` | Daily | Official tankobon from Mylar |
| `Manga (Weekly)` | `/manga-weekly/` | Hourly | Scanlation chapters from Suwayomi |

### Why This Works

1. **Clear separation**: User picks "mode" - archival or current
2. **No sorting conflicts**: Each library has consistent naming
3. **Independent scanning**: Weeklies need frequent scans, tankobon don't
4. **Komga Collections**: Can link "Chainsaw Man" across both libraries
5. **Simple automation**: Mylar -> Comics/, Suwayomi -> Manga-Weekly/

---

## Naming Conventions

### Tankobon (Official Volumes)

**Folder Structure**:
```
{Series} ({Publisher}) [{Language}]/
    |-- {Series} v{volume:02d}.cbz
```

**Accept Mylar Default Formats** (do not force custom naming):
```
# All valid Mylar outputs:
{Series} v{vol:02d} ({Year}).cbz
{Series} v{vol:02d} (Digital).cbz
{Series} v{vol:02d}.cbz
```

Examples:
- `Chainsaw Man (Viz) [EN]/Chainsaw Man v01 (2020).cbz`
- `One Piece (Viz) [EN]/One Piece v107 (Digital).cbz`
- `Mob Psycho 100 (Dark Horse) [EN]/Mob Psycho 100 v08 (Digital).cbz`

### Weeklies (Scanlation Chapters)

**Structure in Manga-Weekly/**:
```
{Series}/
    |-- {Series} c{chapter:04d}[.{decimal}].cbz
```

Examples:
- `Chainsaw Man/Chainsaw Man c0125.cbz`
- `Chainsaw Man/Chainsaw Man c0126.cbz`
- `One Piece/One Piece c1135.5.cbz` (half chapter)

**Why 4-digit padding?**
- Ongoing manga can exceed 1000 chapters (One Piece: 1135+, Detective Conan: 1130+)
- Prevents sorting issues: c0099 < c0100 < c1000
- Future-proof with minimal cost

### Edge Case Naming Conventions

| Type | Convention | Example |
|------|------------|---------|
| **One-shots** | `c0000.cbz` | `{Series} c0000.cbz` |
| **Specials/Extras** | `SP{xx}.cbz` | `{Series} SP01.cbz` |
| **Colored editions** | `[Colored]` tag | `{Series} c0125 [Colored].cbz` |
| **Volume 0/Prologue** | `v00.cbz` | `{Series} v00.cbz` |
| **Fractional chapters** | `.{decimal}` | `{Series} c0125.5.cbz` |
| **Volume+Chapter** | Volume prefix | `{Series} v02 c0015.cbz` (rare) |

### Language Tags

For non-English content, use ISO 639-1 codes:

| Language | Tag | Example Folder |
|----------|-----|----------------|
| English | `[EN]` or omit | `Chainsaw Man (Viz) [EN]/` |
| Japanese | `[JP]` | `Chainsaw Man (Raw) [JP]/` |
| Spanish | `[ES]` | `Chainsaw Man (Panini) [ES]/` |
| Chinese | `[ZH]` | `Chainsaw Man [ZH]/` |
| Korean | `[KO]` | `Solo Leveling (Kakao) [KO]/` |

---

## Implementation Steps

### Step 1: Create Weekly Directory

```bash
mkdir -p "/var/mnt/fast8tb/Cloud/OneDrive/Books/Manga-Weekly"
```

### Step 2: Update Suwayomi Organizer

In `.env`:
```bash
SUWAYOMI_OUTPUT_DIR=/var/mnt/fast8tb/Cloud/OneDrive/Books/Manga-Weekly
```

### Step 3: Add Komga Library

Via Komga UI or API:
```bash
curl -X POST -u "$KOMGA_USER:$KOMGA_PASS" \
  "$KOMGA_URL/api/v1/libraries" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Manga (Weekly)",
    "root": "/manga-weekly",
    "scanForceModifiedTime": true,
    "scanInterval": "HOURLY"
  }'
```

### Step 4: Create Komga Collections

Link related series across libraries using Collections:

**Manual Method** (Komga UI):
1. Go to Collections
2. Create "Chainsaw Man (All Editions)"
3. Add series from both libraries

**Automated Method** (script recommended):
```bash
# See tools/komga-collection-sync.sh (to be created)
# Auto-creates collections linking same-name series across libraries
```

---

## Reading Workflow

### "I want to read from the beginning"
1. Open Manga (Collected) library
2. Find series (e.g., "Chainsaw Man (Viz)")
3. Start from volume 1

### "I want to read the latest chapter"
1. Open Manga (Weekly) library
2. Find series (e.g., "Chainsaw Man")
3. Continue from last read chapter

### "I want both for the same series"
1. Track via Mylar for tankobon releases
2. Track via Suwayomi for weekly chapters
3. Use Komga Collection to see all editions together

### "I can't find a series"
1. Use Komga's **global search** (searches all libraries)
2. Check both library views
3. Series may only exist in one track (weeklies-only or tankobon-only)

---

## When New Tankobon Releases

Scenario: Volume 18 releases, covering chapters 125-140.

**Option A: Keep Both** (Recommended)
- Official v18 for quality rereads
- Keep chapters for reference/different translation

**Option B: Replace**
- Download v18 via Mylar
- Delete c0125-c0140 from Manga-Weekly/
- (Manual curation, but cleaner)

---

## Volume -> Chapter Mapping

For series you follow in both tracks, maintain a mapping:

| Series | Latest Volume | Chapters Covered | Weekly Start |
|--------|---------------|------------------|--------------|
| Chainsaw Man | v17 | c001-c124 | c0125 |
| Kagurabachi | v01 | c001-c009 | c0010 |
| One Piece | v107 | c001-c1086 | c1087 |

This helps know when to clean up chapters after tankobon release.

---

## Komf Metadata Configuration

Configure different providers for each library type:

### Manga (Collected) - Official Releases
```yaml
# komf config - prioritize official metadata sources
komga:
  libraries:
    - name: "Manga (Collected)"
      providers:
        - comicVine      # Official releases have CV entries
        - mangaUpdates   # English publication data
        - aniList        # Fallback
```

### Manga (Weekly) - Scanlations
```yaml
# komf config - prioritize scanlation-aware sources
komga:
  libraries:
    - name: "Manga (Weekly)"
      providers:
        - mangaDex       # Scanlation-centric
        - aniList        # Good chapter counts
        - myAnimeList    # Fallback
```

---

## Migration Path

### Current State Issues

The existing Comics/ directory has:
- **Nested subfolders** (`1. Volumes/`, `2. Chapters/`) - breaks Komga
- **`__Panels` directories** - YACReader artifacts, need removal
- **Duplicate series** (e.g., both "Chainsaw Man (Viz) [EN]" and "Chainsaw Man (2020)")

### Phase 1: Cleanup (1 hour)

```bash
# Remove YACReader panel directories
find /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics -name "__Panels" -type d -exec rm -rf {} +

# Remove hidden directories
find /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics -name ".*" -type d -exec rm -rf {} +
```

### Phase 2: Flatten Nested Directories (4-8 hours)

```bash
# For each series with nested structure:
# Before: Series/1. Volumes/v01.cbz
# After:  Series/Series v01.cbz

# Script needed: tools/flatten-manga-directories.sh
```

### Phase 3: Deduplicate Series (Manual Review)

Some series exist twice:
- `Chainsaw Man (Viz) [EN]/` - Mylar official
- `Chainsaw Man (2020)/` - ComicVine year-based

**Decision per series**:
1. Keep Mylar-managed folder (has proper metadata)
2. Merge content if needed
3. Delete duplicate folder

### Mylar Path Updates

After flattening, update Mylar series paths:
1. Pause Mylar auto-search
2. For each moved series: Edit Settings -> Update path
3. Resume Mylar

---

## Automation Requirements

### Required Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| `suwayomi-organizer.sh` | Chapter download -> CBZ | COMPLETE (4-digit padding, edge cases) |
| `mylar-post-processor.sh` | SABnzbd -> Comics folder | COMPLETE |
| `komga-collection-sync.sh` | Auto-create cross-library collections | COMPLETE |
| `flatten-manga-directories.sh` | Migration helper | COMPLETE |

All scripts are located in `tools/` and documented in `tools/README.md`.

---

## Why Not Other Approaches?

### Single Folder, Mixed Naming

```
Chainsaw Man/
|-- Chainsaw Man v01.cbz
|-- Chainsaw Man c125.cbz  # Sorts after v99!
```
- Confusing sort order
- Mixed quality expectations
- No way to distinguish editions in Komga

### Nested Subfolders

```
Chainsaw Man/
|-- Volumes/
|-- Chapters/
```
- Komga treats Volumes/ and Chapters/ as separate series
- Breaks Komga's design assumptions

### Complex Naming Prefixes

```
Chainsaw Man/
|-- [Official] Chainsaw Man v01.cbz
|-- [Scan] Chainsaw Man c125.cbz
```
- Harder to parse/automate
- Still mixed in one series
- Prefixes look ugly in UI

### Kavita Instead of Komga

- Kavita has better novel support but less mature API
- Komf integration already established for Komga
- OPDS support (mobile readers) better in Komga
- Stick with Komga for now; Kavita for future novels

---

## Related Documentation

- [MANGA_ACQUISITION_PIPELINE.md](./MANGA_ACQUISITION_PIPELINE.md) - Two-track system
- [MANGA_INTEGRATION_STATUS.md](./MANGA_INTEGRATION_STATUS.md) - Current gaps
- [STRATEGIC_ROADMAP.md](./STRATEGIC_ROADMAP.md) - T2 manga tasks
- [decisions/2025-12-29-manga-topology-adversarial-review.md](./decisions/2025-12-29-manga-topology-adversarial-review.md) - Full adversarial analysis

---

## Decision Rationale

This topology was chosen because:

1. **Respects Komga's design** - Separate libraries, flat series folders
2. **Enables automation** - Clear paths for Mylar and Suwayomi
3. **Supports different reading modes** - Archival vs current
4. **Allows coexistence** - Same series in both tracks
5. **Minimizes tech debt** - Simple, obvious structure
6. **Scales well** - Works for 10 series or 1000 series
7. **Accepts tool defaults** - Don't fight Mylar naming conventions

The key insight: **Don't fight the tool. Use separate Komga libraries to represent different edition types, then use Collections to link them.**

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-29 | 1.0.0 | Initial topology proposal |
| 2025-12-29 | 1.1.0 | Post-adversarial review updates: edge cases, Mylar acceptance, migration phases, Komf config |
