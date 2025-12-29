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

## Tdarr Transcoding Strategy

### SVT-AV1 vs GPU Encoding (Decision: 2025-12-29)

After adversarial benchmarking, we chose **CPU-based SVT-AV1** over GPU encoding:

| Method | Encoder | Output Size | Speed | Quality |
|--------|---------|-------------|-------|---------|
| **SVT-AV1 (CPU)** | `libsvtav1` | 4.1 MB | ~2x | Excellent |
| AV1 VAAPI (GPU) | `av1_vaapi` | 12 MB | ~15x | Good |
| HEVC VAAPI (GPU) | `hevc_vaapi` | 8 MB | ~25x | Good |

**Conclusion**: SVT-AV1 produces ~3x smaller files than GPU encoding. For a 28TB library, this represents **9-14TB of potential savings**. The slower encode speed is acceptable for "let it cook" batch processing.

### SVT-AV1 Production Settings

```bash
# Optimized for 96GB RAM, 16-thread CPU, 8 concurrent workers
-c:v libsvtav1 -crf 30 -preset 5 -pix_fmt yuv420p10le \
  -svtav1-params tune=0:enable-overlays=1:scd=1:film-grain=8:keyint=10s:lp=2:pin=0
```

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `crf 30` | Quality target | Balanced quality/size (~65% reduction) |
| `preset 5` | Speed | Moderate speed, good compression |
| `film-grain=8` | Synthesis | Better compression for grainy content |
| `lp=2` | Thread pools | 2 threads per worker (8 workers × 2 = 16 threads) |
| `pin=0` | CPU affinity | Disable pinning for better scheduler flexibility |
| `keyint=10s` | Keyframe interval | 10 seconds between keyframes |

### Worker Configuration (.env)

```bash
# CPU-dominant for maximum compression
TDARR_TRANSCODE_GPU_WORKERS=1      # Keep 1 GPU for quick wins
TDARR_TRANSCODE_CPU_WORKERS=4      # Main CPU workload
TDARR_HEALTHCHECK_GPU_WORKERS=2    # GPU file validation (fast)
TDARR_HEALTHCHECK_CPU_WORKERS=0

# Secondary node - all CPU
TDARR_NODE_TRANSCODE_GPU_WORKERS=0
TDARR_NODE_TRANSCODE_CPU_WORKERS=4
TDARR_NODE_HEALTHCHECK_GPU_WORKERS=2
TDARR_NODE_HEALTHCHECK_CPU_WORKERS=0
```

### Flow Files

Production flows are stored in `tdarr-flows/`:
- `SVT-AV1_Production_v3.json` - Main production flow (recommended)
- Skips already-optimized AV1/VP9 content
- Only re-encodes bloated HEVC (>6Mbps bitrate)
- Uses VAAPI hardware decode → SVT-AV1 CPU encode

---

## MergerFS Performance Tuning

### RAM Caching (Critical for I/O Performance)

MergerFS can cause **CPU spikes (200%+)** with improper cache settings. On high-RAM systems (96GB), enable aggressive caching:

```bash
# Optimized mount options (96GB RAM system)
MOUNT_OPTS="defaults,allow_other,use_ino,cache.files=auto-full,dropcacheonclose=false,category.create=mfs,moveonenospc=true,minfreespace=50G,fsname=mergerfs-pool"
```

| Option | Value | Effect |
|--------|-------|--------|
| `cache.files` | `auto-full` | Aggressive page caching using available RAM |
| `dropcacheonclose` | `false` | Keep cache after file close (critical!) |
| `category.create` | `mfs` | Most-free-space policy for new files |
| `moveonenospc` | `true` | Auto-migrate if drive fills up |
| `minfreespace` | `50G` | Reserve 50GB per drive |

### Before/After Impact

| Metric | Before (`cache.files=off`) | After (`cache.files=auto-full`) |
|--------|----------------------------|--------------------------------|
| MergerFS CPU | 286% | 0-34% |
| I/O latency | High | Near-native |
| System responsiveness | Sluggish | Normal |

### Persistent Mount Configuration

Mount script: `~/.local/bin/mount-mergerfs-pool.sh`
Systemd service: `~/.local/bin/mergerfs-pool.service`

```bash
# Install systemd service for boot persistence
sudo cp ~/.local/bin/mergerfs-pool.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable mergerfs-pool.service
```

---

## Monitoring Checklist

- Track GPU utilisation with `nvidia-smi dmon` or `intel_gpu_top`.
- Track AMD GPU with `radeontop` or `cat /sys/kernel/debug/dri/0/amdgpu_pm_info`.
- Use Netdata's comparative graphs to detect regressions after updates.
- Record metrics before and after applying changes; store reports in
  `docs/advanced/performance-notes/` for institutional knowledge.
- Monitor MergerFS CPU with `htop` filtering for `mergerfs` process.
