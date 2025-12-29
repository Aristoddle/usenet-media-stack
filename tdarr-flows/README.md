# Tdarr Flow Configurations

Custom Tdarr flow files for SVT-AV1 encoding optimized for maximum storage efficiency.

## Production Flow (Recommended)

**File**: `SVT-AV1_Production_v3.json`

This is the production-ready flow with all fixes applied from adversarial review.

### Flow Logic

```
Input File
    │
    ▼
[Skip if AV1?] ──yes──► Keep Original (already optimal)
    │no
    ▼
[Skip if VP9?] ──yes──► Keep Original (already efficient)
    │no
    ▼
[Is HEVC?] ──yes──► [Bitrate >6Mbps?] ──yes──► Encode to AV1
    │no                    │no
    ▼                      ▼
Encode to AV1        Keep Original (already efficient HEVC)
    │
    ▼
[Compare Size]
    │
    ▼
[Smaller?] ──yes──► Replace Original
    │no
    ▼
Keep Original
```

### Key Features

- **Smart Skip Logic**: Preserves already-efficient AV1, VP9, and low-bitrate HEVC
- **VAAPI Decode**: Hardware-accelerated decoding (`-hwaccel vaapi`)
- **SVT-AV1 Encode**: CPU encoding for maximum compression
- **Thread Management**: `lp=2:pin=0` prevents CPU thrashing with 8 concurrent workers
- **Film Grain Synthesis**: `film-grain=8` for better compression on grainy content

### FFmpeg Command

```bash
-hwaccel vaapi -hwaccel_device /dev/dri/renderD128
-map 0 -c:v libsvtav1 -crf 30 -preset 5 -pix_fmt yuv420p10le \
  -svtav1-params tune=0:enable-overlays=1:scd=1:film-grain=8:keyint=10s:lp=2:pin=0 \
  -c:a copy -c:s copy -max_muxing_queue_size 9999
```

## Other Flows (Historical)

| File | Status | Notes |
|------|--------|-------|
| `SVT-AV1_Production_v3.json` | **Production** | Use this one |
| `SVT-AV1_Optimized_v2.json` | Deprecated | Fixed thread issues, missing size check |
| `SVT-AV1_Optimized.json` | Deprecated | Missing `lp=2:pin=0` threading |
| `SVT-AV1_Anime.json` | Experimental | Higher film-grain for anime content |
| `Storage_Optimized_libx265.json` | Legacy | HEVC fallback, larger files |

## Installation

1. Open Tdarr web UI (http://localhost:8265)
2. Go to **Flows** tab
3. Click **Import Flow**
4. Select `SVT-AV1_Production_v3.json`
5. Assign flow to libraries in **Libraries** tab

## Worker Configuration

For optimal performance with 8 concurrent workers on a 16-thread CPU:

```bash
# In .env file
TDARR_TRANSCODE_GPU_WORKERS=1      # Keep 1 GPU for quick wins
TDARR_TRANSCODE_CPU_WORKERS=4      # Main CPU workload
TDARR_HEALTHCHECK_GPU_WORKERS=2    # GPU file validation (fast)
TDARR_HEALTHCHECK_CPU_WORKERS=0
```

The `lp=2` parameter in SVT-AV1 limits each encode to 2 threads:
- 8 workers × 2 threads = 16 threads total (matches CPU)

## Expected Results

| Source | Output | Reduction |
|--------|--------|-----------|
| H.264 1080p (10 Mbps) | AV1 (2 Mbps) | ~80% |
| HEVC 1080p (8 Mbps) | AV1 (2 Mbps) | ~75% |
| HEVC 4K HDR (20 Mbps) | AV1 (6 Mbps) | ~70% |

## Troubleshooting

### Workers Not Starting

```bash
# Check VAAPI availability inside container
docker exec -it tdarr vainfo

# Verify DRI device mounted
docker exec -it tdarr ls -la /dev/dri/
```

### High CPU Load

If CPU load exceeds 100% per worker:
1. Verify `lp=2:pin=0` is in SVT-AV1 params
2. Reduce concurrent workers in `.env`
3. Check for other encoding processes

### Files Skipped Unexpectedly

Check the flow logic - files are intentionally skipped if:
- Already AV1 or VP9 codec
- HEVC with bitrate under 6 Mbps
- Encoded file is larger than original

## Related Documentation

- [Performance Tuning](../docs/advanced/performance.md) - Full SVT-AV1 vs GPU analysis
- [.env Configuration](../.env.example) - Worker count settings
