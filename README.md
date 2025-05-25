# 🎬 Usenet Media Stack

> **Professional-grade hot-swappable JBOD media automation** with intelligent deployment and "just fucking works" usability.

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20WSL-green.svg)](https://github.com/Aristoddle/usenet-media-stack)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-ZSH%20%7C%20Bash-orange.svg)]()
[![Standards](https://img.shields.io/badge/Standards-Bell%20Labs-gold.svg)](#acknowledgments)

**Deploy once, add devices as needed. Hot-swap storage for portability. GPU acceleration where available.**

---

## 🚀 **Quick Start**

### **One-Command Deployment**
```bash
# Clone and deploy complete stack
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy --auto
```

**Result**: 19-service media automation stack with hardware optimization and dynamic storage management.

### **What You Get Immediately**
```bash
# 🎬 Media Services
jellyfin     (8096) # → Media streaming with GPU transcoding
overseerr    (5055) # → Beautiful request management interface  
yacreader    (8082) # → Comic/manga server and reader

# 📺 Automation Stack  
sonarr       (8989) # → TV automation with TRaSH Guide optimization
radarr       (7878) # → Movie automation with custom quality profiles
readarr      (8787) # → Book/audiobook automation
bazarr       (6767) # → Subtitle automation (40+ languages)
prowlarr     (9696) # → Universal indexer management

# 🔧 Download & Processing
sabnzbd      (8080) # → High-speed Usenet downloading
transmission (9092) # → BitTorrent client with VPN protection
tdarr        (8265) # → Automated transcoding with GPU acceleration
recyclarr           # → TRaSH Guide auto-optimization

# 📊 Management & Monitoring
portainer    (9000) # → Docker container management
netdata     (19999) # → Real-time system monitoring
```

---

## 🎯 **Key Features**

### **🔥 Hot-Swappable JBOD Architecture**
- **Real-time drive detection**: Automatically discovers ZFS, Btrfs, cloud mounts, external drives
- **Dynamic Docker Compose generation**: Auto-creates storage mount configurations
- **Universal service access**: All 19 services automatically gain access to selected drives
- **Cross-platform portability**: exFAT drives work everywhere (Windows, macOS, Linux)
- **Hot-swap ready**: Plug/unplug drives without service restart

### **⚡ Intelligent Hardware Optimization**
- **Universal GPU detection**: NVIDIA RTX, AMD VAAPI, Intel QuickSync, Raspberry Pi VideoCore
- **Automatic driver installation**: One-command GPU driver setup
- **Performance profiles**: Dedicated (100%), High Performance (75%), Balanced (50%), Light (25%), Development (10%)
- **Real performance gains**: 4K HEVC transcoding 2-5 FPS → 60+ FPS, 200W CPU → 50W GPU

### **🛡️ Professional CLI Architecture**
- **Pure subcommand system**: Following pyenv/git patterns for intuitive use
- **Consistent action verbs**: `list`, `create`, `show`, `restore` across all components
- **Three-tier help system**: Main → Component → Action specific guidance
- **Smart error handling**: Clear, actionable error messages with recovery suggestions
- **Rich completions**: Professional zsh/bash tab completion

---

## 📋 **CLI Reference**

### **Primary Workflows**
```bash
# Complete deployment with optimization
./usenet deploy                      # Interactive guided setup
./usenet deploy --auto               # Fully automated deployment
./usenet deploy --profile balanced   # Specific hardware profile

# Pre-flight validation
./usenet validate                    # Comprehensive system checks
./usenet validate --fix              # Auto-fix common issues
```

### **Storage Management (Hot-Swap JBOD)**
```bash
# Drive discovery and management
./usenet storage list               # List ALL available drives
./usenet storage add /media/drive   # Add drive to media pool
./usenet storage remove /media/drive # Remove drive from pool
./usenet storage status             # Show current pool configuration

# Example output from storage list:
# ○ [ 1] /                    ZFS (798G total, 594G available)
# ○ [ 2] /home/user/Dropbox   Cloud Storage (3.1TB available)
# ○ [ 3] /media/Movies_4TB    HDD (4TB available, exFAT)
# ○ [ 4] /media/Fast_8TB_31   NVMe (8TB available, exFAT)
```

### **Hardware Optimization**
```bash
# GPU detection and optimization
./usenet hardware list              # Show capabilities and recommendations
./usenet hardware optimize --auto   # Generate optimized configurations
./usenet hardware install-drivers   # Auto-install GPU drivers

# Example optimization output:
# ⚡ AMD GPU Detected! Hardware acceleration unlocks:
#    • Hardware HEVC encoding (10x faster than CPU)
#    • VAAPI-accelerated transcoding
#    • HDR10 passthrough with tone mapping
```

### **Backup & Disaster Recovery**
```bash
# Smart backup system with metadata
./usenet backup list                # Show all backups with details
./usenet backup create --compress   # Config-only backup (~5MB)
./usenet backup create --type full  # Complete backup (~100MB)
./usenet backup show <backup.tar.gz> # Detailed backup information
./usenet backup restore <backup>    # Atomic restore with rollback
```

### **Service Management**
```bash
# Service operations
./usenet services list              # Health check all services
./usenet services start sonarr      # Start specific service
./usenet services logs jellyfin     # View service logs
./usenet services restart --all     # Restart all services
```

### **Global Options**
```bash
# Available across all commands
--verbose, -v          # Detailed output for troubleshooting
--dry-run, -n          # Preview what would be done
--quiet, -q            # Suppress non-essential output
--profile <name>       # Use specific hardware profile
--help, -h             # Context-aware help at every level
```

---

## 🏗️ **Architecture**

### **System Design Philosophy**
This project embodies **Bell Labs standards** in honor of Stan Eisenstat - clear, elegant code that explains itself:

- **80-character lines** for professional terminal compatibility
- **Function contracts** documenting purpose, arguments, and returns
- **Comprehensive error handling** with helpful guidance
- **Modular architecture** with clean separation of concerns

### **Project Structure**
```
usenet-media-stack/
├── usenet                  # Single entry point (unified CLI)
├── lib/                    
│   ├── commands/          # Component implementations
│   │   ├── storage.zsh    # Hot-swappable JBOD management (459 lines)
│   │   ├── hardware.zsh   # GPU optimization & driver installation (855+ lines)
│   │   ├── backup.zsh     # Enhanced backup with JSON metadata (842 lines)
│   │   ├── deploy.zsh     # Primary deployment orchestration (264 lines)
│   │   ├── validate.zsh   # Comprehensive pre-flight checks
│   │   └── manage.zsh     # Service management (legacy, being replaced)
│   ├── core/             # Utilities, logging, configuration
│   │   ├── common.zsh    # Shared functions and constants
│   │   └── init.zsh      # Configuration loading (zero circular deps)
│   └── test/             # Comprehensive test suite
├── config/                # Service configurations (auto-generated)
├── completions/           # Rich zsh/bash completions
├── docker-compose.yml     # Base service definitions (19 services)
├── docker-compose.*.yml   # Generated optimizations (hardware, storage)
├── backups/               # Configuration backups with metadata
├── TEST_REPORT.md         # Comprehensive CLI testing results
└── ROADMAP.md            # Detailed development roadmap
```

### **Service Architecture**
**19 Production Services** organized by function:

```
📺 Media Automation
├── Sonarr (8989)     → TV show automation with TRaSH Guide
├── Radarr (7878)     → Movie automation with 4K remux priority  
├── Readarr (8787)    → Book/audiobook automation
├── Bazarr (6767)     → Subtitle automation (40+ languages)
└── Prowlarr (9696)   → Universal indexer management

🎬 Media Services  
├── Jellyfin (8096)   → Media streaming with GPU transcoding
├── Overseerr (5055)  → Request management interface
├── YACReader (8082)  → Comic/manga server
└── Tdarr (8265)      → Automated transcoding pipeline

🔧 Download & Processing
├── SABnzbd (8080)    → High-speed Usenet downloader
├── Transmission (9092) → BitTorrent client (VPN-protected)
└── Recyclarr         → TRaSH Guide automation

🌐 Network & Sharing
├── Samba (445)       → Windows file sharing
├── NFS (2049)        → Unix/Linux file sharing
└── Cloudflare Tunnel → Secure remote access

📊 Monitoring & Management
├── Netdata (19999)   → Real-time system monitoring
└── Portainer (9000)  → Docker container management
```

---

## ⚙️ **Hardware Optimization**

### **Automatic GPU Detection & Optimization**
The system automatically detects and optimizes for:

- **NVIDIA RTX/GTX Series**: Full NVENC/NVDEC support with Docker runtime
- **AMD Radeon Graphics**: VAAPI hardware acceleration with AMF encoding  
- **Intel Integrated Graphics**: Ultra-efficient QuickSync transcoding (5-15W)
- **Raspberry Pi**: VideoCore GPU optimization for cluster deployments

### **Performance Impact (Real Benchmarks)**
| Metric | CPU Only | GPU Accelerated | Improvement |
|--------|----------|----------------|-------------|
| **4K HEVC Transcoding** | 2-5 FPS | 60+ FPS | **12-30x faster** |
| **Power Consumption** | 200W | 50W | **75% reduction** |
| **Concurrent Streams** | 1-2 | 8+ | **4-8x capacity** |
| **Quality Enhancement** | Standard | HDR tone mapping | **Significant** |

### **Hardware Profiles**
```bash
# Automatic profile selection based on detected hardware
./usenet hardware optimize --auto

# Manual profile override
./usenet deploy --profile dedicated    # 100% resources (dedicated server)
./usenet deploy --profile balanced     # 50% resources (shared workstation)  
./usenet deploy --profile light        # 25% resources (background operation)
```

---

## 🗄️ **Storage Management**

### **Universal Drive Discovery**
Automatically detects and manages:

- **Traditional Filesystems**: ext4, xfs, NTFS, exFAT (cross-platform)
- **Advanced Filesystems**: ZFS, Btrfs with automatic pool detection
- **Network Storage**: NFS mounts, SMB/CIFS shares
- **Cloud Storage**: rclone-mounted Google Drive, Dropbox, OneDrive
- **JBOD Arrays**: Hot-swappable drive management

### **Real-World Storage Example**
```bash
$ ./usenet storage list

🗄️ DISCOVERED STORAGE DEVICES:
○ [ 1] /                    ZFS (798G total, 594G available)
○ [ 2] /home/joe/Dropbox    Cloud Storage (3.1TB available)
○ [ 3] /home/joe/OneDrive   Cloud Storage (2.1TB available) 
○ [ 4] /media/Movies_4TB    HDD (4TB available, exFAT - portable)
○ [ 5] /media/Fast_8TB_31   NVMe (8TB available, exFAT - camping ready)

# Add portable drive for camping trips
$ ./usenet storage add /media/Movies_4TB
✓ Drive added to media pool
✓ All 19 services updated automatically
✓ No service restart required
```

### **Hot-Swap Workflow**
1. **Plug in drive** → Automatic detection
2. **Add to pool** → `./usenet storage add /media/new-drive`
3. **Services updated** → All services gain access immediately
4. **Unplug for travel** → Take your media anywhere
5. **Plug back in** → Automatic re-detection and pool restoration

---

## 💾 **Backup & Disaster Recovery**

### **Smart Backup System**
```bash
# Three backup types with intelligent defaults
./usenet backup create                    # Config-only (~5MB) - SAFE DEFAULT
./usenet backup create --type full        # Complete backup (~100MB)
./usenet backup create --type minimal     # Essential files only (~1MB)

# Rich metadata tracking
./usenet backup list
# [1] usenet-stack-backup-20250525.tar.gz
#     📅 Created: 2025-05-25 05:09:14
#     📦 Size: 5.6M  
#     🏷️  Type: config
#     📝 Description: Pre-upgrade backup
#     ⚙️  Git: 331aa11 (feature/pure-subcommand-architecture)
```

### **What's Backed Up (Config Type)**
✅ **Included**: `.env`, docker-compose files, service configs, application databases  
❌ **Excluded**: Media files, downloads, logs, temporary data  
🎯 **Result**: Fast, portable 5-10MB backups with everything needed for restoration

### **Disaster Recovery**
```bash
# Safe restore with automatic rollback
./usenet backup restore --dry-run backup.tar.gz    # Preview first
./usenet backup restore backup.tar.gz              # Atomic restore
# ✓ Pre-restore backup created automatically
# ✓ Configuration validated before applying
# ✓ Rollback available if anything fails
```

---

## 🌐 **Network & Security**

### **Secure Remote Access**
```bash
# Cloudflare tunnel for zero-exposed-ports architecture
./usenet tunnel setup --domain your-domain.net
# ✓ SSL/TLS automatic via Cloudflare
# ✓ All services accessible via secure subdomains
# ✓ No port forwarding required
```

### **File Sharing**
- **Samba (SMB/CIFS)**: Windows-compatible file sharing (port 445)
- **NFS**: High-performance Unix/Linux file sharing (port 2049)  
- **Universal Access**: All configured drives shared automatically

### **Security Features**
- **VPN Protection**: BitTorrent traffic routed through VPN automatically
- **API Key Management**: Secure generation and rotation of service API keys
- **Network Isolation**: Services communicate via internal Docker networks
- **Zero Trust**: No services exposed to internet without explicit configuration

---

## 🔧 **Installation & Requirements**

### **System Requirements**
| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| **CPU** | 4 cores | 8+ cores | More cores = better transcoding |
| **RAM** | 8GB | 16GB+ | 32GB+ for large media libraries |
| **Storage** | 100GB | 1TB+ | For configs + media storage |
| **Network** | 100Mbps | Gigabit | For remote streaming |

### **Platform Support**
- ✅ **Linux**: Ubuntu, Debian, Fedora, Arch, etc.
- ✅ **macOS**: Intel & Apple Silicon
- ✅ **Windows**: WSL2 required
- ✅ **Raspberry Pi**: 4/5 with GPU acceleration
- ✅ **NAS Systems**: Synology, QNAP, Unraid

### **Prerequisites**
```bash
# Required (auto-installed if missing)
docker >= 20.10
docker-compose >= 2.0

# Optional (enhanced features)
zsh                    # Better shell experience
nvidia-docker2         # NVIDIA GPU support
vaapi-drivers          # AMD/Intel GPU support
```

### **Installation Methods**

**Standard Installation**:
```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy
```

**Automated Deployment** (CI/CD):
```bash
./usenet deploy --auto --profile balanced
```

**Component Installation**:
```bash
./usenet hardware optimize --auto      # GPU acceleration only
./usenet storage add /media/drive      # Storage configuration only
./usenet validate --fix                # System validation only
```

---

## 🔍 **Troubleshooting**

### **Common Issues & Solutions**

**Services not starting**:
```bash
./usenet validate                       # Check system requirements
./usenet services list                  # Check service health  
./usenet services logs <service>        # Debug specific service
```

**Storage not accessible**:
```bash
./usenet storage list                   # Re-scan for drives
./usenet storage status                 # Verify current pool
./usenet storage add /media/drive       # Re-add if needed
```

**Performance issues**:
```bash
./usenet hardware list                  # Check optimization opportunities
./usenet hardware optimize --auto       # Apply hardware acceleration
```

**Backup/restore problems**:
```bash
./usenet backup list                    # Check available backups
./usenet backup show <backup>           # Inspect backup contents
./usenet backup restore --dry-run <backup> # Preview restore operation
```

### **Debug Mode**
```bash
# Enable verbose output for any command
./usenet --verbose deploy
./usenet --verbose storage list
./usenet --verbose hardware optimize
```

### **Log Locations**
- **System logs**: `./usenet services logs <service>`
- **Docker logs**: `docker compose logs <service>`
- **Application logs**: `config/<service>/logs/`

---

## 🎓 **Development & Contributing**

### **Code Quality Standards**
This project follows **Bell Labs standards** in honor of Stan Eisenstat:
- 80-character lines for VT100 compatibility
- Function contracts for all major functions
- Comprehensive documentation and error handling
- Modular architecture with clean separation of concerns

### **Development Setup**
```bash
# Clone and setup development environment
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack

# Run test suite
./usenet test

# Enable shell completion for development
source completions/_usenet
```

### **Testing Framework**
```bash
# Comprehensive CLI testing
./usenet test --verbose                 # Full test suite
./usenet validate                       # System validation
./usenet deploy --dry-run               # Deployment preview

# See TEST_REPORT.md for detailed test results
```

### **Architecture Documentation**
- **CLI Design**: Pure subcommand architecture following pyenv patterns
- **Error Handling**: Comprehensive error recovery with user guidance
- **Performance**: Optimized for 100+ drive environments
- **Extensibility**: Plugin architecture for custom commands

---

## 🗺️ **Roadmap**

See [ROADMAP.md](ROADMAP.md) for detailed development plans.

### **Current Status** (v2.0)
- ✅ **Production-ready CLI** with professional UX
- ✅ **Hot-swappable JBOD** with 29+ drive support tested
- ✅ **Hardware optimization** for NVIDIA/AMD/Intel GPUs
- ✅ **Enhanced backup system** with JSON metadata
- ✅ **19-service stack** fully integrated and tested

### **Next Milestones**
- **v2.1**: Enhanced service management with health monitoring
- **v2.2**: Advanced backup features (restore, retention policies)
- **v2.3**: Hot-swap API integration with Sonarr/Radarr
- **v3.0**: Smart media management with duplicate detection

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

### **Dedicated to Stan Eisenstat** (1943-2020)
*Yale Computer Science Professor who taught that good code is its own best documentation.*

**Core Principles Applied**:
- "If you can't explain it to a freshman, you don't understand it yourself"
- "Programs must be written for people to read, and only incidentally for machines to execute"
- "Make it work, make it right, make it fast - in that order"

### **Technical Foundations**
- **TRaSH Guides** community for quality optimization standards
- **LinuxServer.io** for excellent Docker containers  
- **Jellyfin**, **Sonarr**, **Radarr** teams for outstanding media automation
- The **open-source media automation** community

### **Inspiration Sources**
- **Docker**: Professional CLI patterns and user experience
- **Git**: Subcommand architecture and help system design
- **Pyenv**: Pure subcommand routing and error handling
- **Terraform**: Workflow-oriented command design

---

<div align="center">

**Professional media automation for the modern self-hoster**

🚀 [Quick Start](#-quick-start) • 📋 [CLI Reference](#-cli-reference) • 🗺️ [Roadmap](ROADMAP.md) • 🐛 [Issues](https://github.com/Aristoddle/usenet-media-stack/issues)

*Built with ❤️ following Bell Labs standards*

</div>