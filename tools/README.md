# usenet-media-stack Tools

Utility scripts for monitoring, debugging, and managing the media stack.

## sysinfo-snapshot

Comprehensive system monitoring tool designed for media stack performance tuning.

### Quick Start

```bash
# Human-readable output
./sysinfo-snapshot

# JSON for APIs/databases
./sysinfo-snapshot --json

# Compact single-line for logs
./sysinfo-snapshot --compact

# Continuous monitoring (every 5 seconds)
./sysinfo-snapshot --watch 5

# Skip service API queries (faster, no network calls)
./sysinfo-snapshot --no-services
```

### Metrics Captured

| Category | Metrics |
|----------|---------|
| **CPU** | Total/per-core usage, frequency (cur/min/max), temperature, load average |
| **Memory** | Used/available, swap, cached |
| **GPU** | Utilization, VRAM, temperature, power draw, shader/memory clock |
| **Network** | Throughput (Mbps), interface, totals |
| **Disk** | Read/write throughput (MB/s) |
| **Processes** | ffmpeg, HandBrake, exiftool, Plex, SABnzbd, Transmission counts |
| **Services** | Tdarr status/queue, SABnzbd speed |

### Analysis Flags

The tool automatically detects issues:

- `gpu_underutilized` - GPU < 30% while CPU > 80% (VAAPI not being used)
- `thermal_risk` - CPU temp > 85°C (throttling likely)
- `scanning_heavy` - More than 2 exiftool processes (Tdarr scan phase)

### Environment Variables

```bash
# CPU sampling window (default 200ms)
export SNAPSHOT_INTERVAL_MS=200

# Skip service API queries
export SNAPSHOT_SERVICES=0

# SABnzbd API key for queue/speed stats
export SABNZBD_API_KEY=your_key_here
```

### Example Output

**Human-readable:**
```
ts=2025-12-29T00:40:20-05:00
cpu: total=82% load=32.2,35.1,40.5 temp=85.0°C freq=4500/1100/5137MHz
mem: used=50% (40219MiB/80111MiB) cached=26645MiB swap=38%
gpu: util=15% temp=67.0°C vram=7628/16384MiB power=64.1W/180W sclk=2700MHz mclk=2800MHz
net: enp2s0 ↓125.50Mbps ↑2.30Mbps (total: ↓4738065MiB ↑243927MiB)
disk: read=450.2MB/s write=125.0MB/s
procs: ffmpeg=4 handbrake=0 exiftool=0 plex=2 sab=1 transmission=1
top5: ffmpeg:180.0 Plex:45.0 python3:12.0 node:8.5 java:5.2
services: tdarr=good sab_speed=45MB/s sab_queue=3
analysis: gpu_underutilized=false thermal_risk=false scanning_heavy=false
```

**Compact (for logging):**
```
2025-12-29T00:40:20-05:00 cpu=82% gpu=15% temp=85.0°C freq=4500MHz mem=50% net=↓125.5↑2.3Mbps disk=r450.2w125.0MB/s ffmpeg=4 exiftool=0 plex=2
```

### Database Integration

Pipe JSON output to InfluxDB, TimescaleDB, or any time-series database:

```bash
# InfluxDB line protocol (example)
./sysinfo-snapshot --json | jq -r '
  "sysinfo,host=steambox " +
  "cpu_pct=\(.cpu.total_pct)," +
  "cpu_temp=\(.cpu.temp_c)," +
  "gpu_pct=\(.gpu.util_pct)," +
  "mem_pct=\(.memory.used_pct) " +
  "\(.ts_epoch_ms)000000"
'

# Continuous logging to file
./sysinfo-snapshot --watch 10 --compact >> /var/log/sysinfo.log &
```

### Use Cases

1. **Tdarr Tuning** - Monitor GPU vs CPU utilization during transcode
2. **Thermal Debugging** - Track temperature during heavy workloads
3. **Download Monitoring** - Watch network throughput during SAB/Transmission activity
4. **Scan Phase Detection** - Identify when Tdarr is in CPU-heavy scanning vs GPU encoding
5. **Performance Regression** - Log metrics over time to detect issues

---

## metrics-collector

Time-series storage for long-term analysis. Stores sysinfo-snapshot data in SQLite.

### Quick Start

```bash
# Initialize database and collect single snapshot
./metrics-collector

# Run as background daemon (collect every 30 seconds)
./metrics-collector --daemon 30

# View collection statistics
./metrics-collector --stats

# Query last hour of data
./metrics-collector --query "1h"

# Export to CSV
./metrics-collector --export csv

# Thermal watch mode (live monitoring with alerts)
./metrics-collector --thermal-watch
```

### Database Location

Default: `/var/mnt/fast8tb/config/metrics/sysinfo.db`

Override with: `METRICS_DB=/path/to/db ./metrics-collector`

### Schema

```sql
-- Key tables
metrics       -- Time-series data (one row per snapshot)
alerts        -- Thermal/critical alerts
sessions      -- Named analysis periods

-- Built-in view for quick stats
v_recent_stats  -- Last hour aggregates
```

### Systemd Installation

```bash
# Copy service files
sudo cp tools/systemd/media-stack-metrics.service /etc/systemd/system/
sudo cp tools/systemd/media-stack-metrics.timer /etc/systemd/system/

# For daemon mode (recommended):
sudo systemctl enable --now media-stack-metrics.service

# OR for timer mode:
sudo systemctl enable --now media-stack-metrics.timer
```

### Analysis Queries

```bash
# Average CPU/GPU during high-temp periods
sqlite3 /var/mnt/fast8tb/config/metrics/sysinfo.db "
  SELECT AVG(cpu_total_pct), AVG(gpu_util_pct)
  FROM metrics WHERE cpu_temp_c > 85;"

# Count thermal risk samples per day
sqlite3 /var/mnt/fast8tb/config/metrics/sysinfo.db "
  SELECT DATE(ts), COUNT(*)
  FROM metrics WHERE flag_thermal_risk = 1
  GROUP BY DATE(ts);"

# Peak network throughput
sqlite3 /var/mnt/fast8tb/config/metrics/sysinfo.db "
  SELECT MAX(net_rx_rate_mbps), MAX(net_tx_rate_mbps) FROM metrics;"
```

---

## Manga Pipeline Tools

### suwayomi-organizer.sh

Converts Suwayomi chapter downloads into CBZ archives and moves to Komga library.

```bash
# Single scan
./suwayomi-organizer.sh

# Dry run (show what would be done)
./suwayomi-organizer.sh --dry-run

# Watch mode (daemon - monitor for new downloads)
./suwayomi-organizer.sh --watch
```

**Features:**
- Parses Suwayomi's Source/Series/Chapter directory structure
- Creates properly named CBZ archives (4-digit chapter padding)
- Moves to Manga-Weekly library for Komga
- Triggers Komga library rescan
- Logs processed/failed chapters

**Environment:**
- `SUWAYOMI_DOWNLOADS` - Suwayomi chapter download path
- `SUWAYOMI_OUTPUT_DIR` - Target Komga library (default: Comics/[Weekly Chapters])
- `KOMGA_URL`, `KOMGA_USERNAME`, `KOMGA_PASSWORD` - Komga API credentials

---

### mylar-post-processor.sh

SABnzbd post-processing script for Mylar comic downloads.

```bash
# Usually called by SABnzbd, but can run manually:
./mylar-post-processor.sh "/path/to/download" "NZB.Name" "Clean Name"
```

**Setup:**
1. Add script to SABnzbd Scripts Folder
2. Configure Mylar to use this as post-processing script

**Features:**
- Normalizes filenames for series/volume patterns
- Moves to correct series folder in Comics library
- Creates series folders if needed
- Triggers Komga rescan
- Logs all operations

**Environment:**
- `COMICS_ROOT` - Target comics library path
- `KOMGA_URL`, `KOMGA_USERNAME`, `KOMGA_PASSWORD` - Komga API credentials

---

### komga-collection-sync.sh

Creates Komga collections linking same-name series across libraries.

```bash
# Create collections for cross-library series
./komga-collection-sync.sh

# Dry run
./komga-collection-sync.sh --dry-run

# Verbose output
./komga-collection-sync.sh --verbose
```

**Use Case:** When you have "Chainsaw Man" in both "Manga (Collected)" and "Manga (Weekly)" libraries, this creates a "Chainsaw Man (All Editions)" collection containing both.

**Features:**
- Scans all Komga libraries for same-name series
- Normalizes names (removes publisher tags, language codes, years)
- Creates or updates collections automatically
- Idempotent (safe to run repeatedly)

**Environment:**
- `KOMGA_URL` - Komga server URL (default: http://localhost:8081)
- `KOMGA_USERNAME`, `KOMGA_PASSWORD` - Komga admin credentials

---

### flatten-manga-directories.sh

Migration helper to flatten nested manga directories for Komga compatibility.

```bash
# Dry run (recommended first)
./flatten-manga-directories.sh --dry-run

# Interactive mode (prompt before each change)
./flatten-manga-directories.sh --interactive

# Also remove __Panels, .DS_Store, etc.
./flatten-manga-directories.sh --cleanup

# Target specific directory
./flatten-manga-directories.sh /path/to/comics
```

**Problem Solved:** Some manga has nested structures like `Series/1. Volumes/v01.cbz` which Komga treats as separate series.

**Features:**
- Detects common nested patterns (Volumes, Chapters, Extras, etc.)
- Flattens to `Series/Series v01.cbz` format
- Creates backup manifest before changes
- Removes empty directories after moving files
- Optional cleanup of YACReader `__Panels` directories

**Safety:**
- Always use `--dry-run` first
- Creates JSON manifest of all changes
- Never deletes files (moves only)
- Logs all operations

---

### migrate-readarr-to-bookshelf.sh

Migration script for Readarr to Bookshelf fork (Readarr is EOL as of June 2025).

```bash
./migrate-readarr-to-bookshelf.sh --dry-run
```

See [docs/decisions/2025-12-29-stack-health-audit.md](../docs/decisions/2025-12-29-stack-health-audit.md) for details.

---

## USB/External Media Import Tools

### lidarr-bootstrap.sh

Bootstrap Lidarr with artists from USB/external music directories.

```bash
# Preview what would be added
./lidarr-bootstrap.sh /run/media/deck/Slow_3TB_HD/Music --dry-run

# Add all artists to Lidarr
LIDARR_API_KEY=xxx ./lidarr-bootstrap.sh /run/media/deck/Slow_3TB_HD/Music

# List current Lidarr artists
LIDARR_API_KEY=xxx ./lidarr-bootstrap.sh --list
```

**Features:**
- Scans directory for artist folders
- Queries MusicBrainz via Lidarr API for artist metadata
- Adds artists to Lidarr with monitoring enabled
- Skips artists already in Lidarr
- Reports unmatched artists for manual review
- Rate-limited to respect MusicBrainz (1 req/sec)

**Environment:**
- `LIDARR_URL` - Lidarr server URL (default: http://localhost:8686)
- `LIDARR_API_KEY` - Lidarr API key (required)
- `MUSIC_ROOT` - Target music root path in Lidarr (default: /pool/music)

**Use Case:** Bootstrap Lidarr with 235 artists from USB drive collection.

---

### usb-movie-importer.sh

Analyze and import movies from USB/external drive to Radarr.

```bash
# Analyze USB movies (report only)
RADARR_API_KEY=xxx ./usb-movie-importer.sh /run/media/deck/Slow_4TB_2/Movies

# Preview import
RADARR_API_KEY=xxx ./usb-movie-importer.sh /run/media/deck/Slow_4TB_2/Movies --import --dry-run

# Import unique movies
RADARR_API_KEY=xxx ./usb-movie-importer.sh /run/media/deck/Slow_4TB_2/Movies --import
```

**Features:**
- Scans USB movie folders
- Parses folder names (supports "Movie Name (2023)" and scene naming)
- Queries TMDB via Radarr API for matches
- Reports: unique movies, duplicates (with quality comparison), not found
- Optional: imports unique movies to Radarr library
- Rate-limited for API stability

**Environment:**
- `RADARR_URL` - Radarr server URL (default: http://localhost:7878)
- `RADARR_API_KEY` - Radarr API key (required)
- `POOL_MOVIES` - Target movies root path (default: /pool/movies)

**Use Case:** Import 555 movies from USB drive, identifying duplicates vs pool.

---

## Tool Index

| Tool | Purpose | Status |
|------|---------|--------|
| `sysinfo-snapshot` | System monitoring | Production |
| `metrics-collector` | Time-series metrics storage | Production |
| `suwayomi-organizer.sh` | Manga chapter -> CBZ | Production |
| `mylar-post-processor.sh` | SABnzbd post-processing | Production |
| `komga-collection-sync.sh` | Cross-library collections | Production |
| `flatten-manga-directories.sh` | Manga directory cleanup | Production |
| `migrate-readarr-to-bookshelf.sh` | Readarr migration | Ready |
| `lidarr-bootstrap.sh` | Music library bootstrap | Ready |
| `usb-movie-importer.sh` | Movie dedup/import | Ready |
