# API Integration

> **Deep integration with service APIs for automated configuration management and real-time updates.**

## Overview

The Usenet Media Stack provides comprehensive API integration with all 19 services, enabling:
- Automated configuration synchronization
- Real-time storage updates
- Performance monitoring
- Health checks and alerting

## Supported APIs

### Media Management
- **Sonarr API** - TV show automation and root folder management
- **Radarr API** - Movie management and quality profiles
- **Readarr API** - Book/audiobook automation
- **Prowlarr API** - Indexer synchronization across services

### Download Clients  
- **SABnzbd API** - Queue management and performance monitoring
- **Transmission API** - Torrent management and VPN status

### Media Servers
- **Jellyfin API** - Library updates and user management
- **Overseerr API** - Request management and user notifications

## API Configuration

### Automatic Setup
```bash
# Configure all APIs automatically
./usenet services sync --configure-apis

# Update specific service
./usenet services sync sonarr --update-paths
```

### Manual Configuration
```yaml
# config/api-config.yml
services:
  sonarr:
    api_key: "${SONARR_API_KEY}"
    base_url: "http://localhost:8989"
    root_folders:
      - "/tv/new"
      - "/tv/archive"
      
  radarr:
    api_key: "${RADARR_API_KEY}"
    base_url: "http://localhost:7878"
    quality_profiles:
      - "HD-1080p"
      - "UHD-4K"
```

## Real-Time Updates

When storage changes occur, the system automatically:

1. **Detects changes** via filesystem monitoring
2. **Updates service APIs** with new paths
3. **Refreshes library scans** for immediate recognition
4. **Validates connectivity** to ensure services respond

## Monitoring & Health Checks

```bash
# Check all API endpoints
./usenet services health

# Monitor API response times
./usenet services monitor --realtime

# Get service statistics
./usenet services stats --format json
```