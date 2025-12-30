# Tdarr Setup Guide for AMD VAAPI Transcoding

## Quick Start

```bash
cd ~/Documents/Code/media-automation/usenet-media-stack
docker compose -f docker-compose.tdarr.yml up -d
```

Access UI: http://localhost:8265

## Recommended Transcode Flow

### Library Settings

1. **Movies Library** (`/media/movies`)
   - Source: `/media/movies`
   - Transcode Cache: `/temp`
   - Output: Same as source (in-place replacement)

2. **Anime Library** (`/media/anime`)
   - Same settings, anime-optimized presets

### Plugin Stack (Recommended Order)

1. **Filter by Codec** - Skip files already HEVC/AV1
2. **Filter by Resolution** - Process 1080p+ only
3. **Filter by Size** - Skip files under 1GB (already efficient)
4. **Transcode to HEVC (VAAPI)** - Main transcoding
5. **Remove Duplicate Audio Tracks** - Keep original + one commentary max
6. **Remove Subtitle Formats** - Keep SRT/ASS, remove PGS if SRT exists

### FFmpeg VAAPI Command Template

```bash
# For 1080p H.264 → HEVC
ffmpeg -vaapi_device /dev/dri/renderD128 \
  -i input.mkv \
  -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi \
  -qp 22 \
  -c:a copy \
  -c:s copy \
  output.mkv
```

### Quality Settings

| Resolution | CRF/QP | Expected Savings |
|------------|--------|------------------|
| 4K UHD     | 20-22  | 40-50%           |
| 1080p      | 22-24  | 50-60%           |
| 720p       | 24-26  | 40-50%           |

### Storage Projections

Current: ~11 TB movies on disk
After HEVC transcode: ~5-7 TB (estimated)
Savings: **4-6 TB**

## Plugins to Install

In Tdarr UI → Plugins, search and install:

1. `Tdarr_Plugin_MC93_Migz1FFMPEG` - General HEVC transcode
2. `Tdarr_Plugin_MC93_Migz5ConvertAudio` - Audio normalization
3. `Tdarr_Plugin_bsh1_Boosh_FFMPEG_QSV_VAAPI` - AMD VAAPI specific
4. `Tdarr_Plugin_00td_filter_by_codec` - Skip already-processed
5. `Tdarr_Plugin_lmg1_Reorder_Streams` - Clean stream order

## Health Checks

```bash
# Verify VAAPI is accessible in container
docker exec -it tdarr vainfo

# Check transcode progress
docker logs -f tdarr

# Monitor GPU usage during transcode
watch -n 1 'cat /sys/class/drm/card*/device/gpu_busy_percent'
```

## Deduplication

For actual file deduplication, consider:
- **jdupes** - Fast duplicate finder
- **rdfind** - Creates hardlinks for duplicates

```bash
# Find duplicates by content hash
jdupes -r -S /var/mnt/pool/movies

# Replace duplicates with hardlinks (saves space)
jdupes -r -L /var/mnt/pool/movies
```
