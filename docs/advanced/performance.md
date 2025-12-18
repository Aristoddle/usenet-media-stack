---
title: Performance Optimisation
layout: doc
---

# Performance Optimisation

Formerly published at `codex/collab/performance.md`, this guide explains
how to tune compute, network, and storage layers for demanding workflows.

## Performance Baselines

- **Transcoding**: Plex hardware transcoding should reach 60 FPS for 4K HEVC on
  supported GPUs (Plex Pass required for hardware acceleration).
- **Downloads**: SABnzbd saturates gigabit links with tuned article cache
  and parallelism settings.
- **Indexing**: Prowlarr updates should complete within five minutes even
  with large tracker lists.

## Hardware Profiles

| Profile        | Target Hardware         | Activation Command            |
|----------------|-------------------------|-------------------------------|
| `gpu`          | NVIDIA/AMD/Intel GPUs    | `USENET_PROFILE=gpu ./usenet` |
| `low-power`    | ARM or low TDP systems   | `USENET_PROFILE=eco ./usenet` |
| `storage-heavy`| JBOD enclosures          | `USENET_PROFILE=jbod ./usenet`|

Profiles adjust compose overrides to allocate CPU shares, memory limits,
and GPU device mappings.

## Plex Optimisation

1. Install the latest drivers for your GPU family.
2. Enable hardware transcoding in the Plex dashboard and map `/dev/dri`
   via the hardware profile.
3. Keep transcoder temp on fast storage and leave 1-2 CPU cores free for
   other services under sustained load.

## Download Pipeline

- Increase SABnzbd's article cache to 750 MB on systems with 16 GB RAM.
- Enable `DirectUnpack` to reduce disk churn during extraction.
- Use SSD-backed temp directories for unpacking to avoid HDD contention.

## Database Tuning

- Set PostgreSQL's `shared_buffers` to 25% of system RAM when running Lidarr
  or other heavy metadata services.
- Schedule nightly `VACUUM` tasks via cron to keep sqlite stores healthy.
- Consolidate logs using Loki to reduce random writes on spinning disks.

## Monitoring Checklist

- Track GPU utilisation with `nvidia-smi dmon` or `intel_gpu_top`.
- Use Netdata's comparative graphs to detect regressions after updates.
- Record metrics before and after applying changes; store reports in
  `docs/advanced/performance-notes/` for institutional knowledge.
