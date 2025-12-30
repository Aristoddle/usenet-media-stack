# Books & Audiobooks Acquisition Plan

> **Purpose**: Prioritized acquisition list for books, audiobooks, and comics enrichment.
>
> **Last Updated**: 2025-12-29
> **Version**: 1.1.0 (Post-acquisition session)

---

## Collection Summary

### Current Inventory

| Category | Count | Size | Serving App |
|----------|-------|------|-------------|
| **Comics/Manga** | 162 series | 718 GB | Komga (port 8081) |
| **eBooks** | 127 EPUBs | 4.7 GB | Kavita (port 5000) |
| **Audiobooks** | ~100 titles (1,537 files) | 25 GB | Audiobookshelf (port 13378) |

### Collection Strengths

- **Discworld**: COMPLETE (all 41 novels in audiobook format)
- **Manga**: Excellent coverage of major Shonen Jump titles
- **Terry Pratchett eBooks**: Extensive collection (40+ titles)
- **Non-fiction audiobooks**: Strong biography collection (Chernow, Isaacson)

---

## Priority 1: Dungeon Crawler Carl (MISSING - HIGH PRIORITY)

**Status**: NOT IN COLLECTION (Usenet indexers lack content - see ACQUISITION_LOG_2025-12-29.md)

**Series Details**:
- Author: Matt Dinniman
- Genre: LitRPG, Progression Fantasy
- Narrator: Jeff Hays (Soundbooth Theater full-cast production)
- Total Books: 7 published (Book 8 expected 2026)

| Book | Title | Year | Status |
|------|-------|------|--------|
| 1 | Dungeon Crawler Carl | 2020 | MISSING |
| 2 | Carl's Doomsday Scenario | 2020 | MISSING |
| 3 | The Dungeon Anarchist's Cookbook | 2021 | MISSING |
| 4 | The Gate of the Feral Gods | 2021 | MISSING |
| 5 | The Hunting Grounds | 2022 | MISSING |
| 6 | The Eye of the Bedlam Bride | 2023 | MISSING |
| 7 | The Butcher's Masquerade | 2024 | MISSING |

**Why Priority**:
- Highly acclaimed LitRPG series (4.7+ on Audible)
- Jeff Hays' full-cast production is legendary
- Matches user taste: dark humor, anti-authoritarian, maximalist craft
- Soundbooth Theater's production quality rivals audio drama

**Acquisition Strategy**:
1. ~~Usenet via Prowlarr -> SABnzbd (category: audiobooks)~~ FAILED: No results on NZBgeek, NZBFinder, NZB.su, NZBPlanet
2. Check availability on MyAnonamouse (if user has access) - RECOMMENDED NEXT STEP
3. Consider adding AudioNews/BookTracker indexers to Prowlarr
4. Document sources for future reference

---

## Priority 2: Terry Pratchett Non-Discworld Works

**Discworld Status**: COMPLETE (41/41 audiobooks)

**Non-Discworld Gaps** (audiobook format):

| Title | Type | Status | Notes |
|-------|------|--------|-------|
| The Long Earth (Book 1) | Audiobook | MISSING | Co-authored with Stephen Baxter |
| The Long War (Book 2) | Audiobook | HAVE | Moved to Audiobooks folder (2025-12-29) |
| The Long Mars (Book 3) | Audiobook | HAVE | Moved to Audiobooks folder (2025-12-29) |
| The Long Utopia (Book 4) | Audiobook | MISSING | Only have EPUB |
| The Long Cosmos (Book 5) | Audiobook | MISSING | Only have EPUB |
| Science of Discworld IV | Audiobook | HAVE | Moved to Audiobooks folder (2025-12-29) |
| Dragons at Crumbling Castle | Audiobook | HAVE | In Audiobooks folder |
| Good Omens | Audiobook | HAVE | In Audiobooks folder |
| Nation | Audiobook | MISSING | Only have EPUB |
| Dodger | Audiobook | MISSING | Only have EPUB |
| The Carpet People | Audiobook | MISSING | Only have EPUB |
| Strata | Audiobook | MISSING | Only have EPUB |

**Bromeliad Trilogy (Nomes)**:
- Truckers: MISSING
- Diggers: Have EPUB only
- Wings: Have EPUB only

**Johnny Maxwell Trilogy**:
- Only You Can Save Mankind: MISSING
- Johnny and the Dead: MISSING
- Johnny and the Bomb: Have EPUB only

**Preferred Narrators**:
- Stephen Briggs (most Discworld)
- Nigel Planer (early Discworld)
- Tony Robinson (Discworld)

---

## Priority 3: Organization Issues - RESOLVED (2025-12-29)

### Files in Wrong Location - FIXED

~~The following audiobook files are incorrectly stored in the eBooks folder:~~

**COMPLETED**: All misplaced audiobooks have been moved to correct locations:

| Item | Action | Date |
|------|--------|------|
| The Long Mars | Moved to Audiobooks | 2025-12-29 |
| The Science of Discworld IV | Moved to Audiobooks | 2025-12-29 |
| Dragons at Crumbling Castle | Duplicate removed (already in Audiobooks) | 2025-12-29 |
| The Long War | Duplicate removed (already in Audiobooks) | 2025-12-29 |

### Duplicate Terry Pratchett Audiobooks - CLEANED UP

~~The following exist in BOTH `/Audiobooks/Discworld/` AND `/Audiobooks/Terry Pratchett/`:~~

**COMPLETED**: All 15 duplicates removed from Terry Pratchett folder. Kept higher-quality versions in Discworld folder (with Book XX numbering).

**Duplicates removed** (2025-12-29):
- Guards! Guards!, Hogfather, I Shall Wear Midnight, Lords and Ladies, Mort
- Reaper Man, Small Gods, Soul Music, The Last Continent, The Last Hero
- The Light Fantastic, The Shepherd's Crown, The Wee Free Men, Thud!, Witches Abroad

**Current Terry Pratchett folder** (non-Discworld only):
1. Dragons at Crumbling Castle - And Other Tales
2. Good Omens
3. The Long Mars
4. The Long War
5. The Science of Discworld IV - Judgement Day

**Space recovered**: ~1.2 GB

---

## Priority 4: Taste-Aligned Audiobook Acquisitions

Based on USER_TASTE_PROFILE.md analysis:

### Stand-Up Comedy (Audio-First Core)

| Title | Performer | Priority | Status |
|-------|-----------|----------|--------|
| Dave Chappelle specials (all) | Chappelle | HIGH | MISSING |
| Richard Pryor: Live in Concert | Pryor | HIGH | MISSING |
| George Carlin HBO specials | Carlin | HIGH | MISSING |
| Eddie Murphy: Raw | Murphy | MEDIUM | MISSING |
| Bill Burr specials | Burr | MEDIUM | MISSING |

### Biography/History (Matching Existing Collection)

| Title | Author | Priority | Status |
|-------|--------|----------|--------|
| The Power Broker | Robert A. Caro | HIGH | Have EPUB only |
| Working | Robert A. Caro | MEDIUM | Have EPUB only |
| Benjamin Franklin | Walter Isaacson | MEDIUM | MISSING |
| Einstein | Walter Isaacson | MEDIUM | MISSING |
| Steve Jobs | Walter Isaacson | MEDIUM | Have Elon Musk only |

### Fiction Matching Taste Profile

| Title | Author | Genre | Why |
|-------|--------|-------|-----|
| The Lies of Locke Lamora | Scott Lynch | Fantasy | Heist fantasy, clever protagonist |
| Name of the Wind | Patrick Rothfuss | Fantasy | Master-class prose, Nick Podehl narration |
| Project Hail Mary | Andy Weir | Sci-Fi | Clever problem-solving, Ray Porter narration |
| The Martian | Andy Weir | Sci-Fi | If not already have |
| Piranesi | Susanna Clarke | Fantasy | Dreamlike, atmospheric |

---

## Priority 5: Manga/Comics Enrichment

### Komf Metadata Status

Verify the following have proper metadata from Komf:
- [ ] All Viz releases have ComicVine IDs
- [ ] Japanese series have MangaUpdates/AniList metadata
- [ ] Cover images are high quality

### Missing High-Priority Manga

Based on taste profile gaps:

| Title | Publisher | Status | Priority |
|-------|-----------|--------|----------|
| Kingdom | Viz | MISSING | HIGH |
| Parasyte | Kodansha | MISSING | HIGH |
| Real (Inoue) | Viz | MISSING | MEDIUM |

### Already Have But May Need Enrichment

- Billy Bat (2008) - Urasawa completionism
- Blame! Master Edition - Nihei architectural horror
- Death Note (2005) - Verify complete

---

## Acquisition Workflow

### Audiobooks

```
1. Search Prowlarr (localhost:9696) for title
2. Add to SABnzbd with category "audiobooks"
3. Download completes to /downloads/complete/audiobooks/
4. Move to appropriate folder:
   - Discworld: /Audiobooks/Discworld/Book XX - Title/
   - Other Pratchett: /Audiobooks/Terry Pratchett/Title/
   - Other: /Audiobooks/Author/Title/
5. Audiobookshelf auto-scans and imports metadata
```

### eBooks

```
1. Search Prowlarr for title
2. Add to SABnzbd with category "ebooks"
3. Download completes to /downloads/complete/ebooks/
4. Move to /eBooks/Author/Title/
5. Kavita auto-scans
```

### Manga/Comics

```
1. For ongoing: Mylar3 (localhost:8090) monitors and downloads
2. For complete series: Search Prowlarr manually
3. Add to SABnzbd with category "comics"
4. Download completes to /downloads/complete/comics/
5. Move to /Comics/Series Name (Publisher) [EN]/
6. Komga auto-scans
7. Trigger Komf enrichment if needed
```

---

## Acquisition Blocklist

**Never acquire**:
- Bo Burnham content (per taste profile)
- Generic isekai light novels
- AI-narrated audiobooks
- Abridged versions when unabridged exists

---

## Document Maintenance

**Update when**:
- Priority item acquired (mark as COMPLETE)
- New gaps identified
- Organization issues resolved
- User requests specific titles

**Changelog**:
- v1.1.0 (2025-12-29): Post-acquisition session updates
  - Priority 1 (Dungeon Crawler Carl): Marked Usenet unavailable, updated acquisition strategy
  - Priority 2 (Pratchett non-Discworld): Updated status for Long Earth Books 2-3, Science of Discworld IV
  - Priority 3 (Organization): COMPLETED - All file moves and duplicate cleanup done
  - See ACQUISITION_LOG_2025-12-29.md for full session details
- v1.0.0 (2025-12-29): Initial creation from deep audit
