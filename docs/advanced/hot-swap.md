---
title: Hot-Swap Procedures
layout: doc
---

# Hot-Swap Procedures

The contents of `codex/collab/hot-swap.md` now live here with updates for
current hardware detection routines and JBOD best practices.

## Supported Storage Targets

- **ZFS pools** using by-id path detection.
- **Btrfs volumes** configured via `btrfs filesystem show`.
- **USB JBOD enclosures** exposing disks through `lsblk -o NAME,MODEL`.

## Preparation Checklist

1. Confirm that `usenet storage list` returns the pool you plan to edit.
2. Ensure recent backups exist for both configuration and media volumes.
3. Verify that `systemd-udevd` rules are loaded for the enclosure.

## Swap Workflow

1. **Identify the disk**
   - Run `./usenet storage identify --serial <SERIAL>` to map the device.
   - Cross-check with `smartctl -a` for health metrics.
2. **Mark the disk offline**
   - For ZFS: `zfs offline poolname <disk>`.
   - For Btrfs: `btrfs device offline /mountpoint <disk>`.
3. **Replace hardware**
   - Physically swap the drive and confirm the new serial appears in
     `usenet storage list`.
4. **Bring the disk online**
   - Re-enable using the matching ZFS or Btrfs command.
   - Run `./usenet storage scrub --pool <poolname>` to validate integrity.

## Automation Hooks

- The CLI fires hooks located in `lib/hooks/storage/` during swaps.
- Custom notifications can be added by placing scripts in
  `lib/hooks/storage/post-swap.d/` with executable permissions.
- Hooks receive environment variables describing pool, serial, and status.

## Post-Swap Validation

- Monitor Netdata for I/O anomalies over the first 24 hours.
- Confirm Jellyfin and download clients have access to restored mounts.
- Schedule a SMART long test with `smartctl -t long` to baseline the disk.

## Troubleshooting

- If the disk fails to appear, reload the USB subsystem with
  `echo 0 | tee /sys/bus/usb/devices/<id>/authorized` followed by `1`.
- For repeated enclosure resets, enable the optional UPS integration to
  rule out power fluctuations.
