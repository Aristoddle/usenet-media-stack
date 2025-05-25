# Hardware Command

The `hardware` command provides universal GPU detection, automatic driver installation, and intelligent hardware optimization for maximum transcoding performance across NVIDIA RTX, AMD VAAPI, Intel QuickSync, and Raspberry Pi VideoCore.

## Usage

```bash
usenet hardware <action> [options]
```

## Actions

| Action | Description | Example |
|--------|-------------|---------|
| `list` | Show hardware capabilities and recommendations | `usenet hardware list` |
| `optimize` | Generate hardware-optimized configurations | `usenet hardware optimize --auto` |
| `install-drivers` | Auto-install optimal GPU drivers | `usenet hardware install-drivers` |
| `benchmark` | Test transcoding performance | `usenet hardware benchmark` |
| `profile` | Manage performance profiles | `usenet hardware profile balanced` |

## Hardware Detection

### Show Capabilities

```bash
usenet hardware list
```

**Example output for NVIDIA RTX system:**
```bash
🚀 HARDWARE CAPABILITIES DETECTED

💎 GPU: NVIDIA GeForce RTX 4090
   • NVENC/NVDEC: ✓ Available (AV1, HEVC, H.264)
   • CUDA Cores: 16,384
   • VRAM: 24GB GDDR6X
   • Driver: 545.29.06 ✓ Optimal
   • Docker: nvidia-docker2 ✓ Installed

🧠 CPU: Intel Core i9-13900K
   • Cores: 24 (8P + 16E)
   • Threads: 32
   • Quick Sync: ✓ Available (AV1, HEVC, H.264)
   • AVX-512: ✓ Supported

💾 Memory: 64GB DDR5-5600
   • Available: 48GB (75%)
   • Suitable for: Dedicated performance profile

🚀 PERFORMANCE OPTIMIZATION OPPORTUNITIES:
   ✅ 4K HEVC transcoding: 60+ FPS (vs 2-5 FPS CPU-only)
   ✅ Simultaneous streams: 8+ concurrent 4K transcodes
   ✅ AV1 encoding: 50% smaller files than H.264
   ✅ HDR tone mapping: Real-time HDR10 to SDR conversion
   ✅ Power efficiency: 50W GPU vs 200W CPU transcoding

💡 RECOMMENDATIONS:
   • Use 'dedicated' performance profile for maximum throughput
   • Enable hardware transcoding in Jellyfin and Tdarr
   • Consider AV1 encoding for storage efficiency
```

**Example output for AMD system:**
```bash
🚀 HARDWARE CAPABILITIES DETECTED

🔥 GPU: AMD Radeon RX 7900 XTX
   • VAAPI/AMF: ✓ Available (HEVC, H.264)
   • Compute Units: 96
   • VRAM: 24GB GDDR6
   • Driver: AMDGPU 23.20 ✓ Current
   • VA-API: libva ✓ Configured

🧠 CPU: AMD Ryzen 9 7950X
   • Cores: 16
   • Threads: 32
   • Architecture: Zen 4
   • Integrated Graphics: None

💾 Memory: 32GB DDR5-5200
   • Available: 24GB (75%)
   • Suitable for: High performance profile

⚡ PERFORMANCE OPTIMIZATION OPPORTUNITIES:
   ✅ Hardware HEVC encoding: 10x faster than CPU
   ✅ VAAPI acceleration: Energy-efficient transcoding  
   ✅ Dual-stream processing: Encode while serving
   ✅ HDR10 passthrough: Preserve HDR metadata

💡 RECOMMENDATIONS:
   • Install mesa-va-drivers for optimal VAAPI support
   • Use 'high' performance profile for best balance
   • Enable AMF encoding in supported applications
```

## Driver Installation

### Automatic Driver Installation

```bash
usenet hardware install-drivers
```

**NVIDIA systems:**
```bash
🔧 Installing NVIDIA drivers...

📦 Detecting system:
   • OS: Ubuntu 22.04 LTS
   • Kernel: 6.2.0-39-generic
   • GPU: RTX 4090

🚀 Installing optimal drivers:
   ✓ nvidia-driver-545 (latest stable)
   ✓ nvidia-docker2 (container support)
   ✓ nvidia-cuda-toolkit (development tools)

⚙️ Configuring Docker integration:
   ✓ /etc/docker/daemon.json updated
   ✓ Docker service restarted
   ✓ nvidia-docker runtime available

🧪 Testing installation:
   ✓ nvidia-smi responds correctly
   ✓ NVENC/NVDEC capabilities detected
   ✓ Docker GPU access confirmed

✅ Installation complete! Reboot recommended.
```

**AMD systems:**
```bash
🔧 Installing AMD drivers...

📦 Detecting system:
   • OS: Ubuntu 22.04 LTS  
   • GPU: RX 7900 XTX

🚀 Installing optimal drivers:
   ✓ mesa-va-drivers (VAAPI support)
   ✓ libva-dev (development headers)
   ✓ vainfo (testing utility)

⚙️ Configuring VA-API:
   ✓ /etc/environment updated
   ✓ User added to video group
   ✓ Device permissions configured

🧪 Testing installation:
   ✓ vainfo shows available profiles
   ✓ Hardware acceleration verified
   ✓ VAAPI encoding confirmed

✅ Installation complete!
```

### Manual Driver Options

```bash
# Install specific driver version
usenet hardware install-drivers --version 545.29.06

# Install with development tools
usenet hardware install-drivers --include-dev

# Test installation without installing
usenet hardware install-drivers --dry-run
```

## Performance Optimization

### Generate Optimized Configurations

```bash
usenet hardware optimize --auto
```

**Generated optimizations:**
1. **docker-compose.optimized.yml** - Hardware-tuned service configurations
2. **jellyfin.xml** - Transcoding settings for detected GPU
3. **tdarr_configs.json** - Optimized transcoding profiles
4. **ffmpeg_profiles/** - Hardware-specific encoding presets

### Performance Profiles

```bash
# Set specific performance profile
usenet hardware profile dedicated

# List available profiles  
usenet hardware profile list

# Show current profile
usenet hardware profile
```

| Profile | CPU Usage | RAM Allocation | GPU Usage | Use Case |
|---------|-----------|----------------|-----------|----------|
| `light` | 25% | 4GB | Optional | Development, testing |
| `balanced` | 50% | 8GB | Yes | Home server (default) |
| `high` | 75% | 16GB | Yes | Dedicated media server |
| `dedicated` | 100% | All available | Yes | Media center appliance |

### Custom Optimization

```bash
# Optimize for specific services
usenet hardware optimize --services jellyfin,tdarr

# Optimize for specific codec
usenet hardware optimize --codec hevc

# Generate profiles for all codecs
usenet hardware optimize --all-codecs
```

## Performance Benchmarking

### Transcoding Benchmarks

```bash
usenet hardware benchmark
```

**Example benchmark results:**
```bash
🧪 TRANSCODING PERFORMANCE BENCHMARK

Test Configuration:
• Source: 4K HEVC 10-bit HDR (50 Mbps)
• Target: 1080p H.264 8-bit SDR (8 Mbps)
• Duration: 60 seconds

📊 Results:

CPU-Only Transcoding:
⏱️  Time: 180 seconds (0.33x realtime)
⚡ Power: ~200W
🌡️  Temperature: 85°C
📈 CPU Usage: 100%

GPU-Accelerated (NVENC):
⏱️  Time: 30 seconds (2.0x realtime) 
⚡ Power: ~50W total
🌡️  Temperature: 65°C
📈 GPU Usage: 45%

Improvement:
🚀 Speed: 6x faster
💡 Power: 75% reduction  
❄️  Temperature: 20°C cooler
```

### Custom Benchmark Tests

```bash
# Test specific codec
usenet hardware benchmark --codec hevc

# Test multiple concurrent streams
usenet hardware benchmark --streams 4

# Test different resolutions
usenet hardware benchmark --resolution 1080p,4k
```

## Hardware Configurations

### Generated Docker Compose

**docker-compose.optimized.yml** (NVIDIA example):
```yaml
services:
  jellyfin:
    deploy:
      resources:
        limits:
          memory: 8G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
    volumes:
      - ./config/jellyfin_hw.xml:/config/encoding.xml:ro

  tdarr:
    deploy:
      resources:
        limits:
          memory: 16G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - serverIP=0.0.0.0
      - serverPort=8266
      - webUIPort=8265
      - internalNode=true
      - nodeID=MainNode
```

### Jellyfin Hardware Transcoding

**Generated config/jellyfin_hw.xml:**
```xml
<EncodingOptions>
  <HardwareAccelerationType>nvenc</HardwareAccelerationType>
  <EnableHardwareDecoding>true</EnableHardwareDecoding>
  <EnableHardwareEncoding>true</EnableHardwareEncoding>
  <EnableToneMappingDecodingWithNvenc>true</EnableToneMappingDecodingWithNvenc>
  <AllowHardwareSubtitleExtraction>true</AllowHardwareSubtitleExtraction>
  <H264Crf>23</H264Crf>
  <H265Crf>28</H265Crf>
  <DeinterlaceMethod>yadif</DeinterlaceMethod>
  <EnableDecodingColorDepth10Hevc>true</EnableDecodingColorDepth10Hevc>
  <EnableEnhancedNvdecDecoder>true</EnableEnhancedNvdecDecoder>
</EncodingOptions>
```

## Multi-GPU Support

### GPU Selection

```bash
# List available GPUs
usenet hardware list --gpus

# Optimize for specific GPU
usenet hardware optimize --gpu 0

# Use multiple GPUs
usenet hardware optimize --gpu all
```

**Multi-GPU allocation:**
```bash
🔧 Multiple GPUs detected:

GPU 0: NVIDIA RTX 4090 (24GB) - Primary transcoding
GPU 1: NVIDIA RTX 3080 (10GB) - Secondary transcoding  

Service allocation:
• Jellyfin: GPU 0 (primary streaming)
• Tdarr: GPU 1 (background processing)
• Handbrake: GPU 0 (manual encoding)
```

## Advanced Features

### Custom FFmpeg Profiles

```bash
# Generate custom encoding profiles
usenet hardware generate-profiles --quality high --efficiency balanced

# Create profile for specific use case
usenet hardware generate-profiles --profile "4k-archive" \
  --input-format "hevc" \
  --output-format "av1" \
  --crf 28 \
  --preset slow
```

### Hardware Monitoring

```bash
# Real-time hardware monitoring during transcoding
usenet hardware monitor

# Monitor specific metrics
usenet hardware monitor --metrics gpu-util,temp,power

# Log monitoring data
usenet hardware monitor --log /var/log/hardware-monitor.log
```

### Power Management

```bash
# Set GPU power limits (NVIDIA)
usenet hardware power-limit --gpu 0 --watts 300

# Enable GPU boost
usenet hardware boost enable

# Set performance mode
usenet hardware performance-mode max
```

## Examples

::: code-group

```bash [NVIDIA RTX Setup]
# Detect hardware capabilities
usenet hardware list

# Install optimal drivers
usenet hardware install-drivers

# Generate optimized configs
usenet hardware optimize --auto

# Set high performance profile
usenet hardware profile high

# Benchmark performance
usenet hardware benchmark
```

```bash [AMD RDNA Setup]
# Check VAAPI support
usenet hardware list

# Install VAAPI drivers
usenet hardware install-drivers

# Optimize for AMD hardware
usenet hardware optimize --amd

# Test hardware acceleration
usenet hardware benchmark --codec hevc
```

```bash [Intel QuickSync Setup]
# Detect QuickSync capabilities
usenet hardware list --intel

# Install Intel media drivers
usenet hardware install-drivers --intel

# Optimize for QuickSync
usenet hardware optimize --quicksync

# Set balanced profile (recommended for Intel)
usenet hardware profile balanced
```

```bash [Raspberry Pi Setup]
# Detect VideoCore capabilities
usenet hardware list

# Enable GPU memory split
usenet hardware configure --pi --gpu-mem 128

# Optimize for low power
usenet hardware profile light

# Test hardware decode
usenet hardware benchmark --pi-test
```

:::

## Troubleshooting

### Common Issues

**GPU not detected:**
```bash
# Check driver installation
nvidia-smi  # NVIDIA
vainfo      # AMD
intel_gpu_top  # Intel

# Reinstall drivers
usenet hardware install-drivers --force
```

**Docker GPU access denied:**
```bash
# Check nvidia-docker installation
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# Fix permissions
sudo usermod -aG docker $USER
sudo systemctl restart docker
```

**Poor transcoding performance:**
```bash
# Check hardware utilization
usenet hardware monitor

# Verify optimal profile
usenet hardware profile dedicated

# Check thermal throttling
usenet hardware temperature
```

### Hardware Logs

```bash
# View hardware optimization logs
usenet logs hardware

# Debug driver installation
usenet hardware install-drivers --verbose

# Monitor real-time GPU usage
usenet hardware monitor --live
```

### Performance Analysis

```bash
# Analyze transcoding bottlenecks
usenet hardware analyze

# Compare profiles
usenet hardware benchmark --compare-profiles

# Export performance report
usenet hardware report --export performance.json
```

## Cross-Platform Support

### Platform-Specific Optimizations

**Ubuntu/Debian:**
```bash
# APT-based driver installation
usenet hardware install-drivers --apt

# Enable restricted repositories
usenet hardware enable-repos --non-free
```

**CentOS/RHEL:**
```bash
# YUM/DNF-based installation  
usenet hardware install-drivers --yum

# Enable EPEL repository
usenet hardware enable-repos --epel
```

**Arch Linux:**
```bash
# Pacman-based installation
usenet hardware install-drivers --pacman

# Enable AUR packages
usenet hardware enable-repos --aur
```

### Container Runtimes

```bash
# Configure for Podman
usenet hardware configure --runtime podman

# Configure for containerd
usenet hardware configure --runtime containerd

# Configure for Docker with BuildKit
usenet hardware configure --buildkit
```

## Related Commands

- [`deploy`](./deploy) - Include hardware optimization in deployment
- [`storage`](./storage) - Optimize storage layout for transcoding
- [`services`](./services) - Configure service-specific hardware settings
- [`validate`](./validate) - Hardware health checks