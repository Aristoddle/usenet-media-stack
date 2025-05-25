# Storage Architecture

The hot-swappable JBOD (Just a Bunch of Disks) storage system is designed for maximum flexibility, cross-platform compatibility, and zero-downtime drive management. This architecture supports everything from portable USB drives for camping trips to enterprise NAS integration.

## Design Philosophy

### Hot-Swappable JBOD Principles

- **No RAID dependency** - Drives operate independently for maximum flexibility
- **Cross-platform compatibility** - exFAT support for Windows/macOS/Linux
- **Zero-downtime management** - Add/remove drives without service restart
- **Universal service access** - All 19 services automatically access selected storage
- **API-driven integration** - Automatic service configuration updates

### Real-World Use Cases

```
Storage Scenarios Supported:
├── Portable Media Setup
│   ├── USB drives for camping/travel
│   ├── External SSDs for fast access
│   └── SD cards for lightweight setups
├── Home Server Configuration
│   ├── Internal SATA drives
│   ├── NVMe for cache/transcoding
│   └── Network attached storage
├── Cloud Integration
│   ├── Dropbox/OneDrive mounts
│   ├── Google Drive via rclone
│   └── Remote server storage
└── Enterprise Setup
    ├── JBOD hardware controllers
    ├── SAN/iSCSI integration
    └── ZFS/Btrfs datasets
```

## Storage Discovery Architecture

### Universal Drive Detection

```bash
# Multi-layered drive discovery system
discover_all_drives() {
    local discovered_drives=()
    
    # Layer 1: Mounted filesystems
    discover_mounted_drives discovered_drives
    
    # Layer 2: Cloud storage mounts
    discover_cloud_storage discovered_drives
    
    # Layer 3: Network storage
    discover_network_storage discovered_drives
    
    # Layer 4: ZFS/Btrfs datasets
    discover_advanced_filesystems discovered_drives
    
    # Classification and filtering
    classify_and_filter_drives discovered_drives
}

discover_mounted_drives() {
    local -n drives_ref=$1
    
    # Parse mount output for relevant drives
    while IFS= read -r line; do
        local device mount_point fs_type options
        
        # Parse mount line: device on mount_point type fs_type (options)
        if [[ $line =~ ^(.+)\ on\ (.+)\ type\ (.+)\ \((.+)\)$ ]]; then
            device="${BASH_REMATCH[1]}"
            mount_point="${BASH_REMATCH[2]}"
            fs_type="${BASH_REMATCH[3]}"
            options="${BASH_REMATCH[4]}"
            
            # Filter relevant drives
            if is_media_storage_candidate "$device" "$mount_point" "$fs_type"; then
                drives_ref+=("$device:$mount_point:$fs_type:$options")
            fi
        fi
    done < <(mount | grep -E "(ext[234]|xfs|ntfs|exfat|vfat|zfs|btrfs)")
}

is_media_storage_candidate() {
    local device="$1"
    local mount_point="$2" 
    local fs_type="$3"
    
    # Exclude system drives
    case "$mount_point" in
        /|/boot|/boot/*|/dev|/dev/*|/proc|/sys|/tmp|/run|/var/run)
            return 1
            ;;
    esac
    
    # Exclude virtual filesystems
    case "$device" in
        tmpfs|devpts|sysfs|proc|cgroup*|overlay)
            return 1
            ;;
    esac
    
    # Include common media storage paths
    case "$mount_point" in
        /media/*|/mnt/*|/home/*/Dropbox|/home/*/OneDrive|/srv/*|/data/*)
            return 0
            ;;
    esac
    
    # Check if directory looks like media storage
    if [[ -d "$mount_point" ]]; then
        # Look for common media directories
        if ls "$mount_point" 2>/dev/null | grep -qE "(movies|tv|shows|media|downloads|books|music|comics)" 2>/dev/null; then
            return 0
        fi
        
        # Check if it's a large drive (>100GB)
        local available_space
        available_space=$(df --output=avail "$mount_point" 2>/dev/null | tail -1)
        if [[ ${available_space:-0} -gt 104857600 ]]; then  # 100GB in KB
            return 0
        fi
    fi
    
    return 1
}
```

### Cloud Storage Integration

```bash
# Cloud storage detection and integration
discover_cloud_storage() {
    local -n drives_ref=$1
    
    # Common cloud storage mount points
    local cloud_paths=(
        "/home/$USER/Dropbox"
        "/home/$USER/OneDrive" 
        "/home/$USER/Google Drive"
        "/home/$USER/GoogleDrive"
        "/mnt/gdrive"
        "/mnt/onedrive"
        "/mnt/dropbox"
    )
    
    for path in "${cloud_paths[@]}"; do
        if [[ -d "$path" && $(df "$path" 2>/dev/null | wc -l) -gt 1 ]]; then
            # Detect cloud storage type
            local storage_type
            storage_type=$(detect_cloud_storage_type "$path")
            
            # Get available space
            local available_space total_space
            available_space=$(df --output=avail "$path" 2>/dev/null | tail -1)
            total_space=$(df --output=size "$path" 2>/dev/null | tail -1)
            
            drives_ref+=("cloud:$path:$storage_type:$available_space:$total_space")
        fi
    done
    
    # Check for rclone mounts
    if command -v rclone >/dev/null; then
        discover_rclone_mounts drives_ref
    fi
}

detect_cloud_storage_type() {
    local path="$1"
    
    case "$path" in
        *Dropbox*|*dropbox*)
            echo "dropbox"
            ;;
        *OneDrive*|*onedrive*)
            echo "onedrive"
            ;;
        *Google*|*gdrive*|*googledrive*)
            echo "gdrive"
            ;;
        *)
            echo "cloud"
            ;;
    esac
}

discover_rclone_mounts() {
    local -n drives_ref=$1
    
    # Check for active rclone mounts
    while IFS= read -r line; do
        local remote mount_point
        remote=$(echo "$line" | awk '{print $1}')
        mount_point=$(echo "$line" | awk '{print $3}')
        
        if [[ -n "$mount_point" && -d "$mount_point" ]]; then
            drives_ref+=("rclone:$mount_point:$remote")
        fi
    done < <(mount | grep rclone 2>/dev/null || true)
}
```

## Storage Pool Management

### Pool Configuration

```bash
# Storage pool data structure
declare -A STORAGE_POOL=()
declare -A STORAGE_METADATA=()

# Pool configuration file format
# config/storage.conf:
# STORAGE_POOL_COUNT=3
# STORAGE_1_PATH="/media/external_4tb"
# STORAGE_1_MOUNT="/media/storage1"
# STORAGE_1_TYPE="local"
# STORAGE_1_ACCESS="rw"
# STORAGE_2_PATH="/home/user/Dropbox"
# STORAGE_2_MOUNT="/media/cloud1"
# STORAGE_2_TYPE="cloud"
# STORAGE_2_ACCESS="rw"

load_storage_pool() {
    local config_file="${STORAGE_CONFIG:-./config/storage.conf}"
    
    if [[ ! -f "$config_file" ]]; then
        warning "Storage configuration not found: $config_file"
        return 1
    fi
    
    source "$config_file"
    
    # Load pool configuration
    local pool_count="${STORAGE_POOL_COUNT:-0}"
    
    for ((i=1; i<=pool_count; i++)); do
        local path_var="STORAGE_${i}_PATH"
        local mount_var="STORAGE_${i}_MOUNT"
        local type_var="STORAGE_${i}_TYPE"
        local access_var="STORAGE_${i}_ACCESS"
        
        local path="${!path_var}"
        local mount="${!mount_var}"
        local type="${!type_var:-local}"
        local access="${!access_var:-rw}"
        
        if [[ -n "$path" && -n "$mount" ]]; then
            STORAGE_POOL["$path"]="$mount:$type:$access"
            info "Loaded storage: $path → $mount ($type, $access)"
        fi
    done
    
    success "Loaded ${#STORAGE_POOL[@]} storage devices from pool"
}

save_storage_pool() {
    local config_file="${STORAGE_CONFIG:-./config/storage.conf}"
    local backup_file="${config_file}.backup.$(date +%s)"
    
    # Backup existing configuration
    [[ -f "$config_file" ]] && cp "$config_file" "$backup_file"
    
    # Write new configuration
    {
        echo "# Storage pool configuration"
        echo "# Generated on $(date)"
        echo "STORAGE_POOL_COUNT=${#STORAGE_POOL[@]}"
        echo
        
        local i=1
        for path in "${!STORAGE_POOL[@]}"; do
            local config="${STORAGE_POOL[$path]}"
            local mount type access
            
            IFS=: read -r mount type access <<< "$config"
            
            echo "STORAGE_${i}_PATH=\"$path\""
            echo "STORAGE_${i}_MOUNT=\"$mount\""  
            echo "STORAGE_${i}_TYPE=\"$type\""
            echo "STORAGE_${i}_ACCESS=\"$access\""
            echo
            
            ((i++))
        done
    } > "$config_file"
    
    success "Storage configuration saved: $config_file"
    [[ -f "$backup_file" ]] && info "Backup created: $backup_file"
}
```

### Drive Addition Workflow

```bash
# Add drive to storage pool with validation
add_storage_drive() {
    local drive_path="$1"
    local custom_mount="${2:-}"
    local access_mode="${3:-rw}"
    
    # Validation checks
    validate_drive_addition "$drive_path" || return 1
    
    # Determine mount point
    local mount_point
    if [[ -n "$custom_mount" ]]; then
        mount_point="$custom_mount"
    else
        mount_point=$(generate_mount_point "$drive_path")
    fi
    
    # Detect storage type
    local storage_type
    storage_type=$(detect_storage_type "$drive_path")
    
    # Add to pool
    STORAGE_POOL["$drive_path"]="$mount_point:$storage_type:$access_mode"
    
    # Save configuration
    save_storage_pool
    
    # Generate Docker Compose integration
    generate_storage_compose
    
    # Update service APIs
    sync_storage_apis
    
    success "Added storage drive: $drive_path → $mount_point"
    info "Storage accessible to all 19 services as: $mount_point"
}

validate_drive_addition() {
    local drive_path="$1"
    
    # Check if path exists
    if [[ ! -d "$drive_path" ]]; then
        error "Drive path does not exist: $drive_path"
        return 1
    fi
    
    # Check if already in pool
    if [[ -n "${STORAGE_POOL[$drive_path]:-}" ]]; then
        warning "Drive already in storage pool: $drive_path"
        return 1
    fi
    
    # Check accessibility
    if [[ ! -r "$drive_path" ]]; then
        error "Drive path not readable: $drive_path"
        return 1
    fi
    
    # Check if it's a system path
    case "$drive_path" in
        /|/boot|/dev|/proc|/sys|/tmp|/run|/var/run)
            error "Cannot add system path to storage pool: $drive_path"
            return 1
            ;;
    esac
    
    # Check available space
    local available_space
    available_space=$(df --output=avail "$drive_path" 2>/dev/null | tail -1)
    if [[ ${available_space:-0} -lt 1048576 ]]; then  # 1GB minimum
        warning "Drive has less than 1GB available space: $drive_path"
        read -p "Continue anyway? (y/N): " -r confirm
        [[ $confirm =~ ^[Yy]$ ]] || return 1
    fi
    
    return 0
}

generate_mount_point() {
    local drive_path="$1"
    local base_name
    
    # Extract meaningful name from path
    case "$drive_path" in
        /media/*)
            base_name=$(basename "$drive_path")
            ;;
        /mnt/*)
            base_name=$(basename "$drive_path")
            ;;
        /home/*/Dropbox*)
            base_name="dropbox"
            ;;
        /home/*/OneDrive*)
            base_name="onedrive" 
            ;;
        *)
            base_name="storage"
            ;;
    esac
    
    # Generate unique mount point
    local counter=1
    local mount_point="/media/${base_name}"
    
    # Check for conflicts
    while [[ -n $(get_drive_by_mount "$mount_point") ]]; do
        mount_point="/media/${base_name}${counter}"
        ((counter++))
    done
    
    echo "$mount_point"
}
```

## Docker Compose Integration

### Dynamic Mount Generation

```bash
# Generate docker-compose.storage.yml with current pool
generate_storage_compose() {
    local compose_file="docker-compose.storage.yml"
    local temp_file="${compose_file}.tmp"
    
    # Generate header
    {
        echo "# Auto-generated storage mounts"
        echo "# Generated on $(date)"
        echo "# Do not edit manually - use 'usenet storage' commands"
        echo
        echo "version: '3.8'"
        echo
        echo "services:"
    } > "$temp_file"
    
    # Generate service mounts
    for service in "${MEDIA_SERVICES[@]}" "${AUTOMATION_SERVICES[@]}"; do
        generate_service_mounts "$service" >> "$temp_file"
    done
    
    # Atomic replacement
    mv "$temp_file" "$compose_file"
    
    success "Generated storage configuration: $compose_file"
}

generate_service_mounts() {
    local service="$1"
    
    echo "  $service:"
    echo "    volumes:"
    
    # Add all storage pool mounts
    for drive_path in "${!STORAGE_POOL[@]}"; do
        local config="${STORAGE_POOL[$drive_path]}"
        local mount_point type access
        
        IFS=: read -r mount_point type access <<< "$config"
        
        # Determine access mode for service
        local service_access
        service_access=$(get_service_access_mode "$service" "$access")
        
        echo "      - \"$drive_path:$mount_point:$service_access\""
    done
    
    echo
}

get_service_access_mode() {
    local service="$1"
    local default_access="$2"
    
    case "$service" in
        # Read-only services
        jellyfin|overseerr|netdata)
            echo "ro"
            ;;
        # Read-write services  
        sonarr|radarr|readarr|bazarr|tdarr|sabnzbd|transmission)
            echo "$default_access"
            ;;
        # Management services
        portainer|samba|nfs-server)
            echo "rw"
            ;;
        *)
            echo "$default_access"
            ;;
    esac
}
```

### Compose File Layering

```bash
# Docker Compose file hierarchy
COMPOSE_FILES=(
    "docker-compose.yml"                # Base service definitions
    "docker-compose.optimized.yml"      # Hardware optimizations  
    "docker-compose.storage.yml"        # Dynamic storage mounts
    "docker-compose.override.yml"       # User customizations
)

# Generate combined compose command
generate_compose_command() {
    local action="$1"
    shift
    
    local compose_cmd="docker compose"
    
    # Add all existing compose files
    for compose_file in "${COMPOSE_FILES[@]}"; do
        if [[ -f "$compose_file" ]]; then
            compose_cmd+=" -f $compose_file"
        fi
    done
    
    # Add action and arguments
    compose_cmd+=" $action $*"
    
    echo "$compose_cmd"
}

# Execute compose with all layers
execute_compose() {
    local compose_cmd
    compose_cmd=$(generate_compose_command "$@")
    
    info "Executing: $compose_cmd"
    eval "$compose_cmd"
}
```

## Cross-Platform Compatibility

### ExFAT Support for Portability

```bash
# ExFAT drive management for cross-platform compatibility
setup_exfat_drive() {
    local device="$1"
    local mount_point="$2"
    
    # Install exFAT support if needed
    if ! command -v mount.exfat >/dev/null; then
        info "Installing exFAT support..."
        case "$(get_os_type)" in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get install -y exfat-fuse exfat-utils
                ;;
            centos|rhel|fedora)
                sudo dnf install -y exfat-utils fuse-exfat
                ;;
            arch)
                sudo pacman -S exfat-utils
                ;;
        esac
    fi
    
    # Create mount point
    sudo mkdir -p "$mount_point"
    
    # Mount with proper permissions
    sudo mount -t exfat "$device" "$mount_point" \
        -o uid=1000,gid=1000,dmask=022,fmask=133,iocharset=utf8
    
    # Add to fstab for persistence
    if ! grep -q "$device" /etc/fstab; then
        echo "$device $mount_point exfat defaults,uid=1000,gid=1000,dmask=022,fmask=133,iocharset=utf8 0 0" | \
            sudo tee -a /etc/fstab
    fi
    
    success "ExFAT drive mounted: $device → $mount_point"
}

# Validate cross-platform compatibility
validate_cross_platform_compatibility() {
    local drive_path="$1"
    
    # Check filesystem type
    local fs_type
    fs_type=$(df -T "$drive_path" | tail -1 | awk '{print $2}')
    
    case "$fs_type" in
        exfat|vfat|ntfs)
            success "Cross-platform compatible filesystem: $fs_type"
            return 0
            ;;
        ext2|ext3|ext4|xfs|btrfs|zfs)
            warning "Linux-only filesystem: $fs_type"
            echo "Consider using exFAT for portable drives"
            return 1
            ;;
        *)
            warning "Unknown filesystem type: $fs_type"
            return 1
            ;;
    esac
}
```

### Windows/macOS Integration

```bash
# SMB/CIFS share integration
mount_windows_share() {
    local share_path="$1"      # //server/share
    local mount_point="$2"     # /mnt/windows_share
    local username="$3"
    local password="$4"
    
    # Install SMB client if needed
    if ! command -v mount.cifs >/dev/null; then
        install_smb_client
    fi
    
    # Create mount point
    sudo mkdir -p "$mount_point"
    
    # Mount share with proper permissions
    sudo mount -t cifs "$share_path" "$mount_point" \
        -o username="$username",password="$password",uid=1000,gid=1000,iocharset=utf8,file_mode=0644,dir_mode=0755
    
    # Verify mount
    if mountpoint -q "$mount_point"; then
        success "Windows share mounted: $share_path → $mount_point"
        return 0
    else
        error "Failed to mount Windows share: $share_path"
        return 1
    fi
}

# macOS AFP/SMB integration  
mount_macos_share() {
    local share_path="$1"      # afp://server/share or smb://server/share
    local mount_point="$2"
    local credentials="$3"     # username:password
    
    # Parse protocol
    local protocol
    protocol=$(echo "$share_path" | cut -d: -f1)
    
    case "$protocol" in
        afp)
            mount_afp_share "$share_path" "$mount_point" "$credentials"
            ;;
        smb)
            mount_smb_share "$share_path" "$mount_point" "$credentials"
            ;;
        *)
            error "Unsupported protocol: $protocol"
            return 1
            ;;
    esac
}
```

## API Integration

### Service API Synchronization

```bash
# Synchronize storage changes with service APIs
sync_storage_apis() {
    info "Synchronizing storage configuration with service APIs..."
    
    local sync_results=()
    
    # Update Sonarr root folders
    if sync_sonarr_root_folders; then
        sync_results+=("sonarr:success")
    else
        sync_results+=("sonarr:failed")
    fi
    
    # Update Radarr root folders
    if sync_radarr_root_folders; then
        sync_results+=("radarr:success")
    else
        sync_results+=("radarr:failed")
    fi
    
    # Update Jellyfin libraries
    if sync_jellyfin_libraries; then
        sync_results+=("jellyfin:success")
    else
        sync_results+=("jellyfin:failed")
    fi
    
    # Update Tdarr paths
    if sync_tdarr_paths; then
        sync_results+=("tdarr:success")
    else
        sync_results+=("tdarr:failed")
    fi
    
    # Report results
    report_sync_results "${sync_results[@]}"
}

sync_sonarr_root_folders() {
    local api_url="${SERVICE_APIS[sonarr]}"
    local api_key="${SERVICE_API_KEYS[sonarr]}"
    
    [[ -z "$api_url" || -z "$api_key" ]] && {
        warning "Sonarr API not configured"
        return 1
    }
    
    # Get current root folders
    local current_folders
    if ! current_folders=$(curl -s -H "X-Api-Key: $api_key" "$api_url/rootfolder"); then
        error "Failed to get Sonarr root folders"
        return 1
    fi
    
    # Add storage pool paths
    local added_count=0
    for drive_path in "${!STORAGE_POOL[@]}"; do
        local config="${STORAGE_POOL[$drive_path]}"
        local mount_point
        mount_point=$(echo "$config" | cut -d: -f1)
        
        local tv_path="$mount_point/tv"
        
        # Check if root folder already exists
        if ! echo "$current_folders" | jq -e --arg path "$tv_path" '.[] | select(.path == $path)' >/dev/null; then
            # Add new root folder
            local payload
            payload=$(jq -n --arg path "$tv_path" '{
                path: $path,
                accessible: true,
                freeSpace: 0,
                unmappedFolders: []
            }')
            
            if curl -s -X POST \
                -H "X-Api-Key: $api_key" \
                -H "Content-Type: application/json" \
                -d "$payload" \
                "$api_url/rootfolder" >/dev/null; then
                
                ((added_count++))
                info "Added Sonarr root folder: $tv_path"
            else
                warning "Failed to add Sonarr root folder: $tv_path"
            fi
        fi
    done
    
    success "Sonarr sync complete: $added_count root folders added"
    return 0
}
```

## Performance Optimization

### Storage Performance Tuning

```bash
# Optimize storage performance based on drive type
optimize_storage_performance() {
    local drive_path="$1"
    local mount_point="$2"
    
    # Detect drive type
    local drive_type
    drive_type=$(detect_drive_type "$drive_path")
    
    case "$drive_type" in
        ssd|nvme)
            optimize_ssd_performance "$drive_path" "$mount_point"
            ;;
        hdd)
            optimize_hdd_performance "$drive_path" "$mount_point"
            ;;
        usb)
            optimize_usb_performance "$drive_path" "$mount_point"
            ;;
        network)
            optimize_network_storage "$drive_path" "$mount_point"
            ;;
    esac
}

optimize_ssd_performance() {
    local drive_path="$1"
    local mount_point="$2"
    
    # Enable TRIM support
    if command -v fstrim >/dev/null; then
        sudo fstrim "$mount_point" 2>/dev/null || true
    fi
    
    # Optimize mount options for SSD
    local device
    device=$(df "$mount_point" | tail -1 | awk '{print $1}')
    
    # Add noatime,discard to mount options if not present
    if ! mount | grep "$device" | grep -q "noatime"; then
        info "Consider remounting with noatime,discard for SSD optimization"
    fi
}

optimize_hdd_performance() {
    local drive_path="$1"
    local mount_point="$2"
    
    # Set optimal read-ahead for HDDs
    local device
    device=$(df "$mount_point" | tail -1 | awk '{print $1}')
    device=$(basename "$device")
    
    if [[ -f "/sys/block/$device/queue/read_ahead_kb" ]]; then
        echo 4096 | sudo tee "/sys/block/$device/queue/read_ahead_kb" >/dev/null
        info "Optimized read-ahead for HDD: $device"
    fi
}
```

## Related Documentation

- [Architecture Overview](./index) - System design principles
- [CLI Design](./cli-design) - Storage command implementation
- [Service Architecture](./services) - API integration details
- [Hardware Architecture](./hardware) - Performance optimization
- [Network Architecture](./network) - Network storage integration