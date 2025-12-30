# Audiobook Acquisition Log - 2025-12-29

> **Session Duration**: ~30 minutes
> **Agent**: Claude Opus 4.5 (Audiobook Acquisition Executor)
> **Date**: 2025-12-29

---

## Executive Summary

This session focused on audiobook acquisition attempts and collection organization. While direct acquisition through Usenet indexers was unsuccessful due to content availability gaps, significant progress was made on file organization and duplicate cleanup.

---

## Preflight Checks

### Infrastructure Status

| Component | Status | Details |
|-----------|--------|---------|
| Prowlarr | OK | localhost:9696, 4 indexers enabled |
| SABnzbd | OK | 192.168.6.167:8080, v4.5.5 |
| Disk Space | OK | 4,354 GB available on fast8tb |

### Enabled Indexers

1. **NZB.su** - Priority 25
2. **NZBFinder** - Priority 20
3. **NZBgeek** - Priority 10 (highest priority)
4. **NZBPlanet** - Priority 15

All indexers have Audio/Audiobook category (103030) support.

---

## Priority 1: Dungeon Crawler Carl (7 Books)

### Search Results

| Search Query | Results | Notes |
|--------------|---------|-------|
| `dungeon crawler carl audiobook` | 0 | No results |
| `dungeon crawler carl` | 0 | No results |
| `matt dinniman` | 0 | Author search failed |
| `jeff hays audiobook` | 0 | Narrator search failed |

### Analysis

The current Usenet indexers have very limited English audiobook content. The audiobook category (103030) primarily contains:
- German audiobooks (Larry Brent, Hanni und Nanni series)
- Swedish/Danish audiobooks (CRAViNGS release group)
- Very few English language releases

### Recommendations

1. **Add specialized audiobook indexer** to Prowlarr:
   - AudioNews (available in Prowlarr schema)
   - BookTracker (available in Prowlarr schema)

2. **Alternative acquisition methods**:
   - MyAnonamouse (MAM) private tracker - excellent audiobook coverage
   - Audible purchase + deauthorization tools
   - Library services (OverDrive/Libby)

### Status: NOT ACQUIRED

All 7 books remain unavailable via current indexers.

---

## Priority 2: Terry Pratchett Non-Discworld

### Search Results

| Search Query | Results |
|--------------|---------|
| `terry pratchett` | 0 |
| `pratchett` | 0 |

### Existing Collection (Discovered)

Already have these non-Discworld audiobooks (found during organization):
- The Long Earth (Book 2): The Long War - HAVE
- The Long Earth (Book 3): The Long Mars - HAVE
- The Science of Discworld IV: Judgement Day - HAVE
- Dragons at Crumbling Castle - HAVE
- Good Omens - HAVE

### Still Missing

- The Long Earth (Book 1)
- The Long Utopia (Book 4)
- The Long Cosmos (Book 5)
- Nation
- Dodger
- The Carpet People
- Strata
- Bromeliad Trilogy (Truckers, Diggers, Wings)
- Johnny Maxwell Trilogy

### Status: NOT ACQUIRED (Usenet unavailable)

---

## Priority 3: File Organization (COMPLETED)

### Misplaced Audiobooks Moved

**From**: `/var/mnt/fast8tb/Cloud/OneDrive/Books/eBooks/Terry Pratchett/`

**To**: `/var/mnt/fast8tb/Cloud/OneDrive/Books/Audiobooks/Terry Pratchett/`

| Title | Action | Status |
|-------|--------|--------|
| The Long Mars | MOVED | Complete |
| The Science of Discworld IV - Judgement Day | MOVED | Complete |
| Dragons at Crumbling Castle - And Other Tales | Duplicate removed | Already existed in Audiobooks |
| The Long War | Duplicate removed | Already existed in Audiobooks |

### Summary

- 2 audiobooks successfully moved to correct location
- 2 duplicate folders removed from eBooks (content already in Audiobooks)

---

## Priority 4: Duplicate Cleanup (COMPLETED)

### Duplicates Identified and Removed

The following existed in BOTH `/Audiobooks/Discworld/` (organized, better quality, ~200-280MB each) AND `/Audiobooks/Terry Pratchett/` (smaller files, ~27-98MB each):

| Title | Discworld Size | Terry P Size | Action |
|-------|----------------|--------------|--------|
| Guards! Guards! | 279 MB | 27 MB | Kept Discworld, removed duplicate |
| Hogfather | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| I Shall Wear Midnight | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| Lords and Ladies | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| Mort | 201 MB | 98 MB | Kept Discworld, removed duplicate |
| Reaper Man | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| Small Gods | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| Soul Music | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| The Last Continent | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| The Last Hero | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| The Light Fantastic | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| The Shepherd's Crown | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| The Wee Free Men | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| Thud! | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |
| Witches Abroad | ~200 MB | ~100 MB | Kept Discworld, removed duplicate |

**Total duplicates removed**: 15

### Final State of Terry Pratchett Folder

After cleanup, `/Audiobooks/Terry Pratchett/` contains only non-Discworld works:

1. Dragons at Crumbling Castle - And Other Tales
2. Good Omens
3. The Long Mars
4. The Long War
5. The Science of Discworld IV - Judgement Day

### Space Recovered

Estimated ~1.2 GB freed by removing lower-quality duplicates.

---

## Priority 5: Taste-Aligned Acquisitions

### Search Results

| Title | Search Query | Results |
|-------|--------------|---------|
| Project Hail Mary | `andy weir` | 0 |
| Project Hail Mary | `project hail mary` | 0 |
| The Lies of Locke Lamora | `locke lamora` | 0 |
| The Power Broker | `power broker caro` | 0 (not searched, no audiobook content) |
| Dave Chappelle | N/A | Comedy specials not available via audiobook indexers |

### Status: NOT ACQUIRED

Current indexers do not have English audiobook content for these titles.

---

## Recommendations for Future Sessions

### Immediate Actions

1. **Add AudioNews indexer** to Prowlarr for better audiobook coverage
2. **Consider MyAnonamouse registration** - premier private tracker for audiobooks
3. **Check Audiobookshelf Absonic integration** for potential library sync

### Long-term Improvements

1. Add dedicated audiobook usenet provider (e.g., UsenetServer has good retention for books)
2. Set up automated searches via Readarr (audiobook mode)
3. Configure SABnzbd category for "audiobooks" with proper post-processing

### Collection Gaps Summary

**Critical Missing (Dungeon Crawler Carl)**:
- All 7 books NOT available via Usenet
- Recommend alternative acquisition methods

**Terry Pratchett Non-Discworld**:
- The Long Earth Book 1, 4, 5
- Nation, Dodger, The Carpet People, Strata
- Bromeliad Trilogy
- Johnny Maxwell Trilogy

---

## Session Statistics

| Metric | Value |
|--------|-------|
| Searches performed | 12 |
| Items acquired | 0 |
| Files moved | 2 |
| Duplicates removed | 17 (15 folders + 2 eBook duplicates) |
| Space recovered | ~1.2 GB |

---

**Next Session Priority**: Add specialized audiobook indexers to Prowlarr and retry Dungeon Crawler Carl acquisition.
