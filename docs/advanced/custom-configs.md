# Custom Configurations

Learn how to create sophisticated Docker Compose overrides, service customizations, and configuration templates while maintaining system stability and upgrade compatibility.

## Configuration Architecture

### Override System Design

The Usenet Media Stack uses a hierarchical configuration system that allows safe customization without modifying core files:

```
Configuration Hierarchy:
├── docker-compose.yml              # Base service definitions (never modify)
├── docker-compose.optimized.yml    # Generated hardware optimizations  
├── docker-compose.storage.yml      # Generated storage mounts
├── docker-compose.override.yml     # Your custom overrides ✓
├── docker-compose.local.yml        # Machine-specific overrides ✓
└── .env                           # Environment variables ✓
```

### Safe Customization Principles

- **Override, don't replace** - Use Docker Compose override files
- **Version compatibility** - Test overrides with each update
- **Non-destructive changes** - Preserve upgrade paths
- **Backup before modify** - Always create restore points

## Docker Compose Overrides

### Creating Override Files

```bash
# Generate override template
usenet config generate --template override

# This creates docker-compose.override.yml with examples
```

**Example docker-compose.override.yml:**
```yaml
version: '3.8'

services:
  # Custom Jellyfin configuration
  jellyfin:
    environment:
      # Custom transcoding settings
      - JELLYFIN_PublishedServerUrl=https://jellyfin.yourdomain.com
      - JELLYFIN_CACHE_SIZE=2G
    volumes:
      # Additional volume mounts
      - ./custom/jellyfin/plugins:/config/plugins:rw
      - /mnt/backup_media:/backup:ro
    deploy:
      resources:
        limits:
          # Custom resource limits
          memory: 12G
          cpus: '6'
    labels:
      # Custom labels for monitoring
      - "monitoring.enabled=true"
      - "backup.include=config"

  # Custom Sonarr configuration  
  sonarr:
    environment:
      # Custom quality settings
      - SONARR_BRANCH=phantom-develop
    volumes:
      # Custom scripts directory
      - ./custom/sonarr/scripts:/scripts:ro
    depends_on:
      # Additional dependencies
      - custom-indexer

  # Add completely custom service
  custom-indexer:
    image: custom/indexer:latest
    container_name: custom-indexer
    environment:
      - API_KEY=${CUSTOM_INDEXER_API_KEY}
    ports:
      - "9200:9200"
    volumes:
      - ./config/custom-indexer:/config
    networks:
      - usenet-stack
    restart: unless-stopped

  # Custom monitoring service
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
    ports:
      - "3000:3000"
    volumes:
      - ./config/grafana:/var/lib/grafana
      - ./custom/grafana/dashboards:/var/lib/grafana/dashboards
    networks:
      - usenet-stack
    restart: unless-stopped

# Custom networks
networks:
  monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.25.0.0/16

# Custom volumes
volumes:
  grafana-data:
    driver: local
  custom-indexer-data:
    driver: local
```

### Service-Specific Customizations

#### Jellyfin Advanced Configuration

```yaml
# docker-compose.override.yml
services:
  jellyfin:
    environment:
      # Hardware acceleration for specific GPU
      - NVIDIA_VISIBLE_DEVICES=GPU-12345678-1234-1234-1234-123456789012
      # Custom server settings
      - JELLYFIN_DATA_DIR=/config
      - JELLYFIN_CACHE_DIR=/cache/jellyfin
      - JELLYFIN_LOG_DIR=/config/log
    volumes:
      # Custom plugin directory
      - ./custom/jellyfin/plugins:/config/plugins:rw
      # Custom web interface
      - ./custom/jellyfin/web:/jellyfin/jellyfin-web:ro
      # Additional media sources
      - /mnt/remote_media:/media/remote:ro
      - /mnt/4k_content:/media/4k:ro
    devices:
      # Direct device access for specialized hardware
      - /dev/video0:/dev/video0
    deploy:
      resources:
        limits:
          memory: 16G
          cpus: '8'
        reservations:
          memory: 4G
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    sysctls:
      # Custom kernel parameters
      - net.core.rmem_max=134217728
      - net.core.wmem_max=134217728
    ulimits:
      # Custom resource limits
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
```

#### Sonarr/Radarr Custom Quality Profiles

```yaml
services:
  sonarr:
    environment:
      # Enable advanced logging
      - SONARR_LOG_LEVEL=debug
      # Custom branch for testing
      - SONARR_BRANCH=phantom-develop
    volumes:
      # Custom quality definitions
      - ./custom/sonarr/Definitions:/app/Definitions:ro
      # Custom scripts for post-processing
      - ./custom/scripts:/scripts:ro
    command: >
      sh -c "
        # Wait for database initialization
        sleep 30 &&
        # Import custom quality profiles
        /scripts/import_quality_profiles.sh &&
        # Start Sonarr
        exec /init
      "

  radarr:
    volumes:
      # TRaSH Guide custom formats
      - ./custom/radarr/custom-formats.json:/config/custom-formats.json:ro
      # Advanced post-processing scripts
      - ./custom/scripts/radarr:/scripts/radarr:ro
    environment:
      # Custom format scoring
      - RADARR_CUSTOM_FORMATS_AUTO_IMPORT=true
```

#### Download Client Optimizations

```yaml
services:
  sabnzbd:
    environment:
      # Performance optimizations
      - SABNZBD_MEMORY_LIMIT=4G
      - SABNZBD_CACHE_LIMIT=2G
    volumes:
      # Custom SABnzbd configuration
      - ./custom/sabnzbd/sabnzbd.ini:/config/sabnzbd.ini:rw
      # High-speed temporary directory
      - /mnt/nvme_temp:/incomplete:rw
    deploy:
      resources:
        limits:
          memory: 6G
          cpus: '4'
    tmpfs:
      # RAM-based temporary storage for extraction
      - /tmp/sabnzbd:size=4G,noexec,nosuid,nodev

  transmission:
    environment:
      # VPN kill switch
      - TRANSMISSION_VPN_ENABLED=true
      - TRANSMISSION_VPN_KILLSWITCH=true
    volumes:
      # Custom transmission settings
      - ./custom/transmission/settings.json:/config/settings.json:rw
      # Separate incomplete/complete directories
      - /mnt/fast_ssd/transmission_incomplete:/incomplete:rw
      - /mnt/storage/transmission_complete:/complete:rw
    cap_add:
      - NET_ADMIN
    sysctls:
      - net.ipv6.conf.all.disable_ipv6=1
```

## Environment Variable Customization

### Advanced .env Configuration

```bash
# Custom .env additions
# Copy from .env.example and customize

# === PERFORMANCE TUNING ===
# Hardware performance profile
PERFORMANCE_PROFILE=dedicated
HARDWARE_ACCELERATION=true
GPU_TRANSCODING=true

# Resource allocation
JELLYFIN_MEMORY_LIMIT=8G
TDARR_MEMORY_LIMIT=16G
SONARR_MEMORY_LIMIT=2G
RADARR_MEMORY_LIMIT=2G

# === CUSTOM SERVICE SETTINGS ===
# Jellyfin customization
JELLYFIN_PUBLISHED_SERVER_URL=https://jellyfin.yourdomain.com
JELLYFIN_AUTO_DISCOVERY=false
JELLYFIN_ENABLE_METRICS=true

# Sonarr/Radarr custom branches
SONARR_BRANCH=phantom-develop
RADARR_BRANCH=nightly

# Custom quality settings
SONARR_QUALITY_PRESET=uhd
RADARR_QUALITY_PRESET=uhd-remux

# === NETWORKING ===
# Custom domain configuration
DOMAIN_NAME=yourdomain.com
SUBDOMAIN_PREFIX=media

# VPN configuration
VPN_ENABLED=true
VPN_PROVIDER=nordvpn
VPN_CONFIG_FILE=./config/vpn/nordvpn.conf

# === MONITORING ===
# Enable advanced monitoring
ENABLE_METRICS=true
METRICS_RETENTION=30d
ENABLE_ALERTING=true

# Grafana configuration
GRAFANA_ADMIN_PASSWORD=your_secure_password
GRAFANA_ALLOW_SIGNUP=false

# === BACKUP CONFIGURATION ===
# Automated backup settings
BACKUP_ENABLED=true
BACKUP_SCHEDULE=0 3 * * *
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
BACKUP_ENCRYPTION=true

# Remote backup destinations
BACKUP_REMOTE_ENABLED=true
BACKUP_S3_BUCKET=your-backup-bucket
BACKUP_S3_REGION=us-west-2

# === SECURITY ===
# API security
API_RATE_LIMITING=true
API_RATE_LIMIT=100/hour

# Authentication
ENABLE_SSO=true
SSO_PROVIDER=authelia
SSO_DOMAIN=auth.yourdomain.com

# === CUSTOM INTEGRATIONS ===
# Webhook configurations
WEBHOOK_ENABLED=true
WEBHOOK_URL_SONARR=https://api.yourdomain.com/webhooks/sonarr
WEBHOOK_URL_RADARR=https://api.yourdomain.com/webhooks/radarr

# Discord notifications
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/your/webhook
DISCORD_NOTIFICATIONS_ENABLED=true

# === EXPERIMENTAL FEATURES ===
# Enable beta features
ENABLE_EXPERIMENTAL=false
BETA_FEATURES=av1_encoding,hdr_processing

# Custom service images
JELLYFIN_IMAGE=jellyfin/jellyfin:unstable
SONARR_IMAGE=linuxserver/sonarr:preview
```

### Environment Variable Categories

```bash
# Service-specific environment files
# ./config/env/jellyfin.env
JELLYFIN_DATA_DIR=/config
JELLYFIN_CACHE_DIR=/cache
JELLYFIN_LOG_DIR=/logs
JELLYFIN_FFMPEG_PROBE_SIZE=1G
JELLYFIN_FFMPEG_ANALYZE_DURATION=200M

# ./config/env/sonarr.env  
SONARR_API_KEY=${SONARR_API_KEY}
SONARR_URL_BASE=/sonarr
SONARR_ENABLE_SSL=false
SONARR_LOG_LEVEL=info
SONARR_UPDATE_MECHANISM=docker

# Load environment files in override
services:
  jellyfin:
    env_file:
      - ./config/env/jellyfin.env
      - ./config/env/common.env
      
  sonarr:
    env_file:
      - ./config/env/sonarr.env
      - ./config/env/common.env
```

## Custom Service Integration

### Adding Third-Party Services

#### Plex Media Server Integration

```yaml
# Add Plex alongside Jellyfin
services:
  plex:
    image: plexinc/pms-docker:latest
    container_name: plex
    environment:
      - TZ=${TZ}
      - PLEX_CLAIM=${PLEX_CLAIM_TOKEN}
      - PLEX_UID=1000
      - PLEX_GID=1000
      - ADVERTISE_IP=https://plex.${DOMAIN_NAME}:443
    ports:
      - "32400:32400"
    volumes:
      - ./config/plex:/config
      - /tmp/plex_transcode:/transcode
      # Use same storage as Jellyfin
      - /media/storage1:/media/storage1:ro
      - /media/storage2:/media/storage2:ro
    devices:
      - /dev/dri:/dev/dri  # GPU access
    networks:
      - usenet-stack
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 8G
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
```

#### Authelia Authentication

```yaml
services:
  authelia:
    image: authelia/authelia:latest
    container_name: authelia
    environment:
      - TZ=${TZ}
    volumes:
      - ./config/authelia:/config
    ports:
      - "9091:9091"
    networks:
      - usenet-stack
    restart: unless-stopped
    command: >
      authelia --config /config/configuration.yml

  # Protect services with Authelia
  overseerr:
    labels:
      - "traefik.http.routers.overseerr.middlewares=authelia@docker"
      
  portainer:
    labels:
      - "traefik.http.routers.portainer.middlewares=authelia@docker"
```

#### Custom Indexer Services

```yaml
services:
  jackett-custom:
    image: linuxserver/jackett:latest
    container_name: jackett-custom
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
      - AUTO_UPDATE=true
    volumes:
      - ./config/jackett-custom:/config
      - ./downloads:/downloads
    ports:
      - "9118:9117"  # Different port to avoid conflicts
    networks:
      - usenet-stack
    restart: unless-stopped

  # Custom indexer aggregator
  prowlarr-beta:
    image: linuxserver/prowlarr:nightly
    container_name: prowlarr-beta
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    volumes:
      - ./config/prowlarr-beta:/config
    ports:
      - "9697:9696"  # Different port
    networks:
      - usenet-stack
    restart: unless-stopped
```

## Performance Customizations

### Resource Allocation Strategies

```yaml
# High-performance configuration
services:
  jellyfin:
    deploy:
      resources:
        limits:
          memory: 16G
          cpus: '8'
        reservations:
          memory: 4G
          cpus: '2'
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    # Optimize for transcoding
    environment:
      - JELLYFIN_FFMPEG_PROBE_SIZE=2G
      - JELLYFIN_FFMPEG_ANALYZE_DURATION=500M
    # Use faster storage for transcoding
    volumes:
      - /mnt/nvme_cache:/cache/jellyfin:rw
    # Kernel optimizations
    sysctls:
      - net.core.rmem_max=268435456
      - net.core.wmem_max=268435456
      
  tdarr:
    deploy:
      resources:
        limits:
          memory: 32G
          cpus: '16'
        reservations:
          memory: 8G
          cpus: '4'
    # Multiple GPU access
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
    # Dedicated transcoding storage
    volumes:
      - /mnt/nvme_transcode:/temp:rw
      
  # Prioritize automation services
  sonarr:
    deploy:
      resources:
        limits:
          memory: 4G
          cpus: '2'
    # SSD storage for faster operations
    volumes:
      - /mnt/ssd_config/sonarr:/config:rw
```

### Network Performance Tuning

```yaml
# Network optimizations
networks:
  usenet-stack:
    driver: bridge
    driver_opts:
      # Optimize for high throughput
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
  sabnzbd:
    # Network performance optimizations
    sysctls:
      - net.core.rmem_max=134217728
      - net.core.wmem_max=134217728
      - net.ipv4.tcp_rmem=4096 87380 134217728
      - net.ipv4.tcp_wmem=4096 65536 134217728
    # Use host networking for maximum performance
    network_mode: host
```

## Security Customizations

### Enhanced Authentication

```yaml
services:
  # OAuth2 Proxy for external authentication
  oauth2-proxy:
    image: quay.io/oauth2-proxy/oauth2-proxy:latest
    container_name: oauth2-proxy
    environment:
      - OAUTH2_PROXY_PROVIDER=github
      - OAUTH2_PROXY_CLIENT_ID=${GITHUB_CLIENT_ID}
      - OAUTH2_PROXY_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
      - OAUTH2_PROXY_COOKIE_SECRET=${OAUTH2_COOKIE_SECRET}
      - OAUTH2_PROXY_EMAIL_DOMAINS=yourdomain.com
    ports:
      - "4180:4180"
    networks:
      - usenet-stack
      
  # Fail2ban for intrusion prevention
  fail2ban:
    image: crazymax/fail2ban:latest
    container_name: fail2ban
    environment:
      - TZ=${TZ}
      - F2B_LOG_LEVEL=INFO
    volumes:
      - ./config/fail2ban:/data
      - /var/log:/var/log:ro
    cap_add:
      - NET_ADMIN
      - NET_RAW
    network_mode: host
    restart: unless-stopped
```

### VPN Integration

```yaml
services:
  # WireGuard VPN for download clients
  wireguard:
    image: linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ}
    volumes:
      - ./config/wireguard:/config
      - /lib/modules:/lib/modules
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped

  # Route download clients through VPN
  transmission:
    network_mode: service:wireguard
    depends_on:
      - wireguard
      
  sabnzbd:
    network_mode: service:wireguard
    depends_on:
      - wireguard
```

## Monitoring and Observability

### Advanced Monitoring Stack

```yaml
services:
  # Prometheus for metrics collection
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=30d'
      - '--web.enable-lifecycle'
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus:/etc/prometheus
      - prometheus-data:/prometheus
    networks:
      - usenet-stack
      
  # Grafana for visualization
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-worldmap-panel
    ports:
      - "3000:3000"
    volumes:
      - ./config/grafana:/var/lib/grafana
      - ./custom/grafana/dashboards:/var/lib/grafana/dashboards
    networks:
      - usenet-stack
      
  # Loki for log aggregation
  loki:
    image: grafana/loki:latest
    container_name: loki
    ports:
      - "3100:3100"
    volumes:
      - ./config/loki:/etc/loki
    command: -config.file=/etc/loki/local-config.yaml
    networks:
      - usenet-stack

volumes:
  prometheus-data:
  grafana-data:
```

## Configuration Templates

### Generate Custom Templates

```bash
# Create configuration templates
usenet config template create --name high-performance << 'EOF'
# High-performance media server template
version: '3.8'

services:
  jellyfin:
    deploy:
      resources:
        limits:
          memory: ${JELLYFIN_MEMORY_LIMIT:-16G}
          cpus: '${JELLYFIN_CPU_LIMIT:-8}'
    environment:
      - JELLYFIN_FFMPEG_PROBE_SIZE=${JELLYFIN_PROBE_SIZE:-2G}
    volumes:
      - ${FAST_STORAGE_PATH}/jellyfin_cache:/cache:rw

  tdarr:
    deploy:
      resources:
        limits:
          memory: ${TDARR_MEMORY_LIMIT:-32G}
          cpus: '${TDARR_CPU_LIMIT:-16}'
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      - TDARR_WORKERS=${TDARR_WORKERS:-8}
EOF

# Apply template
usenet config template apply high-performance
```

### Template Variables

```bash
# Template with environment substitution
# ./templates/production.yml
version: '3.8'

services:
  jellyfin:
    environment:
      - JELLYFIN_PUBLISHED_SERVER_URL=https://jellyfin.${DOMAIN_NAME}
    deploy:
      resources:
        limits:
          memory: ${JELLYFIN_MEMORY:-8G}
    volumes:
      - ${MEDIA_PATH_1}:/media/primary:ro
      - ${MEDIA_PATH_2}:/media/secondary:ro

# Use template
export DOMAIN_NAME=example.com
export JELLYFIN_MEMORY=16G
export MEDIA_PATH_1=/mnt/primary_storage
export MEDIA_PATH_2=/mnt/secondary_storage

docker-compose -f docker-compose.yml -f templates/production.yml up -d
```

## Validation and Testing

### Configuration Validation

```bash
# Validate custom configurations
usenet config validate --file docker-compose.override.yml

# Test configuration changes
usenet config test --dry-run --override docker-compose.override.yml

# Syntax validation
docker-compose -f docker-compose.yml -f docker-compose.override.yml config --quiet
```

### Performance Testing

```bash
# Benchmark custom configuration
usenet performance test --config custom --duration 30m

# Compare against baseline
usenet performance compare --baseline default --test custom

# Monitor resource usage
usenet monitor --config custom --duration 1h
```

## Best Practices

### Configuration Management

1. **Version control** - Track configuration changes in git
2. **Documentation** - Comment complex configurations
3. **Testing** - Validate changes in development environment
4. **Backup** - Create restore points before major changes
5. **Monitoring** - Watch performance after configuration changes

### Upgrade Compatibility

```bash
# Test upgrade compatibility
usenet upgrade test --target v2.1.0 --config custom

# Backup before upgrade
usenet backup create --name pre-upgrade-$(date +%Y%m%d)

# Upgrade with custom configurations
usenet upgrade --preserve-overrides
```

### Troubleshooting Custom Configurations

```bash
# Debug configuration issues
usenet debug config --verbose

# Compare with working configuration
usenet config diff --base working --test current

# Reset to defaults if needed
usenet config reset --preserve-data
```

## Related Documentation

- [Performance Tuning](./performance) - Optimize system performance
- [API Integration](./api-integration) - Custom API configurations
- [Backup Strategies](./backup-strategies) - Protect custom configurations
- [Troubleshooting](./troubleshooting) - Debug configuration issues