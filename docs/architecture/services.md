# Service Architecture

The Usenet Media Stack orchestrates 19 specialized services into a cohesive media automation pipeline. This architecture emphasizes service isolation, API integration, dependency management, and intelligent health monitoring.

## Service Ecosystem Overview

### Service Categories

```
Media Automation Stack (19 Services)
├── Media Services (4)
│   ├── Jellyfin      - Media streaming with GPU transcoding
│   ├── Overseerr     - Request management interface
│   ├── YACReader     - Comic/manga server
│   └── Tdarr         - Automated transcoding
├── Automation Core (8)
│   ├── Sonarr        - TV automation
│   ├── Radarr        - Movie automation  
│   ├── Readarr       - Book automation
│   ├── Bazarr        - Subtitle automation
│   ├── Prowlarr      - Indexer management
│   ├── Recyclarr     - TRaSH Guide optimization
│   ├── Mylar         - Comic automation
│   └── Whisparr      - Adult content automation
├── Download Clients (2)
│   ├── SABnzbd       - Usenet downloader
│   └── Transmission  - BitTorrent client
├── Management (3)
│   ├── Portainer     - Container management
│   ├── Netdata       - System monitoring
│   └── Jackett       - Legacy indexer proxy
└── Network Services (2)
    ├── Samba         - Windows file sharing
    └── NFS Server    - Unix/Linux file sharing
```

## Service Dependency Architecture

### Dependency Graph

```
Startup Order (Topological Sort):
1. Core Infrastructure
   ├── Prowlarr (indexer management)
   ├── SABnzbd (download client)
   └── Transmission (torrent client)

2. Automation Services (depend on core)
   ├── Sonarr ──────┐
   ├── Radarr ──────┤ (all depend on Prowlarr + download clients)
   ├── Readarr ─────┤
   └── Mylar ───────┘

3. Enhancement Services (depend on automation)
   ├── Bazarr (depends: Sonarr, Radarr)
   ├── Recyclarr (depends: Sonarr, Radarr) 
   └── Whisparr (depends: Prowlarr, SABnzbd)

4. Media Services (depend on content availability)
   ├── Jellyfin (depends: media storage)
   ├── Tdarr (depends: Jellyfin, storage)
   └── YACReader (depends: comic storage)

5. User Interfaces (depend on backend services)
   ├── Overseerr (depends: Sonarr, Radarr)
   └── Portainer (independent)

6. Network Services (independent)
   ├── Samba
   ├── NFS Server
   └── Netdata
```

### Dependency Management

```bash
# Service dependency tracking
declare -A SERVICE_DEPS=(
    ["sonarr"]="prowlarr sabnzbd"
    ["radarr"]="prowlarr sabnzbd transmission"
    ["bazarr"]="sonarr radarr"
    ["overseerr"]="sonarr radarr"
    ["recyclarr"]="sonarr radarr"
    ["tdarr"]="jellyfin"
)

start_with_dependencies() {
    local service="$1"
    local deps="${SERVICE_DEPS[$service]:-}"
    
    # Start dependencies first
    for dep in $deps; do
        if ! is_service_running "$dep"; then
            info "Starting dependency: $dep"
            start_service "$dep"
            wait_for_service_healthy "$dep"
        fi
    done
    
    # Start requested service
    start_service "$service"
}
```

## Service Definitions

### Docker Compose Structure

**Base Configuration (`docker-compose.yml`):**
```yaml
version: '3.8'

services:
  # Media Services
  jellyfin:
    image: jellyfin/jellyfin:latest
    container_name: jellyfin
    ports:
      - "${JELLYFIN_PORT:-8096}:8096"
    volumes:
      - ./config/jellyfin:/config
      - ./cache/jellyfin:/cache
    restart: unless-stopped
    networks:
      - usenet-stack

  # Automation Services  
  sonarr:
    image: linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=${PUID:-1000}
      - PGID=${PGID:-1000}
      - TZ=${TZ:-UTC}
    ports:
      - "${SONARR_PORT:-8989}:8989"
    volumes:
      - ./config/sonarr:/config
      - ./downloads:/downloads
    restart: unless-stopped
    depends_on:
      - prowlarr
      - sabnzbd
    networks:
      - usenet-stack

networks:
  usenet-stack:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

**Hardware Optimization (`docker-compose.optimized.yml`):**
```yaml
# GPU-optimized configurations
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
      - internalNode=true
      - nodeID=MainNode
```

**Dynamic Storage (`docker-compose.storage.yml`):**
```yaml
# Auto-generated storage mounts
services:
  sonarr:
    volumes:
      - /media/external_4tb:/media/storage1:rw
      - /mnt/nas_media:/media/storage2:rw
      
  radarr:
    volumes:
      - /media/external_4tb:/media/storage1:rw
      - /mnt/nas_media:/media/storage2:rw
      
  jellyfin:
    volumes:
      - /media/external_4tb:/media/storage1:ro
      - /mnt/nas_media:/media/storage2:ro
```

## API Integration Architecture

### Service API Management

```bash
# API configuration for service integration
declare -A SERVICE_APIS=(
    ["sonarr"]="http://localhost:${SONARR_PORT:-8989}/api/v3"
    ["radarr"]="http://localhost:${RADARR_PORT:-7878}/api/v3" 
    ["prowlarr"]="http://localhost:${PROWLARR_PORT:-9696}/api/v1"
    ["jellyfin"]="http://localhost:${JELLYFIN_PORT:-8096}/jellyfin/api"
    ["overseerr"]="http://localhost:${OVERSEERR_PORT:-5055}/api/v1"
)

declare -A SERVICE_API_KEYS=(
    ["sonarr"]="${SONARR_API_KEY}"
    ["radarr"]="${RADARR_API_KEY}"
    ["prowlarr"]="${PROWLARR_API_KEY}"
    ["overseerr"]="${OVERSEERR_API_KEY}"
)
```

### Cross-Service API Synchronization

```bash
# Sync storage configuration across all services
sync_storage_apis() {
    local storage_config="$1"
    
    info "Synchronizing storage with service APIs..."
    
    # Update Sonarr root folders
    sync_sonarr_storage "$storage_config"
    
    # Update Radarr root folders  
    sync_radarr_storage "$storage_config"
    
    # Update Jellyfin libraries
    sync_jellyfin_storage "$storage_config"
    
    # Update Tdarr paths
    sync_tdarr_storage "$storage_config"
    
    success "Storage APIs synchronized"
}

sync_sonarr_storage() {
    local storage_config="$1"
    local api_url="${SERVICE_APIS[sonarr]}"
    local api_key="${SERVICE_API_KEYS[sonarr]}"
    
    # Get current root folders
    local current_folders
    current_folders=$(curl -s -H "X-Api-Key: $api_key" "$api_url/rootfolder")
    
    # Add new storage paths
    while IFS= read -r line; do
        local path mount_point
        path=$(echo "$line" | cut -d: -f1)
        mount_point=$(echo "$line" | cut -d: -f2)
        
        # Check if root folder exists
        if ! echo "$current_folders" | jq -e --arg path "$mount_point/tv" '.[] | select(.path == $path)' >/dev/null; then
            # Add new root folder
            curl -s -X POST \
                -H "X-Api-Key: $api_key" \
                -H "Content-Type: application/json" \
                -d "{\"path\": \"$mount_point/tv\", \"accessible\": true, \"freeSpace\": 0, \"unmappedFolders\": []}" \
                "$api_url/rootfolder"
            
            success "Added Sonarr root folder: $mount_point/tv"
        fi
    done < "$storage_config"
}
```

## Health Monitoring Architecture

### Service Health Checks

```bash
# Comprehensive health check system
check_service_health() {
    local service="$1"
    local health_score=0
    local max_score=100
    
    # Basic container health (25 points)
    if is_container_running "$service"; then
        ((health_score += 25))
        
        # Resource usage check (25 points)
        local cpu_usage memory_usage
        cpu_usage=$(get_container_cpu_usage "$service")
        memory_usage=$(get_container_memory_usage "$service")
        
        if [[ ${cpu_usage%.*} -lt 80 && ${memory_usage%.*} -lt 80 ]]; then
            ((health_score += 25))
        fi
        
        # API responsiveness (25 points)
        if check_service_api "$service"; then
            ((health_score += 25))
            
            # Service-specific functionality (25 points)
            case "$service" in
                sonarr|radarr)
                    if check_arr_service_health "$service"; then
                        ((health_score += 25))
                    fi
                    ;;
                jellyfin)
                    if check_jellyfin_health; then
                        ((health_score += 25))
                    fi
                    ;;
                prowlarr)
                    if check_prowlarr_indexers; then
                        ((health_score += 25))
                    fi
                    ;;
                *)
                    ((health_score += 25))  # Default healthy
                    ;;
            esac
        fi
    fi
    
    echo "$health_score"
}

check_arr_service_health() {
    local service="$1"
    local api_url="${SERVICE_APIS[$service]}"
    local api_key="${SERVICE_API_KEYS[$service]}"
    
    # Check system status
    local system_status
    system_status=$(curl -s -H "X-Api-Key: $api_key" "$api_url/system/status")
    
    # Verify essential components
    if echo "$system_status" | jq -e '.version' >/dev/null; then
        # Check for active indexers
        local indexers
        indexers=$(curl -s -H "X-Api-Key: $api_key" "$api_url/indexer")
        
        if echo "$indexers" | jq -e '.[] | select(.enable == true)' >/dev/null; then
            return 0
        fi
    fi
    
    return 1
}
```

### Real-Time Monitoring

```bash
# Service monitoring with alerting
monitor_services() {
    local alert_threshold="${1:-80}"
    local check_interval="${2:-60}"
    
    while true; do
        local unhealthy_services=()
        
        for service in "${ALL_SERVICES[@]}"; do
            local health_score
            health_score=$(check_service_health "$service")
            
            if [[ $health_score -lt $alert_threshold ]]; then
                unhealthy_services+=("$service:$health_score")
                warning "Service $service health degraded: $health_score%"
            fi
        done
        
        if [[ ${#unhealthy_services[@]} -gt 0 ]]; then
            send_health_alert "${unhealthy_services[@]}"
        fi
        
        sleep "$check_interval"
    done
}
```

## Resource Management

### Dynamic Resource Allocation

```bash
# Performance profile-based resource allocation
generate_resource_limits() {
    local profile="${PERFORMANCE_PROFILE:-balanced}"
    local total_memory total_cpu
    
    total_memory=$(get_total_memory_gb)
    total_cpu=$(nproc)
    
    case "$profile" in
        light)
            generate_light_profile "$total_memory" "$total_cpu"
            ;;
        balanced)
            generate_balanced_profile "$total_memory" "$total_cpu"
            ;;
        high)
            generate_high_profile "$total_memory" "$total_cpu"
            ;;
        dedicated)
            generate_dedicated_profile "$total_memory" "$total_cpu"
            ;;
    esac
}

generate_balanced_profile() {
    local memory="$1"
    local cpu="$2"
    
    # Allocate 50% of resources to media services
    local media_memory=$((memory / 2))
    local media_cpu=$((cpu / 2))
    
    cat > docker-compose.resources.yml << EOF
services:
  jellyfin:
    deploy:
      resources:
        limits:
          memory: ${media_memory}G
          cpus: '${media_cpu}'
        reservations:
          memory: $((media_memory / 4))G
          cpus: '1'
          
  tdarr:
    deploy:
      resources:
        limits:
          memory: $((media_memory / 2))G
          cpus: '${media_cpu}'
        reservations:
          memory: 1G
          cpus: '2'
EOF
}
```

### GPU Resource Management

```bash
# GPU allocation for transcoding services
allocate_gpu_resources() {
    local gpu_count
    gpu_count=$(get_gpu_count)
    
    if [[ $gpu_count -eq 0 ]]; then
        warning "No GPU detected, using CPU-only transcoding"
        return 1
    fi
    
    # Single GPU: Share between Jellyfin and Tdarr
    if [[ $gpu_count -eq 1 ]]; then
        configure_shared_gpu_access
    # Multiple GPUs: Dedicated allocation
    else
        configure_dedicated_gpu_access "$gpu_count"
    fi
}

configure_shared_gpu_access() {
    cat >> docker-compose.gpu.yml << 'EOF'
services:
  jellyfin:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
      
  tdarr:
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1  
              capabilities: [gpu]
    environment:
      - NVIDIA_VISIBLE_DEVICES=all
EOF
}
```

## Configuration Management

### Service Configuration Templates

```bash
# Generate service-specific configurations
generate_service_configs() {
    local service="$1"
    
    case "$service" in
        jellyfin)
            generate_jellyfin_config
            ;;
        sonarr|radarr)
            generate_arr_config "$service"
            ;;
        prowlarr)
            generate_prowlarr_config
            ;;
        tdarr)
            generate_tdarr_config
            ;;
    esac
}

generate_jellyfin_config() {
    local config_dir="./config/jellyfin"
    mkdir -p "$config_dir"
    
    # Generate hardware transcoding configuration
    if has_gpu_acceleration; then
        cat > "$config_dir/encoding.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<EncodingOptions>
  <HardwareAccelerationType>nvenc</HardwareAccelerationType>
  <EnableHardwareDecoding>true</EnableHardwareDecoding>
  <EnableHardwareEncoding>true</EnableHardwareEncoding>
  <EnableToneMappingDecodingWithNvenc>true</EnableToneMappingDecodingWithNvenc>
  <AllowHardwareSubtitleExtraction>true</AllowHardwareSubtitleExtraction>
  <H264Crf>23</H264Crf>
  <H265Crf>28</H265Crf>
  <DeinterlaceMethod>yadif</DeinterlaceMethod>
</EncodingOptions>
EOF
    fi
    
    # Generate system configuration
    cat > "$config_dir/system.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<ServerConfiguration>
  <EnableDashboard>true</EnableDashboard>
  <EnableExternalContentInSuggestions>false</EnableExternalContentInSuggestions>
  <RemoteIPFilter />
  <IsRemoteIPFilterBlacklist>false</IsRemoteIPFilterBlacklist>
  <ImageSavingConvention>Compatible</ImageSavingConvention>
  <PublishedServerUriBySubnet />
  <AutoDiscovery>true</AutoDiscovery>
  <EnableUPnP>false</EnableUPnP>
  <EnableRemoteAccess>true</EnableRemoteAccess>
  <LocalNetworkSubnets>
    <string>172.20.0.0/16</string>
    <string>192.168.0.0/16</string>
    <string>10.0.0.0/8</string>
  </LocalNetworkSubnets>
</ServerConfiguration>
EOF
}
```

## Service Discovery and Registration

### Dynamic Service Registration

```bash
# Register services with internal discovery
register_service() {
    local service="$1"
    local port="$2"
    local health_endpoint="$3"
    
    # Add to service registry
    cat >> ./config/service-registry.json << EOF
{
  "name": "$service",
  "port": $port,
  "health_endpoint": "$health_endpoint",
  "registered_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "api_key": "${SERVICE_API_KEYS[$service]:-}"
}
EOF
    
    # Update Traefik/reverse proxy configuration
    update_proxy_config "$service" "$port"
}

# Service discovery for API integration
discover_service_endpoints() {
    local discovered_services=()
    
    # Scan for running services
    for service in "${ALL_SERVICES[@]}"; do
        if is_service_running "$service"; then
            local port
            port=$(get_service_port "$service")
            discovered_services+=("$service:$port")
        fi
    done
    
    echo "${discovered_services[@]}"
}
```

## Security Architecture

### Service Authentication

```bash
# API key management
generate_api_keys() {
    local service="$1"
    local api_key
    
    # Generate secure API key
    api_key=$(openssl rand -hex 32)
    
    # Store in environment
    update_env_var "${service^^}_API_KEY" "$api_key"
    
    # Configure service with API key
    configure_service_auth "$service" "$api_key"
    
    echo "$api_key"
}

configure_service_auth() {
    local service="$1" 
    local api_key="$2"
    
    case "$service" in
        sonarr|radarr)
            # Configure *arr authentication
            local config_file="./config/$service/config.xml"
            if [[ -f "$config_file" ]]; then
                sed -i "s|<ApiKey>.*</ApiKey>|<ApiKey>$api_key</ApiKey>|" "$config_file"
            fi
            ;;
        jellyfin)
            # Jellyfin uses different auth mechanism
            configure_jellyfin_auth "$api_key"
            ;;
    esac
}
```

### Network Security

```bash
# Container network isolation
create_secure_network() {
    local network_name="usenet-stack"
    local subnet="172.20.0.0/16"
    
    # Create isolated bridge network
    docker network create \
        --driver bridge \
        --subnet="$subnet" \
        --ip-range="172.20.1.0/24" \
        --gateway="172.20.0.1" \
        "$network_name" 2>/dev/null || true
    
    # Configure firewall rules
    configure_network_firewall "$subnet"
}

configure_network_firewall() {
    local subnet="$1"
    
    # Allow internal communication
    ufw allow from "$subnet" to "$subnet"
    
    # Allow specific external access
    ufw allow "${JELLYFIN_PORT:-8096}/tcp"
    ufw allow "${OVERSEERR_PORT:-5055}/tcp"
    
    # Block direct access to management interfaces
    ufw deny "${SONARR_PORT:-8989}/tcp"
    ufw deny "${RADARR_PORT:-7878}/tcp"
}
```

## Related Documentation

- [Architecture Overview](./index) - System design principles
- [CLI Design](./cli-design) - Command interface architecture
- [Storage Architecture](./storage) - JBOD storage integration
- [Hardware Architecture](./hardware) - GPU optimization system
- [Network Architecture](./network) - Connectivity and security