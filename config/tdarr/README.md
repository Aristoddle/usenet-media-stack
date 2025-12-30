# Tdarr Configuration (Git-Tracked)

This directory contains git-tracked Tdarr configuration that can be restored to a fresh container.

## Architecture

```
config/tdarr/
├── flows/                    # Custom encoding flows (JSON exports)
│   ├── svt_av1_production_v3.json   # Primary SVT-AV1 flow
│   ├── svt_av1_optimized.json       # High compression variant
│   ├── svt_av1_anime.json           # Anime-tuned variant
│   └── hevc_vaapi.json              # GPU HEVC fallback
├── libraries/                # Library settings (JSON exports)
│   ├── movies.json
│   ├── tv.json
│   ├── anime_movies.json
│   ├── anime_tv.json
│   ├── iso_extracts.json
│   ├── christmas_movies.json
│   └── christmas_tv.json
├── tdarr-config-sync.sh     # Export/Import tool
└── README.md                 # This file
```

## Workflow: Container Updates

The Tdarr container uses volume mounts for persistence:

```yaml
# docker-compose.yml
volumes:
  - ${CONFIG_ROOT}/tdarr/server:/app/server:rw,z    # SQLite database + state
  - ${CONFIG_ROOT}/tdarr/configs:/app/configs:rw,z  # Additional configs
  - ${CONFIG_ROOT}/tdarr/logs:/app/logs:rw,z        # Log files
```

**Normal update flow:**
1. `docker compose pull tdarr` - Get latest image
2. `docker compose up -d tdarr` - Restart with new image
3. Configuration persists via volumes ✓

**Fresh install / recovery flow:**
1. Deploy fresh container
2. Run `./tdarr-config-sync.sh import` to restore flows + libraries
3. Restart Tdarr for changes to take effect

## Usage

### Export (after making changes in Tdarr UI)
```bash
./tdarr-config-sync.sh export
git add flows/ libraries/
git commit -m "chore(tdarr): update flow configuration"
```

### Import (fresh install or recovery)
```bash
./tdarr-config-sync.sh import
docker compose restart tdarr
```

### Status (view current state)
```bash
./tdarr-config-sync.sh status
```

## Flow Configuration

### SVT-AV1 Production v3 (Primary)
- **Purpose**: Maximum compression for storage savings
- **Codec**: libsvtav1 with CRF 30, preset 5
- **Parameters**:
  - `film-grain=8` - Preserves grain in film content
  - `lp=2` - Limit parallel threads (prevents CPU overload)
  - `tune=0` - Balanced quality/speed
  - `enable-overlays=1` - Better motion handling
  - `scd=1` - Scene change detection
- **Skips**: Already AV1/VP9, or HEVC under 6 Mbps

### SVT-AV1 Optimized (Storage Max)
- Higher compression variant for bulk libraries
- Used by: TV, Movies

### SVT-AV1 Anime
- Tuned for clean animation sources
- Used by: Anime-Movies, Anime-TV

## Library → Flow Mapping

| Library | Flow | Purpose |
|---------|------|---------|
| Movies | svt_av1_optimized | Bulk movie compression |
| TV | svt_av1_optimized | Bulk TV compression |
| Anime-Movies | svt_av1_anime | Anime-tuned compression |
| Anime-TV | svt_av1_anime | Anime-tuned compression |
| ISO Extracts | svt_av1_production_v3 | MakeMKV output processing |
| Christmas Movies | svt_av1_production_v3 | Holiday content |
| Christmas TV | svt_av1_production_v3 | Holiday content |

## Troubleshooting

### Flows not loading after import
Tdarr caches configuration in memory. Restart the container:
```bash
docker compose restart tdarr
```

### Queue shows 0 files despite database having entries
Known Tdarr issue - in-memory state doesn't sync with SQLite on startup.
Workaround: Trigger library rescan via web UI.

### Import fails with SQL error
Ensure Tdarr container is stopped before import to avoid database locks:
```bash
docker compose stop tdarr
./tdarr-config-sync.sh import
docker compose start tdarr
```

## Related Documentation

- [TDARR.md](../../docs/TDARR.md) - Main Tdarr documentation
- [ISO_REENCODING_WORKFLOW.md](../../docs/ISO_REENCODING_WORKFLOW.md) - MakeMKV → Tdarr pipeline
- [ENCODING_STRATEGY.md](./ENCODING_STRATEGY.md) - Codec selection rationale

---

*Last updated: 2025-12-30*
