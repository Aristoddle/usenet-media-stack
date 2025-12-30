# Suwayomi (Tachidesk) Setup

## Overview

Suwayomi is a self-hosted manga reader server that allows downloading chapters from various manga sources. It functions as the "weekly chapter" acquisition pipeline for ongoing manga series.

## Container Details

- **Name**: suwayomi
- **Port**: 4567
- **UI**: http://localhost:4567
- **Config Path**: /var/mnt/fast8tb/config/suwayomi/
- **Downloads Path**: /var/mnt/fast8tb/config/suwayomi/downloads/ (internal container path)

## Current Configuration Status

### Server Settings (from server.conf)
- Auto-download new chapters: **Enabled**
- Exclude entries with unread chapters: **Enabled**
- Auto-download ignore re-uploads: **Disabled**
- Download as CBZ: **Disabled** (organizer script handles CBZ conversion)
- Global update interval: **12 hours**
- Extension repository: keiyoushi/extensions

### Authentication
- Auth mode: **none** (local network only)

## Extension Sources

Popular extensions to add via the UI:
- MangaDex (primary source, EN chapters)
- MangaPlus (official Shueisha releases)
- MangaSee (aggregator, high quality)
- TCBScans (fanscans, fast releases)

## Workflow: Weekly Chapter Downloads

```
Suwayomi Downloads → suwayomi-organizer.sh → [Weekly Chapters]/ → Komga
```

### Step 1: Configure Series in Suwayomi UI

1. Browse to http://localhost:4567
2. Search for manga using installed extensions
3. Add series to library
4. Enable auto-download in series settings

### Step 2: Suwayomi Downloads Chapters

Suwayomi downloads chapters as image folders:
```
downloads/
  └── ExtensionSource/
      └── SeriesName/
          └── Chapter X/
              ├── 001.jpg
              ├── 002.jpg
              └── ...
```

### Step 3: Organizer Script Converts to CBZ

The `suwayomi-organizer.sh` script:
1. Scans download directories
2. Creates CBZ archives from image folders
3. Names files with proper chapter padding
4. Moves to `[Weekly Chapters]/SeriesName/` folder
5. Triggers Komga library rescan

**Usage:**
```bash
# Dry run (preview changes)
./tools/suwayomi-organizer.sh --dry-run

# Execute once
./tools/suwayomi-organizer.sh

# Watch mode (continuous monitoring)
./tools/suwayomi-organizer.sh --watch
```

**Output naming:**
```
[Weekly Chapters]/
  └── One Piece/
      ├── One Piece c1132.cbz
      ├── One Piece c1133.cbz
      └── One Piece c1134.cbz
```

### Step 4: Komga Ingests

Komga automatically scans libraries hourly, or the organizer script triggers a rescan after processing.

## Initial Setup Checklist

1. [ ] Open the UI (http://localhost:4567) and add sources/extensions
2. [ ] Configure extension settings (language preferences, etc.)
3. [ ] Add manga series to library
4. [ ] Enable auto-download for followed series
5. [ ] Configure suwayomi-organizer.sh environment variables if needed
6. [ ] Set up cron job or systemd timer for organizer script (optional)

## Cron Job Setup (Recommended)

Add to crontab to run organizer every hour:
```bash
crontab -e
# Add this line:
0 * * * * /var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/suwayomi-organizer.sh >> /tmp/suwayomi-organizer.log 2>&1
```

Or run as a background daemon:
```bash
nohup ./tools/suwayomi-organizer.sh --watch > /tmp/suwayomi-organizer.log 2>&1 &
```

## Komga/Kavita Integration

- Komga scans libraries hourly via `KOMGA_LIBRARIES_SCAN_CRON`
- Force manual scan: `curl -u <user>:<pass> -X POST http://localhost:8081/api/v1/libraries/<id>/scan`
- Kavita: Configure library to watch the `[Weekly Chapters]` folder

## Backup

Suwayomi creates automatic backups to:
```
/var/mnt/fast8tb/config/suwayomi/backups/
```

Backup settings:
- Interval: Daily at 00:00
- Retention: 14 days

## Troubleshooting

### Common Issues

1. **Extensions not loading**
   - Check extension repository URL in server.conf
   - Verify network connectivity

2. **Downloads stuck/failing**
   - Check source website availability
   - Try a different extension/source

3. **Organizer script not creating CBZs**
   - Verify download directory path
   - Check image count (minimum 3 images required)

4. **Permission errors**
   - Suwayomi runs as uid/gid 1000
   - Ensure directories are chowned to 1000:1000

### Logs

- Suwayomi logs: `/var/mnt/fast8tb/config/suwayomi/logs/`
- Organizer logs: `/tmp/suwayomi-organizer.log` (if configured)

## Notes

- The Suwayomi container runs as uid/gid 1000; host paths are chowned to 1000:1000
- Weekly chapters are kept separate from tankobon (volume) releases
- The `c{chapter}` naming distinguishes from `v{volume}` for tankobon
- If Suwayomi fails to start, check permissions on config/suwayomi directory

## Related Documentation

- BOOKS_AND_AUDIOBOOKS_GUIDE.md - Overall books ecosystem
- NAMING_STANDARD_V2.md - Manga naming conventions
- KOMGA_SETUP.md - Komga configuration
