---
title: Backup Strategies
layout: doc
---

# Backup Strategies

Migrated from `codex/collab/backup-strategies.md`, this guide documents
battle-tested workflows for protecting configuration, metadata, and media
states across the stack.

## Backup Layers

1. **Configuration Snapshots**
   - Triggered with `./usenet backup create`.
   - Stores compressed archives in `backups/` with timestamped names.
   - Includes API keys, automation scripts, and Docker Compose overlays.
2. **Application Databases**
   - Postgres-backed apps (e.g., Lidarr) dump to `/var/lib/postgresql`.
   - Lightweight sqlite stores are captured through bind mounts.
3. **Media Storage**
   - Rely on filesystem-level snapshots using ZFS or Btrfs.
   - Incremental replication handled by `zfs send` or `btrfs send` jobs.

## Schedule Matrix

| Layer              | Frequency | Retention | Tooling                 |
|--------------------|-----------|-----------|-------------------------|
| Config snapshots   | Daily     | 14 days   | `./usenet backup`       |
| Databases          | 6 hours   | 7 days    | Cron + `docker exec`    |
| Media snapshots    | Hourly    | 48 hours  | ZFS/Btrfs native tools  |
| Off-site sync      | Daily     | 30 days   | `rclone` + object store |

## Off-Site Replication

1. Encrypt the archive using `age` before upload.
2. Push to an S3-compatible bucket using `rclone copy`. Set lifecycle
   policies on the bucket so older archives purge automatically.
3. Store the decrypt key on a hardware token stored off-site.

## Disaster Recovery Drill

- Restore the latest config snapshot to a staging host.
- Run `./usenet deploy --validate-only` to catch credential drift.
- Execute sample automation to confirm API integrations work.
- Document the drill in your operational runbook with timestamps.

## Advanced Tips

- Enable Netdata cloud backups if you rely on its historical dashboards.
- Script verification of archive integrity using `sha256sum` before
  deleting local copies.
- Maintain a manifest file describing the contents of each archive to
  accelerate restores under pressure.
