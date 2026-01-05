# Decision: Pool Health Monitoring Architecture

**Date**: 2026-01-04
**Status**: Implemented
**Author**: Claude Code (Agent A)

## Context

The usenet-media-stack supports two operating modes:
- **Full mode**: External drive bays connected, all 30+ services running
- **Portable mode**: No external bays, reading stack only (10 services)

Previously, mode switching was manual and boot-only. Users had to restart the stack to switch modes, and hot-unplugging drives risked data corruption.

## Decision

Implement a runtime pool health monitoring system with:
1. **Hot-unplug detection** - Poll every 10s for drive/pool state changes
2. **Graceful drain** - Pause download clients and wait for I/O before stopping
3. **Auto-upgrade** - Seamlessly upgrade to full mode when pool recovers
4. **Rate limiting** - Prevent upgrade spam if pool flaps

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                   pool-health-monitor.sh                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    10s poll    ┌──────────────┐              │
│  │ check_pool_  │ ─────────────► │ do_health_   │              │
│  │ mounted()    │                │ check()      │              │
│  └──────────────┘                └──────┬───────┘              │
│                                         │                       │
│                    ┌────────────────────┴────────────────────┐ │
│                    │           State Changes                  │ │
│                    ├──────────────────────────────────────────┤ │
│                    │                                          │ │
│                    ▼                                          ▼ │
│  ┌─────────────────────────┐          ┌─────────────────────┐ │
│  │   healthy → unmounted   │          │ unmounted → healthy │ │
│  │                         │          │                     │ │
│  │  pause_download_clients │          │ should_auto_upgrade │ │
│  │  wait_for_io_settle     │          │ (rate limit check)  │ │
│  │  stop_full_stack        │          │ start_full_stack    │ │
│  └─────────────────────────┘          └─────────────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Graceful Drain Sequence

1. **Pause SABnzbd** - API call: `mode=pause&apikey=KEY`
2. **Pause Transmission** - RPC with CSRF token handling
3. **Stop Tdarr node** - Prevent new transcodes
4. **Wait for I/O** - `sync` + up to 10s wait
5. **Stop containers** - 30s graceful timeout
6. **Force kill** - Only as last resort

## Auto-Upgrade Logic

```bash
should_auto_upgrade() {
    # 1. Check if enabled (AUTO_UPGRADE_ON_RECOVERY=true)
    # 2. Rate limit (60s cooldown between upgrades)
    # 3. Check current mode (only upgrade from local/pool-degraded)
}
```

## State Files

Location: `/tmp/media-stack/`

| File | Contents | Purpose |
|------|----------|---------|
| `stack-mode` | `full`, `local`, `pool-degraded` | Current operating mode |
| `pool-state` | `healthy`, `degraded`, `stale`, `unmounted` | Pool health |
| `stack-started` | Unix timestamp | Last stack start (for rate limiting) |
| `start-method` | `autostart`, `manual`, `auto-upgrade` | How stack was started |
| `pool-degraded` | Unix timestamp | Last degradation event |
| `pool-health.log` | Event log | Debugging |

## Known Limitations

1. **SABnzbd config path hardcoded**: `/var/mnt/fast8tb/config/sabnzbd/sabnzbd.ini`
   - Works for this deployment, not portable

2. **Transmission auth not supported**: Relies on no-auth RPC access
   - Add username/password env vars if needed

3. **No parallel upgrade protection**: If two monitors run, both could try upgrade
   - Mitigated by systemd running single instance

4. **State files not atomic**: Simple echo > file, no locking
   - Acceptable for single-instance daemon

## Alternatives Considered

1. **udev-based detection**: Instant but requires system-level rules
2. **inotify on mount paths**: More efficient but complex for mergerfs
3. **systemd path units**: Would need one per drive label

Polling was chosen for simplicity and portability.

## Testing

```bash
# Simulate hot-unplug (stop mergerfs)
sudo systemctl stop mergerfs-pool.service
# Watch for graceful drain in logs
tail -f /tmp/media-stack/pool-health.log

# Simulate hot-plug (start mergerfs)
sudo systemctl start mergerfs-pool.service
# Watch for auto-upgrade in logs
```

## Related Documents

- [Boot and Launchers](../BOOT_AND_LAUNCHERS.md) - Systemd integration
- [Recovery Runbook](../runbook-pool-recovery.md) - Incident procedures
- [Reading Stack](../reading-stack.md) - Portable mode services

## Changelog

| Date | Change |
|------|--------|
| 2026-01-04 | Initial implementation |
| 2026-01-04 | Fix Transmission CSRF handling |
| 2026-01-04 | Add 60s upgrade rate limiting |
