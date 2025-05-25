# Performance Tuning

Comprehensive guide to optimizing your Usenet Media Stack for maximum performance, covering hardware optimization, system tuning, service configuration, and benchmarking techniques for professional-grade media automation.

## Performance Philosophy

### Optimization Hierarchy

```
Performance Optimization Strategy:
├── 1. Hardware Optimization (10-50x gains)
│   ├── GPU acceleration for transcoding
│   ├── Fast storage for cache/temp operations
│   └── Sufficient RAM for service operations
├── 2. System Configuration (2-5x gains)
│   ├── Kernel parameter tuning
│   ├── Filesystem optimization
│   └── Network stack configuration
├── 3. Service Tuning (1.5-3x gains)
│   ├── Resource allocation optimization
│   ├── Service-specific settings
│   └── Workflow optimization
└── 4. Application Settings (1.2-2x gains)
    ├── Quality profile optimization
    ├── Download client tuning
    └── Monitoring overhead reduction
```

### Performance Targets

| Component | Baseline | Optimized | Best Possible |
|-----------|----------|-----------|---------------|
| **4K HEVC Transcoding** | 2-5 FPS | 30+ FPS | 60+ FPS |
| **Service Startup** | 5-10 minutes | 2-3 minutes | <1 minute |
| **Storage Hot-Swap** | 2-5 minutes | 30 seconds | 10 seconds |
| **Search Response** | 5-15 seconds | 1-3 seconds | <1 second |
| **Download Processing** | Manual | 90% automated | 98% automated |

## Hardware Optimization

### GPU Acceleration Deep Dive

#### NVIDIA RTX Performance Tuning

```bash
# Check current NVIDIA configuration
./usenet hardware list --detailed

# Generate optimized configuration
./usenet hardware optimize --target-resolution 4k --max-streams 8

# Fine-tune GPU memory allocation
nvidia-smi -pm 1  # Enable persistence mode
nvidia-smi -pl 300  # Set power limit (adjust for your card)
```

**Advanced NVIDIA Configuration:**
```yaml
# docker-compose.performance.yml
services:
  jellyfin:
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
      # NVIDIA-specific optimizations
      - NVIDIA_VISIBLE_DEVICES=all
      - NVIDIA_DRIVER_CAPABILITIES=compute,video,utility
      # FFmpeg NVENC optimizations
      - JELLYFIN_FFMPEG_OPT_HWACCEL=cuda
      - JELLYFIN_FFMPEG_OPT_HWACCEL_OUTPUT_FORMAT=cuda
      # Performance tuning
      - JELLYFIN_FFMPEG_PROBE_SIZE=2G
      - JELLYFIN_FFMPEG_ANALYZE_DURATION=500M
    sysctls:
      # GPU memory management
      - kernel.shmmax=68719476736
      - kernel.shmmni=4096
```

#### AMD GPU Optimization

```bash
# Verify VAAPI support
vainfo

# Install optimization packages
sudo apt-get install mesa-va-drivers-all vainfo radeontop

# Monitor GPU usage
radeontop
```

**AMD-Specific Configuration:**
```yaml
services:
  jellyfin:
    devices:
      - /dev/dri:/dev/dri
    environment:
      # AMD VAAPI optimizations
      - VAAPI_DEVICE=/dev/dri/renderD128
      - LIBVA_DRIVER_NAME=radeonsi
      # Performance settings
      - JELLYFIN_FFMPEG_OPT_HWACCEL=vaapi
      - JELLYFIN_FFMPEG_OPT_HWACCEL_DEVICE=/dev/dri/renderD128
    sysctls:
      # AMD GPU optimizations
      - kernel.sched_rt_runtime_us=-1
```

### Storage Performance Optimization

#### NVMe/SSD Optimization

```bash
# Check current storage performance
./usenet storage benchmark

# Optimize for transcoding workloads
./usenet storage optimize --workload transcoding
```

**High-Performance Storage Configuration:**
```yaml
services:
  jellyfin:
    volumes:
      # Dedicated NVMe for transcoding
      - /mnt/nvme_fast/jellyfin_transcode:/transcode:rw
      # Separate cache and metadata
      - /mnt/ssd_fast/jellyfin_cache:/cache:rw
      - /mnt/ssd_fast/jellyfin_metadata:/config/metadata:rw
    tmpfs:
      # RAM-based temporary storage
      - /tmp/jellyfin:size=4G,noexec,nosuid,nodev
      
  tdarr:
    volumes:
      # Dedicated high-speed storage for Tdarr
      - /mnt/nvme_fast/tdarr_temp:/temp:rw
      - /mnt/nvme_fast/tdarr_cache:/cache:rw
    environment:
      # Optimize for SSD usage
      - TDARR_TEMP_PATH=/temp
      - TDARR_CACHE_SIZE=50G
```

#### Storage Performance Tuning

```bash
# Filesystem optimizations
# Add to /etc/fstab for permanent changes

# For SSD/NVMe (add noatime,discard)
/dev/nvme0n1p1 /mnt/nvme_fast ext4 defaults,noatime,discard 0 2

# For HDD (optimize for sequential access)
/dev/sda1 /mnt/hdd_storage ext4 defaults,noatime,data=writeback 0 2

# Apply optimizations
sudo mount -o remount /mnt/nvme_fast
sudo mount -o remount /mnt/hdd_storage

# Verify improvements
./usenet storage benchmark --before-after
```

### Memory Optimization

#### System Memory Tuning

```bash
# Check current memory usage
./usenet monitor memory --detailed

# Optimize memory allocation
sudo sysctl -w vm.swappiness=10
sudo sysctl -w vm.vfs_cache_pressure=50
sudo sysctl -w vm.dirty_ratio=15
sudo sysctl -w vm.dirty_background_ratio=5

# Make permanent
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=15" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf
```

#### Service Memory Allocation

```yaml
# High-performance memory configuration
services:
  jellyfin:
    deploy:
      resources:
        limits:
          memory: 16G
        reservations:
          memory: 4G
    environment:
      # JVM tuning for Jellyfin
      - JELLYFIN_MAX_MEMORY=12G
      - JELLYFIN_INITIAL_MEMORY=4G
    sysctls:
      # Memory optimizations
      - vm.max_map_count=262144
      
  tdarr:
    deploy:
      resources:
        limits:
          memory: 32G
        reservations:
          memory: 8G
    environment:
      # Node.js memory tuning
      - NODE_OPTIONS="--max-old-space-size=28672"
      
  sonarr:
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 1G
    environment:
      # .NET runtime optimizations
      - DOTNET_GCHeapHardLimit=3G
      - DOTNET_GCHighMemPercent=75
```

## System-Level Optimizations

### Kernel Parameter Tuning

```bash
# Network performance optimizations
echo 'net.core.rmem_max = 134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_rmem = 4096 87380 134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 65536 134217728' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' | sudo tee -a /etc/sysctl.conf

# File system optimizations
echo 'fs.file-max = 2097152' | sudo tee -a /etc/sysctl.conf
echo 'fs.inotify.max_user_watches = 524288' | sudo tee -a /etc/sysctl.conf

# Apply immediately
sudo sysctl -p
```

### CPU Governor and Scaling

```bash
# Set CPU governor for performance
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Make permanent
sudo apt-get install cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl enable cpufrequtils
```

### I/O Scheduler Optimization

```bash
# Check current I/O schedulers
cat /sys/block/*/queue/scheduler

# Optimize for different storage types
# For SSDs: use none or mq-deadline
echo none | sudo tee /sys/block/nvme0n1/queue/scheduler

# For HDDs: use mq-deadline or bfq
echo mq-deadline | sudo tee /sys/block/sda/queue/scheduler

# Make permanent by adding to GRUB
# Edit /etc/default/grub:
# GRUB_CMDLINE_LINUX_DEFAULT="elevator=mq-deadline"
sudo update-grub
```

## Service-Specific Optimizations

### Jellyfin Performance Tuning

#### Transcoding Optimization

```bash
# Generate optimized Jellyfin configuration
./usenet hardware optimize --service jellyfin --workload transcoding
```

**Advanced Jellyfin Configuration:**
```xml
<!-- config/jellyfin/encoding.xml -->
<EncodingOptions>
  <HardwareAccelerationType>nvenc</HardwareAccelerationType>
  <EnableHardwareDecoding>true</EnableHardwareDecoding>
  <EnableHardwareEncoding>true</EnableHardwareEncoding>
  <EnableToneMappingDecodingWithNvenc>true</EnableToneMappingDecodingWithNvenc>
  <AllowHardwareSubtitleExtraction>true</AllowHardwareSubtitleExtraction>
  
  <!-- Performance optimizations -->
  <H264Crf>23</H264Crf>
  <H265Crf>28</H265Crf>
  <EncoderPreset>fast</EncoderPreset>
  <DeinterlaceMethod>yadif</DeinterlaceMethod>
  
  <!-- Quality vs speed balance -->
  <EnableDecodingColorDepth10Hevc>true</EnableDecodingColorDepth10Hevc>
  <EnableEnhancedNvdecDecoder>true</EnableEnhancedNvdecDecoder>
  <MaxMuxingQueueSize>4096</MaxMuxingQueueSize>
  
  <!-- Transcoding thread management -->
  <TranscodingTempPath>/transcode</TranscodingTempPath>
  <VaapiDevice>/dev/dri/renderD128</VaapiDevice>
</EncodingOptions>
```

### Download Client Optimization

#### SABnzbd High-Performance Configuration

```ini
# config/sabnzbd/sabnzbd.ini optimizations
[misc]
# Memory and performance
article_cache_max = 2G
cache_limit = 1G
par2_multicore = 1
nice = -10
ionice = 4

# Network optimizations
max_connections = 50
max_art_tries = 3
max_art_opt = 1
req_completion_rate = 100.2

# Processing optimizations
direct_unpack = 1
direct_unpack_tested = 1
flat_unpack = 0
script_can_fail = 0
enable_all_par = 0
```

#### Transmission Optimization

```json
{
    "alt-speed-down": 50000,
    "alt-speed-enabled": false,
    "alt-speed-time-begin": 540,
    "alt-speed-time-day": 127,
    "alt-speed-time-enabled": false,
    "alt-speed-time-end": 1020,
    "alt-speed-up": 50,
    "bind-address-ipv4": "0.0.0.0",
    "bind-address-ipv6": "::",
    "blocklist-enabled": false,
    "cache-size-mb": 16,
    "dht-enabled": true,
    "download-dir": "/downloads/complete",
    "download-queue-enabled": true,
    "download-queue-size": 10,
    "encryption": 1,
    "idle-seeding-limit": 30,
    "idle-seeding-limit-enabled": false,
    "incomplete-dir": "/downloads/incomplete",
    "incomplete-dir-enabled": true,
    "lpd-enabled": false,
    "max-peers-global": 400,
    "max-peers-per-torrent": 80,
    "message-level": 1,
    "peer-congestion-algorithm": "",
    "peer-id-ttl-hours": 6,
    "peer-limit-global": 400,
    "peer-limit-per-torrent": 80,
    "peer-port": 51413,
    "peer-port-random-high": 65535,
    "peer-port-random-low": 49152,
    "peer-port-random-on-start": false,
    "peer-socket-tos": "default",
    "pex-enabled": true,
    "port-forwarding-enabled": true,
    "preallocation": 1,
    "prefetch-enabled": true,
    "queue-stalled-enabled": true,
    "queue-stalled-minutes": 30,
    "ratio-limit": 2,
    "ratio-limit-enabled": false,
    "rename-partial-files": true,
    "rpc-authentication-required": false,
    "rpc-bind-address": "0.0.0.0",
    "rpc-enabled": true,
    "rpc-host-whitelist": "",
    "rpc-host-whitelist-enabled": true,
    "rpc-password": "{9ca1b915a583407a5793b91ce98b20c81c07ff9cAGY8gSUe",
    "rpc-port": 9091,
    "rpc-url": "/transmission/",
    "rpc-username": "",
    "rpc-whitelist": "127.0.0.1,192.168.*.*,172.*.*.*",
    "rpc-whitelist-enabled": true,
    "scrape-paused-torrents-enabled": true,
    "script-torrent-done-enabled": false,
    "script-torrent-done-filename": "",
    "seed-queue-enabled": false,
    "seed-queue-size": 10,
    "speed-limit-down": 100000,
    "speed-limit-down-enabled": false,
    "speed-limit-up": 100,
    "speed-limit-up-enabled": false,
    "start-added-torrents": true,
    "trash-original-torrent-files": false,
    "umask": 2,
    "upload-slots-per-torrent": 14,
    "utp-enabled": true
}
```

### Automation Service Tuning

#### Sonarr/Radarr Performance

```bash
# Optimize database performance
./usenet services optimize sonarr --database-tuning

# Configure for high-throughput processing
./usenet services configure sonarr --workers 8 --concurrent-downloads 10
```

**Database Optimization:**
```xml
<!-- config/sonarr/config.xml optimizations -->
<Config>
  <LogLevel>Info</LogLevel>
  <UpdateMechanism>Docker</UpdateMechanism>
  <Branch>main</Branch>
  <LaunchBrowser>False</LaunchBrowser>
  <Port>8989</Port>
  <SslPort>9898</SslPort>
  <EnableSsl>False</EnableSsl>
  
  <!-- Performance optimizations -->
  <DatabaseVacuumInterval>24</DatabaseVacuumInterval>
  <DatabaseAnalyzeInterval>168</DatabaseAnalyzeInterval>
  <MaximumSize>0</MaximumSize>
  <Retention>30</Retention>
  
  <!-- API optimizations -->
  <ApiKey>your_api_key_here</ApiKey>
  <AuthenticationMethod>None</AuthenticationMethod>
  <AuthenticationRequired>Enabled</AuthenticationRequired>
  
  <!-- Processing optimizations -->
  <DownloadClientWorkingFolders>_UNPACK_|_FAILED_</DownloadClientWorkingFolders>
  <CreateEmptySeriesFolders>False</CreateEmptySeriesFolders>
  <DeleteEmptyFolders>True</DeleteEmptyFolders>
  <SkipFreeSpaceCheckWhenImporting>False</SkipFreeSpaceCheckWhenImporting>
  <MinimumFreeSpaceWhenImporting>100</MinimumFreeSpaceWhenImporting>
  <CopyUsingHardlinks>True</CopyUsingHardlinks>
  <ImportExtraFiles>True</ImportExtraFiles>
  <ExtraFileExtensions>srt,nfo</ExtraFileExtensions>
</Config>
```

## Network Performance Optimization

### Docker Network Tuning

```bash
# Create optimized Docker networks
./usenet network optimize --mtu 9000 --driver-opts performance
```

**High-Performance Network Configuration:**
```yaml
networks:
  usenet-stack:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.default_bridge: "false"
      com.docker.network.bridge.enable_icc: "true"
      com.docker.network.bridge.enable_ip_masquerade: "true"
      com.docker.network.bridge.host_binding_ipv4: "0.0.0.0"
      com.docker.network.bridge.name: "usenet-stack0"
      com.docker.network.driver.mtu: "9000"  # Jumbo frames
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
          ip_range: 172.20.1.0/24

services:
  jellyfin:
    sysctls:
      # Network performance tuning
      - net.core.rmem_max=134217728
      - net.core.wmem_max=134217728
      - net.ipv4.tcp_rmem=4096 87380 134217728
      - net.ipv4.tcp_wmem=4096 65536 134217728
      - net.ipv4.tcp_congestion_control=bbr
    ulimits:
      # Increase connection limits
      nofile:
        soft: 65536
        hard: 65536
```

### Cloudflare Tunnel Optimization

```bash
# Optimize Cloudflare tunnel for high bandwidth
./usenet tunnel optimize --bandwidth high --latency low
```

## Performance Monitoring and Benchmarking

### Comprehensive Performance Testing

```bash
# Run complete performance benchmark
./usenet benchmark --comprehensive --duration 1h

# Component-specific benchmarks
./usenet benchmark transcoding --resolution 4k --duration 10m
./usenet benchmark storage --workload random-io --size 10G
./usenet benchmark network --throughput --latency
./usenet benchmark services --concurrent-requests 100
```

### Real-Time Performance Monitoring

```bash
# Start performance monitoring dashboard
./usenet monitor --live --metrics all

# Monitor specific components
./usenet monitor gpu --live --duration 30m
./usenet monitor storage --io-patterns --duration 1h
./usenet monitor network --bandwidth --connections
```

### Performance Alerting

```bash
# Configure performance alerts
./usenet alert configure performance \
  --cpu-threshold 80 \
  --memory-threshold 90 \
  --gpu-threshold 95 \
  --storage-io-threshold 85 \
  --webhook https://your-monitoring-system.com/webhook

# Test alerting system
./usenet alert test --simulate high-cpu
```

## Performance Analysis Tools

### Built-in Analysis

```bash
# Generate performance report
./usenet performance analyze --period 24h --output detailed

# Compare performance over time
./usenet performance compare \
  --baseline "1 week ago" \
  --current "now" \
  --metrics transcoding,storage,network

# Identify bottlenecks
./usenet performance bottlenecks --auto-detect --recommendations
```

### External Monitoring Integration

#### Grafana Dashboard Setup

```yaml
# Custom Grafana service for performance monitoring
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana-performance
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_PASSWORD}
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    ports:
      - "3000:3000"
    volumes:
      - ./config/grafana:/var/lib/grafana
      - ./monitoring/dashboards:/var/lib/grafana/dashboards
    networks:
      - usenet-stack

  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus-metrics
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    networks:
      - usenet-stack
```

## Performance Optimization Workflows

### Daily Performance Routine

```bash
#!/bin/bash
# Daily performance check script

# Check overall system health
./usenet services health --detailed

# Monitor resource usage trends
./usenet monitor resources --summary --period 24h

# Check for performance degradation
./usenet performance check --baseline yesterday --alert-on-regression

# Optimize if needed
if ./usenet performance needs-optimization; then
    ./usenet performance optimize --auto --backup-config
fi

# Update performance metrics
./usenet metrics update --timestamp $(date +%s)
```

### Performance Regression Detection

```bash
# Set performance baselines
./usenet performance baseline create --name "post-optimization-$(date +%Y%m%d)"

# Monitor for regressions
./usenet performance monitor --regression-detection \
  --baseline post-optimization \
  --threshold 10% \
  --alert-webhook https://your-alerts.com/webhook
```

## Troubleshooting Performance Issues

### Common Performance Problems

#### Slow Transcoding

```bash
# Diagnose transcoding performance
./usenet troubleshoot transcoding --verbose

# Check GPU utilization
./usenet monitor gpu --live --duration 5m

# Verify GPU drivers and settings
./usenet hardware validate --gpu-focus

# Test with different encoder settings
./usenet benchmark transcoding --encoder-comparison
```

#### High Memory Usage

```bash
# Identify memory-hungry services
./usenet troubleshoot memory --top-consumers

# Analyze memory leaks
./usenet monitor memory --leak-detection --duration 2h

# Optimize memory allocation
./usenet services optimize --memory-tuning --auto
```

#### Storage I/O Bottlenecks

```bash
# Analyze storage performance
./usenet troubleshoot storage --io-analysis

# Check filesystem health
./usenet storage validate --performance-check

# Optimize storage configuration
./usenet storage optimize --auto --benchmark-first
```

## Best Practices Summary

### Performance Optimization Checklist

- [ ] **GPU acceleration enabled** and properly configured
- [ ] **Storage optimized** with appropriate filesystems and mount options
- [ ] **Memory allocation** tuned for your workload
- [ ] **Network stack** optimized for high throughput
- [ ] **Service configurations** tuned for performance
- [ ] **Monitoring enabled** with alerting on performance degradation
- [ ] **Regular benchmarking** to track performance trends
- [ ] **Performance baselines** established for regression detection

### Maintenance Schedule

| Frequency | Task | Command |
|-----------|------|---------|
| **Daily** | Health check | `./usenet services health` |
| **Weekly** | Performance analysis | `./usenet performance analyze --period 7d` |
| **Monthly** | Comprehensive benchmark | `./usenet benchmark --comprehensive` |
| **Quarterly** | Configuration review | `./usenet performance review --recommendations` |

## Related Documentation

- [Hardware Architecture](../architecture/hardware) - Technical implementation details
- [Custom Configurations](./custom-configs) - Advanced service customization
- [Troubleshooting](./troubleshooting) - Debugging performance issues
- [API Integration](./api-integration) - Performance monitoring via APIs