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
