# ISO Disc Image Re-encoding Workflow

> **Purpose**: Convert .iso disc images to high-fidelity, Plex-optimized media files
> **Last Updated**: 2025-12-25

---

## Why Re-encode ISOs?

| Factor | Raw ISO | Re-encoded |
|--------|---------|------------|
| Size | 25-50GB (Blu-ray) | 8-15GB (same quality) |
| Plex compatibility | Requires disc menu | Direct play |
| Streaming | Impossible | Native |
| Storage efficiency | ~30% of capacity | 100% usable |
| Quality | Lossless (overkill) | Visually lossless |

**Your math is correct**: A 40GB Blu-ray ISO → ~12GB HEVC/AV1 at visually lossless quality = **70% storage savings** with no perceptible loss.

---

## Recommended Toolchain

### Primary: MakeMKV + HandBrake

```
ISO/Disc → MakeMKV → .mkv (lossless) → HandBrake → Final .mkv (encoded)
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
