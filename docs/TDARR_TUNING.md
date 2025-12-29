# Tdarr Performance Tuning Guide

Reference for GPU-only VAAPI transcoding configuration on AMD 780M (RDNA3).

---

## Configuration Profiles

### Conservative (Default - Coexists with Plex)

Use when Plex is doing heavy work (first-run scans, library analysis) or thermals are high.

```bash
# .env settings
TDARR_TRANSCODE_GPU_WORKERS=4
TDARR_TRANSCODE_CPU_WORKERS=0
TDARR_HEALTHCHECK_GPU_WORKERS=1
TDARR_HEALTHCHECK_CPU_WORKERS=0

TDARR_NODE_TRANSCODE_GPU_WORKERS=2
TDARR_NODE_TRANSCODE_CPU_WORKERS=0
TDARR_NODE_HEALTHCHECK_GPU_WORKERS=1
TDARR_NODE_HEALTHCHECK_CPU_WORKERS=0
```

**Expected behavior:**
- CPU: 40-70% (leaves headroom for Plex)
- GPU: 30-50%
- Temp: <85°C
- Throughput: ~2-4 files/hour

### Aggressive (Maximum Throughput)

Use when Plex is idle and thermals are under control.

```bash
# .env settings
TDARR_TRANSCODE_GPU_WORKERS=6
TDARR_TRANSCODE_CPU_WORKERS=0
TDARR_HEALTHCHECK_GPU_WORKERS=2
TDARR_HEALTHCHECK_CPU_WORKERS=0

TDARR_NODE_TRANSCODE_GPU_WORKERS=4
TDARR_NODE_TRANSCODE_CPU_WORKERS=0
TDARR_NODE_HEALTHCHECK_GPU_WORKERS=1
TDARR_NODE_HEALTHCHECK_CPU_WORKERS=0
```

**Expected behavior:**
- CPU: 60-85%
- GPU: 50-80%
- Temp: <90°C
- Throughput: ~4-8 files/hour

---

## Key Concepts

### Why GPU-Only?

1. **VAAPI (Video Acceleration API)** uses the GPU's dedicated Video Codec Engine (VCE), separate from shader cores
2. GPU encoding is 5-10x faster than CPU for HEVC/H.265
3. CPU is still needed for health-check scanning (ffprobe/exiftool), but not for encoding
4. Setting `cpuWorkers=0` prevents CPU-bound HandBrake fallback

### Health-Check vs Transcode Workers

| Type | What It Does | Resource Impact |
|------|--------------|-----------------|
| **Health-check GPU** | Scans file metadata using GPU-accelerated ffprobe | Low GPU, moderate CPU |
| **Health-check CPU** | Uses exiftool/ffprobe on CPU | High CPU, thermal risk |
| **Transcode GPU** | Encodes video using VAAPI | High GPU (VCE), low CPU |
| **Transcode CPU** | Uses x264/x265 on CPU | Very high CPU, thermal risk |

### Schedule Override (Critical!)

Tdarr has a **24-hour schedule** that can OVERRIDE `workerLimits`. Each hour slot must be configured correctly:

```json
{
  "_id": "00-01",
  "healthcheckcpu": 0,
  "healthcheckgpu": 1,
  "transcodecpu": 0,
  "transcodegpu": 4
}
```

The schedule is stored in `nodejsondb` table. To verify:

```bash
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db \
  "SELECT json_extract(json_data, '$.schedule[0]') FROM nodejsondb WHERE id='MainNode';"
```

---

## Troubleshooting

### Symptoms of Misconfiguration

| Symptom | Cause | Fix |
|---------|-------|-----|
| CPU at 100%, GPU at 10% | CPU workers enabled or schedule override | Check schedule in DB |
| HandBrakeCLI processes | Libraries set to `handbrake=true` | Fix in librarysettingsjsondb |
| Limbo timeout errors | Thermal throttling slowing workers | Reduce workers, check temps |
| Files stuck in "Error" | Workers timed out, files need reset | Reset health_check to "Queued" |

### Reset Error Files

```bash
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db "
UPDATE filejsondb
SET json_data = json_set(json_data,
    '\$.HealthCheck', 'Queued',
    '\$.TranscodeDecisionMaker', 'Queued'
)
WHERE health_check = 'Error';
SELECT changes();"
```

### Delete Orphaned xpost Records

```bash
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db "
DELETE FROM filejsondb WHERE id LIKE '%-xpost%';
SELECT changes();"
```

### Fix GPU-Only Schedule for All Hours

```bash
GPU_SCHEDULE='['
for i in {0..23}; do
  NEXT=$((i+1))
  if [ $i -lt 10 ]; then HOUR="0$i"; else HOUR="$i"; fi
  if [ $NEXT -lt 10 ]; then NEXTH="0$NEXT"; else NEXTH="$NEXT"; fi
  if [ $NEXT -eq 24 ]; then NEXTH="00"; fi
  GPU_SCHEDULE="$GPU_SCHEDULE"'{"_id":"'"$HOUR-$NEXTH"'","healthcheckcpu":0,"healthcheckgpu":1,"transcodecpu":0,"transcodegpu":4}'
  if [ $i -lt 23 ]; then GPU_SCHEDULE="$GPU_SCHEDULE,"; fi
done
GPU_SCHEDULE="$GPU_SCHEDULE]"

sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db "
UPDATE nodejsondb
SET json_data = json_set(json_data, '\$.schedule', json('$GPU_SCHEDULE'))
WHERE id = 'MainNode';"
```

---

## Monitoring

### Real-time Check

```bash
./tools/sysinfo-snapshot
```

Look for:
- `gpu_underutilized=false` - GPU is being used
- `thermal_risk=false` - Temps under control
- `exiftool=0` or low - Not in heavy scan phase

### Historical Analysis

```bash
./tools/metrics-collector --stats
./tools/metrics-collector --query "1h"
```

---

## Switching Profiles

After editing `.env`:

```bash
sudo docker compose up -d tdarr tdarr-node --force-recreate
```

Verify with:
```bash
./tools/sysinfo-snapshot --watch 5
```

Wait 2-3 minutes for workers to stabilize before assessing.
