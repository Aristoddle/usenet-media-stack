# *arr Stack Wiring Guide

> **Purpose**: Full integration of media library with Sonarr/Radarr for ongoing automated management.
> **Last Updated**: 2025-12-25

---

## Philosophy

The *arr stack isn't just for downloading - it's the **source of truth** for your library:

| Without *arr Wiring | With *arr Wiring |
|---------------------|------------------|
| Manual episode hunting | Auto-grab on release |
| Quality scattered | Consistent upgrades |
| No metadata management | Rich episode info |
| Files wherever | Organized structure |

**Goal**: Every series in your library is monitored by Sonarr. Every movie by Radarr. No orphans.

---

## API Reference

### Sonarr
```bash
BASE_URL="http://localhost:8989"
API_KEY="4da8f9d97b0449ad8cfc7dcca2362287"

# List all series
curl -s "$BASE_URL/api/v3/series" -H "X-Api-Key: $API_KEY" | jq '.[].title'

# Add series by TVDB ID
curl -X POST "$BASE_URL/api/v3/series" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tvdbId": 81189,
    "title": "One Piece",
    "qualityProfileId": 4,
    "rootFolderPath": "/tv",
    "monitored": true,
    "addOptions": {"searchForMissingEpisodes": true}
  }'

# Trigger manual import scan
curl -X POST "$BASE_URL/api/v3/command" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "DownloadedEpisodesScan", "path": "/path/to/scan"}'
```

### Radarr
```bash
BASE_URL="http://localhost:7878"
API_KEY="e2c1b4e03d0749bb822409d59ef2de07"

# List all movies
curl -s "$BASE_URL/api/v3/movie" -H "X-Api-Key: $API_KEY" | jq '.[].title'

# Add movie by TMDB ID
curl -X POST "$BASE_URL/api/v3/movie" \
  -H "X-Api-Key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "tmdbId": 12345,
    "title": "Movie Title",
    "qualityProfileId": 4,
    "rootFolderPath": "/movies",
    "monitored": true,
    "addOptions": {"searchForMovie": true}
  }'
```

---

## Wiring Workflow

### Step 1: Inventory Current Library

```bash
# Count series folders
find /tv -maxdepth 1 -type d | wc -l

# Count movie folders
find /movies -maxdepth 1 -type d | wc -l

# Compare with *arr counts
curl -s "http://localhost:8989/api/v3/series" -H "X-Api-Key: $SONARR_KEY" | jq 'length'
curl -s "http://localhost:7878/api/v3/movie" -H "X-Api-Key: $RADARR_KEY" | jq 'length'
```

### Step 2: Add Missing Series to Sonarr

For each series folder not in Sonarr:
1. Search TVDB for correct series
2. Add via API or UI
3. Point to existing folder
4. Run "Rescan Series Files"

### Step 3: Add Missing Movies to Radarr

Same process with TMDB lookups.

### Step 4: Import Existing Files

```bash
# Sonarr: Scan for existing files
curl -X POST "http://localhost:8989/api/v3/command" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "RescanSeries"}'

# Radarr: Scan for existing files
curl -X POST "http://localhost:7878/api/v3/command" \
  -H "X-Api-Key: $RADARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "RescanMovie"}'
```

### Step 5: Verify No Orphans

```bash
# Series in folder but not Sonarr
comm -23 <(find /tv -maxdepth 1 -type d -printf '%f\n' | sort) \
         <(curl -s "$SONARR_URL/api/v3/series" -H "X-Api-Key: $SONARR_KEY" | jq -r '.[].path | split("/")[-1]' | sort)
```

---

## Bulk Operations

### Add Multiple Series from List

```bash
#!/bin/bash
# add_series_bulk.sh - Add series from TVDB ID list

SONARR_URL="http://localhost:8989"
SONARR_KEY="4da8f9d97b0449ad8cfc7dcca2362287"

while read tvdb_id; do
  # Lookup series
  SERIES=$(curl -s "$SONARR_URL/api/v3/series/lookup?term=tvdb:$tvdb_id" \
    -H "X-Api-Key: $SONARR_KEY" | jq '.[0]')

  # Add with monitoring
  echo "$SERIES" | jq '. + {
    qualityProfileId: 4,
    rootFolderPath: "/tv",
    monitored: true,
    addOptions: {searchForMissingEpisodes: false}
  }' | curl -X POST "$SONARR_URL/api/v3/series" \
    -H "X-Api-Key: $SONARR_KEY" \
    -H "Content-Type: application/json" \
    -d @-

  echo "Added: $(echo "$SERIES" | jq -r '.title')"
  sleep 1  # Rate limiting
done < tvdb_ids.txt
```

### Trigger Search for All Missing

```bash
# Sonarr: Search for all missing episodes
curl -X POST "http://localhost:8989/api/v3/command" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "MissingEpisodeSearch"}'
```

---

## Validation Checks

### Health Check
```bash
# Sonarr health
curl -s "http://localhost:8989/api/v3/health" -H "X-Api-Key: $SONARR_KEY" | jq

# Radarr health
curl -s "http://localhost:7878/api/v3/health" -H "X-Api-Key: $RADARR_KEY" | jq
```

### Queue Status
```bash
# Active downloads
curl -s "http://localhost:8989/api/v3/queue" -H "X-Api-Key: $SONARR_KEY" | jq '.records | length'
```

### Missing Content
```bash
# Sonarr: Missing episodes count
curl -s "http://localhost:8989/api/v3/wanted/missing" -H "X-Api-Key: $SONARR_KEY" | jq '.totalRecords'
```

---

## Integration with Claude Agents

These workflows should be codified as:

1. **media-acquisition-agent**: Already exists - handles adding content
2. **library-wiring-agent** (TO CREATE): Audits library vs *arr, wires orphans
3. **quality-upgrade-agent** (TO CREATE): Triggers cutoff unmet searches

See: `~/.local/share/chezmoi/.claude/agents/` for agent definitions.

---

## Maintenance Schedule

| Task | Frequency | Command/Action |
|------|-----------|----------------|
| Check for orphan folders | Weekly | Run orphan detection script |
| Verify all series monitored | Monthly | Compare folder count vs Sonarr count |
| Quality upgrade search | Weekly | Cutoff Unmet search |
| Recyclarr sync | After config changes | `docker compose run recyclarr sync` |

---

## Document Maintenance

**Update when**: New *arr features added, API changes, new automation patterns discovered.
