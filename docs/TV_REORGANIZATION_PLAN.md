# TV Folder Reorganization Plan

**Last Updated**: 2025-12-25
**Location**: /var/mnt/swap_drive/TV/ (backup during btrfs migration)
**Status**: Ready to execute after copy completes

---

## TL;DR

**Problem**: 2,326 episode folders at root level instead of proper `Series/Season/` structure.

**Solution**: Use Sonarr's Manual Import (already in stack) - no extra tools needed.

**Time**: ~4-8 hours spread over a few sessions.

---

## Current State

| Metric | Value |
|--------|-------|
| Total folders | 2,326 |
| Unique series | ~179 |
| Video files | 5,876 |
| Already structured | ~24 (1%) |
| Size | 3.5 TB |

### Top Series (by episode count)
- One Piece: 713+ episodes
- Doctor Who: 198+ (across 1963/2005/2023)
- Hunter x Hunter 2011: 116+
- It's Always Sunny: 120+
- Fist of the North Star: 85+

---

## The Sonarr Approach (Recommended)

### Phase 1: Add Series to Sonarr

1. Go to Sonarr → Add Series
2. Add each unique series (~179 total)
3. Use `/tv` as root folder
4. Enable "Monitor: All Episodes"
5. **Don't** trigger search yet (we have the files)

**Tip**: Use Sonarr Lists to bulk-add by TVDB list if available.

### Phase 2: Manual Import

1. Go to Wanted → Manual Import
2. Point to `/var/mnt/swap_drive/TV/`
3. Sonarr scans and matches episodes to series
4. Review matches (fix any mismatches)
5. Click "Import" - Sonarr moves + renames files

### Phase 3: Verify Structure

After import, folders should look like:
```
/tv/
  One Piece (1999)/
    Season 01/
      One Piece - S01E01 - I'm Luffy.mkv
    Season 02/
      ...
  Doctor Who (1963)/
    Season 01/
      ...
```

### Phase 4: Cleanup

```bash
# Remove empty folders after import
find /var/mnt/swap_drive/TV -type d -empty -delete
```

---

## Naming Format (Sonarr Settings)

Ensure Sonarr is configured with:

**Series Folder Format**:
```
{Series Title} ({Series Year})
```

**Season Folder Format**:
```
Season {season:00}
```

**Episode Format**:
```
{Series Title} - S{season:00}E{episode:00} - {Episode Title}
```

---

## Special Cases

### Doctor Who (3 separate series)
| Series | TVDB ID | Years |
|--------|---------|-------|
| Doctor Who (1963) | 76107 | 1963-1989 |
| Doctor Who (2005) | 78804 | 2005-2022 |
| Doctor Who (2023) | 436992 | 2023+ |

Sonarr treats these as separate series - ensure folders without year tags get mapped correctly.

### One Piece Naming Variants
All of these should map to the same series:
- `One.Piece.S12E44...`
- `One_Piece_(1999)_-_S13E57...`
- `[Group]_One_Piece_-_E0957...`

### Anime Fansub Tags
Folders like `[Arid].SteinsGate.2011-S01E08...` - Sonarr handles these fine, just ignore the group tag.

---

## Safety Notes

1. **Backup exists**: Files copied to swap_drive during migration
2. **btrfs moves are instant**: Same filesystem = metadata only
3. **Sonarr doesn't delete**: It moves files, originals stay if import fails
4. **Verify before proceeding**: Check a few imports before bulk approving

---

## Why Not FileBot?

FileBot is excellent but:
- Costs $48
- Another tool to learn
- Sonarr already does this

Use FileBot if: You have massive one-time imports regularly, or Sonarr's UI is too slow.

---

## Execution Checklist

- [ ] Phase 3e copy complete (3.5TB on swap_drive)
- [ ] All ~179 series added to Sonarr
- [ ] Sonarr naming format configured correctly
- [ ] Manual Import run on /var/mnt/swap_drive/TV/
- [ ] Mismatches reviewed and fixed
- [ ] All imports approved
- [ ] Empty folders cleaned up
- [ ] Plex library rescanned
- [ ] Verify playback works

---

**Document Maintenance**: Update after reorganization completes.
