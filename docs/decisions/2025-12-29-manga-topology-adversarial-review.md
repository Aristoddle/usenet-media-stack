# Decision: Manga Collection Topology - Adversarial Review

**Date**: 2025-12-29
**Status**: Analysis Complete - Revisions Recommended
**Deciders**: Deep-Thinker Agent (adversarial review)
**Methodology**: Sequential Analysis (12+ thoughts)

---

## Executive Summary

The proposed two-library topology (MANGA_COLLECTION_TOPOLOGY.md) is **fundamentally sound** but has **critical implementation gaps** and **underspecified edge cases** that will cause problems at scale. This review identifies 23 specific weaknesses across 6 categories and proposes targeted refinements.

**Verdict**: APPROVE WITH MODIFICATIONS

---

## Attack Analysis

### 1. NAMING SCHEMA ADVERSARIAL REVIEW

#### 1.1 4-Digit Chapter Padding: Overkill or Essential?

**Current Proposal**: `c0001.cbz` (4-digit padding)

**Attack**: Most manga never exceed 999 chapters. The median ongoing series has ~200 chapters. 4-digit padding is defensive overkill that adds visual noise.

**Counter-Attack (Defense Wins)**:
- Detective Conan: 1,130+ chapters
- One Piece: 1,135+ chapters
- Hajime no Ippo: 1,400+ chapters
- Golgo 13: 200+ volumes (tankoubon equivalent)
- Future-proofing costs nothing

**Verdict**: 4-digit padding is CORRECT. The topology survives this attack.

#### 1.2 Edge Cases Not Addressed

| Edge Case | Current Handling | Weakness | Severity |
|-----------|------------------|----------|----------|
| **One-shots** | Not specified | Should be `c0000.cbz` per Daiz naming scheme | MEDIUM |
| **Specials/Extras** | Not specified | No convention for `x001`, `SP01` patterns | HIGH |
| **Colored editions** | Not specified | How to distinguish colored vs B&W chapters? | MEDIUM |
| **Box sets** | Not specified | What if download is multi-volume archive? | LOW |
| **Spin-offs** | Not specified | Should be separate series or tagged? | MEDIUM |
| **Chapter parts** | Partially addressed | `c0125.1.cbz` works but `.5` chapters common | LOW |
| **Volume 0/Prologue** | Not specified | Some series have v00 | MEDIUM |

**Missing Convention Proposal**:
```
# One-shots
{Series} c0000.cbz

# Specials
{Series} SP{number:02d}.cbz

# Colored editions (append tag)
{Series} c0125 [Colored].cbz

# Volume 0
{Series} v00.cbz

# Fractional chapters
{Series} c0125.5.cbz  (decimal, not .1)
```

#### 1.3 Mylar Naming Mismatch

**Critical Weakness Discovered**:

Per [Mylar3 Wiki](https://github.com/mylar3/mylar3/wiki/Folder-and-File-formats), Mylar uses ComicVine naming by default:
```
ComicName v01 (Year).cbz
ComicName v02 (Year).cbz
```

But the topology proposes:
```
{Series} v01.cbz
{Series} v02.cbz
```

**Observed in Actual Collection**:
- `Mob Psycho 100 v08 (Digital).cbz` - Mylar format
- `Hells Paradise v01 (Digital).cbz` - Mylar format with (Digital) tag
- `v01.cbz` - stripped format (likely manual)

**Impact**: The suwayomi-organizer.sh and any Mylar post-processor will need to harmonize these formats. The topology doesn't address this.

**Recommendation**: Accept Mylar's default format for tankobon. Document the expected patterns:
```
# Mylar tankobon (accept as-is)
{Series} v{vol:02d} ({Year}).cbz
{Series} v{vol:02d} (Digital).cbz
{Series} v{vol:02d}.cbz

# Suwayomi chapters (normalize to)
{Series} c{chapter:04d}.cbz
```

#### 1.4 Non-English Content

**Weakness**: Topology assumes `[EN]` suffix but doesn't address:
- Raw Japanese (`[JP]`)
- Chinese scanlations (`[CN]`)
- Korean webtoons (`[KR]`)
- Fan translations from non-English sources

**Recommendation**: Add language tag convention:
```
{Series} ({Publisher}) [{Language}]/
```

Where `{Language}` is ISO 639-1 code or omitted for English default.

---

### 2. LIBRARY SEPARATION CRITIQUE

#### 2.1 Two Libraries = Two Entries Confusion

**Attack**: A user searching for "Chainsaw Man" will see:
- "Chainsaw Man (Viz)" in Manga (Collected)
- "Chainsaw Man" in Manga (Weekly)

This IS confusing for casual users who just want to read.

**Counter-Attack (Partial Defense)**:
- Power users understand the distinction
- Komga Collections can link them
- Different use cases justify separation

**Verdict**: WEAKNESS CONFIRMED. Mitigation: Auto-create Collections linking same series across libraries.

#### 2.2 Cross-Library Collections - Do They Actually Work?

**Research Findings** ([Komga Collections Docs](https://komga.org/docs/guides/collections/)):

> "Collections can include series from any library. By adding items in different libraries to collections, you can relate them to each other."

**Confirmed**: Cross-library Collections ARE supported in Komga 1.16.0 (January 2025).

**However**: Collections must be manually created or scripted. The topology doesn't specify:
1. Who creates the Collections?
2. What naming convention?
3. Automatic vs manual?

**Recommendation**: Add automation requirement:
```bash
# Auto-collection script pseudo-code
for series in Manga-Weekly/*; do
  series_name=$(basename "$series")
  matching_tankobon=$(find Comics -name "*${series_name}*" -type d)
  if [[ -n "$matching_tankobon" ]]; then
    komga_api_create_collection "$series_name (All Editions)" \
      --add-series "$series" \
      --add-series "$matching_tankobon"
  fi
done
```

#### 2.3 Single-Track Series Handling

**Weakness**: What about series that only exist in one track?

- **Weeklies-only**: Series not licensed (e.g., many Korean manhwa)
- **Tankobon-only**: Completed series not being scanlated

**Current Handling**: Implicitly works (series exists in one library only)

**But**: User might not know which library to check. If searching in wrong library, series appears missing.

**Recommendation**: Add to documentation that Komga's global search works across all libraries. Users should use search, not browse.

#### 2.4 Reading List Across Both

**Attack**: User wants ONE reading list spanning both tankobon and chapters.

**Research**: Komga Read Lists are independent of Collections and can include books from any library.

**Verdict**: WORKS. Read Lists solve this use case. Document this capability.

---

### 3. AUTOMATION INTEGRATION HOLES

#### 3.1 Suwayomi Extension Naming Variations

**Critical Weakness**: suwayomi-organizer.sh assumes consistent Suwayomi output.

Per [Suwayomi Issue #768](https://github.com/Suwayomi/Suwayomi-Server/issues/768) and [Issue #311](https://github.com/Suwayomi/Tachidesk-Sorayomi/issues/311):

> "Inconsistent naming schema on providers it didn't work for all"
> "The name of the scanlator comes after the chapter number or chapter titles"

**Observed Suwayomi patterns**:
```
# MangaDex format
Source/Series Name/Chapter 1/

# Other extensions
Source/Series Name/Ch. 001/
Source/Series Name/Chapter 001: Title Here/
Source/Series Name/Vol.1 Ch.1/
Source/Series Name/[Scanlator] Chapter 1/
```

**suwayomi-organizer.sh Analysis** (lines 153-165):
```bash
# Extract chapter number for proper naming
# Suwayomi uses: "Chapter X", "Chapter X.5", "Ch. X", etc.
local chapter_num=""
if [[ "$chapter_name" =~ [Cc]h(apter)?[[:space:]]*([0-9]+(\.[0-9]+)?) ]]; then
    chapter_num="${BASH_REMATCH[2]}"
else
    # Fallback: use chapter_name as-is
    chapter_num="$chapter_name"
fi
```

**Weaknesses**:
1. Doesn't handle `Vol.1 Ch.1` format (would extract just chapter, lose volume)
2. Doesn't handle titled chapters `Chapter 001: Title Here`
3. Doesn't strip scanlator tags `[Scanlator]`
4. 3-digit padding in script (`%03d`) contradicts 4-digit in topology

**Recommendation**: Update suwayomi-organizer.sh regex:
```bash
# Handle more patterns
if [[ "$chapter_name" =~ [Cc]h(apter)?\.?[[:space:]]*([0-9]+(\.[0-9]+)?)[[:space:]]*(:|-)? ]]; then
    chapter_num="${BASH_REMATCH[2]}"
elif [[ "$chapter_name" =~ [Vv]ol\.?[0-9]+[[:space:]]+[Cc]h(apter)?\.?[[:space:]]*([0-9]+(\.[0-9]+)?) ]]; then
    chapter_num="${BASH_REMATCH[2]}"  # Extract chapter from Vol.X Ch.Y
else
    chapter_num="$chapter_name"
fi

# Pad to 4 digits (not 3)
if [[ "$chapter_num" =~ ^[0-9]+$ ]]; then
    chapter_num=$(printf "%04d" "$chapter_num")
fi
```

#### 3.2 Mylar Post-Processing

**Gap Identified**: No post-processor for Mylar downloads.

Current flow:
```
Mylar -> Prowlarr -> SABnzbd -> /downloads/
                                    |
                                    v
                            ??? (manual move)
                                    |
                                    v
                              /comics/
```

**Needed**: Script to:
1. Detect completed Mylar downloads
2. Extract/organize to Comics/ with proper naming
3. Trigger Komga rescan

#### 3.3 Failed/Partial Downloads

**Weakness**: No handling specified for:
- Incomplete chapters (< 3 images, as checked in organizer)
- Corrupt CBZ files
- Download retries

**Mitigation in organizer** (lines 130-135):
```bash
if [[ $image_count -lt 3 ]]; then
    debug "Incomplete chapter (only $image_count images): $chapter_dir"
    return 0
fi
```

**But**: This silently skips. No alerting, no retry queue.

**Recommendation**: Add logging to a failed-chapters.log and periodic retry logic.

---

### 4. KOMF METADATA IMPLICATIONS

#### 4.1 Chapter Naming vs Metadata Matching

**Research** ([Komf GitHub](https://github.com/Snd-R/komf)):

> "Fetches metadata and thumbnails for your digital comic book library"
> "Automatically pick up added series and update their metadata"

**Weakness**: Komf matches at SERIES level, not chapter level. The `c0001.cbz` naming won't confuse Komf because:
1. Komf reads the series folder name
2. Individual file naming doesn't affect matching
3. Komf looks up series on MangaUpdates, AniList, etc.

**Verdict**: Chapter naming is TRANSPARENT to Komf. No issue.

#### 4.2 Separate Libraries and Komf

**Question**: Does Komf handle multiple Komga libraries?

**Research**: Yes. Komf configuration specifies which libraries to process. Can run different providers per library.

**Recommendation**: Configure Komf with:
- Manga (Collected): Prioritize ComicVine, MangaUpdates
- Manga (Weekly): Prioritize MangaDex, AniList (scanlation-aware)

#### 4.3 Metadata Pollution Between Editions

**Concern**: What if Komf applies wrong metadata (e.g., Japanese volume count to English release)?

**Mitigation**:
- Use `aggregateMetadata: true` to merge from multiple sources
- English publishers (Viz, Kodansha) have ComicVine entries
- Japanese scanlations use MangaDex/AniList

**Verdict**: Configurable. Not a blocking issue.

---

### 5. SCALE AND MAINTENANCE

#### 5.1 Migration Reality Check

**Current State** (from MANGA_INTEGRATION_STATUS.md):
- 17,200 files
- 97% non-compliant naming
- 79 series
- 311 `__Panels` directories

**Observed Actual State**:
```
Comics/
  Chainsaw Man (Viz) [EN]/
    1. Volumes/          <- BREAKS KOMGA (becomes separate series)
    2. Chapters/         <- BREAKS KOMGA
    3. Extras/           <- BREAKS KOMGA
    __Panels/            <- Needs cleanup
```

**Migration Effort**:
1. Flatten nested directories: HIGH effort, must relocate ~17K files
2. Standardize naming: MEDIUM effort, scripted renaming
3. Remove `__Panels`: LOW effort, `find -name __Panels -exec rm -rf {} +`
4. Dedupe (Viz vs Year folders): HIGH effort, manual decisions needed

**Recommendation**:
- Phase 1: Remove `__Panels` and obvious cruft (1 hour)
- Phase 2: Flatten directories with script (4-8 hours)
- Phase 3: Dedupe redundant series (requires manual review)

#### 5.2 Ongoing Acquisition During Migration

**Critical Question**: What happens when Mylar downloads new content during migration?

**Risk**: New downloads go to old structure, undoing migration work.

**Mitigation**:
1. Pause Mylar during migration
2. Configure Mylar to use new naming before resuming
3. Or: Migrate in-place, new downloads will be compliant, old content catches up gradually

**Recommendation**: Option 3 is safest. Accept mixed state temporarily.

#### 5.3 The 82 Mylar Series

**Concern**: Mylar is already monitoring 82 series. Changing folder structure breaks Mylar tracking.

**Mylar Behavior**: If series folder moves, Mylar loses track. Must re-add or update paths.

**Mitigation**:
- Document Mylar path update procedure
- Or: Keep Mylar naming as-is, don't force migration

---

### 6. ALTERNATIVE APPROACHES EVALUATED

#### 6.1 Single Library with Smart Naming

**Proposal**: Instead of two libraries, use one with prefixes:
```
Comics/
  Chainsaw Man/
    [VOL] Chainsaw Man v01.cbz
    [CHP] Chainsaw Man c0125.cbz
```

**Pros**:
- One search location
- No cross-library collection needed

**Cons**:
- Komga can't filter by prefix
- Mixed sort order within series
- Prefix pollution in UI

**Verdict**: REJECTED. Two-library approach is cleaner.

#### 6.2 Komga Read Lists Instead of Collections

**Research**: Read Lists are for specific reading order (like a playlist). Collections are for grouping related series.

**Use Case Fit**:
- Collections: "All Chainsaw Man editions"
- Read Lists: "My Weekly Reading Queue"

**Verdict**: Both have roles. Not alternatives.

#### 6.3 Kavita Instead of Komga

**Research** ([Kavita vs Komga](https://www.bookrunch.com/comparison/Kavita_vs_Komga/)):

Kavita advantages:
- Better novel/light novel support
- Built-in chapter-level tracking
- More flexible metadata

Komga advantages:
- Better OPDS support (mobile readers)
- More mature API
- Komf integration established

**Consideration**: User already has Kavita running (port 5000 in docker-compose). Could use Kavita for weeklies, Komga for tankobon.

**Verdict**: Possible but adds complexity. Stick with Komga for now.

#### 6.4 Accept Mixing, Rely on Komga Sorting

**Proposal**: Don't migrate. Let Komga sort naturally.

**Problem**: Current nested structure (`1. Volumes/`, `2. Chapters/`) BREAKS Komga. Each subfolder becomes a series.

**Verdict**: REJECTED. Migration is required to fix Komga compatibility.

---

## Synthesis: Refined Recommendations

### APPROVED (No Changes Needed)

1. Two-library architecture (Manga Collected vs Manga Weekly)
2. 4-digit chapter padding (`c0001.cbz`)
3. Cross-library Collections for linking
4. Suwayomi staging directory approach

### MODIFICATIONS REQUIRED

| Issue | Current | Recommended Change |
|-------|---------|-------------------|
| One-shots | Not specified | Add `c0000.cbz` convention |
| Specials | Not specified | Add `SP{xx}.cbz` convention |
| Colored editions | Not specified | Add `[Colored]` tag option |
| Mylar naming | Forces custom format | Accept Mylar default format |
| Collection automation | Manual | Script auto-collection creation |
| suwayomi-organizer.sh | 3-digit padding | Fix to 4-digit, improve regex |
| Failed downloads | Silent skip | Add logging and retry queue |
| Migration plan | Vague | Add phased approach with Mylar guidance |

### ADDITIONS REQUIRED

1. **Komf Configuration Guide**: Which providers for which library
2. **Mylar Path Migration Script**: Update series paths after migration
3. **Collection Sync Script**: Auto-create cross-library collections
4. **Failed Download Handler**: Logging and retry for incomplete chapters
5. **Language Tag Convention**: For non-English content

---

## Implementation Priority

### Phase 1: Critical Fixes (Before Any Migration)

1. Update suwayomi-organizer.sh to 4-digit padding
2. Add edge case naming conventions to topology doc
3. Create Mylar post-processor script

### Phase 2: Migration Prep

1. Create migration script for flattening directories
2. Test migration on one series (Chainsaw Man)
3. Document Mylar re-pathing procedure

### Phase 3: Automation

1. Collection sync script
2. Komf provider configuration
3. Failed download logging

---

## Confidence Assessment

| Recommendation | Confidence | Reasoning |
|----------------|------------|-----------|
| Two-library approach | HIGH | Research confirms Komga supports, users validate pattern |
| 4-digit padding | HIGH | Long-running series exist, minimal cost |
| Edge case naming | MEDIUM | Based on Daiz scheme, needs validation |
| Mylar acceptance | HIGH | Fighting Mylar naming is tech debt |
| Collection automation | MEDIUM | API available, implementation effort TBD |
| Migration phasing | MEDIUM | Depends on actual file state complexity |

---

## References

- [Komga Libraries Docs](https://komga.org/docs/guides/libraries/)
- [Komga Collections Docs](https://komga.org/docs/guides/collections/)
- [Komga One-Shots Docs](https://komga.org/docs/guides/oneshots/)
- [Mylar3 File Formats Wiki](https://github.com/mylar3/mylar3/wiki/Folder-and-File-formats)
- [Daiz Manga Naming Scheme](https://github.com/Daiz/manga-naming-scheme)
- [Komf GitHub](https://github.com/Snd-R/komf)
- [Kavita Scanner Docs](https://wiki.kavitareader.com/guides/scanner/manga/)
- [Suwayomi CBZ Naming Issue #768](https://github.com/Suwayomi/Suwayomi-Server/issues/768)
- [Komga Discussion #1295 - Directory Structure](https://github.com/gotson/komga/discussions/1295)

---

## Changelog

| Date | Version | Changes |
|------|---------|---------|
| 2025-12-29 | 1.0.0 | Initial adversarial review complete |

---

*This document serves as the adversarial review record. Apply modifications to MANGA_COLLECTION_TOPOLOGY.md based on approved recommendations.*
