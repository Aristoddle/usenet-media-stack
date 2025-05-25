# System Requirements

This document outlines the system requirements for running the Arr Stack Manager. Requirements are provided for different deployment scales to help you choose the appropriate configuration for your needs.

## Table of Contents
- [Basic Requirements](#basic-requirements)
- [Hardware Requirements](#hardware-requirements)
- [Software Requirements](#software-requirements)
- [Network Requirements](#network-requirements)
- [Storage Requirements](#storage-requirements)
- [Deployment Scales](#deployment-scales)
- [Additional Considerations](#additional-considerations)

## Basic Requirements

All deployments require:
- 64-bit operating system
- Docker Engine (20.10.0 or newer)
- Docker Compose (v2.0.0 or newer)
- Internet connectivity
- User with Docker permissions

## Hardware Requirements

### Minimum Requirements (Small Scale)
- **CPU**: Dual-core processor, 2.0 GHz or better
- **RAM**: 4GB
- **Storage**: 20GB for system + media storage requirements
- Suitable for: Single user, 1-2 services, small media library

### Recommended (Medium Scale)
- **CPU**: Quad-core processor, 2.5 GHz or better
- **RAM**: 8GB
- **Storage**: 40GB for system + media storage requirements
- Suitable for: Small household, 3-4 services, medium media library

### Performance (Large Scale)
- **CPU**: 6+ cores, 3.0 GHz or better
- **RAM**: 16GB+
- **Storage**: 80GB+ for system + media storage requirements
- Suitable for: Multiple users, 5+ services, large media library

## Software Requirements

### Required Software
- **Operating System**:
  - Linux (Ubuntu 20.04+, Debian 11+, or equivalent)
  - Windows 10/11 with WSL2
  - macOS 12+
- **Container Platform**:
  - Docker Engine 20.10.0+
  - Docker Compose v2.0.0+
- **Web Browser**:
  - Chrome 90+ (recommended)
  - Firefox 90+
  - Safari 15+
  - Edge 90+

### Optional Software
- Git (for installation from source)
- Text editor for configuration
- Terminal emulator
- VPN client (if using VPN integration)

## Network Requirements

### Connectivity
- **Bandwidth**: 
  - Minimum: 10 Mbps download/upload
  - Recommended: 50+ Mbps download/upload
  - Optimal: 100+ Mbps download/upload
- **Ports**:
  - Port 8080 (default web interface)
  - Additional ports per service (configurable)
  - Common service ports:
    - Sonarr: 8989
    - Radarr: 7878
    - Lidarr: 8686
    - Prowlarr: 9696

### Networking Features
- DHCP or static IP configuration
- Port forwarding capabilities (if remote access required)
- DNS resolution
- IPv4 required, IPv6 supported

## Storage Requirements

### System Storage
- **Base System**: 2GB
- **Docker Images**: 5-10GB
- **Application Data**: 5-20GB (varies by configuration)

### Media Storage
- Plan according to your media library size:
  - Movies: 2-10GB per movie (4K content: 40-100GB)
  - TV Shows: 1-5GB per hour (4K content: 15-30GB)
  - Music: 10-50MB per album (FLAC: 200-500MB)

### Recommendations
- Use SSDs for system and database storage
- Use HDDs or NAS for media storage
- Implement RAID for data protection
- Plan for 20% growth buffer

## Deployment Scales

### Home User (Small)
- 1-2 users
- Up to 3 services
- Media library < 1TB
- Basic monitoring

### Home Server (Medium)
- 2-5 users
- 3-5 services
- Media library 1-10TB
- Standard monitoring
- Basic automation

### Power User (Large)
- 5+ users
- 5+ services
- Media library 10TB+
- Advanced monitoring
- Full automation
- High availability options

## Additional Considerations

### Backup Requirements
- System backup capability
- Database backup storage
- Media backup strategy (recommended)
- Configuration backup location

### Security Considerations
- Firewall configuration
- Reverse proxy (recommended)
- VPN support
- User authentication
- SSL/TLS certificates

### Environmental Factors
- Adequate ventilation
- UPS recommended for server deployments
- Temperature-controlled environment
- Physical security for servers

### Scalability
- Ability to add storage
- Network expandability
- Service upgrade path
- Resource monitoring

## Notes

- Requirements may vary based on specific use cases and configurations
- All requirements assume default configurations
- Additional services may require additional resources
- Monitor system resources and adjust as needed
- Regular maintenance and updates require temporary additional resources

---

For assistance with specific configurations or requirements, please refer to the [Troubleshooting Guide](../user-guide/troubleshooting.md) or create an issue on our GitHub repository.