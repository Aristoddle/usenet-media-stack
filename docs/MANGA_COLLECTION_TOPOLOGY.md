# Manga Collection Topology

How to organize manga across two acquisition tracks for optimal Komga/Komf serving.

---

## Two-Track System Overview

| Track | Source | Format | Delay | Quality | Use Case |
|-------|--------|--------|-------|---------|----------|
| **Tankobon** | Mylar → Prowlarr → Usenet | Vol. XX | 3-6 months | Archival (official EN) | Collecting, rereading |
| **Weeklies** | Suwayomi → staging | cXXX | Same-day | Current (scanlation) | Staying current |

---

## Recommended Folder Structure

```
Comics/
├── [Official Releases]/                   # Tankobon from Mylar
│   ├── Chainsaw Man (Viz) [EN]/
│   │   ├── Chainsaw Man v01.cbz
│   │   ├── Chainsaw Man v02.cbz
│   │   └── ...
│   ├── Kagurabachi (Viz) [EN]/
│   │   └── ...
│   └── ...
│
├── [Weekly Chapters]/                     # Scanlations from Suwayomi
│   ├── Chainsaw Man/
│   │   ├── Chainsaw Man c125.cbz
│   │   ├── Chainsaw Man c126.cbz
│   │   └── ...
│   ├── Kagurabachi/
│   │   ├── Kagurabachi c001.cbz
│   │   └── ...
│   └── ...
```

**Rationale**:
- Top-level separation prevents mixing official and scanlation in Komga views
- Each series appears in **both** locations if you track both editions
- Clear namespace: `v01` = volume, `c001` = chapter
- Komga can configure separate libraries or combined with smart filtering

---

## Naming Conventions

### Tankobon (Mylar)

```
{Series Name} v{Volume:02d}.cbz
```

Examples:
- `Chainsaw Man v01.cbz`
- `Chainsaw Man v02.cbz`
- `One Piece v107.cbz`

### Weekly Chapters (Suwayomi)

```
{Series Name} c{Chapter:03d}[.{Part}].cbz
```

Examples:
- `Chainsaw Man c125.cbz`
- `Chainsaw Man c126.cbz`
- `One Piece c1135.1.cbz` (for split chapters)

### Why This Naming?

1. **Sorting**: `c001` always sorts after `v99` alphabetically
2. **Parsing**: Komga/Komf can detect chapter vs volume patterns
3. **Disambiguation**: Clear which is official vs scanlation
4. **Zero-padding**: Ensures proper ordering (c001 < c010 < c100)

---

## Komga Configuration

### Option A: Separate Libraries (Recommended)

| Library | Root Path | Description |
|---------|-----------|-------------|
| `Manga (Official)` | `/comics/[Official Releases]` | Tankobon only |
| `Manga (Weekly)` | `/comics/[Weekly Chapters]` | Scanlations only |

**Benefits**:
- Clear separation in UI
- Different scan frequencies (weekly library scans hourly, official scans daily)
- Users can bookmark both libraries for same series

### Option B: Single Library with Collections

| Library | Root Path | Collections |
|---------|-----------|-------------|
| `Manga` | `/comics/` | Auto-detect via folder name pattern |

Use Komga collections to group by edition type.

### Option C: Flat Structure (Not Recommended)

Mixing all content in one folder. Causes:
- Sorting issues (c125 appears before v01)
- Confusion between editions
- Metadata conflicts in Komf

---

## Komf Metadata Strategy

### For Tankobon (Official)

- **Primary**: MangaUpdates (volume info)
- **Fallback**: AniList, MyAnimeList
- Metadata tends to be complete and accurate for official releases

### For Weeklies (Scanlation)

- **Primary**: MangaDex (chapter metadata)
- **Note**: Chapter-level metadata less reliable; series-level should work
- Consider disabling auto-metadata for weeklies if noise is high

---

## Suwayomi Organizer Integration

The `suwayomi-organizer.sh` script should be updated to:

1. Output to `[Weekly Chapters]/` subdirectory
2. Use `c{chapter:03d}` naming convention
3. Preserve source series name from Suwayomi

Configuration in `.env`:
```bash
# Where Suwayomi organizer places chapters
SUWAYOMI_OUTPUT_DIR="${COMICS_ROOT}/[Weekly Chapters]"
```

---

## Example: Following "Chainsaw Man"

### What You Have

| Location | Source | Format | Content |
|----------|--------|--------|---------|
| `Comics/Chainsaw Man (Viz) [EN]/` | Mylar | v01-v17 | Official volumes |
| `Comics/[Weekly Chapters]/Chainsaw Man/` | Suwayomi | c125-c195 | Current scanlations |

### In Komga

- **Manga (Official)** library shows: Chainsaw Man with 17 volumes
- **Manga (Weekly)** library shows: Chainsaw Man with 70+ chapters
- User reads current chapters in Weekly, rereads in Official

### Transition Path

When a new tankobon releases (e.g., v18 covering c125-c140):
1. Mylar downloads `Chainsaw Man v18.cbz`
2. User can optionally delete weekly chapters c125-c140
3. Or keep both for different reading experiences

---

## Migration for Existing Collection

If current collection has mixed content:

1. Identify scanlation vs official by folder naming:
   - `(Viz)`, `(Kodansha)`, `(Dark Horse)` = Official
   - `(MangaDex)`, `(Suwayomi)`, no publisher = Scanlation

2. Move scanlation folders to `[Weekly Chapters]/`

3. Update Suwayomi organizer to use new output path

4. Reconfigure Komga libraries

---

## Related Documentation

- [MANGA_ACQUISITION_PIPELINE.md](./MANGA_ACQUISITION_PIPELINE.md) - Two-track system details
- [MANGA_INTEGRATION_STATUS.md](./MANGA_INTEGRATION_STATUS.md) - Current integration gaps
- [STRATEGIC_ROADMAP.md](./STRATEGIC_ROADMAP.md) - T2 manga pipeline tasks
