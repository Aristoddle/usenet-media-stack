# Decision: ROM Acquisition Pipeline Architecture

**Date**: 2025-12-18
**Status**: Proposed
**Deciders**: deep-thinker agent, user
**Consulted**: Sequential thinking analysis (12 thoughts)

## Context

The user has a 1.3TB ROM collection across 247 system directories at `/var/mnt/fast8tb/Emudeck/Emulation/roms/`. The existing `emudeck-rom-manager` skill enforces directory structure but lacks:
1. Automated gap detection (missing/corrupt ROMs)
2. Usenet-first acquisition workflow (mirrors manga pipeline)
3. Hash verification against No-Intro/Redump databases

The manga pipeline has been hardened with correct Prowlarr API patterns. Usenet indexers support Console categories (1000 general, 101010 NDS, 101020 PSP, 101030 Wii, 101040 Switch, 101080 PS3, 101100 PS4).

## Decision

Implement a **layered skill architecture** with three components:

1. **`rom-acquisition-agent`** - Search/download orchestration (new)
2. **`rom-hash-verifier`** - DAT parsing and verification (new utility)
3. **`emudeck-rom-manager`** - Structure enforcement (existing, extend)

### Why Layered vs Unified

| Approach | Pros | Cons |
|----------|------|------|
| Single unified agent | One file, simpler | 247 systems = edge case explosion |
| Layered skills | Separation of concerns, reusable | More files, coordination |
| Per-system agents | Clean logic per system | Massive duplication (10+ agents) |

Layered approach mirrors the successful manga-acquisition pattern and allows independent testing of each component.

## Rationale

### Options Considered

#### Option A: Extend emudeck-rom-manager with Prowlarr

**Pros**:
- Single skill to maintain
- Already has Transmission fallback

**Cons**:
- Would grow to 1000+ lines
- Mixes concerns (structure vs acquisition vs verification)

**Estimated impact**: Medium complexity, low maintainability

#### Option B: Create rom-acquisition-agent (layered)

**Pros**:
- Clean separation: search/download vs verify vs organize
- Ports proven patterns from usenet-download-pipeline
- Each component testable independently

**Cons**:
- Three files instead of one
- Need to coordinate between skills

**Estimated impact**: Higher initial setup, better long-term maintainability

#### Option C: System-specific agents (switch-agent, psp-agent)

**Pros**:
- Perfect per-system customization
- No cross-system complexity

**Cons**:
- 10+ agents to maintain
- Duplicate 80% of code across agents

**Estimated impact**: Over-engineering, maintenance nightmare

### Why Option B Won

1. **Proven pattern**: Matches manga-acquisition structure
2. **Testable**: Can validate each component independently
3. **Extensible**: Easy to add mod/texture acquisition later
4. **Reusable**: rom-hash-verifier useful for collection audits

## Implementation Plan

### Phase 1: MVP (Day 1-2)

**Goal**: Search Prowlarr for ROMs, download to staging, manual verification

**Files to create**:

```
~/.claude/skills/rom-acquisition-agent/
  SKILL.md                    # Main skill (port from usenet-download-pipeline)
```

**Key functions**:
- `prowlarr_search_rom()` - Console category search
- `fetch_rom_nzb()` - NZB fetch with redirect handling
- `upload_rom_to_sab()` - SABnzbd upload with category `roms`
- `monitor_rom_download()` - Completion monitoring

**SABnzbd configuration**:
- New category: `roms`
- Download path: `/var/mnt/fast8tb/Local/downloads/sabnzbd/complete/roms`

### Phase 2: Hash Verification (Day 2-3)

**Goal**: Automated verification against No-Intro/Redump DATs

**Files to create**:

```
~/.claude/skills/rom-hash-verifier/
  SKILL.md                    # Verification skill
  scripts/
    dat-parser.py             # Parse No-Intro XML DATs
    verify-rom.sh             # Single ROM verification
```

**DAT sources**:
- No-Intro: https://datomatic.no-intro.org/
- Redump: http://redump.org/

**Key functions**:
- `parse_dat()` - Extract rom entries from DAT XML
- `verify_rom_hash()` - Compare file hash to DAT
- `generate_gap_report()` - List missing/corrupt ROMs

### Phase 3: Integration (Day 3-4)

**Goal**: Connected workflow from gap detection to verified acquisition

**Updates to emudeck-rom-manager**:
- Add `rom_verify_collection()` - Batch verification
- Add `rom_fill_gap()` - Acquire specific missing ROM

**Staging workflow**:
```
/staging/roms/
  pending/     # Downloaded, awaiting verification
  verified/    # Hash matches DAT, ready to replace
  rejected/    # Hash mismatch, investigate
```

### Phase 4: Future Enhancements

- Mod/texture/shader acquisition
- RomM/IGDB metadata integration
- Automated upgrade detection
- Multi-system gap reports

## Prowlarr Category Mapping

| Category Code | System | EmuDeck Folder |
|---------------|--------|----------------|
| 1000 | Console (general) | varies |
| 101010 | NDS | nds/ |
| 101020 | PSP | psp/ |
| 101030 | Wii | wii/ |
| 101040 | Switch | switch/ |
| 101080 | PS3 | ps3/ |
| 101100 | PS4 | ps4/ |

**Note**: PS2, GameCube, 3DS often appear under general 1000. Search strategy should try specific category first, then fall back to 1000 with title filter.

## Consequences

### Positive

- Clean separation of concerns (search, verify, organize)
- Reusable components for future automation
- Hash verification prevents bad ROM replacements
- Mirrors proven manga-acquisition pattern

### Negative

- Three skills to coordinate instead of one
- Initial setup more complex
- DAT files need periodic updates

### Neutral

- Staging directory adds storage overhead (~10-50GB typical)
- Learning curve for DAT format

## Validation

### E2E Test Case: NDS ROM

**Why NDS**:
1. Category 101010 exists in Prowlarr
2. Small file size (~30MB for popular games)
3. No-Intro DAT widely available
4. Known good hashes documented

**Test ROM**: "New Super Mario Bros (USA)"
- Expected size: ~30MB
- No-Intro name: `New Super Mario Bros. (USA, Europe).nds`
- Verifiable hash available

**Test Steps**:
1. `prowlarr_search_rom "New Super Mario Bros" 101010`
2. Fetch NZB, upload to SABnzbd
3. Wait for download completion
4. Verify SHA1 against No-Intro DAT
5. Move to staging/verified/
6. Replace in live collection (with backup)

### Acceptance Criteria

- [ ] Prowlarr search returns results for NDS test ROM
- [ ] NZB download + SABnzbd upload succeeds
- [ ] Downloaded ROM passes hash verification
- [ ] Staging workflow moves file correctly
- [ ] Live collection updated with verified ROM

### Rollback Plan

If acquisition corrupts collection:
1. Staging workflow keeps originals until verification passes
2. Backup of replaced ROMs in staging/replaced/
3. EmuDeck can rescan to restore metadata

## File Specifications

### rom-acquisition-agent/SKILL.md

```markdown
---
name: rom-acquisition-agent
description: Usenet-first ROM acquisition. Prowlarr Console categories (1000/101010/101020/etc) to SABnzbd staging. Hash-verify against No-Intro/Redump before replacing. Torrent fallback if Usenet misses.
---

# ROM Acquisition Agent

## Activation
- User requests ROM acquisition/upgrade
- Gap-fill workflow triggered
- Mentions: No-Intro, Redump, ROM upgrade, missing game

## Prowlarr Console Categories
| Code | System |
|------|--------|
| 1000 | General |
| 101010 | NDS |
| 101020 | PSP |
| 101030 | Wii |
| 101040 | Switch |

## Workflow
1. Search Prowlarr with Console category
2. Fetch NZB (follow redirects)
3. Upload to SABnzbd (category: roms)
4. Monitor completion
5. Stage in pending/
6. Verify hash against DAT
7. Move to verified/ or rejected/
8. Replace in collection (with backup)

## Key Functions
[see implementation below]
```

### rom-hash-verifier/SKILL.md

```markdown
---
name: rom-hash-verifier
description: Verify ROMs against No-Intro/Redump DATs. Parse XML DATs, compute hashes, generate gap reports. Supports CRC32 (fast) and SHA1 (thorough).
---

# ROM Hash Verifier

## Activation
- ROM verification request
- Collection audit
- Gap report generation

## DAT Sources
- No-Intro: datomatic.no-intro.org
- Redump: redump.org

## Verification Levels
1. Filename match (fast, inaccurate)
2. CRC32 (fast, good for cartridges)
3. SHA1 (thorough, required for disc images)

## Key Functions
[see implementation below]
```

## References

- Sequential thinking analysis: 12 thoughts documented
- Manga acquisition skill: `~/.claude/skills/manga-acquisition/SKILL.md`
- Usenet download pipeline: `~/.claude/skills/usenet-download-pipeline/SKILL.md`
- Existing emudeck-rom-manager: `~/.claude/skills/emudeck-rom-manager/SKILL.md`
- No-Intro DAT format: https://datomatic.no-intro.org/
