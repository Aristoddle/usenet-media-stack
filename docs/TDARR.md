# Tdarr Configuration and Troubleshooting

**Last Updated**: 2025-12-29
**Status**: Active
**Version**: Tdarr v2.58.02

Complete reference for Tdarr transcoding setup on AMD 780M (RDNA3) with Steam Deck.

---

## Current Configuration (December 2025)

### Encoding Strategy: CPU-based SVT-AV1

**Decision**: Use CPU-based SVT-AV1 encoding for maximum compression ratio.

| Approach | Compression | Speed | Quality |
|----------|-------------|-------|---------|
| GPU HEVC (VAAPI) | ~50% reduction | Fast (5-10x) | Good |
| **CPU SVT-AV1** | **60-70% reduction** | Slower | Excellent |

**Rationale**: With 41TB pool and limited headroom, compression efficiency beats speed.

### Worker Configuration

```bash
# Current .env settings (CPU-focused)
TDARR_TRANSCODE_GPU_WORKERS=1
TDARR_TRANSCODE_CPU_WORKERS=4
TDARR_HEALTHCHECK_GPU_WORKERS=2
TDARR_HEALTHCHECK_CPU_WORKERS=0
```

See `docs/advanced/performance.md` for SVT-AV1 tuning details.

---

## Alternative: GPU-Only VAAPI Configuration

For faster throughput at slightly lower compression:

### Conservative Profile (Coexists with Plex)

Use when Plex is doing heavy work or thermals are high.

```bash
# .env settings
TDARR_TRANSCODE_GPU_WORKERS=4
TDARR_TRANSCODE_CPU_WORKERS=0
TDARR_HEALTHCHECK_GPU_WORKERS=1
TDARR_HEALTHCHECK_CPU_WORKERS=0
```

**Expected behavior:**
- CPU: 40-70% (leaves headroom for Plex)
- GPU: 30-50%
- Temp: <85 C
- Throughput: ~2-4 files/hour

### Aggressive Profile (Maximum Throughput)

Use when Plex is idle and thermals are under control.

```bash
# .env settings
TDARR_TRANSCODE_GPU_WORKERS=6
TDARR_TRANSCODE_CPU_WORKERS=0
TDARR_HEALTHCHECK_GPU_WORKERS=2
TDARR_HEALTHCHECK_CPU_WORKERS=0
```

**Expected behavior:**
- CPU: 60-85%
- GPU: 50-80%
- Temp: <90 C
- Throughput: ~4-8 files/hour

---

## Key Concepts

### Why GPU VAAPI?

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
| **Transcode CPU** | Uses x264/x265/SVT-AV1 on CPU | Very high CPU |

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

## Volume Mounts Reference

```
Host Path                                -> Container Path
/var/mnt/pool/tv                        -> /media/tv
/var/mnt/pool/movies                    -> /media/movies
/var/mnt/pool/anime-tv                  -> /media/anime-tv
/var/mnt/pool/anime-movies              -> /media/anime-movies
/var/mnt/pool/christmas-tv              -> /media/christmas-tv
/var/mnt/pool/christmas-movies          -> /media/christmas-movies
/tmp/tdarr_transcode                    -> /temp
/var/mnt/fast8tb/config/tdarr/server    -> /app/server
/var/mnt/fast8tb/config/tdarr/configs   -> /app/configs
/var/mnt/fast8tb/config/tdarr/logs      -> /app/logs
```

---

## Troubleshooting

### Common Symptoms

| Symptom | Cause | Fix |
|---------|-------|-----|
| CPU at 100%, GPU at 10% | CPU workers enabled or schedule override | Check schedule in DB |
| HandBrakeCLI processes | Libraries set to `handbrake=true` | Fix in librarysettingsjsondb |
| Limbo timeout errors | Thermal throttling slowing workers | Reduce workers, check temps |
| Files stuck in "Error" | Workers timed out, files need reset | Reset health_check to "Queued" |
| FATAL TypeError during scan | Library configuration corruption | Delete and recreate library |

### Known Issue: Worker Dispatch Failures (v2.58.02)

Tdarr v2.58.02 can exhibit worker dispatch failure:
- `hevc_vaapi-true-true` confirmed (GPU encoder works!)
- Files stuck in "limbo" for 300+ seconds
- Workers configured but never spawn
- FATAL errors in file scanner on certain libraries

**Root Causes**:

1. **Library Configuration Corruption**: SQLite records causing crashes in `scanFilesInternal`
2. **allowedNodes Mismatch**: Node IDs regenerate on restart, libraries reference stale IDs
3. **Output Path Configuration**: Output set to "." instead of actual path

---

## Recovery Procedures

### Fix 1: Reset Error Files to Queued

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

### Fix 2: Update allowedNodes to Empty Array

```sql
-- Allow all nodes to process all libraries
UPDATE librarysettingsjsondb
SET json_data = json_set(json_data, '$.allowedNodes', json('[]'));
```

### Fix 3: Delete Corrupted Libraries (Nuclear Option)

```sql
-- Stop Tdarr first!
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db

-- Identify problematic libraries (ones causing FATAL errors)
SELECT id, json_extract(json_data, '$.name') FROM librarysettingsjsondb;

-- Delete corrupted libraries
DELETE FROM librarysettingsjsondb WHERE id = 'LIBRARY_ID';

-- Recreate via Tdarr UI after restart
```

### Fix 4: Clean Stale Work Directories

```bash
# Host path (check docker inspect for temp mount)
rm -rf /tmp/tdarr_transcode/tdarr-workDir2-*
```

### Fix 5: Fix Output Paths

```sql
UPDATE librarysettingsjsondb
SET json_data = json_set(json_data, '$.output', '/pool/anime-movies')
WHERE json_extract(json_data, '$.name') = 'Anime-Movies';
```

### Fix 6: Delete Orphaned xpost Records

```bash
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db "
DELETE FROM filejsondb WHERE id LIKE '%-xpost%';
SELECT changes();"
```

### Fix 7: Fix GPU-Only Schedule for All Hours

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

## Diagnostic Commands

### Check Library Configuration

```sql
SELECT
  json_extract(json_data, '$.name'),
  json_extract(json_data, '$.allowedNodes'),
  json_extract(json_data, '$.cache'),
  json_extract(json_data, '$.output')
FROM librarysettingsjsondb;
```

### Check Queue Status

```sql
SELECT
  (SELECT COUNT(*) FROM filejsondb WHERE health_check = 'Queued') as queued,
  (SELECT COUNT(*) FROM filejsondb WHERE health_check = 'Error') as error,
  (SELECT COUNT(*) FROM filejsondb WHERE health_check = 'Success') as success,
  (SELECT COUNT(*) FROM filejsondb WHERE health_check LIKE 'Transcode%') as transcoding;
```

### Check Node Configuration

```sql
SELECT id, json_extract(json_data, '$.workerLimits') FROM nodejsondb;
```

### Verify VAAPI in Container

```bash
# Check VAAPI availability
sudo docker exec tdarr vainfo

# Test HEVC encoding
sudo docker exec tdarr ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi -f lavfi -i "nullsrc=s=320x240:d=1" \
  -vf "format=nv12,hwupload" -c:v hevc_vaapi -t 1 -f null -
```

### Check Node Encoder Status

Look for `hevc_vaapi-true-true` in logs:
```bash
sudo docker logs tdarr-node --tail 100 | grep encoder-enabled
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

---

## Known Working Library Configuration

```json
{
  "name": "Anime-TV",
  "folder": "/media/anime-tv",
  "output": "/pool/anime-tv",
  "cache": "/temp",
  "folderWatching": 0,
  "scanOnStart": true,
  "processLibrary": true,
  "useFlow": 0,
  "allowedNodes": [],
  "transcodePluginStack": [
    {
      "source": "Community",
      "id": "Tdarr_Plugin_00td_filter_by_codec",
      "Inputs": {"codec": "hevc", "condition": "not"}
    },
    {
      "source": "Community",
      "id": "Tdarr_Plugin_00td_action_transcode",
      "Inputs": {
        "target_codec": "hevc",
        "target_bitrate_multiplier": 0.5,
        "try_use_gpu": true,
        "container": "mkv"
      }
    }
  ]
}
```

### Node Worker Limits

```json
{
  "workerLimits": {
    "healthcheckcpu": 0,
    "healthcheckgpu": 1,
    "transcodecpu": 0,
    "transcodegpu": 4
  }
}
```

---

## GitHub Issues Reference

| Issue | Description | Status |
|-------|-------------|--------|
| #1140 | "Entire Tdarr stuck on one staging file" - cache config missing | Fixed in v2.58+ |
| #1304 | "SQLITE_ERROR: too many SQL variables" with 95k files | Fixed in v2.58.02 |
| #821 | Scanner database mismatch race condition | Clear corrupted entries |
| #1192 | Lockup with multiple scan API calls | Use debugFolderWatcher=true |

---

## Related Documentation

- [Performance Tuning](./advanced/performance.md) - SVT-AV1 configuration details
- [ISO to AV1 Pipeline](./ISO_REENCODING_WORKFLOW.md) - Blu-ray ISO extraction and transcoding
- [Stack Usage Guide](./STACK_USAGE_GUIDE.md) - Tdarr API reference and setup
- [Services](./SERVICES.md) - Container overview

---

## Changelog

| Date | Author | Changes |
|------|--------|---------|
| 2025-12-29 | Claude | Merged TDARR_TUNING.md and TDARR_TROUBLESHOOTING.md |
| 2025-12-29 | Claude | Added SVT-AV1 strategy reference |
| 2025-12-29 00:45 | Claude | Initial troubleshooting documentation |
