# Tdarr Troubleshooting Guide

**Date**: 2025-12-29 (00:45 EST)
**Purpose**: Document Tdarr corruption states, fixes, and operational insights

---

## Critical Finding: VAAPI Works, Worker Dispatch Broken

### The Problem

Tdarr v2.58.02 exhibiting worker dispatch failure:
- `hevc_vaapi-true-true` confirmed (GPU encoder works!)
- Files stuck in "limbo" for 300+ seconds
- Workers configured but never spawn
- FATAL errors in file scanner on certain libraries

### Root Cause Analysis

**Layer 1: Library Configuration Corruption**
```
Movies library: FATAL TypeError during scan
TV library: FATAL TypeError during scan
Anime-TV library: Scans successfully (5,828 files in 4.6s)
```

The Movies and TV library records in SQLite caused crashes in `scanFilesInternal`. Deleting and recreating these libraries was required.

**Layer 2: allowedNodes Mismatch**
Node IDs are regenerated on each container restart. Libraries reference stale IDs.
```sql
-- Before: Libraries reference wrong IDs
allowedNodes = ["MainNode", "SecondaryNode"]  -- Static names

-- Reality: Nodes register with random IDs
Node h1S1Jfim7 (MainNode), Node ofFGyVa-n (SecondaryNode)

-- Fix: Use empty array to allow all nodes
UPDATE librarysettingsjsondb SET json_data =
  json_set(json_data, '$.allowedNodes', json('[]'));
```

**Layer 3: Output Path Configuration**
```sql
-- Broken (output = ".")
Anime-Movies|/temp|.
Anime-TV|/temp|.

-- Fixed
Anime-Movies|/temp|/pool/anime-movies
Anime-TV|/temp|/pool/anime-tv
```

---

## GitHub Issues Reference

### Issue #1140 - "Entire Tdarr stuck on one staging file"
**Error**: `TypeError: Cannot read properties of undefined (reading 'cache')`
**Root Cause**: Transcode cache configuration missing in library settings
**Solution**: Verify cache paths, generate job reports for diagnostics

### Issue #1304 - "SQLITE_ERROR: too many SQL variables"
**Trigger**: Library with ~95,000 files
**Solution**: Upgrade to v2.58.02+ with batched SQL operations

### Issue #821 - Scanner database mismatch
**Error**: `Cannot read properties of undefined (reading '_id')`
**Root Cause**: Race condition during concurrent scan operations
**Fix**: Clear corrupted entries, fresh scan

### Issue #1192 - Lockup with multiple scan API calls
**Workaround**: Use `debugFolderWatcher=true` environment variable

---

## Recovery Procedures

### Fix 1: Delete Corrupted Libraries (Nuclear)

```sql
-- Stop Tdarr first!
sqlite3 /var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db

-- Identify problematic libraries (ones causing FATAL errors)
SELECT id, json_extract(json_data, '$.name') FROM librarysettingsjsondb;

-- Delete corrupted libraries
DELETE FROM librarysettingsjsondb WHERE id = 'LIBRARY_ID';

-- Recreate via Tdarr UI after restart
```

### Fix 2: Update allowedNodes to Empty Array

```sql
-- Allow all nodes to process all libraries
UPDATE librarysettingsjsondb
SET json_data = json_set(json_data, '$.allowedNodes', json('[]'));
```

### Fix 3: Clean Stale Work Directories

```bash
# Host path (check docker inspect for temp mount)
rm -rf /tmp/tdarr_transcode/tdarr-workDir2-*
```

### Fix 4: Reset Error Files to Queued

```sql
UPDATE filejsondb SET health_check = 'Queued'
WHERE health_check = 'Error';
```

### Fix 5: Fix Output Paths

```sql
UPDATE librarysettingsjsondb
SET json_data = json_set(json_data, '$.output', '/pool/anime-movies')
WHERE json_extract(json_data, '$.name') = 'Anime-Movies';
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

## Known Working Configuration

### Library Settings (Stable)

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

## Unresolved Issue: Workers Not Dispatching

Despite all configuration fixes, workers are not actively processing files. The nodes:
1. Register successfully
2. Pass all encoder/binary/scanner tests
3. Report `hevc_vaapi-true-true`
4. Then sit idle

Files are picked up (logs show "in limbo") but never actually staged to workers.

**Next Steps**:
1. Consider complete Tdarr rebuild (delete config, fresh setup)
2. Check v2.58.02 changelog for known dispatch issues
3. Test with a simpler plugin configuration (single file)
4. Monitor Tdarr Discord/GitHub for similar reports

---

## Volume Mounts (Reference)

```
/var/mnt/pool/tv -> /media/tv
/var/mnt/pool/movies -> /media/movies
/var/mnt/pool/anime-tv -> /media/anime-tv
/var/mnt/pool/anime-movies -> /media/anime-movies
/var/mnt/pool/christmas-tv -> /media/christmas-tv
/var/mnt/pool/christmas-movies -> /media/christmas-movies
/tmp/tdarr_transcode -> /temp
/var/mnt/fast8tb/config/tdarr/server -> /app/server
/var/mnt/fast8tb/config/tdarr/configs -> /app/configs
/var/mnt/fast8tb/config/tdarr/logs -> /app/logs
```

---

## Changelog

| Date | Author | Changes |
|------|--------|---------|
| 2025-12-29 00:45 | Claude | Initial troubleshooting documentation |
