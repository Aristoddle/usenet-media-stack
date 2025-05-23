#!/bin/bash
# Complete Media Server Installation Script
# Version: 2.0 - Docker Swarm Ready with Integrated Samba/NFS
#
# This script automates the complete setup of a production-ready
# media automation and file sharing stack including:
# - System preparation and security hardening
# - Docker and Docker Compose installation
# - Firewall configuration
# - Storage setup and mounting
# - Service deployment and configuration
# - Multi-device Swarm initialization (optional)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_NAME="joe"
USER_ID="1000"
GROUP_ID="1000"
INSTALL_DIR="/home/joe/usenet"
DOCKER_COMPOSE_VERSION="2.24.0"
SWARM_SETUP=false
SECURITY_HARDENING=true
STORAGE_SETUP=true

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
    echo
    echo -e "${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        log_info "Please run as a regular user with sudo privileges"
        exit 1
    fi

    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo access"
        log_info "Please ensure your user has sudo privileges"
        exit 1
    fi
}

# Display banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║    Complete Home Media Automation & Network Sharing Stack    ║
║                        Version 2.0                           ║
║                                                               ║
║    🎬 Media Automation: Sonarr, Radarr, Bazarr, Prowlarr    ║
║    📥 Download Clients: SABnzbd, Transmission                ║
║    📁 File Sharing: Samba, NFS                              ║
║    📊 Monitoring: Netdata, Portainer                        ║
║    🐳 Docker Swarm Ready for Multi-Device Deployment        ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Interactive configuration
configure_installation() {
    log_header "INSTALLATION CONFIGURATION"
    
    echo "This installer will set up a complete media automation stack."
    echo "Please answer a few questions to customize your installation:"
    echo
    
    # Installation directory
    read -p "Installation directory [$INSTALL_DIR]: " input_dir
    INSTALL_DIR=${input_dir:-$INSTALL_DIR}
    
    # User configuration
    read -p "Username for services [$USER_NAME]: " input_user
    USER_NAME=${input_user:-$USER_NAME}
    
    # Swarm setup
    echo
    echo "Multi-Device Setup Options:"
    echo "1) Single device installation (Docker Compose)"
    echo "2) Multi-device setup (Docker Swarm Manager)"
    echo "3) Join existing Docker Swarm"
    read -p "Select option [1]: " swarm_option
    
    case ${swarm_option:-1} in
        2)
            SWARM_SETUP=true
            log_info "Will initialize Docker Swarm on this node"
            ;;
        3)
            SWARM_SETUP="join"
            read -p "Enter Swarm join token: " SWARM_TOKEN
            read -p "Enter manager IP address: " SWARM_MANAGER_IP
            ;;
        *)
            SWARM_SETUP=false
            log_info "Single device installation selected"
            ;;
    esac
    
    # Security options
    echo
    read -p "Enable security hardening (firewall, SSH, etc.)? [Y/n]: " security_choice
    if [[ ${security_choice,,} == "n" ]]; then
        SECURITY_HARDENING=false
    fi
    
    # Storage setup
    echo
    read -p "Configure storage drives and mounting? [Y/n]: " storage_choice
    if [[ ${storage_choice,,} == "n" ]]; then
        STORAGE_SETUP=false
    fi
    
    echo
    log_info "Configuration complete. Installation will begin..."
    sleep 3
}

# System update and preparation
prepare_system() {
    log_header "SYSTEM PREPARATION"
    
    log_info "Updating system packages..."
    sudo apt update -qq
    sudo apt upgrade -y -qq
    
    log_info "Installing essential packages..."
    sudo apt install -y \
        curl \
        wget \
        git \
        htop \
        iotop \
        net-tools \
        unzip \
        zip \
        tree \
        rsync \
        nfs-common \
        cifs-utils \
        smbclient \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    # Create user if doesn't exist
    if ! id "$USER_NAME" &>/dev/null; then
        log_info "Creating user $USER_NAME..."
        sudo useradd -m -u $USER_ID -s /bin/bash $USER_NAME
        sudo usermod -aG sudo $USER_NAME
        echo "$USER_NAME:mediaserver" | sudo chpasswd
        log_success "User $USER_NAME created"
    fi
    
    log_success "System preparation completed"
}

# Docker installation
install_docker() {
    log_header "DOCKER INSTALLATION"
    
    # Check if Docker is already installed
    if command -v docker &> /dev/null; then
        log_warning "Docker is already installed"
        docker --version
        return 0
    fi
    
    log_info "Installing Docker..."
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt update -qq
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Add user to docker group
    sudo usermod -aG docker $USER_NAME
    sudo usermod -aG docker $(whoami)
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Configure Docker daemon
    sudo tee /etc/docker/daemon.json > /dev/null << EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "userland-proxy": false,
    "experimental": false,
    "live-restore": true
}
EOF
    
    sudo systemctl restart docker
    
    log_success "Docker installation completed"
    log_info "Docker version: $(docker --version)"
}

# Storage configuration
configure_storage() {
    if [[ "$STORAGE_SETUP" != "true" ]]; then
        log_info "Skipping storage configuration"
        return 0
    fi
    
    log_header "STORAGE CONFIGURATION"
    
    # Create base directories
    log_info "Creating directory structure..."
    sudo mkdir -p /media/joe
    sudo mkdir -p $INSTALL_DIR/{config,downloads,backups}
    
    # Set permissions
    sudo chown -R $USER_NAME:$USER_NAME /media/joe
    sudo chown -R $USER_NAME:$USER_NAME $INSTALL_DIR
    
    # Detect available drives
    log_info "Scanning for available storage drives..."
    available_drives=$(lsblk -dpno NAME,SIZE,TYPE | grep disk | grep -v $(df / | tail -1 | awk '{print $1}' | sed 's/[0-9]*//g'))
    
    if [[ -n "$available_drives" ]]; then
        echo "Available drives:"
        echo "$available_drives"
        echo
        read -p "Would you like to configure these drives? [y/N]: " configure_drives
        
        if [[ ${configure_drives,,} == "y" ]]; then
            echo "$available_drives" | while read -r drive size type; do
                echo "Configure drive $drive ($size)?"
                read -p "Mount point (e.g., Fast_8TB_1): " mount_name
                
                if [[ -n "$mount_name" ]]; then
                    mount_point="/media/joe/$mount_name"
                    
                    # Create filesystem if needed
                    if ! sudo blkid "$drive" &>/dev/null; then
                        log_info "Creating filesystem on $drive..."
                        sudo mkfs.ext4 -F "$drive"
                    fi
                    
                    # Create mount point
                    sudo mkdir -p "$mount_point"
                    
                    # Add to fstab
                    uuid=$(sudo blkid -s UUID -o value "$drive")
                    echo "UUID=$uuid $mount_point ext4 defaults,nofail 0 2" | sudo tee -a /etc/fstab
                    
                    # Mount drive
                    sudo mount "$mount_point"
                    sudo chown -R $USER_NAME:$USER_NAME "$mount_point"
                    
                    log_success "Mounted $drive at $mount_point"
                fi
            done
        fi
    else
        log_warning "No additional drives detected"
    fi
    
    log_success "Storage configuration completed"
}

# Security configuration
configure_security() {
    if [[ "$SECURITY_HARDENING" != "true" ]]; then
        log_info "Skipping security hardening"
        return 0
    fi
    
    log_header "SECURITY CONFIGURATION"
    
    # Install and configure UFW
    log_info "Installing and configuring firewall..."
    sudo apt install -y ufw
    
    # Reset UFW
    sudo ufw --force reset
    
    # Set default policies
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Define trusted network (adjust as needed)
    TRUSTED_NETWORK="192.168.0.0/16"
    
    # Media server ports
    log_info "Configuring firewall rules for media services..."
    sudo ufw allow from $TRUSTED_NETWORK to any port 8080  # SABnzbd
    sudo ufw allow from $TRUSTED_NETWORK to any port 8989  # Sonarr
    sudo ufw allow from $TRUSTED_NETWORK to any port 7878  # Radarr
    sudo ufw allow from $TRUSTED_NETWORK to any port 6767  # Bazarr
    sudo ufw allow from $TRUSTED_NETWORK to any port 9696  # Prowlarr
    sudo ufw allow from $TRUSTED_NETWORK to any port 9117  # Jackett
    sudo ufw allow from $TRUSTED_NETWORK to any port 8787  # Readarr
    sudo ufw allow from $TRUSTED_NETWORK to any port 8090  # Mylar3
    sudo ufw allow from $TRUSTED_NETWORK to any port 8082  # YacReader
    sudo ufw allow from $TRUSTED_NETWORK to any port 6969  # Whisparr
    sudo ufw allow from $TRUSTED_NETWORK to any port 9092  # Transmission
    
    # Monitoring ports
    sudo ufw allow from $TRUSTED_NETWORK to any port 19999 # Netdata
    sudo ufw allow from $TRUSTED_NETWORK to any port 9000  # Portainer
    
    # File sharing ports
    sudo ufw allow from $TRUSTED_NETWORK to any port 139   # SMB
    sudo ufw allow from $TRUSTED_NETWORK to any port 445   # SMB
    sudo ufw allow from $TRUSTED_NETWORK to any port 2049  # NFS
    sudo ufw allow from $TRUSTED_NETWORK to any port 111   # NFS
    
    # BitTorrent ports
    sudo ufw allow 51413/tcp
    sudo ufw allow 51413/udp
    
    # Docker Swarm ports (if needed)
    if [[ "$SWARM_SETUP" == "true" ]] || [[ "$SWARM_SETUP" == "join" ]]; then
        sudo ufw allow from $TRUSTED_NETWORK to any port 2377  # Swarm management
        sudo ufw allow from $TRUSTED_NETWORK to any port 7946  # Node communication
        sudo ufw allow from $TRUSTED_NETWORK to any port 4789  # Overlay network
    fi
    
    # Enable UFW
    sudo ufw --force enable
    
    # Install Fail2Ban for additional protection
    log_info "Installing Fail2Ban..."
    sudo apt install -y fail2ban
    
    # Basic Fail2Ban configuration
    sudo tee /etc/fail2ban/jail.local > /dev/null << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s
EOF
    
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    
    log_success "Security configuration completed"
}

# Docker Swarm setup
setup_docker_swarm() {
    if [[ "$SWARM_SETUP" == "true" ]]; then
        log_header "DOCKER SWARM INITIALIZATION"
        
        # Get primary IP address
        LOCAL_IP=$(ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
        
        log_info "Initializing Docker Swarm on $LOCAL_IP..."
        
        if docker swarm init --advertise-addr $LOCAL_IP; then
            log_success "Docker Swarm initialized successfully"
            
            # Label this node
            hostname=$(hostname)
            docker node update --label-add storage=true $hostname
            docker node update --label-add performance=high $hostname
            docker node update --label-add node-type=storage-manager $hostname
            
            echo
            log_info "To add worker nodes to this swarm, run the following command on other machines:"
            echo
            docker swarm join-token worker
            echo
            
        else
            log_error "Failed to initialize Docker Swarm"
        fi
        
    elif [[ "$SWARM_SETUP" == "join" ]]; then
        log_header "JOINING DOCKER SWARM"
        
        if [[ -n "$SWARM_TOKEN" ]] && [[ -n "$SWARM_MANAGER_IP" ]]; then
            log_info "Joining swarm at $SWARM_MANAGER_IP..."
            
            if docker swarm join --token $SWARM_TOKEN $SWARM_MANAGER_IP:2377; then
                log_success "Successfully joined Docker Swarm"
            else
                log_error "Failed to join Docker Swarm"
            fi
        else
            log_error "Missing swarm token or manager IP"
        fi
    fi
}

# Deploy media stack
deploy_stack() {
    log_header "DEPLOYING MEDIA STACK"
    
    # Change to installation directory
    cd $INSTALL_DIR
    
    # Make management script executable
    chmod +x manage.sh
    
    # Start the stack
    log_info "Starting media server stack..."
    if ./manage.sh start; then
        log_success "Media stack deployed successfully!"
        
        sleep 5
        
        echo
        log_info "🌐 Services are starting up. Access points:"
        ./manage.sh status
        
        echo
        log_info "🔗 File Sharing Information:"
        echo "Run './manage.sh sharing-info' for detailed connection instructions"
        
    else
        log_error "Failed to deploy media stack"
        return 1
    fi
}

# Post-installation setup
post_installation() {
    log_header "POST-INSTALLATION SETUP"
    
    # Create useful aliases
    log_info "Creating helpful aliases..."
    cat >> ~/.bashrc << 'EOF'

# Media Server Aliases
alias media-start='cd /home/joe/usenet && ./manage.sh start'
alias media-stop='cd /home/joe/usenet && ./manage.sh stop'
alias media-status='cd /home/joe/usenet && ./manage.sh status'
alias media-logs='cd /home/joe/usenet && ./manage.sh logs'
alias media-health='cd /home/joe/usenet && ./manage.sh system-health'
alias media-backup='cd /home/joe/usenet && ./manage.sh backup-configs'
EOF
    
    # Create desktop shortcuts (if GUI available)
    if [[ -n "$DISPLAY" ]] && command -v xdg-desktop-menu &> /dev/null; then
        log_info "Creating desktop shortcuts..."
        
        mkdir -p ~/.local/share/applications
        
        cat > ~/.local/share/applications/media-server.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Media Server Dashboard
Comment=Access Media Server Services
Exec=xdg-open http://localhost:9000
Icon=applications-multimedia
Categories=AudioVideo;Network;
EOF
        
        xdg-desktop-menu forceupdate
    fi
    
    # Create backup script
    log_info "Setting up automated backups..."
    cat > $INSTALL_DIR/backup-cron.sh << 'EOF'
#!/bin/bash
# Automated backup script for media server
cd /home/joe/usenet
./manage.sh backup-configs
# Keep only last 7 days of backups
find /home/joe/usenet/backups -name "*.tar.gz" -mtime +7 -delete
EOF
    
    chmod +x $INSTALL_DIR/backup-cron.sh
    
    # Add to crontab (weekly backups)
    (crontab -l 2>/dev/null; echo "0 3 * * 0 $INSTALL_DIR/backup-cron.sh") | crontab -
    
    log_success "Post-installation setup completed"
}

# Display final information
show_completion() {
    log_header "INSTALLATION COMPLETED SUCCESSFULLY!"
    
    local hostname=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    
    cat << EOF

🎉 Your Complete Media Automation & File Sharing Stack is ready!

📊 MANAGEMENT:
   • System Status:     cd $INSTALL_DIR && ./manage.sh status
   • Start Services:    cd $INSTALL_DIR && ./manage.sh start
   • Stop Services:     cd $INSTALL_DIR && ./manage.sh stop
   • View Logs:         cd $INSTALL_DIR && ./manage.sh logs [service]
   • System Health:     cd $INSTALL_DIR && ./manage.sh system-health

🌐 WEB INTERFACES:
   • Portainer:         http://$ip:9000 (Container Management)
   • Sonarr (TV):       http://$ip:8989
   • Radarr (Movies):   http://$ip:7878
   • SABnzbd:           http://$ip:8080
   • Prowlarr:          http://$ip:9696
   • Netdata:           http://$ip:19999 (System Monitoring)

📁 FILE SHARING:
   • SMB/CIFS:          \\\\$hostname\\Media or smb://$ip/Media
   • NFS:               mount -t nfs $ip:/media/joe /mnt/point

🔐 SECURITY:
   • Firewall:          sudo ufw status
   • Fail2Ban:          sudo fail2ban-client status

📚 DOCUMENTATION:
   • Main Guide:        $INSTALL_DIR/README.md
   • Swarm Guide:       $INSTALL_DIR/DOCKER_SWARM_GUIDE.md
   • Security Guide:    $INSTALL_DIR/SECURITY_GUIDE.md

💡 NEXT STEPS:
   1. Configure indexers in Prowlarr: http://$ip:9696
   2. Set up download clients (SABnzbd/Transmission)
   3. Add media root folders in Sonarr/Radarr
   4. Configure subtitle providers in Bazarr

EOF

    if [[ "$SWARM_SETUP" == "true" ]]; then
        echo "🐝 DOCKER SWARM:"
        echo "   • This node is initialized as Swarm manager"
        echo "   • Use the provided join tokens to add worker nodes"
        echo "   • Run './manage.sh label-nodes' to configure node placement"
        echo
    fi

    echo "📞 SUPPORT:"
    echo "   • GitHub Issues: https://github.com/Aristoddle/home-media-server/issues"
    echo "   • Documentation: https://github.com/Aristoddle/home-media-server"
    echo
    echo "🎯 Happy media automation!"
}

# Main installation flow
main() {
    show_banner
    check_root
    configure_installation
    prepare_system
    install_docker
    configure_storage
    configure_security
    setup_docker_swarm
    deploy_stack
    post_installation
    show_completion
}

# Error handling
trap 'log_error "Installation failed at line $LINENO. Check the output above for details."; exit 1' ERR

# Run main installation
main "$@" 