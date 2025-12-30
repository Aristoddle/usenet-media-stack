# ISO to AV1 Transcoding Pipeline

> **Purpose**: Convert Blu-ray ISOs to highly compressed AV1 files for Plex
> **Last Updated**: 2025-12-29
> **Pipeline**: ISO -> MakeMKV (Docker) -> Tdarr (SVT-AV1)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         ISO → AV1 TRANSCODING PIPELINE                          │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  STAGE 1: ISO EXTRACTION (MakeMKV Container)                                   │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  scripts/iso-to-mkv-processor.sh                                        │   │
│  │  - Scans pool/movies for .iso files                                     │   │
│  │  - Extracts main title (>60min) via MakeMKV CLI                         │   │
│  │  - Outputs lossless MKV to downloads/makemkv-output/                    │   │
│  │  - Tracks processed ISOs to avoid re-extraction                         │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                              │                                                  │
│                              ▼                                                  │
│  STAGE 2: AV1 ENCODING (Tdarr)                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │  tdarr-flows/SVT-AV1_Production_v3.json                                 │   │
│  │  - VAAPI hardware decode (GPU-accelerated)                              │   │
│  │  - SVT-AV1 CPU encode (libsvtav1, CRF 30)                               │   │
│  │  - Film grain synthesis for better compression                          │   │
│  │  - 60-70% file size reduction                                           │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Why This Pipeline?

| Factor | Raw ISO | MKV (Lossless) | AV1 (Final) |
|--------|---------|----------------|-------------|
| Size | 40GB | 35GB | **10-12GB** |
| Plex compatible | No (disc menu) | Yes | Yes |
| Streaming | Impossible | Possible | Excellent |
| CPU decode cost | High | Medium | Low |
| Storage savings | 0% | 12% | **70%** |

**Bottom line**: 40GB Blu-ray ISO -> 12GB AV1 = **70% storage savings** with visually lossless quality.

---

## Component Details

### Stage 1: MakeMKV Container

The Docker stack includes a dedicated MakeMKV container for ISO extraction:

```yaml
# docker-compose.yml excerpt
makemkv:
  image: jlesage/makemkv:latest
  container_name: makemkv
  environment:
    - MAKEMKV_KEY=BETA           # Auto-fetch beta key
    - AUTO_DISC_RIPPER=0         # ISO-only mode
  volumes:
    - ${CONFIG_ROOT}/makemkv:/config
    - ${POOL_ROOT}:/pool:ro      # Read ISOs from pool
    - ${DOWNLOADS_ROOT}/makemkv-output:/output
  ports:
    - 5800:5800                  # Web GUI
```

**Key Points**:
- Uses free BETA license (auto-refreshes)
- Read-only pool access for safety
- Output goes to staging area (not directly to library)

### Stage 2: ISO Processor Script

The `scripts/iso-to-mkv-processor.sh` automates extraction:

```bash
# Scan for ISOs and show status
./scripts/iso-to-mkv-processor.sh --scan

# Process all unprocessed ISOs
./scripts/iso-to-mkv-processor.sh

# Process specific ISO
./scripts/iso-to-mkv-processor.sh /var/mnt/pool/movies/Some.Movie.2024/movie.iso

# Watch mode (continuous monitoring)
./scripts/iso-to-mkv-processor.sh --watch
```

**Environment Variables**:
| Variable | Default | Purpose |
|----------|---------|---------|
| `POOL_ROOT` | `/var/mnt/pool` | Media pool base path |
| `MAKEMKV_OUTPUT` | `${DOWNLOADS_ROOT}/makemkv-output` | MKV output directory |
| `MAKEMKV_MIN_LENGTH` | `3600` | Min title length (60min filters bonus content) |

### Stage 3: Tdarr SVT-AV1 Flow

After MKV extraction, Tdarr encodes to AV1:

**Flow**: `tdarr-flows/SVT-AV1_Production_v3.json`

```json
{
  "name": "SVT-AV1 Production v3 (Fixed)",
  "description": "VAAPI decode -> SVT-AV1 CPU encode",
  "flowPlugins": [
    "inputFile",
    "checkVideoCodec (skip AV1/VP9)",
    "checkVideoBitrate (only HEVC >6Mbps)",
    "ffmpegCommandStart (VAAPI decode)",
    "ffmpegCommandCustomArguments (SVT-AV1)",
    "ffmpegCommandSetContainer (MKV)",
    "ffmpegCommandExecute",
    "compareFileSizeRatio",
    "replaceOriginalFile"
  ]
}
```

**SVT-AV1 Encode Parameters**:
```bash
-c:v libsvtav1 -crf 30 -preset 5 -pix_fmt yuv420p10le \
  -svtav1-params tune=0:enable-overlays=1:scd=1:film-grain=8:keyint=10s:lp=2:pin=0
```

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `crf 30` | Quality | ~65% size reduction, excellent quality |
| `preset 5` | Speed | Balanced speed/compression |
| `film-grain=8` | Compression | Film grain synthesis for grainy content |
| `lp=2` | Threads | 2 thread pools per worker |
| `pin=0` | Affinity | Let OS schedule threads |

---

## Systemd Service (Optional)

For automatic ISO watching on boot:

```bash
# Install service
sudo cp systemd/iso-processor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable iso-processor.service
sudo systemctl start iso-processor.service

# Check status
systemctl status iso-processor.service
```

Service watches `pool/movies` and auto-processes new ISOs.

---

## Original Toolchain Reference

### Primary: MakeMKV + Tdarr (Recommended)

```
ISO → MakeMKV (Docker) → .mkv (lossless) → Tdarr → Final .mkv (AV1)
```

This is the production pipeline documented above.

### Alternative: MakeMKV + HandBrake (Manual)

```
ISO → MakeMKV → .mkv (lossless) → HandBrake → Final .mkv (HEVC/AV1)
```

1. **MakeMKV** ($50 lifetime, free beta available)
   - Extracts main feature from ISO/disc
   - Preserves all audio tracks, subtitles
   - Outputs lossless .mkv container
   - No re-encoding (fast, no quality loss)

2. **HandBrake** (free, open source)
   - Re-encodes video to efficient codec
   - Preserves/converts audio
   - Adds chapter markers
   - Outputs Plex-ready .mkv

### Alternative: FFmpeg (CLI, scriptable)

```bash
ffmpeg -i input.mkv -c:v libsvtav1 -crf 22 -preset 4 \
       -c:a copy -c:s copy output.mkv
```

---

## Encoding Presets for Maximum Quality

### Video: AV1 (Preferred for new encodes)

```yaml
# HandBrake Settings - AV1 High Quality
Codec: SVT-AV1
Encoder Preset: 4 (balanced speed/quality)
Quality: CRF 20-22 (visually lossless)
Resolution: Same as source
Frame Rate: Same as source

# Estimated output:
# - 1080p Blu-ray: 6-10GB
# - 4K UHD Blu-ray: 15-25GB
```

### Video: HEVC (Fallback for compatibility)

```yaml
# HandBrake Settings - HEVC High Quality
Codec: x265
Encoder Preset: Slow (better compression)
Quality: CRF 18-20 (visually lossless)
Resolution: Same as source

# Estimated output:
# - 1080p Blu-ray: 8-12GB
# - 4K UHD Blu-ray: 20-35GB
```

### Audio: Preserve Quality

```yaml
# Preferred Audio Handling
Track 1: Passthrough (TrueHD/DTS-HD MA if present)
Track 2: AAC Stereo 256kbps (compatibility fallback)

# For space savings (still excellent):
Track 1: FLAC/Opus lossless
Track 2: AAC Stereo

# Do NOT: Re-encode Atmos/TrueHD to lossy
```

### Subtitles

```yaml
# Include all subtitle tracks
- PGS (Blu-ray native) - Passthrough
- SRT (text) - if available
- Forced subs - Always include
```

---

## Workflow: Batch Processing ISOs

### Step 1: Extract with MakeMKV

```bash
# Single ISO
makemkvcon mkv iso:/path/to/movie.iso all /output/dir

# Batch (all ISOs in directory)
for iso in /path/to/isos/*.iso; do
    name=$(basename "$iso" .iso)
    makemkvcon mkv iso:"$iso" all "/output/$name/"
done
```

### Step 2: Encode with HandBrake CLI

```bash
# AV1 high-quality encode
HandBrakeCLI \
    --input "/output/movie/title_main.mkv" \
    --output "/final/Movie (Year)/Movie (Year).mkv" \
    --encoder svt_av1 \
    --encoder-preset 4 \
    --quality 21 \
    --audio-lang-list und,eng,jpn \
    --all-audio \
    --aencoder copy \
    --all-subtitles \
    --subtitle-lang-list und,eng \
    --markers
```

### Step 3: Verify & Cleanup

```bash
# Verify output plays
ffprobe "/final/Movie (Year)/Movie (Year).mkv"

# Check file size ratio
original=$(stat -c%s "$iso")
encoded=$(stat -c%s "/final/Movie (Year)/Movie (Year).mkv")
ratio=$((100 * encoded / original))
echo "Compression: ${ratio}% of original"
```

---

## Quality Verification Checklist

- [ ] Video plays without artifacts
- [ ] Audio tracks present (all languages)
- [ ] Subtitles work (forced + full)
- [ ] Chapters preserved
- [ ] HDR/Dolby Vision intact (if source had it)
- [ ] File size reasonable (not larger than source)

---

## Hardware Acceleration (Optional)

### Your System: AMD Ryzen 7840HS

```yaml
# VCN 4.0 Hardware Encoding
# Faster but slightly lower quality than software

# HandBrake Setting:
Encoder: AMD VCE HEVC  # or AV1 if supported

# FFmpeg:
ffmpeg -i input.mkv -c:v hevc_amf -quality quality \
       -c:a copy output.mkv
```

**Recommendation**: Use software encoding (SVT-AV1) for archival quality. Hardware encoding is fine for previews/quick conversions.

---

## Integration with *arr Stack

### Option A: Post-Import Script (Radarr/Sonarr)

```yaml
# In Radarr/Sonarr settings → Connect → Custom Script
Path: /path/to/iso-to-mkv.sh
On Import: Yes
```

### Option B: Unmanic (Automated Library Optimization)

Unmanic is a dedicated library optimizer that watches for new files and re-encodes them automatically.

```yaml
# docker-compose.yml addition
unmanic:
  image: josh5/unmanic
  volumes:
    - /movies:/library
    - ./unmanic-config:/config
```

### Option C: Tdarr (Distributed Transcoding)

For large libraries, Tdarr distributes encoding across multiple nodes.

---

## CRF Quality Guide

| CRF | Quality | Use Case |
|-----|---------|----------|
| 16-18 | Transparent | Archival master |
| 19-21 | Visually lossless | **Recommended for library** |
| 22-24 | High quality | Storage-constrained |
| 25-28 | Good quality | Streaming copies |

**Your target**: CRF 20-21 for maximum quality with reasonable size.

---

## Handling Special Cases

### 4K HDR with Dolby Vision

```bash
# Preserve Dolby Vision (requires profile 8.1)
HandBrakeCLI ... --encoder svt_av1_10bit --colorspace bt2020
# Note: Full DV preservation may require dovi_tool
```

### Anime (Film Grain)

```bash
# Add film-grain synthesis for anime
--encoder-tune animation
# Or for live-action grain preservation:
--encoder-tune film
```

### Multi-Disc Sets (Lord of the Rings Extended, etc.)

```bash
# Extract each disc separately
makemkvcon mkv iso:disc1.iso all /temp/disc1/
makemkvcon mkv iso:disc2.iso all /temp/disc2/

# Verify chapter alignment
# Then concatenate or keep as parts
```

---

## Storage Impact Examples

| Title | ISO Size | Encoded (AV1 CRF21) | Savings |
|-------|----------|---------------------|---------|
| Typical 1080p Blu-ray | 35GB | 10GB | 71% |
| 4K UHD Blu-ray | 65GB | 20GB | 69% |
| Anime Blu-ray (12 eps) | 40GB | 8GB | 80% |
| Concert/Documentary | 25GB | 6GB | 76% |

**48TB library of ISOs → ~15TB re-encoded = 33TB freed**

---

## Document Maintenance

**Update when**: New codecs emerge, HandBrake updates, hardware transcoding improves.

---

*"You're not losing quality. You're removing the overhead of a physical disc format that your server doesn't need."*
