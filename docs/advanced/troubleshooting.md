---
title: Troubleshooting Playbook
layout: doc
---

# Troubleshooting Playbook

Migrated from `codex/collab/troubleshooting.md`, this playbook centralises
remediation steps for the most common production issues.

## Incident Workflow

1. **Detect**: Use Netdata or `./usenet services status` to confirm scope.
2. **Stabilise**: Pause automation jobs and disable affected services to
   prevent cascading failures.
3. **Diagnose**: Gather logs, metrics, and configuration diffs.
4. **Resolve**: Apply fixes and document the outcome in the runbook.
5. **Retrospective**: Create follow-up actions and schedule validation.

## Common Issues

### Port Conflicts

- Run `./usenet validate --fix` to kill stray docker-proxy processes.
 - Check `docker ps --format '\\{\\{.Ports\\}\\} \\{\\{.Names\\}\\}'` for unexpected binds.
- Reserve ports in `/etc/systemd/system.conf` when the OS auto-claims them.

### Storage Degradation

- Inspect ZFS health with `zpool status` and run a scrub if errors appear.
- For Btrfs, verify `btrfs device stats` and replace suspect drives using
  the hot-swap procedure.
- Ensure `udisks2` is disabled to prevent desktop environments from
  mounting pools automatically.

### Slow Automation

- Confirm API tokens have not expired by running `./usenet env list`.
- Review Netdata dashboards for CPU steal or iowait spikes.
- Restart automation containers with `./usenet services restart <name>`.

### Transmission Watch Folder Not Importing

1) **Confirm settings**
   - `watch-dir-enabled` should be `true`.
   - `watch-dir` should match the container path (often `/downloads/watch`).
2) **Verify volume mapping**
   - Ensure the host watch directory is mounted to the expected container path.
3) **Permissions**
   - Confirm the container UID/GID can read the watch folder.
4) **Filesystem + inotify**
   - Watch folders rely on inotify; some network mounts or GVFS paths can fail.
   - Check `fs.inotify.max_user_watches` if you expect many files.
5) **Dry test**
   - Drop a small `.torrent` into the watch folder and tail logs for import activity.

### Failed Updates

- Re-run `./usenet deploy --auto` to reapply Compose templates.
- Inspect `docker compose pull` output to ensure registries are reachable.
- Roll back to the previous tag stored in `docs/advanced/migration-log.md`.

## Diagnostic Commands

| Scenario            | Command                                        |
|---------------------|------------------------------------------------|
| Service health      | `./usenet services status --verbose`           |
| Log tail            | `./usenet services logs <service> --tail 200`  |
| Network capture     | `./usenet services exec <svc> -- tcpdump ...`  |
| Disk benchmarks     | `fio --filename=/data/test --rw=randrw ...`    |

## Escalation

- Maintain a contact list for hardware vendors and tunnel providers.
- Use the `triage-results.json` template to capture evidence for audits.
- Schedule a post-incident review within 48 hours of resolution.
