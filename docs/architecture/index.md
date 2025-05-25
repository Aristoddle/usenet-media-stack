# Architecture Overview

The Usenet Media Stack is built on a foundation of professional software engineering principles, combining hot-swappable JBOD storage, universal hardware optimization, and a sophisticated CLI following modern design patterns.

## Core Design Philosophy

### Bell Labs Standards

The codebase follows principles taught by **Stan Eisenstat** at Yale:

- **Clarity over cleverness** - Every function is documented, every error teaches
- **Professional standards** - 80-character lines, comprehensive error handling
- **Quality architecture** - Single responsibility, proper abstractions, testing

### Modern CLI Design

Inspired by industry-leading tools:

- **Git**: Subcommand + flags perfection (`git commit -m "msg" --amend`)
- **Docker**: Object + action model (`docker container run --rm -it`)
- **Pyenv**: Workflow-oriented with smart help (`pyenv install 3.9.7`)

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Usenet Media Stack                     │
├─────────────────────────────────────────────────────────────┤
│  CLI Interface (usenet)                                     │
│  ├─ Pure subcommand routing                                 │
│  ├─ Three-tier help system                                  │
│  └─ Rich zsh/bash completions                               │
├─────────────────────────────────────────────────────────────┤
│  Component Management                                       │
│  ├─ Storage: Hot-swappable JBOD                            │
│  ├─ Hardware: Universal GPU optimization                    │
│  ├─ Services: 19-service orchestration                     │
│  └─ Backup: Configuration management                       │
├─────────────────────────────────────────────────────────────┤
│  Service Layer (19 Services)                               │
│  ├─ Media: Jellyfin, Overseerr, YACReader, Tdarr          │
│  ├─ Automation: Sonarr, Radarr, Readarr, Bazarr, etc.     │
│  ├─ Downloads: SABnzbd, Transmission                       │
│  └─ Management: Portainer, Netdata                         │
├─────────────────────────────────────────────────────────────┤
│  Container Orchestration (Docker Compose)                  │
│  ├─ Base: docker-compose.yml                               │
│  ├─ Hardware: docker-compose.optimized.yml                 │
│  └─ Storage: docker-compose.storage.yml (dynamic)          │
├─────────────────────────────────────────────────────────────┤
│  Storage Layer                                              │
│  ├─ Hot-swappable JBOD drives                              │
│  ├─ Cross-platform exFAT support                           │
│  ├─ Cloud storage integration                               │
│  └─ Network storage (NFS/SMB)                              │
├─────────────────────────────────────────────────────────────┤
│  Hardware Layer                                             │
│  ├─ Universal GPU support (NVIDIA/AMD/Intel/Pi)            │
│  ├─ Automatic driver installation                          │
│  ├─ Performance profiling                                   │
│  └─ Real-time optimization                                  │
└─────────────────────────────────────────────────────────────┘
```

## Component Architecture

### CLI Design Pattern

```bash
# Modern subcommand architecture
usenet <component> <action> [options]

# Examples:
usenet storage list           # Component: storage, Action: list
usenet hardware optimize     # Component: hardware, Action: optimize  
usenet services restart      # Component: services, Action: restart
```

### Component Responsibilities

| Component | Purpose | Key Features |
|-----------|---------|--------------|
| **Storage** | Hot-swappable JBOD management | Real-time detection, API sync, exFAT support |
| **Hardware** | GPU optimization & drivers | Universal detection, auto-install, benchmarking |
| **Services** | 19-service orchestration | Health monitoring, log access, API management |
| **Backup** | Configuration management | Metadata tracking, atomic operations, encryption |
| **Deploy** | Orchestrated deployment | Pre-flight checks, profile selection, validation |
| **Validate** | System health checks | Auto-fix, monitoring, troubleshooting |

## Data Flow Architecture

### Media Automation Pipeline

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Request   │    │   Search    │    │  Download   │    │   Process   │
│ (Overseerr) │───▶│ (Prowlarr)  │───▶│ (SABnzbd)   │───▶│   (Tdarr)   │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  Organize   │    │   Quality   │    │   Storage   │    │   Serve     │
│ (Sonarr/    │───▶│ (Recyclarr) │───▶│   (JBOD)    │───▶│ (Jellyfin)  │
│  Radarr)    │    │             │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
```

### Storage Integration Flow

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│    Drive    │    │  Discovery  │    │     API     │
│  Detection  │───▶│   & Pool    │───▶│    Sync     │
│             │    │ Management  │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Docker    │    │   Service   │    │   Health    │
│  Compose    │───▶│  Restart    │───▶│ Validation  │
│ Generation  │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

## File System Architecture

### Project Structure

```
usenet-media-stack/
├── usenet                  # Single entry point CLI
├── lib/                    # Component implementations
│   ├── commands/          # CLI command handlers
│   │   ├── storage.zsh    # Hot-swappable JBOD management
│   │   ├── hardware.zsh   # GPU optimization system
│   │   ├── backup.zsh     # Configuration backup/restore
│   │   ├── services.zsh   # 19-service management
│   │   ├── deploy.zsh     # Orchestrated deployment
│   │   └── validate.zsh   # System health validation
│   ├── core/             # Shared utilities
│   │   ├── init.zsh      # Configuration loading
│   │   ├── common.zsh    # Utilities and logging
│   │   └── stan-quality.zsh # Code quality framework
│   └── test/             # Testing framework
├── config/               # Service configurations (19 services)
├── completions/          # Rich CLI completions
├── docker-compose.yml    # Base service definitions
├── docker-compose.*.yml  # Generated optimizations
├── .env                  # All credentials (gitignored)
└── docs/                # Professional documentation
```

### Configuration Management

```
Configuration Sources (Priority Order):
1. Command-line flags    (--profile dedicated)
2. Environment variables (.env file)
3. Configuration files   (config/*.conf)
4. Intelligent defaults  (hardware-based)
```

## Network Architecture

### Service Exposure

```
External Access (Cloudflare Tunnel):
├── jellyfin.example.com → Jellyfin (8096)
├── requests.example.com → Overseerr (5055)
├── comics.example.com → YACReader (8082)
└── manage.example.com → Portainer (9000)

Internal Network (Docker Bridge):
├── Media Services     (8080-8099)
├── Automation Stack   (8900-8999, 6700-6799)
├── Management Tools   (9000-9999, 19999)
└── File Sharing      (445, 2049)
```

### Security Model

- **Zero exposed ports** - All access via Cloudflare Tunnel
- **API authentication** - Unique keys for each service
- **Container isolation** - Services in dedicated network
- **Credential management** - Environment-based secrets

## Hardware Optimization Architecture

### Multi-Platform GPU Support

```
GPU Detection & Optimization:
├── NVIDIA RTX Series
│   ├── NVENC/NVDEC encoding
│   ├── CUDA acceleration
│   └── nvidia-docker2 integration
├── AMD RDNA/GCN Series  
│   ├── VAAPI acceleration
│   ├── AMF encoding
│   └── Mesa driver integration
├── Intel Arc/Iris
│   ├── QuickSync encoding
│   ├── VA-API support
│   └── Intel media drivers
└── Raspberry Pi
    ├── VideoCore GPU
    ├── Hardware decode
    └── GPU memory allocation
```

### Performance Profiles

| Profile | Resources | Use Case | Transcoding |
|---------|-----------|----------|-------------|
| **Light** | 25% CPU, 4GB RAM | Development | Software only |
| **Balanced** | 50% CPU, 8GB RAM | Home server | Hardware enabled |
| **High** | 75% CPU, 16GB RAM | Media server | Optimized |
| **Dedicated** | 100% CPU, All RAM | Appliance | Maximum |

## Storage Architecture

### Hot-Swappable JBOD Design

```
Storage Pool Management:
├── Drive Discovery
│   ├── Local drives (HDD/SSD/NVMe)
│   ├── USB/External (hot-pluggable)
│   ├── Network storage (NFS/SMB)
│   └── Cloud mounts (rclone)
├── Pool Configuration
│   ├── Interactive selection
│   ├── Cross-platform compatibility
│   ├── Permission management
│   └── Mount point generation
└── Service Integration
    ├── Dynamic Docker Compose
    ├── API synchronization
    ├── Hot-swap workflows
    └── Zero-downtime updates
```

### Cross-Platform Compatibility

- **ExFAT support** - Works across Windows/macOS/Linux
- **Portable drives** - Camping trips and travel
- **Cloud integration** - Dropbox, OneDrive, Google Drive
- **Network storage** - NAS and server integration

## Service Integration Architecture

### API Synchronization

```
Storage Change Event:
├── Drive Detection
├── Pool Update
├── Docker Compose Generation
├── Service API Updates
│   ├── Sonarr: Root folders
│   ├── Radarr: Movie libraries  
│   ├── Jellyfin: Media libraries
│   └── Tdarr: Processing paths
└── Health Validation
```

### Service Dependencies

```
Dependency Graph:
├── Core Services (Always first)
│   ├── Prowlarr (indexer management)
│   └── SABnzbd (download client)
├── Automation Services
│   ├── Sonarr (depends: Prowlarr, SABnzbd)
│   ├── Radarr (depends: Prowlarr, SABnzbd)
│   └── Bazarr (depends: Sonarr, Radarr)
├── Media Services
│   ├── Jellyfin (depends: storage availability)
│   └── Tdarr (depends: Jellyfin, storage)
└── Management Services
    ├── Overseerr (depends: Sonarr, Radarr)
    └── Recyclarr (depends: Sonarr, Radarr)
```

## Quality Assurance Architecture

### Testing Framework

```
Quality Gates:
├── Code Quality (Stan's Standards)
│   ├── 80-character lines
│   ├── Function contracts
│   ├── Error handling
│   └── Documentation
├── Functionality Testing
│   ├── Unit tests (component level)
│   ├── Integration tests (workflow level)
│   ├── System tests (full stack)
│   └── Regression tests (change validation)
└── User Experience Testing
    ├── CLI usability
    ├── Error message clarity
    ├── Help system completeness
    └── Performance benchmarks
```

### Validation System

- **Pre-deployment checks** - System requirements, configuration
- **Runtime monitoring** - Service health, resource usage
- **Auto-fix capabilities** - Common issues resolution
- **Comprehensive reporting** - JSON exports, troubleshooting

## Extensibility Architecture

### Adding New Services

```bash
# Add service to docker-compose.yml
services:
  new-service:
    image: new-service:latest
    ports:
      - "8888:8080"
    volumes:
      - ./config/new-service:/config
    environment:
      - API_KEY=${NEW_SERVICE_API_KEY}

# Register with CLI system
usenet services add new-service --category custom
```

### Custom Hardware Support

```bash
# Add hardware detection logic
detect_custom_hardware() {
    # Custom GPU detection
    if lspci | grep -i "custom gpu"; then
        echo "Custom GPU detected"
        return 0
    fi
    return 1
}

# Register optimization profile
usenet hardware profile add custom-gpu \
  --transcoding-args "-hwaccel custom" \
  --quality-settings high
```

## Related Architecture Documentation

- [CLI Design Patterns](./cli-design) - Command architecture deep dive
- [Service Architecture](./services) - 19-service integration details
- [Storage Architecture](./storage) - Hot-swappable JBOD implementation
- [Hardware Architecture](./hardware) - Multi-platform GPU optimization
- [Network Architecture](./network) - Security and connectivity design