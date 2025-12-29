# Service Logs & Status Reference

Quick reference for checking logs, status, and health of all media stack services.

---

## Quick Status Check

```bash
# All containers status
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -25

# Resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

---

## Container Logs

### Core Media Services

| Service | Log Command | Web UI |
|---------|-------------|--------|
| **Plex** | `docker logs plex --tail 100` | http://localhost:32400/web |
| **Tdarr** | `docker logs tdarr --tail 100` | http://localhost:8265 |
| **Tdarr Node** | `docker logs tdarr-node --tail 100` | (via Tdarr UI) |
| **Radarr** | `docker logs radarr --tail 100` | http://localhost:7878 |
| **Sonarr** | `docker logs sonarr --tail 100` | http://localhost:8989 |
| **Prowlarr** | `docker logs prowlarr --tail 100` | http://localhost:9696 |

### Download Clients

| Service | Log Command | Web UI |
|---------|-------------|--------|
| **SABnzbd** | `docker logs sabnzbd --tail 100` | http://localhost:8080 |
| **Transmission** | `docker logs transmission --tail 100` | http://localhost:9091 |

### Reading/Comics Stack

| Service | Log Command | Web UI |
|---------|-------------|--------|
| **Komga** | `docker logs komga --tail 100` | http://localhost:25600 |
| **Audiobookshelf** | `docker logs audiobookshelf --tail 100` | http://localhost:13378 |
| **Mylar** | `docker logs mylar --tail 100` | http://localhost:8090 |
| **Readarr** | `docker logs readarr --tail 100` | http://localhost:8787 |

### Support Services

| Service | Log Command | Web UI |
|---------|-------------|--------|
| **Overseerr** | `docker logs overseerr --tail 100` | http://localhost:5055 |
| **Tautulli** | `docker logs tautulli --tail 100` | http://localhost:8181 |
| **Bazarr** | `docker logs bazarr --tail 100` | http://localhost:6767 |
| **Portainer** | `docker logs portainer --tail 100` | http://localhost:9000 |

---

## Log File Locations (Host)

### Config Directory Structure
```
/var/mnt/fast8tb/config/
├── plex/Library/Application Support/Plex Media Server/Logs/
│   ├── Plex Media Server.log
│   ├── Plex Media Scanner.log
│   └── Plex Transcoder Statistics.log
├── tdarr/
│   └── server/Tdarr/Logs/
├── radarr/logs/
├── sonarr/logs/
├── prowlarr/logs/
├── sabnzbd/logs/
├── transmission/
├── komga/
└── audiobookshelf/
```

### Metrics & Monitoring
```
/var/mnt/fast8tb/config/metrics/
├── sysinfo.db          # SQLite time-series database
└── collector.log       # Metrics daemon log
```

---

## Filtered Log Queries

### Tdarr Errors
```bash
docker logs tdarr 2>&1 | grep -iE "(error|fail|limbo)" | tail -30
```

### Plex Transcoding Issues
```bash
docker logs plex 2>&1 | grep -iE "(transcode|error|fail)" | tail -20
```

### SABnzbd Download Failures
```bash
docker logs sabnzbd 2>&1 | grep -iE "(fail|error|abort)" | tail -20
```

### Radarr Import Issues
```bash
docker logs radarr 2>&1 | grep -iE "(import|error|fail)" | tail -20
```

---

## Health Checks

### Tdarr Status
```bash
# API status
curl -s http://localhost:8265/api/v2/status | jq

# Library scan status
curl -s -X POST "http://localhost:8265/api/v2/cruddb" \
  -H "Content-Type: application/json" \
  -d '{"data":{"collection":"LibrarySettingsJSONDB","mode":"getAll"}}' | \
  jq '.[] | {name, lastScan: .lastScan}'

# Count files by health status
curl -s -X POST "http://localhost:8265/api/v2/cruddb" \
  -H "Content-Type: application/json" \
  -d '{"data":{"collection":"FileJSONDB","mode":"getAll"}}' | \
  jq 'group_by(.HealthCheck) | map({status: .[0].HealthCheck, count: length})'
```

### Plex Health
```bash
# Server identity
curl -s "http://localhost:32400/identity" | head -5

# Library sections
curl -s "http://localhost:32400/library/sections?X-Plex-Token=$PLEX_TOKEN" | \
  grep -oP 'title="[^"]*"' | head -10
```

### *arr Apps Health
```bash
# Radarr system status
curl -s "http://localhost:7878/api/v3/system/status" \
  -H "X-Api-Key: $RADARR_API_KEY" | jq '{version, startupPath}'

# Sonarr system status
curl -s "http://localhost:8989/api/v3/system/status" \
  -H "X-Api-Key: $SONARR_API_KEY" | jq '{version, startupPath}'
```

---

## System Metrics

### Real-time Snapshot
```bash
/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/sysinfo-snapshot
```

### Historical Stats
```bash
/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/metrics-collector --stats
```

### Query Last Hour
```bash
/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/metrics-collector --query "1h"
```

---

## Common Troubleshooting

### Tdarr Workers Not Starting
```bash
# Check worker config
docker exec tdarr env | grep -i worker

# Check GPU access
docker exec tdarr ls -la /dev/dri/

# Restart workers
docker restart tdarr tdarr-node
```

### High CPU / Thermal Issues
```bash
# Live thermal watch
./tools/metrics-collector --thermal-watch

# Check what's consuming CPU
./tools/sysinfo-snapshot | grep "top5"

# Reduce Tdarr workers (in .env)
# TDARR_HEALTHCHECK_GPU_WORKERS=1
docker compose up -d tdarr tdarr-node --force-recreate
```

### Download Client Issues
```bash
# SABnzbd queue
curl -s "http://localhost:8080/api?mode=queue&apikey=$SABNZBD_API_KEY&output=json" | \
  jq '.queue | {speed, noofslots, status}'

# Transmission status
transmission-remote localhost:9091 -l
```

### Plex Not Finding Media
```bash
# Check mount visibility
docker exec plex ls -la /pool/

# Force library scan
curl -X POST "http://localhost:32400/library/sections/1/refresh?X-Plex-Token=$PLEX_TOKEN"
```
