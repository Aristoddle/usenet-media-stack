# Manga Collection Topology

A carefully considered approach to organizing manga across two acquisition tracks for optimal Komga/Komf serving.

**Decision Date**: 2025-12-29
**Research Sources**: [Komga Libraries Docs](https://komga.org/docs/guides/libraries/), [Komga Discussion #1295](https://github.com/gotson/komga/discussions/1295), [MangaHelpers Organization Thread](https://mangahelpers.com/forum/threads/how-do-you-organize-your-downloaded-manga.56760/)

---

## The Problem

We have two fundamentally different manga acquisition tracks:

| Track | Source | Format | Delay | Use Case |
|-------|--------|--------|-------|----------|
| **Tankobon** | Mylar → Usenet | Official volumes | 3-6 months | Archival, rereading |
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
├── Comics/                    # Existing manga collection (tankobon)
│   ├── Chainsaw Man (Viz) [EN]/
│   │   ├── Chainsaw Man v01.cbz
│   │   └── Chainsaw Man v02.cbz
│   └── One Piece (Viz) [EN]/
│       └── ...
│
└── Manga-Weekly/              # NEW: Scanlation chapters
    ├── Chainsaw Man/
    │   ├── Chainsaw Man c125.cbz
    │   └── Chainsaw Man c126.cbz
    └── Kagurabachi/
        └── ...
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
5. **Simple automation**: Mylar → Comics/, Suwayomi → Manga-Weekly/

---

## Naming Conventions

### Tankobon (Official Volumes)

Already in Comics/ with existing naming:
```
{Series} ({Publisher}) [{Language}]/
    └── {Series} v{volume:02d}.cbz
```

Examples:
- `Chainsaw Man (Viz) [EN]/Chainsaw Man v01.cbz`
- `One Piece (Viz) [EN]/One Piece v107.cbz`

### Weeklies (Scanlation Chapters)

New structure in Manga-Weekly/:
```
{Series}/
    └── {Series} c{chapter:04d}[.{part}].cbz
```

Examples:
- `Chainsaw Man/Chainsaw Man c0125.cbz`
- `Chainsaw Man/Chainsaw Man c0126.cbz`
- `One Piece/One Piece c1135.1.cbz` (split chapter)

**Why 4-digit padding?**
- Ongoing manga can exceed 1000 chapters (One Piece, Detective Conan)
- Prevents sorting issues: c0099 < c0100 < c1000

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

### Step 4: Create Komga Collections (Optional)

Link related series across libraries:
- Collection: "Chainsaw Man (All Editions)"
  - Series from Manga (Collected)
  - Series from Manga (Weekly)

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

---

## When New Tankobon Releases

Scenario: Volume 18 releases, covering chapters 125-140.

**Option A: Keep Both** (Recommended)
- Official v18 for quality rereads
- Keep chapters for reference/different translation

**Option B: Replace**
- Download v18 via Mylar
- Delete c125-c140 from Manga-Weekly/
- (Manual curation, but cleaner)

---

## Volume → Chapter Mapping

For series you follow in both tracks, maintain a mapping:

| Series | Latest Volume | Chapters Covered | Weekly Start |
|--------|---------------|------------------|--------------|
| Chainsaw Man | v17 | c001-c124 | c125 |
| Kagurabachi | v01 | c001-c009 | c010 |
| One Piece | v107 | c001-c1086 | c1087 |

This helps know when to clean up chapters after tankobon release.

---

## Why Not Other Approaches?

### ❌ Single Folder, Mixed Naming

```
Chainsaw Man/
├── Chainsaw Man v01.cbz
└── Chainsaw Man c125.cbz  # Sorts after v99!
```
- Confusing sort order
- Mixed quality expectations
- No way to distinguish editions in Komga

### ❌ Nested Subfolders

```
Chainsaw Man/
├── Volumes/
└── Chapters/
```
- Komga treats Volumes/ and Chapters/ as separate series
- Breaks Komga's design assumptions

### ❌ Complex Naming Prefixes

```
Chainsaw Man/
├── [Official] Chainsaw Man v01.cbz
└── [Scan] Chainsaw Man c125.cbz
```
- Harder to parse/automate
- Still mixed in one series
- Prefixes look ugly in UI

---

## Migration Path

If existing Comics/ has scanlation content mixed in:

1. **Identify scanlation series**:
   - No publisher in folder name
   - Contains chapter files (c###.cbz vs v##.cbz)

2. **Move to Manga-Weekly/**:
   ```bash
   mv "Comics/Series (Scanlation)" "Manga-Weekly/Series/"
   ```

3. **Trigger Komga rescan** on both libraries

4. **Update organizer config** to use new output path

---

## Related Documentation

- [MANGA_ACQUISITION_PIPELINE.md](./MANGA_ACQUISITION_PIPELINE.md) - Two-track system
- [MANGA_INTEGRATION_STATUS.md](./MANGA_INTEGRATION_STATUS.md) - Current gaps
- [STRATEGIC_ROADMAP.md](./STRATEGIC_ROADMAP.md) - T2 manga tasks

---

## Decision Rationale

This topology was chosen because:

1. **Respects Komga's design** - Separate libraries, flat series folders
2. **Enables automation** - Clear paths for Mylar and Suwayomi
3. **Supports different reading modes** - Archival vs current
4. **Allows coexistence** - Same series in both tracks
5. **Minimizes tech debt** - Simple, obvious structure
6. **Scales well** - Works for 10 series or 1000 series

The key insight: **Don't fight the tool. Use separate Komga libraries to represent different edition types, then use Collections to link them.**
