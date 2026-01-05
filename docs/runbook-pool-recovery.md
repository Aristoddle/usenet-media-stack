# Pool Recovery Runbook

> **Purpose**: Step-by-step procedures for recovering from pool disconnection, failure, or data corruption.
> **Last Updated**: 2026-01-04

## Quick Reference

| Scenario | First Action | Recovery Time |
|----------|--------------|---------------|
| Clean hot-unplug (drives removed) | Reconnect drives, wait for auto-upgrade | 2-3 min |
| Stale mount (I/O errors) | `sudo systemctl restart mergerfs-pool.service` | 1-2 min |
| Partial disconnect (some drives) | Check connections, restart mergerfs | 2-3 min |
| Corrupt files after crash | Run integrity checks, restore from backup | 15-60 min |

---

## Scenario 1: Clean Hot-Unplug Recovery

**Symptoms**: Drives were disconnected while system was idle or after graceful drain.

### Steps

1. **Reconnect drive bays** (USB dock/enclosure)

2. **Wait for auto-detection** (30-60 seconds)
   ```bash
   # Check if drives are detected
   ls /dev/disk/by-label/Fast*
   ```

3. **Verify pool mount**
   ```bash
   # Check mergerfs status
   sudo systemctl status mergerfs-pool.service

   # If not started, start it
   sudo systemctl start mergerfs-pool.service
   ```

4. **Check pool health**
   ```bash
   ./scripts/pool-health-monitor.sh --status
   ```

5. **Auto-upgrade should trigger** (if enabled)
   - Watch for desktop notification: "Media Stack Upgraded"
   - Check logs: `tail -f /tmp/media-stack/pool-health.log`

6. **Manual upgrade if needed**
   ```bash
   ./scripts/smart-start.sh restart
   ```

---

## Scenario 2: Stale FUSE Mount

**Symptoms**: Containers show I/O errors, `ls /var/mnt/pool` hangs, but drives are connected.

### Steps

1. **Force unmount stale mergerfs**
   ```bash
   sudo umount -l /var/mnt/pool
   ```

2. **Restart mergerfs service**
   ```bash
   sudo systemctl restart mergerfs-pool.service
   ```

3. **Restart pool-dependent containers**
   ```bash
   ./scripts/restart-pool-containers.sh
   ```

4. **Verify container health**
   ```bash
   docker compose ps
   docker logs sonarr --tail 20
   docker logs plex --tail 20
   ```

---

## Scenario 3: Partial Drive Failure

**Symptoms**: mergerfs reports degraded state, some drives missing.

### Steps

1. **Identify missing drives**
   ```bash
   ./scripts/pool-health-monitor.sh --status

   # Check physical connections
   ls /dev/disk/by-label/Fast*
   lsblk
   ```

2. **Check drive health**
   ```bash
   # For each connected drive
   sudo smartctl -a /dev/sdX
   ```

3. **If drive is physically disconnected**
   - Reconnect and restart mergerfs
   - Pool will resync automatically

4. **If drive has SMART errors**
   - Back up data from that drive immediately
   - Replace drive
   - Run btrfs scrub on replacement

---

## Scenario 4: Data Corruption After Crash

**Symptoms**: Files won't open, services report database errors, unexpected EOF.

### Immediate Actions

1. **Stop all services**
   ```bash
   docker compose down
   docker compose -f docker-compose.reading.yml down
   ```

2. **Check filesystem integrity**
   ```bash
   # For each btrfs drive in the pool
   sudo btrfs check --readonly /dev/disk/by-label/Fast_4TB_1
   # Repeat for all drives
   ```

3. **Check for orphaned/corrupt downloads**
   ```bash
   # Find incomplete downloads
   find /var/mnt/pool/downloads/incomplete -type f -mmin +60

   # Find zero-byte files (corruption indicator)
   find /var/mnt/pool -type f -size 0 -name "*.mkv" -o -name "*.mp4"
   ```

### Database Recovery

**SQLite databases** (Sonarr, Radarr, etc.) are stored on native btrfs (`/var/mnt/fast8tb/config/`), NOT on mergerfs. They should be safe, but verify:

```bash
# Check database integrity
sqlite3 /var/mnt/fast8tb/config/sonarr/sonarr.db "PRAGMA integrity_check;"
sqlite3 /var/mnt/fast8tb/config/radarr/radarr.db "PRAGMA integrity_check;"
sqlite3 /var/mnt/fast8tb/config/komga/database.sqlite "PRAGMA integrity_check;"
```

**If database is corrupt**:
```bash
# Restore from backup (configs are backed up to OneDrive)
cp /path/to/backup/sonarr.db /var/mnt/fast8tb/config/sonarr/sonarr.db
```

### Media File Recovery

1. **Check Plex for missing files**
   - Open Plex web UI
   - Settings → Troubleshooting → "Optimize Database"
   - Settings → Manage → Libraries → "Empty Trash" (don't auto-empty!)

2. **Rescan libraries**
   ```bash
   # Plex full rescan
   curl -X POST "http://localhost:32400/library/sections/all/refresh?X-Plex-Token=$PLEX_TOKEN"

   # Komga rescan
   curl -X POST "http://localhost:8081/api/v1/libraries/scan" \
     -H "Authorization: Bearer $KOMGA_TOKEN"
   ```

3. **Check for partial transcodes**
   ```bash
   # Tdarr leaves temp files
   find /var/mnt/pool -name "*.tmp" -o -name "*_TDARR_*"

   # Delete if corrupt
   rm -f /var/mnt/pool/media/movies/*_TDARR_*.mkv
   ```

---

## Scenario 5: Complete Pool Loss

**Symptoms**: All drives failed or catastrophic data loss.

### Immediate Actions

1. **Stop panicking** - configs are on internal NVMe, not pool
2. **Stop all services** to prevent further issues
3. **Assess damage**:
   - Are drives physically damaged or just disconnected?
   - Is data recoverable?

### If Drives Are Recoverable

1. Reconnect one drive at a time
2. Check each with `btrfs check --readonly`
3. Mount read-only to assess data
4. Reconstruct pool gradually

### If Data Is Lost

1. **Configs are safe** - stored on `/var/mnt/fast8tb/config/`
2. **Watch history is safe** - in Plex/Komga databases (also on internal drive)
3. **Media must be re-acquired** - use Sonarr/Radarr to search again

### Restoring From Backup

```bash
# If you have restic/borg backups
restic -r /path/to/backup restore latest --target /var/mnt/pool

# If restoring from OneDrive
rclone copy onedrive:Backups/media-stack /var/mnt/pool
```

---

## Prevention Checklist

- [ ] Pool health monitor running (`systemctl --user status pool-health-monitor`)
- [ ] Graceful drain enabled (check graceful stop on disconnect)
- [ ] Configs on internal NVMe, not pool
- [ ] Regular config backups (to OneDrive or external)
- [ ] SMART monitoring for drive health
- [ ] UPS for clean shutdown during power loss

---

## State Files Reference

Location: `/tmp/media-stack/`

| File | Purpose |
|------|---------|
| `stack-mode` | Current mode: `full`, `local`, `pool-degraded` |
| `pool-state` | Pool health: `healthy`, `degraded`, `stale`, `unmounted` |
| `pool-health.log` | Event log for debugging |
| `pool-degraded` | Timestamp of last degradation |
| `stack-started` | Timestamp of last stack start |
| `start-method` | How stack was started: `autostart`, `manual`, `auto-upgrade` |

---

## Related Documentation

- [Boot and Launchers](./BOOT_AND_LAUNCHERS.md) - Mode detection and startup
- [Storage Architecture](./storage/architecture.md) - mergerfs pool design
- [Reading Stack](./reading-stack.md) - Portable mode services
