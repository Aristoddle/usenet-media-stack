# Hardware Optimization

Automatic GPU detection and optimization for maximum performance.

## Supported Hardware

- **NVIDIA RTX Series**: NVENC/NVDEC acceleration
- **AMD GPUs**: VAAPI/AMF acceleration  
- **Intel QuickSync**: Hardware transcoding
- **Raspberry Pi**: VideoCore optimization

## Quick Start

```bash
# Detect your hardware
./usenet --hardware detect

# Auto-optimize configuration
./usenet --hardware optimize --auto

# Install drivers
./usenet --hardware install-drivers
```

## Performance Gains

<PerformanceMetrics />

### Real-World Benefits
- 4K HEVC: 2-5 FPS → 60+ FPS (1200% improvement)
- Power usage: 200W CPU → 50W GPU (75% reduction)  
- Multiple streams: 8+ concurrent 4K transcodes
- HDR10+ tone mapping with zero quality loss