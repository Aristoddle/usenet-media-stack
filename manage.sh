#!/bin/bash
# Enhanced Media Server Management Script
# Version: 2.0 - Docker Swarm Ready with Samba/NFS Integration
#
# This script manages a complete media automation and sharing stack:
# - Docker Compose/Swarm orchestration
# - Samba/NFS file sharing services  
# - Storage monitoring and health checks
# - Multi-device deployment support
# - System resource monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
COMPOSE_FILE="docker-compose.yml"
STACK_NAME="media-stack"
SWARM_MODE=${SWARM_MODE:-false}
MONITORING_ENABLED=${MONITORING_ENABLED:-true}

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Check if running in Docker Swarm mode
check_swarm_mode() {
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        SWARM_MODE=true
        log_info "Docker Swarm mode detected"
    else
        SWARM_MODE=false
        log_info "Docker Compose mode (standalone)"
    fi
}

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        log_error "Neither docker-compose nor 'docker compose' found. Please install Docker Compose."
        exit 1
    fi
}

# Docker Swarm initialization
init_swarm() {
    log_header "INITIALIZING DOCKER SWARM"
    
    if docker info 2>/dev/null | grep -q "Swarm: active"; then
        log_warning "Docker Swarm already initialized"
        return 0
    fi
    
    log_info "Initializing Docker Swarm..."
    
    # Get the primary network interface IP
    LOCAL_IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
    
    if docker swarm init --advertise-addr $LOCAL_IP; then
        log_success "Docker Swarm initialized successfully"
        log_info "Manager node IP: $LOCAL_IP"
        
        # Label this node for storage and high performance
        docker node update --label-add storage=true $(docker node ls --format "{{.Hostname}}" --filter "role=manager")
        docker node update --label-add performance=high $(docker node ls --format "{{.Hostname}}" --filter "role=manager")
        
        # Show join tokens
        echo
        log_info "To add worker nodes, run the following on other machines:"
        echo
        docker swarm join-token worker
        echo
        log_info "To add additional manager nodes, run:"
        echo  
        docker swarm join-token manager
        
    else
        log_error "Failed to initialize Docker Swarm"
        exit 1
    fi
}

# Add node to swarm
join_swarm() {
    local join_token="$1"
    local manager_ip="$2"
    
    if [ -z "$join_token" ] || [ -z "$manager_ip" ]; then
        log_error "Usage: $0 join-swarm <join-token> <manager-ip>"
        exit 1
    fi
    
    log_header "JOINING DOCKER SWARM"
    log_info "Attempting to join swarm at $manager_ip..."
    
    if docker swarm join --token $join_token $manager_ip:2377; then
        log_success "Successfully joined Docker Swarm"
    else
        log_error "Failed to join Docker Swarm"
        exit 1
    fi
}

# Label swarm nodes for optimal placement
label_nodes() {
    log_header "LABELING SWARM NODES"
    
    if [ "$SWARM_MODE" != "true" ]; then
        log_warning "Not in Swarm mode, skipping node labeling"
        return 0
    fi
    
    log_info "Available nodes:"
    docker node ls
    echo
    
    read -p "Enter node hostname to label: " node_hostname
    
    if [ -z "$node_hostname" ]; then
        log_warning "No node specified, exiting"
        return 0
    fi
    
    echo "Node capabilities:"
    echo "1) Storage node (has local storage)"
    echo "2) High performance (powerful CPU/RAM)"
    echo "3) Medium performance (moderate CPU/RAM)"
    echo "4) Low performance (limited resources)"
    echo "5) Remove all labels"
    
    read -p "Select capability (1-5): " capability
    
    case $capability in
        1)
            docker node update --label-add storage=true $node_hostname
            log_success "Labeled $node_hostname as storage node"
            ;;
        2)
            docker node update --label-add performance=high $node_hostname
            log_success "Labeled $node_hostname as high performance"
            ;;
        3)
            docker node update --label-add performance=medium $node_hostname
            log_success "Labeled $node_hostname as medium performance"
            ;;
        4)
            docker node update --label-add performance=low $node_hostname
            log_success "Labeled $node_hostname as low performance"
            ;;
        5)
            docker node update --label-rm storage $node_hostname 2>/dev/null || true
            docker node update --label-rm performance $node_hostname 2>/dev/null || true
            log_success "Removed labels from $node_hostname"
            ;;
        *)
            log_error "Invalid option selected"
            ;;
    esac
}

# Start the media stack
start_stack() {
    log_header "STARTING MEDIA SERVER STACK"
    
    check_swarm_mode
    
    if [ "$SWARM_MODE" = "true" ]; then
        log_info "Deploying stack to Docker Swarm..."
        docker stack deploy -c $COMPOSE_FILE $STACK_NAME
        
        # Wait for services to be ready
        log_info "Waiting for services to become ready..."
        sleep 10
        
        log_success "Media server stack deployed to Swarm!"
        
    else
        log_info "Starting stack with Docker Compose..."
        $COMPOSE_CMD up -d
        log_success "Media server stack started!"
    fi
    
    # Wait a bit for services to start
    sleep 5
    
    echo
    log_info "🌐 Services are starting up. Access points:"
    show_service_urls
    
    echo
    log_info "🔗 File Sharing:"
    show_sharing_info
}

# Stop the media stack
stop_stack() {
    log_header "STOPPING MEDIA SERVER STACK"
    
    check_swarm_mode
    
    if [ "$SWARM_MODE" = "true" ]; then
        log_info "Removing stack from Docker Swarm..."
        docker stack rm $STACK_NAME
        
        # Wait for stack to be fully removed
        log_info "Waiting for stack to be completely removed..."
        while docker stack ps $STACK_NAME &>/dev/null; do
            sleep 2
        done
        
        log_success "Media server stack removed from Swarm!"
    else
        log_info "Stopping stack with Docker Compose..."
        $COMPOSE_CMD down
        log_success "Media server stack stopped!"
    fi
}

# Restart the media stack
restart_stack() {
    log_header "RESTARTING MEDIA SERVER STACK"
    stop_stack
    sleep 5
    start_stack
}

# Update the media stack
update_stack() {
    log_header "UPDATING MEDIA SERVER STACK"
    
    check_swarm_mode
    
    if [ "$SWARM_MODE" = "true" ]; then
        log_info "Updating stack images..."
        docker stack deploy -c $COMPOSE_FILE $STACK_NAME
        log_success "Media server stack updated in Swarm!"
    else
        log_info "Pulling latest images..."
        $COMPOSE_CMD pull
        log_info "Recreating containers with new images..."
        $COMPOSE_CMD up -d
        log_success "Media server stack updated!"
    fi
}

# Show service status
show_status() {
    log_header "MEDIA SERVER STACK STATUS"
    
    check_swarm_mode
    
    if [ "$SWARM_MODE" = "true" ]; then
        log_info "Docker Swarm stack status:"
        docker stack ps $STACK_NAME --format "table {{.Name}}\t{{.Image}}\t{{.Node}}\t{{.CurrentState}}\t{{.Error}}"
        
        echo
        log_info "Service details:"
        docker service ls --filter "label=com.docker.stack.namespace=$STACK_NAME"
        
    else
        log_info "Docker Compose status:"
        $COMPOSE_CMD ps
    fi
    
    echo
    check_sharing_services
    check_storage_health
}

# Show service URLs  
show_service_urls() {
    cat << EOF
📺 Media Management:
   • Sonarr (TV):      http://localhost:8989
   • Radarr (Movies):  http://localhost:7878  
   • Bazarr (Subs):    http://localhost:6767

📥 Downloaders:
   • SABnzbd (Usenet): http://localhost:8080
   • Transmission:     http://localhost:9092

🔍 Indexers:
   • Prowlarr:         http://localhost:9696
   • Jackett:          http://localhost:9117

📚 Specialized:
   • Readarr (Books):  http://localhost:8787
   • Mylar3 (Comics):  http://localhost:8090
   • YacReader:        http://localhost:8082
   • Whisparr:         http://localhost:6969

🖥️  Monitoring:
   • Netdata:          http://localhost:19999
   • Portainer:        http://localhost:9000
EOF
}

# Show sharing information
show_sharing_info() {
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    
    cat << EOF
🗂️  SMB/CIFS Shares (Windows/macOS/Linux):
   • Media:     \\\\${hostname}\\Media     or  smb://${ip}/Media
   • Downloads: \\\\${hostname}\\Downloads or  smb://${ip}/Downloads
   • TV:        \\\\${hostname}\\TV        or  smb://${ip}/TV
   • Movies:    \\\\${hostname}\\Movies    or  smb://${ip}/Movies

📁 NFS Exports (Linux/Unix):
   • All Media: mount -t nfs ${ip}:/media/$USER /mnt/point
   • Downloads: mount -t nfs ${ip}:/downloads /mnt/point
   • Config:    mount -t nfs ${ip}:/config /mnt/point

🔑 Authentication: Username: joe, Password: joe (or guest access)
EOF
}

# Check sharing services status
check_sharing_services() {
    log_info "File Sharing Services Status:"
    
    # Check Samba container
    if docker ps --filter "name=samba" --format "{{.Names}}" | grep -q "samba"; then
        echo -e "   🟢 Samba: ${GREEN}Running${NC} (SMB/CIFS shares active)"
        
        # Test Samba connectivity
        if smbclient -L localhost -N &>/dev/null; then
            echo -e "   🟢 SMB shares: ${GREEN}Accessible${NC}"
        else
            echo -e "   🟡 SMB shares: ${YELLOW}Not responding${NC}"
        fi
    else
        echo -e "   🔴 Samba: ${RED}Not running${NC}"
    fi
    
    # Check NFS container
    if docker ps --filter "name=nfs-server" --format "{{.Names}}" | grep -q "nfs-server"; then
        echo -e "   🟢 NFS: ${GREEN}Running${NC} (NFS exports active)"
        
        # Test NFS connectivity  
        if showmount -e localhost &>/dev/null; then
            echo -e "   🟢 NFS exports: ${GREEN}Accessible${NC}"
        else
            echo -e "   🟡 NFS exports: ${YELLOW}Not responding${NC}"
        fi
    else
        echo -e "   🔴 NFS: ${RED}Not running${NC}"
    fi
}

# Check storage health
check_storage_health() {
    log_info "Storage Health Check:"
    
    # Check main storage drives
    echo "   📊 Disk Usage:"
    df -h /media/$USER/* 2>/dev/null | grep -E "(Fast_|Slow_)" | while read line; do
        usage=$(echo $line | awk '{print $5}' | tr -d '%')
        if [ $usage -gt 90 ]; then
            echo -e "   🔴 $line (${RED}Critical${NC})"
        elif [ $usage -gt 80 ]; then
            echo -e "   🟡 $line (${YELLOW}Warning${NC})"
        else
            echo -e "   🟢 $line (${GREEN}OK${NC})"
        fi
    done
    
    # Check downloads directory
    if [ -d "$HOME/usenet/downloads" ]; then
        downloads_usage=$(df -h $HOME/usenet/downloads | tail -1 | awk '{print $5}' | tr -d '%')
        if [ $downloads_usage -gt 80 ]; then
            echo -e "   🟡 Downloads: ${YELLOW}${downloads_usage}% used - Consider cleanup${NC}"
        else
            echo -e "   🟢 Downloads: ${GREEN}${downloads_usage}% used${NC}"
        fi
    fi
}

# Show logs
show_logs() {
    local service=$1
    check_swarm_mode
    
    if [ -n "$service" ]; then
        log_info "Showing logs for $service..."
        if [ "$SWARM_MODE" = "true" ]; then
            docker service logs -f --tail=50 "${STACK_NAME}_${service}"
        else
            $COMPOSE_CMD logs -f --tail=50 "$service"
        fi
    else
        log_info "Showing logs for all services..."
        if [ "$SWARM_MODE" = "true" ]; then
            docker stack ps $STACK_NAME
        else
            $COMPOSE_CMD logs -f --tail=50
        fi
    fi
}

# Restart specific service
restart_service() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Please specify a service name"
        exit 1
    fi
    
    check_swarm_mode
    
    log_info "Restarting $service..."
    
    if [ "$SWARM_MODE" = "true" ]; then
        docker service update --force "${STACK_NAME}_${service}"
        log_success "$service restarted in Swarm!"
    else
        $COMPOSE_CMD restart "$service"
        log_success "$service restarted!"
    fi
}

# Create Samba share
create_samba_share() {
    local share_name="$1"
    local share_path="$2"
    
    if [ "$#" -ne 2 ]; then
        echo "Usage: $0 create-share <share_name> <path>"
        echo "Example: $0 create-share NewMovies /media/$USER/Fast_8TB_1/Movies4K"
        exit 1
    fi
    
    if [ ! -d "$share_path" ]; then
        log_error "Directory $share_path does not exist"
        exit 1
    fi
    
    log_header "CREATING SAMBA SHARE"
    log_info "Creating share '$share_name' for path '$share_path'"
    
    # Add the share to the running Samba container
    if docker ps --filter "name=samba" --format "{{.Names}}" | grep -q "samba"; then
        # For dynamic shares, we'd need to modify the container config
        # For now, show instructions for manual addition
        log_info "To add this share permanently, add to docker-compose.yml:"
        echo "   -s \"${share_name};${share_path};yes;no;no;joe;joe;joe\""
        echo
        log_info "Then restart the stack with: $0 restart samba"
        echo
        log_info "Temporary access via existing Media share:"
        echo "   Path: ${share_path}"
    else
        log_error "Samba container not running. Start the stack first."
        exit 1
    fi
}

# System monitoring and health
system_health() {
    log_header "SYSTEM HEALTH OVERVIEW"
    
    # System load
    echo "💻 System Load:"
    uptime | awk -F'load average:' '{ print "   Current load:" $2 }'
    
    # Memory usage
    echo
    echo "🧠 Memory Usage:"
    free -h | grep -E "(Mem|Swap)" | awk '{printf "   %-4s: %s used / %s total (%s available)\n", $1, $3, $2, $7}'
    
    # Docker resource usage
    echo
    echo "🐳 Docker Resource Usage:"
    if command -v docker &> /dev/null; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | head -10
    fi
    
    echo
    check_storage_health
    
    echo
    check_sharing_services
}

# Network diagnostics
network_diagnostics() {
    log_header "NETWORK DIAGNOSTICS"
    
    echo "🌐 Network Configuration:"
    echo "   Hostname: $(hostname)"
    echo "   Primary IP: $(hostname -I | awk '{print $1}')"
    
    echo
    echo "🔌 Port Status:"
    netstat -tuln | grep -E "(8080|8989|7878|6767|9696|9117|139|445|2049)" | while read line; do
        echo "   $line"
    done
    
    echo
    echo "🔥 Firewall Status (UFW):"
    if command -v ufw &> /dev/null; then
        ufw status | head -10
    else
        echo "   UFW not installed"
    fi
    
    if [ "$SWARM_MODE" = "true" ]; then
        echo
        echo "🐝 Docker Swarm Networks:"
        docker network ls --filter "driver=overlay"
    fi
}

# Backup configurations
backup_configs() {
    local backup_dir="$HOME/usenet/backups/$(date +%Y%m%d_%H%M%S)"
    
    log_header "BACKING UP CONFIGURATIONS"
    log_info "Creating backup at $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # Backup docker-compose file
    cp "$COMPOSE_FILE" "$backup_dir/"
    
    # Backup service configs
    if [ -d "$HOME/usenet/config" ]; then
        tar czf "$backup_dir/config_backup.tar.gz" -C $HOME/usenet config/
        log_success "Service configurations backed up"
    fi
    
    # Backup this script
    cp "$0" "$backup_dir/"
    
    log_success "Backup completed at $backup_dir"
}

# Show help
show_help() {
    cat << EOF
Enhanced Media Server Management Script v2.0

USAGE: $0 [COMMAND] [OPTIONS]

STACK MANAGEMENT:
  start               Start all services
  stop                Stop all services  
  restart             Restart all services
  update              Update and restart all services
  status              Show service status and health
  logs [service]      Show logs (optionally for specific service)
  restart-service <service>  Restart specific service

DOCKER SWARM:
  init-swarm          Initialize Docker Swarm on this node
  join-swarm <token> <manager-ip>  Join existing swarm
  label-nodes         Label nodes for optimal service placement

FILE SHARING:
  create-share <name> <path>  Create new Samba share
  sharing-info        Show file sharing connection details

MONITORING & DIAGNOSTICS:
  system-health       Show system resource usage and health
  network-diag        Show network configuration and port status
  backup-configs      Backup all configuration files

AVAILABLE SERVICES:
  Media Management:   sonarr, radarr, bazarr, prowlarr
  Downloaders:        sabnzbd, transmission  
  Specialized:        whisparr, readarr, mylar, yacreader
  Indexers:           jackett
  File Sharing:       samba, nfs-server
  Monitoring:         netdata, portainer

EXAMPLES:
  $0 start                    # Start entire stack
  $0 logs sonarr             # View Sonarr logs
  $0 restart-service radarr  # Restart only Radarr
  $0 init-swarm              # Initialize Docker Swarm
  $0 create-share Movies4K /media/$USER/Fast_8TB_1/Movies4K
  $0 system-health           # Check system resources

ENVIRONMENT VARIABLES:
  SWARM_MODE=true            # Force Swarm mode
  MONITORING_ENABLED=false   # Disable monitoring services

For multi-device deployment, initialize Swarm on the main node, 
then join other devices using the provided tokens.
EOF
}

# Main script logic
main() {
    # Check docker-compose availability
    check_docker_compose
    
    case "${1:-help}" in
        start)
            start_stack
            ;;
        stop)
            stop_stack
            ;;
        restart)
            restart_stack
            ;;
        update)
            update_stack
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        restart-service)
            restart_service "$2"
            ;;
        init-swarm)
            init_swarm
            ;;
        join-swarm)
            join_swarm "$2" "$3"
            ;;
        label-nodes)
            label_nodes
            ;;
        create-share)
            create_samba_share "$2" "$3"
            ;;
        sharing-info)
            show_sharing_info
            ;;
        system-health)
            system_health
            ;;
        network-diag)
            network_diagnostics
            ;;
        backup-configs)
            backup_configs
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            echo
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@" 