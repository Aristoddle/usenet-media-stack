# Mylar3 Setup Documentation

## Overview

Mylar3 is configured as the primary comics acquisition tool, integrated with Prowlarr for indexer management and SABnzbd for Usenet downloads.

## Container Details

- **Name**: mylar
- **Port**: 8090
- **Config Path**: /var/mnt/fast8tb/config/mylar/
- **Comics Path**: /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics/ (mounted as /comics)
- **API Key**: `cad4f40858c77c4177c99bebae4f3e17`

## Integration Status

### Prowlarr Integration (CONFIGURED)

Mylar is connected to Prowlarr with 5 indexers:
- NZB.su (Prowlarr) - http://prowlarr:9696/3/api
- NZBFinder (Prowlarr) - http://prowlarr:9696/2/api
- NZBgeek (Prowlarr) - http://prowlarr:9696/1/api
- NZBPlanet (Prowlarr) - http://prowlarr:9696/4/api
- Nyaa (Prowlarr) - http://prowlarr:9696/5/api (Torznab for manga)

### SABnzbd Integration (CONFIGURED)

- Host: http://sabnzbd:8080
- Category: comics
- Priority: High
- Post-processing: Enabled
- Remove completed: Enabled
- Remove failed: Enabled

### Direct Download (DDL) Integration (CONFIGURED)

- GetComics: Enabled (fallback for missing issues)
- DDL Location: Uses system downloads folder
- Auto Resume: Enabled
- Prefer Upscaled: Enabled
- Priority: mega > mediafire > pixeldrain > main

### Post-Processing (CONFIGURED)

- Script: `/config/scripts/notify-komga.sh`
- Shell: /bin/bash
- This script triggers Komga library rescan after new comics are downloaded

## Monitored Series

As of 2025-12-29:
- **82 series** are currently monitored
- Series folder format: `$Series ($Year)`
- File format: `$Series $Annual $Issue ($Year)`

## Comic Directory Structure

Mylar stores comics in:
```
/comics/
  ├── Series Name (Year)/
  │   ├── Series Name #001 (Year).cbz
  │   ├── Series Name #002 (Year).cbz
  │   └── ...
```

Note: This differs from the manga naming standard `Series Name (Publisher) [EN]/`. Mylar uses ComicVine-based naming.

## Key Configuration Highlights

### Quality Settings
- Min file size: 5 MB
- Max file size: 15000 MB
- Usenet retention: 3500 days
- Ignored words: .exe, .iso, pdf-xpost, pdf, ebook

### Automation
- Auto-want upcoming: Enabled
- Auto-want all: Enabled
- NZB startup search: Enabled
- RSS check interval: 20 minutes
- Search interval: 24 hours

### Metadata
- ComicVine API: Configured
- CVInfo metadata: Enabled
- Comic cover local: Enabled
- Series metadata local: Enabled
- MetaTagging: Enabled with ComicTagger

## API Usage

Test API connectivity:
```bash
curl "http://localhost:8090/api?cmd=getVersion&apikey=cad4f40858c77c4177c99bebae4f3e17"
```

Get all monitored comics:
```bash
curl "http://localhost:8090/api?cmd=getIndex&apikey=cad4f40858c77c4177c99bebae4f3e17"
```

Search for a comic:
```bash
curl "http://localhost:8090/api?cmd=searchComic&name=Batman&apikey=cad4f40858c77c4177c99bebae4f3e17"
```

## Troubleshooting

### Common Issues

1. **No results from Prowlarr indexers**
   - Check Prowlarr is running: `docker ps | grep prowlarr`
   - Verify API key in Prowlarr matches Mylar config

2. **Downloads not appearing**
   - Check SABnzbd category exists: "comics"
   - Verify download path is accessible

3. **Post-processing failures**
   - Check notify-komga.sh script exists
   - Verify Komga API is accessible

### Logs

Mylar logs are in: `/var/mnt/fast8tb/config/mylar/mylar/logs/`

## Related Documentation

- BOOKS_AND_AUDIOBOOKS_GUIDE.md - Overall books ecosystem
- NAMING_STANDARD_V2.md - Manga naming conventions (differs from Mylar)
- KOMGA_SETUP.md - Komga configuration
