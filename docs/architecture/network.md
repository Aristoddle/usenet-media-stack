# Network Architecture

The network architecture provides secure, scalable connectivity through Cloudflare tunnels, container isolation, and intelligent service exposure. This design ensures zero exposed ports while maintaining professional-grade security and performance.

## Design Philosophy

### Zero-Trust Network Model

- **No exposed ports** - All external access via Cloudflare tunnels
- **Container isolation** - Services in dedicated Docker networks
- **Encrypted communications** - TLS termination at Cloudflare edge
- **API authentication** - Service-level security with unique keys

### Professional Connectivity

```
Network Access Layers:
├── Public Internet
│   └── Cloudflare Edge (SSL/TLS termination)
├── Cloudflare Tunnel
│   └── Encrypted connection to local system
├── Local Reverse Proxy
│   └── Service routing and load balancing
├── Docker Networks
│   └── Isolated container communication
└── Service APIs
    └── Individual service authentication
```

## Network Topology

### Container Network Architecture

```bash
# Docker network configuration
create_container_networks() {
    # Primary media stack network
    docker network create \
        --driver bridge \
        --subnet 172.20.0.0/16 \
        --ip-range 172.20.1.0/24 \
        --gateway 172.20.0.1 \
        --opt com.docker.network.bridge.name=usenet-stack0 \
        usenet-stack || true
    
    # Management network (isolated)
    docker network create \
        --driver bridge \
        --subnet 172.21.0.0/16 \
        --ip-range 172.21.1.0/24 \
        --gateway 172.21.0.1 \
        --opt com.docker.network.bridge.name=usenet-mgmt0 \
        usenet-management || true
    
    # External network for file sharing
    docker network create \
        --driver bridge \
        --subnet 172.22.0.0/16 \
        --ip-range 172.22.1.0/24 \
        --gateway 172.22.0.1 \
        --opt com.docker.network.bridge.name=usenet-share0 \
        usenet-sharing || true
}
```

### Service Network Segmentation

```yaml
# Network assignment by service category
networks:
  # Media services - high bandwidth, moderate security
  media-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
    
  # Automation services - API-heavy, secure
  automation-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
        
  # Management services - admin access, high security
  management-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/16
        
  # File sharing - external access, controlled
  sharing-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/16

services:
  # Media Services
  jellyfin:
    networks:
      - media-network
      - automation-network  # API access to *arr services
      
  overseerr:
    networks:
      - media-network
      - automation-network  # API access to Sonarr/Radarr
      
  # Automation Services
  sonarr:
    networks:
      - automation-network
      
  radarr:
    networks:
      - automation-network
      
  # Management Services
  portainer:
    networks:
      - management-network
      - media-network       # Monitor all services
      
  netdata:
    networks:
      - management-network
      
  # File Sharing
  samba:
    networks:
      - sharing-network
      - media-network       # Access to media files
```

## Cloudflare Tunnel Integration

### Tunnel Configuration

```bash
# Cloudflare tunnel setup and management
setup_cloudflare_tunnel() {
    local domain="$1"
    local tunnel_name="${2:-usenet-stack}"
    
    info "Setting up Cloudflare tunnel for domain: $domain"
    
    # Install cloudflared if needed
    install_cloudflared
    
    # Authenticate with Cloudflare
    authenticate_cloudflare
    
    # Create tunnel
    create_tunnel "$tunnel_name" "$domain"
    
    # Configure tunnel routing
    configure_tunnel_routes "$tunnel_name" "$domain"
    
    # Install tunnel service
    install_tunnel_service "$tunnel_name"
    
    success "Cloudflare tunnel configured: $tunnel_name"
}

install_cloudflared() {
    if command -v cloudflared >/dev/null; then
        info "cloudflared already installed"
        return 0
    fi
    
    info "Installing cloudflared..."
    
    local os_arch
    os_arch="$(uname -s | tr '[:upper:]' '[:lower:]')-$(uname -m)"
    
    case "$os_arch" in
        linux-x86_64)
            local download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
            ;;
        linux-aarch64)
            local download_url="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
            ;;
        *)
            error "Unsupported architecture: $os_arch"
            return 1
            ;;
    esac
    
    # Download and install
    curl -Lo /tmp/cloudflared "$download_url"
    sudo install /tmp/cloudflared /usr/local/bin/cloudflared
    rm /tmp/cloudflared
    
    success "cloudflared installed"
}

create_tunnel() {
    local tunnel_name="$1"
    local domain="$2"
    
    # Create tunnel
    local tunnel_id
    tunnel_id=$(cloudflared tunnel create "$tunnel_name" 2>/dev/null | grep -o '[a-f0-9-]\{36\}' | head -1)
    
    if [[ -z "$tunnel_id" ]]; then
        # Tunnel might already exist
        tunnel_id=$(cloudflared tunnel list | grep "$tunnel_name" | awk '{print $1}' | head -1)
        
        if [[ -n "$tunnel_id" ]]; then
            info "Using existing tunnel: $tunnel_name ($tunnel_id)"
        else
            error "Failed to create or find tunnel: $tunnel_name"
            return 1
        fi
    else
        success "Created tunnel: $tunnel_name ($tunnel_id)"
    fi
    
    # Store tunnel ID
    echo "$tunnel_id" > "./config/cloudflare_tunnel_id"
}

configure_tunnel_routes() {
    local tunnel_name="$1"
    local domain="$2"
    
    # Generate tunnel configuration
    local config_file="$HOME/.cloudflared/config.yml"
    mkdir -p "$(dirname "$config_file")"
    
    cat > "$config_file" << EOF
tunnel: $tunnel_name
credentials-file: $HOME/.cloudflared/${tunnel_name}.json

ingress:
  # Media Services
  - hostname: jellyfin.${domain}
    service: http://localhost:8096
    originRequest:
      noTLSVerify: true
      
  - hostname: overseerr.${domain}
    service: http://localhost:5055
    originRequest:
      noTLSVerify: true
      
  - hostname: comics.${domain}
    service: http://localhost:8082
    originRequest:
      noTLSVerify: true
      
  # Management Services
  - hostname: portainer.${domain}
    service: http://localhost:9000
    originRequest:
      noTLSVerify: true
      
  - hostname: monitor.${domain}
    service: http://localhost:19999
    originRequest:
      noTLSVerify: true
      
  # Automation Services (admin subdomain)
  - hostname: sonarr.admin.${domain}
    service: http://localhost:8989
    originRequest:
      noTLSVerify: true
      
  - hostname: radarr.admin.${domain}
    service: http://localhost:7878
    originRequest:
      noTLSVerify: true
      
  - hostname: prowlarr.admin.${domain}
    service: http://localhost:9696
    originRequest:
      noTLSVerify: true
      
  # Catch-all
  - service: http_status:404
EOF
    
    # Create DNS records
    create_dns_records "$domain"
    
    success "Tunnel configuration created: $config_file"
}

create_dns_records() {
    local domain="$1"
    local tunnel_id
    tunnel_id=$(cat "./config/cloudflare_tunnel_id")
    
    # Public services
    local public_services=(
        "jellyfin"
        "overseerr" 
        "comics"
        "portainer"
        "monitor"
    )
    
    # Admin services
    local admin_services=(
        "sonarr.admin"
        "radarr.admin"
        "prowlarr.admin"
        "bazarr.admin"
        "sabnzbd.admin"
    )
    
    # Create DNS records for public services
    for service in "${public_services[@]}"; do
        cloudflared tunnel route dns "$tunnel_id" "${service}.${domain}" || {
            warning "Failed to create DNS record: ${service}.${domain}"
        }
    done
    
    # Create DNS records for admin services
    for service in "${admin_services[@]}"; do
        cloudflared tunnel route dns "$tunnel_id" "${service}.${domain}" || {
            warning "Failed to create DNS record: ${service}.${domain}"
        }
    done
    
    success "DNS records created for domain: $domain"
}
```

### SSL Certificate Management

```bash
# Cloudflare automatically handles SSL certificates
configure_ssl_security() {
    local domain="$1"
    
    info "Configuring SSL security settings..."
    
    # Set minimum TLS version via Cloudflare API
    local zone_id
    zone_id=$(get_cloudflare_zone_id "$domain")
    
    if [[ -n "$zone_id" ]]; then
        # Set minimum TLS to 1.2
        curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_id/settings/min_tls_version" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data '{"value":"1.2"}' >/dev/null
        
        # Enable HSTS
        curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_id/settings/security_header" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data '{"value":{"strict_transport_security":{"enabled":true,"max_age":15552000,"include_subdomains":true}}}' >/dev/null
        
        # Enable automatic HTTPS rewrites
        curl -X PATCH "https://api.cloudflare.com/client/v4/zones/$zone_id/settings/automatic_https_rewrites" \
            -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
            -H "Content-Type: application/json" \
            --data '{"value":"on"}' >/dev/null
        
        success "SSL security settings configured"
    else
        warning "Could not configure SSL settings - zone not found"
    fi
}

get_cloudflare_zone_id() {
    local domain="$1"
    
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$domain" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" | \
        jq -r '.result[0].id // empty'
}
```

## Service Discovery and Load Balancing

### Internal Service Discovery

```bash
# Service discovery for internal API communication
discover_service_endpoints() {
    local service_registry="./config/service_registry.json"
    
    # Initialize registry if it doesn't exist
    if [[ ! -f "$service_registry" ]]; then
        echo '{"services": {}, "last_updated": ""}' > "$service_registry"
    fi
    
    # Discover running services
    local discovered_services=()
    
    for service in "${ALL_SERVICES[@]}"; do
        if is_container_running "$service"; then
            local container_ip port health_status
            container_ip=$(get_container_ip "$service")
            port=$(get_service_port "$service")
            health_status=$(check_service_health "$service")
            
            discovered_services+=("$service:$container_ip:$port:$health_status")
        fi
    done
    
    # Update service registry
    update_service_registry "${discovered_services[@]}"
    
    echo "${discovered_services[@]}"
}

update_service_registry() {
    local discovered_services=("$@")
    local service_registry="./config/service_registry.json"
    local temp_registry="${service_registry}.tmp"
    
    # Build new registry
    {
        echo '{'
        echo '  "services": {'
        
        local first=true
        for service_info in "${discovered_services[@]}"; do
            local service container_ip port health_status
            IFS=: read -r service container_ip port health_status <<< "$service_info"
            
            if [[ "$first" == "true" ]]; then
                first=false
            else
                echo ','
            fi
            
            echo -n "    \"$service\": {"
            echo -n "\"ip\": \"$container_ip\", "
            echo -n "\"port\": $port, "
            echo -n "\"health\": \"$health_status\", "
            echo -n "\"last_seen\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
            echo -n "}"
        done
        
        echo
        echo '  },'
        echo "  \"last_updated\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
        echo '}'
    } > "$temp_registry"
    
    # Atomic update
    mv "$temp_registry" "$service_registry"
}

get_container_ip() {
    local service="$1"
    docker inspect "$service" --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null | head -1
}
```

### Load Balancing Configuration

```bash
# Configure load balancing for scalable services
configure_load_balancing() {
    local service="$1"
    local replicas="${2:-2}"
    
    case "$service" in
        tdarr)
            configure_tdarr_load_balancing "$replicas"
            ;;
        jellyfin)
            # Jellyfin doesn't support horizontal scaling
            warning "Jellyfin does not support load balancing"
            ;;
        *)
            configure_generic_load_balancing "$service" "$replicas"
            ;;
    esac
}

configure_tdarr_load_balancing() {
    local replicas="$1"
    
    # Create Tdarr node configuration
    local nodes_config="./config/tdarr/nodes.json"
    mkdir -p "$(dirname "$nodes_config")"
    
    {
        echo '{'
        echo '  "nodes": ['
        
        for ((i=1; i<=replicas; i++)); do
            if [[ $i -gt 1 ]]; then
                echo ','
            fi
            
            echo "    {"
            echo "      \"id\": \"node$i\","
            echo "      \"type\": \"worker\","
            echo "      \"gpu_access\": true,"
            echo "      \"max_workers\": 2"
            echo -n "    }"
        done
        
        echo
        echo '  ]'
        echo '}'
    } > "$nodes_config"
    
    success "Tdarr load balancing configured: $replicas nodes"
}
```

## Security Architecture

### Network Security Policies

```bash
# Configure network security policies
configure_network_security() {
    # Container network isolation
    configure_container_isolation
    
    # Firewall rules
    configure_host_firewall
    
    # API authentication
    configure_api_security
    
    # Network monitoring
    setup_network_monitoring
}

configure_container_isolation() {
    # Disable inter-container communication by default
    docker network create \
        --driver bridge \
        --internal \
        --subnet 172.30.0.0/16 \
        usenet-isolated || true
    
    # Create communication rules
    docker network create \
        --driver bridge \
        --subnet 172.31.0.0/16 \
        usenet-frontend || true
    
    # Connect services to appropriate networks
    connect_services_to_networks
}

configure_host_firewall() {
    info "Configuring host firewall rules..."
    
    # Reset UFW to defaults
    sudo ufw --force reset >/dev/null
    
    # Default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH (be careful!)
    sudo ufw allow ssh
    
    # Allow internal docker networks
    sudo ufw allow from 172.20.0.0/16
    sudo ufw allow from 172.21.0.0/16
    sudo ufw allow from 172.22.0.0/16
    
    # Block direct access to service ports
    sudo ufw deny 8080:9999/tcp comment "Block direct service access"
    
    # Allow only Cloudflare tunnel
    sudo ufw allow from 198.41.128.0/17 comment "Cloudflare IP range"
    sudo ufw allow from 173.245.48.0/20 comment "Cloudflare IP range"
    sudo ufw allow from 103.21.244.0/22 comment "Cloudflare IP range"
    sudo ufw allow from 103.22.200.0/22 comment "Cloudflare IP range"
    sudo ufw allow from 103.31.4.0/22 comment "Cloudflare IP range"
    
    # Enable firewall
    sudo ufw --force enable
    
    success "Host firewall configured"
}

configure_api_security() {
    info "Configuring API security..."
    
    # Generate unique API keys for each service
    for service in sonarr radarr readarr bazarr prowlarr overseerr; do
        if [[ -z "${!service^^}_API_KEY" ]]; then
            local api_key
            api_key=$(openssl rand -hex 32)
            update_env_var "${service^^}_API_KEY" "$api_key"
            info "Generated API key for $service"
        fi
    done
    
    # Configure service authentication
    configure_service_authentication
    
    success "API security configured"
}
```

### VPN Integration

```bash
# Configure VPN for download clients
configure_vpn_integration() {
    local vpn_provider="$1"
    local vpn_config="$2"
    
    info "Configuring VPN integration for download clients..."
    
    case "$vpn_provider" in
        wireguard)
            configure_wireguard_vpn "$vpn_config"
            ;;
        openvpn)
            configure_openvpn_vpn "$vpn_config"
            ;;
        *)
            error "Unsupported VPN provider: $vpn_provider"
            return 1
            ;;
    esac
}

configure_wireguard_vpn() {
    local config_file="$1"
    
    # Create VPN network
    docker network create \
        --driver bridge \
        --subnet 172.40.0.0/16 \
        usenet-vpn || true
    
    # Update transmission configuration for VPN
    cat >> docker-compose.vpn.yml << EOF
services:
  wireguard:
    image: linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./config/wireguard:/config
      - /lib/modules:/lib/modules
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
    networks:
      - usenet-vpn
      
  transmission:
    network_mode: service:wireguard
    depends_on:
      - wireguard
EOF
    
    # Copy VPN configuration
    mkdir -p ./config/wireguard
    cp "$config_file" ./config/wireguard/wg0.conf
    
    success "WireGuard VPN configured"
}
```

## Monitoring and Analytics

### Network Performance Monitoring

```bash
# Network performance monitoring
setup_network_monitoring() {
    info "Setting up network performance monitoring..."
    
    # Configure Netdata for network monitoring
    configure_netdata_network_monitoring
    
    # Set up bandwidth monitoring
    setup_bandwidth_monitoring
    
    # Configure connection tracking
    setup_connection_tracking
}

configure_netdata_network_monitoring() {
    local netdata_config="./config/netdata/netdata.conf"
    mkdir -p "$(dirname "$netdata_config")"
    
    cat > "$netdata_config" << 'EOF'
[global]
    process scheduling policy = other
    OOM score = 1000

[plugins]
    apps = yes
    cgroups = yes
    charts.d = yes
    checks = no
    diskspace = yes
    fping = yes
    idlejitter = yes
    node.d = yes
    proc = yes
    python.d = yes
    tc = yes

[plugin:tc]
    script to run to get tc values = /usr/libexec/netdata/plugins.d/tc-qos-helper.sh

[plugin:proc:/proc/net/dev]
    refresh every = 1

[plugin:proc:/proc/net/netstat]
    refresh every = 1
EOF
    
    success "Netdata network monitoring configured"
}

setup_bandwidth_monitoring() {
    # Create bandwidth monitoring script
    cat > ./scripts/monitor_bandwidth.sh << 'EOF'
#!/bin/bash
# Bandwidth monitoring for Usenet Media Stack

LOG_FILE="/var/log/usenet-bandwidth.log"
INTERVAL=60

while true; do
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get interface statistics
    rx_bytes=$(cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null || echo 0)
    tx_bytes=$(cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null || echo 0)
    
    # Convert to MB
    rx_mb=$(echo "scale=2; $rx_bytes / 1024 / 1024" | bc -l)
    tx_mb=$(echo "scale=2; $tx_bytes / 1024 / 1024" | bc -l)
    
    # Log statistics
    echo "$timestamp,RX:${rx_mb}MB,TX:${tx_mb}MB" >> "$LOG_FILE"
    
    sleep $INTERVAL
done
EOF
    
    chmod +x ./scripts/monitor_bandwidth.sh
    
    success "Bandwidth monitoring script created"
}
```

## File Sharing Architecture

### SMB/CIFS Configuration

```bash
# Configure Samba for Windows file sharing
configure_samba_sharing() {
    local share_name="${1:-media}"
    local share_path="${2:-/media/storage1}"
    
    info "Configuring Samba file sharing..."
    
    # Create Samba configuration
    local samba_config="./config/samba/smb.conf"
    mkdir -p "$(dirname "$samba_config")"
    
    cat > "$samba_config" << EOF
[global]
    workgroup = WORKGROUP
    server string = Usenet Media Stack
    server role = standalone server
    log file = /var/log/samba/log.%m
    max log size = 1000
    logging = file
    panic action = /usr/share/samba/panic-action %d
    server min protocol = SMB2
    server max protocol = SMB3
    encrypt passwords = true
    obey pam restrictions = yes
    unix password sync = yes
    passwd program = /usr/bin/passwd %u
    passwd chat = *Enter\snew\s*\spassword:* %n\n *Retype\snew\s*\spassword:* %n\n *password\supdated\ssuccessfully* .
    pam password change = yes
    map to guest = bad user
    usershare allow guests = yes

[$share_name]
    comment = Media Files
    path = $share_path
    browseable = yes
    read only = no
    guest ok = yes
    create mask = 0644
    directory mask = 0755
    force user = 1000
    force group = 1000
EOF
    
    success "Samba configuration created: $samba_config"
}

# Configure NFS for Unix/Linux file sharing  
configure_nfs_sharing() {
    local export_path="${1:-/media/storage1}"
    local allowed_networks="${2:-192.168.0.0/16,172.16.0.0/12,10.0.0.0/8}"
    
    info "Configuring NFS file sharing..."
    
    # Create NFS exports configuration
    local exports_config="./config/nfs/exports"
    mkdir -p "$(dirname "$exports_config")"
    
    cat > "$exports_config" << EOF
# NFS exports for Usenet Media Stack
$export_path $allowed_networks(rw,sync,no_subtree_check,no_root_squash,insecure)
EOF
    
    success "NFS exports configured: $exports_config"
}
```

## Related Documentation

- [Architecture Overview](./index) - System design principles
- [CLI Design](./cli-design) - Network command implementation  
- [Service Architecture](./services) - Service connectivity
- [Storage Architecture](./storage) - Network storage integration
- [Hardware Architecture](./hardware) - Network performance optimization