# Tdarr Encoding Strategy - AMD VAAPI (RDNA3)

**Last Updated**: 2025-12-28
**Hardware**: AMD Radeon 780M (VCN 4.0)
**Encoder**: hevc_vaapi (NOT av1_vaapi - too immature)

---

## Why HEVC Over AV1?

1. **Encoder Maturity**: AMD's HEVC encoder has years of optimization; AV1 is new
2. **Quality at Speed**: Hardware AV1 doesn't leverage AV1's advantages at realtime speeds
3. **Compatibility**: HEVC plays everywhere; AV1 still has gaps (older devices, some TVs)

Source: [Reddit r/AV1 Discussion](https://www.reddit.com/r/AV1) - "HEVC is older and mature"

---

## Critical: CRF vs QP

**VAAPI does NOT support CRF!**

- Software encoders (x265): Use `-crf <value>`
- Hardware encoders (VAAPI): Use `-qp <value>` or `-global_quality <value>`

These are NOT equivalent scales. QP 22 ≠ CRF 22.

Source: [FFmpeg VAAPI Guide](https://gist.github.com/Brainiarc7/95c9338a737aa36d9bb2931bed379219)

---

## Recommended QP Values

| Content Type | QP | Rationale |
|--------------|-----|-----------|
| **4K UHD Blu-ray Rips** | 20 | Preserve premium source quality |
| **1080p Movies** | 21 | High quality, good compression |
| **TV Shows** | 22 | Episodic content, balance storage |
| **Anime** | 21 | Line art benefits from lower QP |

Source: [CRF Guide](https://slhck.info/video/2017/02/24/crf-guide.html), [VideoHelp Forum](https://forum.videohelp.com/threads/416630-What-is-a-good-HEVC-CRF-rate-to-balance-Size-with-Quality)

---

## FFmpeg Command Template

```bash
ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
  -hwaccel_output_format vaapi \
  -i "input.mkv" \
  -c:v hevc_vaapi \
  -rc_mode 1 \
  -qp 20 \
  -c:a copy \
  -c:s copy \
  "output.mkv"
```

### Parameter Explanation

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `-hwaccel vaapi` | - | Use VAAPI hardware acceleration |
| `-hwaccel_output_format vaapi` | - | Keep frames on GPU (faster) |
| `-rc_mode 1` | CQP | Constant Quality mode |
| `-qp 20` | 20 | Quality level (lower = better) |
| `-c:a copy` | - | Preserve original audio |
| `-c:s copy` | - | Preserve subtitles |

---

## Expected Results

| Resolution | Original (H.264) | After HEVC QP20 | Savings |
|------------|------------------|-----------------|---------|
| 4K UHD | 40-60 GB | 20-35 GB | ~40-45% |
| 1080p | 15-25 GB | 8-14 GB | ~40-50% |
| 720p | 5-10 GB | 3-5 GB | ~45-50% |

---

## Why NOT "Actually Lossless"?

1. **Lossless HEVC** would be larger than source (pointless)
2. **QP 0** is mathematically lossless but huge files
3. **QP 18-20** is "visually lossless" - human eye can't distinguish
4. If true lossless matters, keep the original source

**Philosophy**: You acquired max-bitrate sources for quality. QP 20 preserves that while saving 40% space. Going lower (QP 18) gives diminishing returns.

---

## Tdarr Plugin/Flow Notes

For Tdarr, use a custom ffmpeg command flow rather than built-in plugins. The built-in plugins often don't expose `-rc_mode` and `-qp` properly for VAAPI.

Custom flow should:
1. Filter: Only process non-HEVC files
2. Filter: Skip files already < 10 Mbps average bitrate
3. Transcode: hevc_vaapi with settings above
4. Verify: Output is smaller than input (reject if not)
