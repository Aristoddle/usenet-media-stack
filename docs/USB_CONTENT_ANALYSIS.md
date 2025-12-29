# USB Drive Content Analysis

**Date**: 2025-12-29 (02:50 EST)
**Purpose**: Document legacy content on USB drives for potential import into media stack

---

## Executive Summary

Five USB drives discovered with ~3.5TB of valuable media content:
- **555 movies** ready for Radarr import
- **64 anime series** ready for Sonarr import
- **235 music artists** (129GB) for Lidarr bootstrap
- **Audiobooks, eBooks, Comics** for Bookshelf

**Architecture Decision**: Do NOT integrate USB drives into MergerFS pool. Use as temporary "inform & import" source, then repurpose drives.

---

## Drive Inventory

| Drive | Model | Size | Used | Mount Point |
|-------|-------|------|------|-------------|
| Slow_3TB_HD | WD My Passport | 2.8TB | 545GB (20%) | `/run/media/deck/Slow_3TB_HD` |
| Slow_4TB_2 | SanDisk Extreme | 3.7TB | 1.7TB (45%) | `/run/media/deck/Slow_4TB_2` |
| Slow_2TB_1 | SanDisk Extreme | 1.9TB | 1.5TB (78%) | `/run/media/deck/Slow_2TB_1` |
| Slow_2TB_2 | SanDisk Extreme | 1.9TB | 855GB (46%) | `/run/media/deck/Slow_2TB_2` |
| JoeTerabyte | DSWC1M NVMe | 954GB | 465GB (49%) | `/run/media/deck/JoeTerabyte` |

---

## Content Analysis

### Slow_3TB_HD (Spinning Disk)

**Type**: WD My Passport USB 3.0 (5400 RPM)
**Best Use**: Music library (sequential reads, not latency-sensitive)

#### Music Collection (129GB, 235 artists)
```
/run/media/deck/Slow_3TB_HD/Music/
├── 311/
├── ABBA/
├── Action Bronson/
├── Alabama Shakes/
├── Alanis Morissette/
├── alt-J/
├── Anderson .Paak/
├── Arctic Monkeys/
├── Aretha Franklin/
├── Audioslave/
├── Bee Gees/
├── Billie Eilish/
... (235 total artist folders)
```

**Assessment**: Well-organized by artist. Suitable for Lidarr import.

#### Bookz Collection
```
/run/media/deck/Slow_3TB_HD/Bookz/
├── Audiobooks/          # Audio content
├── Audiobooks 2/        # More audio content
├── Calibre/             # Calibre library export
├── Comics/              # Comics (Mylar?)
├── Default/             # Unsorted
├── eBooks/              # Digital books
├── Readarr/             # Previous Readarr library!
├── Real Books/          # Physical book scans?
├── Spoken/              # Audiobooks
├── J R R Tolkien - */   # Individual Tolkien works
├── Terry Pratchett - */ # Individual Pratchett works
```

**Assessment**: Mixed organization. The `Readarr/` folder may have usable import data.

---

### Slow_4TB_2 (SSD)

**Type**: SanDisk Extreme Portable SSD
**Content**: Movies (1.7TB, 555 films)

#### Sample Movies
```
/run/media/deck/Slow_4TB_2/Movies/
├── 2001 A Space Odyssey (1968)/
├── 3 Idiots (2009)/
├── A Clockwork Orange (1971)/
├── Akira (1988)/
├── Alice Doesn't Live Here Anymore (1974)/
├── Ant-Man (2015)/
├── Apocalypse Now (1979)/
├── Avengers Age of Ultron (2015)/
├── Barbie (2023)/
├── Batman Begins (2005)/
├── Being John Malkovich (1999)/
├── Birdman or (The Unexpected Virtue of Ignorance) (2014)/
├── Blazing Saddles (1974)/
... (555 total films)
```

**Naming Convention**: `Title (Year)/` - clean Radarr-compatible naming
**Quality**: Mixed (likely 1080p based on era of collection)

**Assessment**: Excellent for Radarr import. Clean naming will enable automatic matching.

---

### Slow_2TB_2 (SSD)

**Type**: SanDisk Extreme Portable SSD
**Content**: Anime (854GB, 64 series)

#### Sample Anime
```
/run/media/deck/Slow_2TB_2/Anime/
├── Assassination Classroom/
├── Astro Boy/
├── Attack on Titan/
├── Bakuman/
├── Bleach/
├── Bocchi the Rock!/
├── Chainsaw Man/
├── Code Geass - Lelouch of the Rebellion/
├── Cowboy Bebop/
├── Cyberpunk - Edgerunners/
├── Demon Slayer - Kimetsu no Yaiba/
├── Dragon Ball/
├── FLCL/
├── Fullmetal Alchemist - Brotherhood/
├── Gintama/
├── Great Teacher Onizuka/
├── Gurren Lagann/
... (64 total series)
```

**Assessment**: Great anime collection. May have overlap with existing `anime-tv/` pool content.

---

### Slow_2TB_1 (SSD)

**Type**: SanDisk Extreme Portable SSD
**Content**: Emulation/Gaming (NOT for media stack)

```
/run/media/deck/Slow_2TB_1/
├── Batocera_Share_Bak/   # Batocera emulation backup
├── Emulation/            # EmuDeck content
├── ROMS_TO_SORT/         # Unsorted ROMs
```

**Assessment**: Keep separate from media stack. This is EmuDeck/gaming content.

---

### JoeTerabyte (NVMe)

**Type**: External NVMe enclosure
**Content**: Mostly empty/system junk

```
/run/media/deck/JoeTerabyte/
├── $RECYCLE.BIN/
├── System Volume Information/
├── .Spotlight-V100/
├── .fseventsd/
```

**Assessment**: Wipe and repurpose. Fast NVMe could serve as:
- Tdarr scratch/temp drive
- Transcode cache
- Fast transfer staging area

---

## Deduplication Analysis

### Movies: USB vs Pool

**Pool movies**: 665 films
**USB movies**: 555 films

**Naming Difference**:
- Pool: Release names (`2001 A Space Odyssey 1968 1080p BDRip DDP5 1 x265 Vialle`)
- USB: Clean names (`2001 A Space Odyssey (1968)`)

**Strategy**:
1. Scan USB titles through Radarr API to identify matches
2. Compare quality (4K pool vs likely 1080p USB)
3. Only import USB content not already in pool OR if USB quality is better

### Anime: USB vs Pool

**Pool anime-tv**: 75 series
**USB anime**: 64 series

**Potential Overlap**: High - many common titles (Bleach, Attack on Titan, etc.)

**Strategy**:
1. Generate series lists from both sources
2. Compare TheTVDB/AniDB IDs if available
3. Check episode coverage - USB may have episodes pool lacks

---

## Import Action Plan

### Phase 1: Music → Lidarr (PRIORITY)

Lidarr is not currently configured. USB music provides bootstrap opportunity.

1. Add Lidarr container to docker-compose.yml
2. Configure with pool music directory as root
3. Import 235 artists from USB
4. Let Lidarr upgrade to better releases over time

**Estimated Time**: 2-4 hours for import + overnight for metadata

### Phase 2: Movies → Radarr

1. Create script to scan USB movies and query Radarr API
2. Identify movies not in Radarr database
3. Import unique titles OR upgrade candidates
4. Copy files to pool, add to Radarr

**Tool Needed**: `tools/usb-movie-import.sh`

### Phase 3: Anime → Sonarr

1. List anime series on USB
2. Cross-reference with existing anime-tv pool
3. Import missing series
4. Check episode coverage for existing series

**Tool Needed**: `tools/usb-anime-import.sh`

### Phase 4: Books → Bookshelf

1. Migrate Readarr to Bookshelf (script exists)
2. Import USB Bookz content
3. Organize Calibre/eBooks/Audiobooks

---

## Commands for Analysis

```bash
# List all USB movies
ls "/run/media/deck/Slow_4TB_2/Movies/" | sort > /tmp/usb_movies.txt

# List all pool movies
ls /var/mnt/pool/movies/ | sort > /tmp/pool_movies.txt

# List USB anime
ls "/run/media/deck/Slow_2TB_2/Anime/" | sort > /tmp/usb_anime.txt

# List pool anime
ls /var/mnt/pool/anime-tv/ | sort > /tmp/pool_anime.txt

# Count music artists
ls "/run/media/deck/Slow_3TB_HD/Music/" | wc -l

# Check USB drive health
sudo smartctl -a /dev/sde  # Slow_3TB_HD spinning disk
```

---

## Risk Assessment

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| USB disconnect during copy | Medium | Use rsync with --partial for resumable transfers |
| File corruption on old drives | Low | Verify checksums after copy |
| Naming conflicts during import | Medium | Use *arr API for matching, manual review flagged items |
| Pool space exhaustion | Low | 11TB free, importing ~3TB content |

---

## Related Documentation

- [SESSION_STATE.md](../SESSION_STATE.md) - Current session state
- [STRATEGIC_ROADMAP.md](./STRATEGIC_ROADMAP.md) - Overall priorities
- [docs/decisions/2025-12-29-stack-health-audit.md](./decisions/2025-12-29-stack-health-audit.md) - Readarr retirement

---

## Changelog

| Date | Author | Changes |
|------|--------|---------|
| 2025-12-29 02:50 | Claude | Initial analysis and documentation |
