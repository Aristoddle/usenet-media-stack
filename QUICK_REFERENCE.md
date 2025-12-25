# TV Reorganization - Quick Reference Card

> **Philosophy**: Use tools already in the stack. Sonarr handles renaming, organizing, and ongoing management - no extra tools needed.

**Last Updated**: 2025-12-25

---

## Sonarr Manual Import Workflow

### The Core Approach

```
Disorganized Files --> Sonarr Manual Import --> Organized Library --> Ongoing Management
                           |                         |
                      Matches to TVDB           Auto-upgrades
                      Renames properly          Monitors releases
                      Creates structure         Quality cutoff
```

---

## Step-by-Step Process

### Phase 1: Add All Series to Sonarr

```bash
# Check how many series folders you have
find /tv -maxdepth 1 -type d | wc -l

# Compare with Sonarr's count
curl -s "http://localhost:8989/api/v3/series" \
  -H "X-Api-Key: $SONARR_KEY" | jq 'length'
```

**In Sonarr UI:**
1. Series --> Add New
2. Search for series name
3. Configure:
   - Root Folder: `/tv`
   - Monitor: All Episodes
   - Quality Profile: Your preference
   - **Do NOT** trigger search (you have the files)
4. Repeat for all ~179 series

**Pro Tip:** Use Sonarr Lists for bulk additions if you have TVDB or Trakt lists.

### Phase 2: Manual Import

1. Go to **Wanted --> Manual Import**
2. Select path: `/var/mnt/swap_drive/TV/` (or current location)
3. Wait for Sonarr to scan and match
4. Review matches:
   - Green = Correct match
   - Orange = Needs review
   - Red = No match found
5. Fix any mismatches (dropdown to select correct series/episode)
6. Select all correct matches
7. Click **Import Selected**

Sonarr will:
- Move files to proper `/tv/Series Name (Year)/Season XX/` structure
- Rename according to your naming format
- Update its database
- Trigger Plex/Jellyfin refresh

### Phase 3: Verify and Cleanup

```bash
# Check new structure
tree -L 3 /tv | head -100

# Count organized series
find /tv -maxdepth 1 -type d | wc -l

# Find and remove empty folders
find /var/mnt/swap_drive/TV -type d -empty -delete

# Verify Sonarr recognizes all files
curl -s "http://localhost:8989/api/v3/wanted/missing" \
  -H "X-Api-Key: $SONARR_KEY" | jq '.totalRecords'
```

---

## API Commands (Automation-Ready)

### Trigger Manual Import Scan via API

```bash
SONARR_URL="http://localhost:8989"
SONARR_KEY="4da8f9d97b0449ad8cfc7dcca2362287"

# Scan a specific path for import
curl -X POST "$SONARR_URL/api/v3/command" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "DownloadedEpisodesScan", "path": "/var/mnt/swap_drive/TV"}'
```

### Add Series by TVDB ID

```bash
# Lookup series first
curl -s "$SONARR_URL/api/v3/series/lookup?term=tvdb:81189" \
  -H "X-Api-Key: $SONARR_KEY" | jq '.[0]'

# Add series
curl -X POST "$SONARR_URL/api/v3/series" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tvdbId": 81189,
    "title": "One Piece",
    "qualityProfileId": 4,
    "rootFolderPath": "/tv",
    "monitored": true,
    "addOptions": {"searchForMissingEpisodes": false}
  }'
```

### Rescan All Series

```bash
curl -X POST "$SONARR_URL/api/v3/command" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "RescanSeries"}'
```

---

## Sonarr Naming Configuration

**Settings --> Media Management --> Episode Naming**

### Recommended Formats

**Series Folder Format:**
```
{Series Title} ({Series Year})
```

**Season Folder Format:**
```
Season {season:00}
```

**Standard Episode Format:**
```
{Series Title} - S{season:00}E{episode:00} - {Episode Title}
```

**Daily Episode Format:**
```
{Series Title} - {Air-Date} - {Episode Title}
```

**Anime Episode Format (Absolute Numbering):**
```
{Series Title} - {absolute:000} - {Episode Title}
```

---

## Special Cases

### Doctor Who (Three Separate Series)

| Series | TVDB ID | Years | Notes |
|--------|---------|-------|-------|
| Doctor Who (1963) | 76107 | 1963-1989 | Classic Who |
| Doctor Who (2005) | 78804 | 2005-2022 | Modern Who |
| Doctor Who (2023) | 436992 | 2023+ | Disney+ era |

Add each as separate series in Sonarr. During Manual Import, verify year tags.

### One Piece (700+ Episodes)

Process in batches if Manual Import times out:
1. Manual Import first 200 episodes
2. Import, verify
3. Repeat for next batch

### Anime with Absolute Numbering

Enable "Anime" series type when adding in Sonarr. Uses absolute episode numbers (E001, E002...) instead of seasons.

---

## Verification Checklist

### After Manual Import

- [ ] All series folders in `/tv/` follow `Name (Year)/` format
- [ ] Season folders exist (`Season 01`, `Season 02`, etc.)
- [ ] Episode files renamed properly
- [ ] Sonarr shows "0 missing" for imported series
- [ ] Plex/Jellyfin library refreshed and shows content
- [ ] Video playback works (spot-check a few)

### Ongoing Health Checks

```bash
# Weekly: Check for orphan folders not in Sonarr
comm -23 \
  <(find /tv -maxdepth 1 -type d -printf '%f\n' | sort) \
  <(curl -s "$SONARR_URL/api/v3/series" -H "X-Api-Key: $SONARR_KEY" | \
    jq -r '.[].path | split("/")[-1]' | sort)

# Weekly: Check for quality upgrade opportunities
curl -s "$SONARR_URL/api/v3/wanted/cutoff" \
  -H "X-Api-Key: $SONARR_KEY" | jq '.totalRecords'
```

---

## Troubleshooting

### Manual Import Shows "No Match"

1. Click on the file/folder
2. Use search box to find correct series
3. Select series from dropdown
4. Verify episode mapping
5. Import

### Files Not Moving

```bash
# Check permissions
ls -la /tv
ls -la /var/mnt/swap_drive/TV

# Sonarr needs write access to both source and destination
# If containerized, verify volume mounts
```

### Wrong Episode Matched

1. In Manual Import, click the episode
2. Use dropdown to select correct season/episode
3. Verify title matches before importing

### Duplicate Series Folders

After import, if you have `Series Name` and `Series Name (Year)`:
1. Check which one Sonarr created
2. Manually merge content
3. Rescan series in Sonarr

---

## Emergency Rollback

If something goes wrong:

```bash
# Files are on swap_drive backup
# Restore specific series
rsync -av "/var/mnt/swap_drive/TV/One.Piece.*" /tv/

# Or restore everything
rsync -av --delete /var/mnt/swap_drive/TV/ /tv/

# Rescan in Sonarr after restore
curl -X POST "$SONARR_URL/api/v3/command" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "RescanSeries"}'
```

---

## Key Reminders

1. **Use Sonarr** - It's already in your stack, no extra tools needed
2. **Add series first** - Sonarr needs to know about series before import
3. **Monitor: All** - Enables ongoing quality upgrades
4. **Don't trigger search** - You have the files, just organize them
5. **Review matches** - Spend time verifying before bulk import
6. **Keep backup** - Until you've verified everything works

---

## Related Documentation

- **Detailed Plan:** `docs/TV_REORGANIZATION_PLAN.md`
- **API Reference:** `docs/ARR_STACK_WIRING.md`
- **ISO Re-encoding:** `docs/ISO_REENCODING_WORKFLOW.md`

---

## Why Sonarr, Not FileBot?

| Factor | Sonarr | FileBot |
|--------|--------|---------|
| Cost | $0 (already installed) | $48 license |
| New tool to learn | No | Yes |
| Ongoing management | Built-in | Separate step needed |
| Quality upgrades | Automatic | Manual |
| Release monitoring | Automatic | None |
| API automation | Full API | Limited |

**Bottom line:** Sonarr does everything FileBot does PLUS ongoing library management. One tool, not two.
