# 🎬 Usenet Media Stack

**Version 2.0** - Professional-grade media automation with intelligent hardware optimization and modern CLI

[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://www.docker.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20|%20macOS%20|%20WSL2-green)]()
[![License](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-ZSH%20%7C%20Bash-orange)]()

## ✨ What's New in 2.0

- 🎛️ **Modern CLI Interface**: Professional flag-based syntax (`--storage`, `--hardware`, `--backup`)
- 🔍 **Intelligent Drive Discovery**: Automatic detection of ALL mounted storage (JBOD, ZFS, cloud mounts)
- 🚀 **GPU Acceleration**: Automated optimization for NVIDIA RTX, AMD, Intel QuickSync, Raspberry Pi
- 🎯 **Interactive TUI**: Beautiful drive selection and hardware configuration interfaces
- 🔧 **Rich Autocompletion**: Professional zsh/bash completion with context-aware suggestions
- 📦 **Universal Storage**: Selected drives automatically accessible to ALL services
- ⚡ **Hardware Profiles**: Automatic resource allocation based on detected hardware

## 🖥️ Platform Support

This stack runs anywhere Docker runs:
- **Linux** (Ubuntu, Debian, Fedora, Arch, etc.)
- **macOS** (Intel & Apple Silicon)
- **Windows** (via WSL2)
- **Raspberry Pi** (4/5 with GPU acceleration)
- **Synology/QNAP** NAS systems
- **Any Docker-capable system**

## 📋 Prerequisites

- **Docker** & **Docker Compose v2**
- **4GB+ RAM** (8GB+ recommended for transcoding)
- **50GB+ free disk space**
- **Internet connection** for initial setup

Don't have Docker? We'll help you install it!

## 🚀 Quick Start

```bash
# Clone and enter directory
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack

# One command deployment with hardware optimization
./usenet setup
```

## 🎯 Complete Media Automation System

### 📺 Core Automation
- **SABnzbd** (8080) - Usenet downloader with SSL/NZB support
- **Prowlarr** (9696) - Universal indexer manager
- **Sonarr** (8989) - TV show automation with quality profiles
- **Radarr** (7878) - Movie automation with custom formats
- **Readarr** (8787) - Book/audiobook automation
- **Lidarr** (8686) - Music automation

### 🎬 Media Services
- **Jellyfin** (8096) - Open-source media server with hardware transcoding
- **Overseerr** (5055) - Beautiful request management for users
- **YACReader** (8082) - Comic/manga server and reader
- **Tdarr** (8265) - Automated transcoding with GPU acceleration

### 🔧 Quality & Optimization
- **Bazarr** (6767) - Subtitle automation for 40+ languages
- **Recyclarr** - Automatic TRaSH Guide optimization
- **Whisparr** (6969) - Specialized content management
- **Mylar3** (8090) - Comic book automation

### 🌐 Network & Sharing
- **Samba** (445) - Windows file sharing
- **NFS** (2049) - Unix/Linux file sharing
- **Cloudflare Tunnel** - Secure remote access

### 📊 Monitoring & Management
- **Netdata** (19999) - Real-time system monitoring
- **Portainer** (9000) - Docker container management

## 🎛️ Modern CLI Interface

### Component-Based Commands
```bash
# Storage Management - Intelligent JBOD Discovery
usenet --storage discover          # List ALL mounted drives (ZFS, cloud, etc.)
usenet --storage select            # Interactive drive selection TUI
usenet --storage add /mnt/drive1   # Add specific drive to pool
usenet --storage apply             # Apply changes and restart services

# Hardware Optimization - GPU Acceleration
usenet --hardware detect           # Show detected GPU capabilities
usenet --hardware optimize --auto  # Generate hardware-tuned configs
usenet --hardware install-drivers  # Auto-install GPU drivers (NVIDIA/AMD/Intel)

# Backup & Recovery
usenet --backup create             # Create compressed configuration backup
usenet --backup restore backup.tar # Restore from backup with verification

# Network & Security
usenet --tunnel setup              # Configure Cloudflare secure tunnel
```

### Service Management
```bash
# Core Operations
usenet setup                       # Complete deployment with optimization
usenet status                      # Health check all services
usenet logs sonarr                 # View service logs
usenet restart                     # Restart all services

# Advanced Operations
usenet test                        # Run comprehensive system tests
usenet validate                    # Pre-deployment validation
usenet update                      # Update all containers
```

### Global Options
```bash
usenet --verbose --storage discover    # Detailed output
usenet --quiet --hardware detect       # Suppress non-essential output
usenet --yes --storage select          # Auto-confirm prompts
```

## 🚀 GPU Acceleration Support

### Automatic Detection & Optimization
- **NVIDIA RTX/GTX** - Full NVENC/NVDEC support with automatic driver installation
- **AMD Radeon** - VAAPI hardware acceleration with AMF encoding
- **Intel QuickSync** - Ultra-efficient iGPU transcoding (5-15W power usage)
- **Raspberry Pi** - VideoCore GPU optimization for distributed clusters

### Performance Benefits
- **4K HEVC Transcoding**: 2-5 FPS (CPU) → 60+ FPS (GPU)
- **Power Efficiency**: 200W CPU → 50W GPU transcoding
- **Concurrent Streams**: 1-2 → 8+ simultaneous 4K streams
- **Quality Preservation**: Hardware tone mapping and HDR passthrough

## 🗄️ Universal Storage Management

### Intelligent Drive Discovery
Automatically detects and manages:
- **Traditional Filesystems** (ext4, xfs, NTFS, exFAT)
- **Advanced Filesystems** (ZFS, Btrfs)
- **Network Storage** (NFS, SMB/CIFS)
- **Cloud Storage** (rclone mounts: Google Drive, Dropbox, OneDrive)
- **JBOD Arrays** with hot-swap support

### Universal Service Access
Once configured, ALL services can access selected storage:
- **Sonarr/Radarr**: Organize media across multiple drives
- **Jellyfin**: Stream from any selected storage location
- **Tdarr**: Transcode across all configured drives
- **SABnzbd**: Download to any selected destination
- **Samba/NFS**: Share all selected drives over network

## 📊 Hardware Profiles & Auto-Optimization

### Deployment Profiles
- **Dedicated Server** (100% resources) - Maximum performance
- **High Performance** (75% resources) - Powerful desktop sharing
- **Balanced** (50% resources) - Standard desktop/workstation
- **Light** (25% resources) - Laptop or limited hardware
- **Development** (10% resources) - Testing and development
- **Custom** - User-defined resource limits

### Automatic Resource Allocation
```bash
# Auto-detect optimal configuration
usenet --hardware optimize --auto

# Interactive hardware configuration
usenet --hardware configure

# Manual profile selection
usenet --hardware optimize --profile balanced
```

## 🎯 Rich Interactive Features

### Drive Selection TUI
```
🗄️  USENET MEDIA STACK - DRIVE SELECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select drives for your media storage pool:
All selected drives will be accessible to Sonarr, Radarr, Jellyfin, Tdarr, etc.

[✓] [1] /                    ZFS (798G available)
[ ] [2] /mnt/media_drive1    HDD (4TB available)  
[✓] [3] /home/user/Dropbox   Cloud (3.1TB available)
[ ] [4] /mnt/nvme_cache      NVMe (1TB available)

Commands: 1-4 (toggle), a (all), n (none), s (save), q (quit)
```

### Hardware Detection Output
```
🚀 PERFORMANCE OPTIMIZATION OPPORTUNITIES DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💎 NVIDIA RTX 4090 Detected! Your hardware is capable of:
   • 4K HEVC transcoding at 60+ FPS (vs 2-5 FPS CPU-only)
   • Simultaneous multi-stream encoding (up to 8 concurrent 4K streams)
   • Real-time HDR tone mapping for optimal quality preservation
   • AV1 encoding (50% smaller files than H.264)

🔧 OPTIMIZATION RECOMMENDATIONS:
   ✅ NVIDIA drivers: ✓ Installed
   🔧 Install NVIDIA Docker: sudo apt install nvidia-docker2

💡 Want us to optimize your system?
   Run: usenet --hardware install-drivers for automatic setup
```

## 🔧 Advanced Configuration

### Custom Storage Layouts
```yaml
# Auto-generated docker-compose.storage.yml
services:
  sonarr:
    volumes:
      - /mnt/drive1:/tv/drive1:rw
      - /mnt/drive2:/tv/drive2:rw
      - /home/user/Dropbox:/tv/cloud:rw

  jellyfin:
    volumes:
      - /mnt/drive1:/media/drive1:rw
      - /mnt/drive2:/media/drive2:rw
      - /home/user/Dropbox:/media/cloud:rw
```

### Hardware-Optimized Configurations
```yaml
# Auto-generated docker-compose.optimized.yml based on detected hardware
services:
  tdarr:
    deploy:
      resources:
        limits:
          cpus: '12.0'      # 75% of 16-core CPU
          memory: 18G       # High-performance profile
    devices:
      - /dev/dri:/dev/dri   # AMD VAAPI acceleration
    environment:
      - VAAPI_DEVICE=/dev/dri/renderD128
```

## 🌐 Network Configuration

### Secure Remote Access
```bash
# Configure Cloudflare tunnel for secure remote access
usenet --tunnel setup

# Traditional reverse proxy support
# Traefik, Nginx Proxy Manager, etc. supported
```

### File Sharing
- **Samba (SMB/CIFS)**: Windows-compatible file sharing
- **NFS**: High-performance Unix/Linux file sharing  
- **Direct Access**: All configured drives accessible via network shares

## 🧪 Testing & Validation

### Comprehensive Test Suite
```bash
# Run all tests
usenet test

# Specific test categories  
usenet test unit          # Unit tests for individual components
usenet test integration   # Full-stack integration tests
usenet test services      # Service health and connectivity tests
```

### Pre-deployment Validation
```bash
# Validate system before deployment
usenet validate

# Check specific requirements
usenet validate docker    # Docker installation and permissions
usenet validate storage   # Storage requirements and permissions
usenet validate network   # Network connectivity and ports
```

## 🚀 Performance Optimizations

### TRaSH Guides Integration
- **Automatic Quality Profiles**: Optimal settings for maximum quality
- **Custom Formats**: Remux prioritization, HDR/DV support
- **Release Profiles**: Preferred release groups and naming
- **Regular Updates**: Automatic synchronization with TRaSH recommendations

### Transcoding Optimization
- **Hardware Acceleration**: GPU-optimized encoding for all supported formats
- **Quality Preservation**: Intelligent H.265 encoding with tone mapping
- **Storage Efficiency**: 40-60% size reduction while maintaining quality
- **Multi-stream Support**: Concurrent transcoding across multiple drives

## 📚 Documentation & Support

### Built-in Help System
```bash
usenet --help                    # Complete command reference
usenet --storage --help          # Storage-specific help
usenet --hardware --help         # Hardware optimization help
```

### Rich Autocompletion
Enable zsh/bash completion:
```bash
# Add to ~/.zshrc or ~/.bashrc
source /path/to/usenet/completions/_usenet
```

### Service URLs (Post-Setup)
After running `./usenet setup`, access your services:

| Service | URL | Purpose |
|---------|-----|---------|
| Jellyfin | http://localhost:8096 | Media streaming |
| Overseerr | http://localhost:5055 | Request management |
| Sonarr | http://localhost:8989 | TV automation |
| Radarr | http://localhost:7878 | Movie automation |
| Prowlarr | http://localhost:9696 | Indexer management |
| SABnzbd | http://localhost:8080 | Downloads |
| Portainer | http://localhost:9000 | Container management |
| Netdata | http://localhost:19999 | System monitoring |

## 🔧 Troubleshooting

### Common Issues
```bash
# Check service health
usenet status

# View logs for specific service
usenet logs servicename

# Validate configuration
usenet validate

# Reset to defaults
usenet --hardware --reset
usenet --storage remove --all
```

### Debug Mode
```bash
# Enable verbose output for troubleshooting
usenet --verbose setup
usenet --verbose --storage discover
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup
```bash
# Clone repository
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack

# Run tests
usenet test

# Enable completion for development
source completions/_usenet
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

Dedicated to **Stan Eisenstat** and the Yale Computer Science tradition of clear, elegant code that explains itself.

Special thanks to:
- **TRaSH Guides** community for quality optimization
- **LinuxServer.io** for excellent Docker containers
- **Jellyfin**, **Sonarr**, **Radarr** teams for outstanding media automation tools

---

**Built with ❤️ for the media automation community**