#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/storage.zsh
# Project: Usenet Media Stack
# Description: JBOD storage pool management
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Manages JBOD (Just a Bunch of Disks) storage configuration for the media
# stack. Handles adding/removing drives, checking disk health, and managing
# mount points for optimal media storage distribution.
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Load core functions
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"
source "${SCRIPT_DIR:h}/core/common.zsh"
source "${SCRIPT_DIR:h}/core/init.zsh"

# Ensure config is loaded
load_stack_config || die 1 "Failed to load configuration"

##############################################################################
#                             STORAGE FUNCTIONS                              #
##############################################################################

#=============================================================================
# Function: show_storage_help
# Description: Display storage management help
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#=============================================================================
show_storage_help() {
    cat <<'HELP'
🗄️  Storage Management

USAGE
    usenet storage <action> [options]

ACTIONS
    status             Show current storage configuration and health
    discover           Scan and list all available mounted drives
    select             Interactive drive selection with TUI interface
    add <path>         Add a new drive to the storage pool
    remove <path>      Remove drive from storage pool (data preserved)
    health             Check health status of all drives
    balance            Rebalance data across available drives
    mount              Mount all configured drives
    unmount            Safely unmount all drives
    apply              Apply storage changes and restart services

OPTIONS
    --force, -f        Force operation without confirmation
    --verbose, -v      Show detailed output
    --dry-run, -n      Show what would be done without executing

EXAMPLES
    Check storage status:
        $ usenet storage status
        
    Add a new drive:
        $ usenet storage add /mnt/disk2
        
    Check drive health:
        $ usenet storage health
        
    Balance storage usage:
        $ usenet storage balance --verbose

NOTES
    • All drives must be pre-mounted in /mnt/ directory
    • JBOD configuration distributes content across drives
    • Use 'balance' after adding new drives for optimal distribution
    • Health checks use smartctl if available

HELP
}

#=============================================================================
# Function: get_storage_config
# Description: Get current storage pool configuration
#
# Returns:
#   0 - Configuration found
#   1 - No configuration exists
#=============================================================================
get_storage_config() {
    local config_file="${PROJECT_ROOT}/config/storage.conf"
    
    if [[ -f "$config_file" ]]; then
        return 0
    else
        return 1
    fi
}

#=============================================================================
# Function: show_storage_status
# Description: Display current storage pool status
#
# Arguments:
#   None
#
# Returns:
#   0 - Status shown successfully
#   1 - Error getting status
#=============================================================================
show_storage_status() {
    info "Storage Pool Status"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local config_file="${PROJECT_ROOT}/config/storage.conf"
    
    if [[ ! -f "$config_file" ]]; then
        warning "No storage configuration found"
        info "Run 'usenet storage add <path>' to add your first drive"
        return 1
    fi
    
    # Read storage configuration
    local drive_count=0
    local total_space=0
    local used_space=0
    
    while IFS= read -r drive_path; do
        [[ -z "$drive_path" || "$drive_path" =~ ^# ]] && continue
        
        if [[ -d "$drive_path" ]]; then
            ((drive_count++))
            
            # Get disk usage (convert from KB to GB)
            local usage=$(df -k "$drive_path" 2>/dev/null | tail -1)
            if [[ -n "$usage" ]]; then
                local size_kb=$(echo "$usage" | awk '{print $2}')
                local used_kb=$(echo "$usage" | awk '{print $3}')
                local avail_kb=$(echo "$usage" | awk '{print $4}')
                local percent=$(echo "$usage" | awk '{print $5}')
                
                local size_gb=$((size_kb / 1024 / 1024))
                local used_gb=$((used_kb / 1024 / 1024))
                local avail_gb=$((avail_kb / 1024 / 1024))
                
                total_space=$((total_space + size_gb))
                used_space=$((used_space + used_gb))
                
                print "  ${COLOR_GREEN}✓${COLOR_RESET} $drive_path"
                print "    Size: ${size_gb}GB | Used: ${used_gb}GB (${percent}) | Available: ${avail_gb}GB"
            else
                print "  ${COLOR_RED}✗${COLOR_RESET} $drive_path (not accessible)"
            fi
        else
            print "  ${COLOR_RED}✗${COLOR_RESET} $drive_path (not found)"
        fi
    done < "$config_file"
    
    print ""
    print "Total Pool: ${drive_count} drives, ${total_space}GB total, ${used_space}GB used"
    
    # Show mount status
    info "Media directories:"
    for dir in downloads media; do
        local dir_path="${PROJECT_ROOT}/$dir"
        if [[ -d "$dir_path" ]]; then
            local mount_info=$(df -h "$dir_path" 2>/dev/null | tail -1 | awk '{print $5 " used on " $6}')
            print "  $dir: $mount_info"
        fi
    done
}

#=============================================================================
# Function: add_storage_drive
# Description: Add a new drive to the storage pool
#
# Arguments:
#   $1 - Drive path to add
#
# Returns:
#   0 - Drive added successfully
#   1 - Error adding drive
#=============================================================================
add_storage_drive() {
    local drive_path="$1"
    
    if [[ -z "$drive_path" ]]; then
        error "Drive path required"
        print "Usage: usenet storage add <path>"
        return 1
    fi
    
    # Validate drive path
    if [[ ! -d "$drive_path" ]]; then
        error "Directory does not exist: $drive_path"
        return 1
    fi
    
    # Check if drive is mounted
    if ! mountpoint -q "$drive_path" 2>/dev/null; then
        warning "Path is not a mount point: $drive_path"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi
    
    # Create storage config if it doesn't exist
    local config_file="${PROJECT_ROOT}/config/storage.conf"
    local config_dir="${PROJECT_ROOT}/config"
    
    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir"
    fi
    
    if [[ ! -f "$config_file" ]]; then
        cat > "$config_file" <<EOF
# Usenet Media Stack Storage Configuration
# Each line represents a drive in the JBOD pool
# Lines starting with # are ignored
#
# Created: $(date)
EOF
    fi
    
    # Check if drive already exists in config
    if grep -Fxq "$drive_path" "$config_file" 2>/dev/null; then
        warning "Drive already in pool: $drive_path"
        return 1
    fi
    
    # Add drive to config
    echo "$drive_path" >> "$config_file"
    success "Added drive to storage pool: $drive_path"
    
    # Update Docker Compose bind mounts
    info "Updating Docker Compose configuration..."
    update_compose_mounts
    
    info "Drive added successfully. Consider running 'usenet storage balance' to redistribute content."
    return 0
}

#=============================================================================
# Function: remove_storage_drive
# Description: Remove a drive from the storage pool
#
# Arguments:
#   $1 - Drive path to remove
#
# Returns:
#   0 - Drive removed successfully
#   1 - Error removing drive
#=============================================================================
remove_storage_drive() {
    local drive_path="$1"
    
    if [[ -z "$drive_path" ]]; then
        error "Drive path required"
        print "Usage: usenet storage remove <path>"
        return 1
    fi
    
    local config_file="${PROJECT_ROOT}/config/storage.conf"
    
    if [[ ! -f "$config_file" ]]; then
        error "No storage configuration found"
        return 1
    fi
    
    # Check if drive exists in config
    if ! grep -Fxq "$drive_path" "$config_file"; then
        error "Drive not found in pool: $drive_path"
        return 1
    fi
    
    warning "Removing drive from storage pool: $drive_path"
    warning "This will NOT delete data on the drive"
    if ! confirm "Continue with removal?"; then
        return 1
    fi
    
    # Remove from config (create temp file to avoid issues)
    local temp_file=$(mktemp)
    grep -Fxv "$drive_path" "$config_file" > "$temp_file"
    mv "$temp_file" "$config_file"
    
    success "Removed drive from storage pool: $drive_path"
    
    # Update Docker Compose bind mounts
    info "Updating Docker Compose configuration..."
    update_compose_mounts
    
    return 0
}

#=============================================================================
# Function: check_storage_health
# Description: Check health status of all drives in the pool
#
# Arguments:
#   None
#
# Returns:
#   0 - Health check completed
#   1 - Error during health check
#=============================================================================
check_storage_health() {
    info "Storage Health Check"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local config_file="${PROJECT_ROOT}/config/storage.conf"
    
    if [[ ! -f "$config_file" ]]; then
        error "No storage configuration found"
        return 1
    fi
    
    local healthy_drives=0
    local total_drives=0
    
    while IFS= read -r drive_path; do
        [[ -z "$drive_path" || "$drive_path" =~ ^# ]] && continue
        
        ((total_drives++))
        print "Checking: $drive_path"
        
        # Check if mounted and accessible
        if [[ -d "$drive_path" ]] && [[ -r "$drive_path" ]] && [[ -w "$drive_path" ]]; then
            print "  ${COLOR_GREEN}✓${COLOR_RESET} Mount point accessible"
            ((healthy_drives++))
            
            # Try to get device name for SMART check
            local device=$(df "$drive_path" | tail -1 | awk '{print $1}' | sed 's/[0-9]*$//')
            
            if command -v smartctl >/dev/null 2>&1 && [[ -b "$device" ]]; then
                local smart_status=$(smartctl -H "$device" 2>/dev/null | grep "SMART overall-health" | awk '{print $NF}')
                if [[ "$smart_status" == "PASSED" ]]; then
                    print "  ${COLOR_GREEN}✓${COLOR_RESET} SMART status: PASSED"
                else
                    print "  ${COLOR_YELLOW}⚠${COLOR_RESET} SMART status: $smart_status"
                fi
            else
                print "  ${COLOR_BLUE}ℹ${COLOR_RESET} SMART check not available"
            fi
        else
            print "  ${COLOR_RED}✗${COLOR_RESET} Drive not accessible"
        fi
        
        print ""
    done < "$config_file"
    
    if [[ $healthy_drives -eq $total_drives ]]; then
        success "All $total_drives drives are healthy"
    else
        warning "$((total_drives - healthy_drives)) of $total_drives drives have issues"
    fi
    
    return 0
}

#=============================================================================
# Function: update_compose_mounts
# Description: Update Docker Compose with current storage configuration
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration updated
#   1 - Error updating configuration
#=============================================================================
update_compose_mounts() {
    info "Updating Docker Compose with dynamic JBOD mounts..."
    
    local config_file="${PROJECT_ROOT}/config/storage.conf"
    local compose_override="${PROJECT_ROOT}/docker-compose.storage.yml"
    
    if [[ ! -f "$config_file" ]]; then
        warning "No storage configuration found"
        return 1
    fi
    
    # Generate storage-specific compose override
    cat > "$compose_override" <<EOF
# Auto-generated JBOD Storage Configuration
# Generated: $(date)
# 
# This file is automatically generated by 'usenet storage' commands
# Do not edit manually - changes will be overwritten
#
# Usage: docker-compose -f docker-compose.yml -f docker-compose.storage.yml up -d

services:
EOF
    
    # Read configured drives and generate mount points
    local drive_num=1
    local tv_mounts=""
    local movie_mounts=""
    local media_mounts=""
    
    while IFS= read -r drive_path; do
        [[ -z "$drive_path" || "$drive_path" =~ ^# ]] && continue
        
        # Generate mount paths for each content type
        tv_mounts="${tv_mounts}      - ${drive_path}:/tv/drive${drive_num}:rw\n"
        movie_mounts="${movie_mounts}      - ${drive_path}:/movies/drive${drive_num}:rw\n"
        media_mounts="${media_mounts}      - ${drive_path}:/media/drive${drive_num}:rw\n"
        
        ((drive_num++))
    done < "$config_file"
    
    # Add mounts to relevant services
    for service in sonarr radarr bazarr jellyfin tdarr; do
        cat >> "$compose_override" <<EOF

  ${service}:
    volumes:
$(echo -e "$tv_mounts$movie_mounts$media_mounts")
EOF
    done
    
    # Add Samba/NFS sharing mounts
    cat >> "$compose_override" <<EOF

  samba:
    volumes:
$(echo -e "$media_mounts")

  nfs:
    volumes:
$(echo -e "$media_mounts")
EOF
    
    success "Generated storage configuration: $compose_override"
    info "Apply with: docker-compose -f docker-compose.yml -f docker-compose.storage.yml up -d"
    return 0
}

#=============================================================================
# Function: discover_all_drives
# Description: Discover and list all mounted drives on the system
#
# Arguments:
#   None
#
# Returns:
#   0 - Discovery completed successfully
#   1 - Error during discovery
#=============================================================================
discover_all_drives() {
    info "Discovering all mounted drives on system..."
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get all mounted filesystems, excluding system/virtual ones
    local discovered_drives=()
    local drive_details=()
    
    # Parse mount output and filter for real storage devices
    while IFS= read -r line; do
        local device=$(echo "$line" | awk '{print $1}')
        local mount_point=$(echo "$line" | awk '{print $3}')
        local fs_type=$(echo "$line" | awk '{print $5}')
        local size_info=""
        
        # Skip system virtual filesystems but include real storage
        [[ "$mount_point" =~ ^/(proc|sys|dev|run|boot/efi|snap) ]] && continue
        [[ "$fs_type" =~ ^(proc|sysfs|devtmpfs|tmpfs|securityfs|cgroup|pstore|bpf|tracefs|debugfs|mqueue|hugetlbfs|fusectl|configfs|squashfs|overlay) ]] && continue
        [[ "$device" =~ ^(udev|tmpfs|none) ]] && continue
        
        # Include real storage filesystems: ext4, xfs, btrfs, zfs, ntfs, etc.
        # Also include root filesystem and data mounts
        
        # Get size information
        if [[ -d "$mount_point" ]]; then
            size_info=$(df -h "$mount_point" 2>/dev/null | tail -1 | awk '{print $2 " total, " $4 " available (" $5 " used)"}')
        fi
        
        # Determine drive type and characteristics
        local drive_type="Unknown"
        local drive_description=""
        
        if [[ "$device" =~ nvme ]]; then
            drive_type="NVMe SSD"
            drive_description="High-performance NVMe storage"
        elif [[ "$fs_type" == "ext4" ]] || [[ "$fs_type" == "xfs" ]] || [[ "$fs_type" == "btrfs" ]]; then
            if [[ -b "$device" ]]; then
                local rotational=$(cat "/sys/block/$(basename ${device%[0-9]*})/queue/rotational" 2>/dev/null || echo "1")
                if [[ "$rotational" == "0" ]]; then
                    drive_type="SSD"
                    drive_description="Solid State Drive"
                else
                    drive_type="HDD"
                    drive_description="Traditional Hard Drive"
                fi
            else
                drive_type="Storage"
                drive_description="Storage device"
            fi
        elif [[ "$fs_type" == "ntfs" ]]; then
            drive_type="NTFS"
            drive_description="Windows NTFS drive"
        elif [[ "$fs_type" == "vfat" ]] || [[ "$fs_type" == "exfat" ]]; then
            drive_type="FAT/ExFAT"
            drive_description="Cross-platform storage"
        elif [[ "$fs_type" == "zfs" ]]; then
            drive_type="ZFS"
            drive_description="ZFS filesystem"
        fi
        
        # Skip root filesystem unless it's clearly a separate data drive
        if [[ "$mount_point" == "/" ]]; then
            drive_description="System root drive"
        fi
        
        discovered_drives+=("$mount_point")
        drive_details+=("$device|$mount_point|$fs_type|$drive_type|$drive_description|$size_info")
        
    done < <(mount | grep -v -E '^(sysfs|proc|udev|devpts|tmpfs) ')
    
    # Display discovered drives
    print "${COLOR_GREEN}Discovered Storage Devices:${COLOR_RESET}\n"
    
    local index=1
    for detail in "${drive_details[@]}"; do
        IFS='|' read -r device mount_point fs_type drive_type drive_description size_info <<< "$detail"
        
        # Check if drive is currently in storage pool
        local status_icon="${COLOR_BLUE}○${COLOR_RESET}"  # Available
        local status_text="Available"
        
        if [[ -f "${PROJECT_ROOT}/config/storage.conf" ]] && grep -Fxq "$mount_point" "${PROJECT_ROOT}/config/storage.conf" 2>/dev/null; then
            status_icon="${COLOR_GREEN}●${COLOR_RESET}"  # In use
            status_text="In Storage Pool"
        fi
        
        printf "%s [%2d] %-20s %s\n" "$status_icon" "$index" "$mount_point" "$drive_type"
        printf "     Device: %s\n" "$device"
        printf "     Type: %s (%s)\n" "$drive_description" "$fs_type"
        printf "     Size: %s\n" "$size_info"
        printf "     Status: %s\n\n" "$status_text"
        
        ((index++))
    done
    
    print "${COLOR_YELLOW}Legend:${COLOR_RESET}"
    print "  ${COLOR_GREEN}●${COLOR_RESET} Currently in storage pool"
    print "  ${COLOR_BLUE}○${COLOR_RESET} Available for storage pool"
    print ""
    print "${COLOR_BLUE}Next Steps:${COLOR_RESET}"
    print "  • Run ${COLOR_GREEN}usenet storage select${COLOR_RESET} for interactive drive selection"
    print "  • Run ${COLOR_GREEN}usenet storage add <path>${COLOR_RESET} to add individual drives"
    print "  • Run ${COLOR_GREEN}usenet storage apply${COLOR_RESET} to restart services with new configuration"
    
    return 0
}

#=============================================================================
# Function: interactive_drive_selection
# Description: Interactive TUI for selecting drives to include in storage pool
#
# Arguments:
#   None
#
# Returns:
#   0 - Selection completed
#   1 - User cancelled or error
#=============================================================================
interactive_drive_selection() {
    info "Interactive Drive Selection"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get all available drives
    local available_drives=()
    local drive_info=()
    local selected_drives=()
    
    # Parse mounted drives
    while IFS= read -r line; do
        local device=$(echo "$line" | awk '{print $1}')
        local mount_point=$(echo "$line" | awk '{print $3}')
        local fs_type=$(echo "$line" | awk '{print $5}')
        
        # Skip system mounts
        [[ "$mount_point" =~ ^/(proc|sys|dev|run|tmp|boot/efi|snap) ]] && continue
        [[ "$fs_type" =~ ^(proc|sysfs|devtmpfs|tmpfs|securityfs|cgroup|pstore|bpf|tracefs|debugfs|mqueue|hugetlbfs|fusectl|configfs|squashfs) ]] && continue
        [[ "$device" =~ ^(udev|tmpfs|none|/dev/loop) ]] && continue
        
        available_drives+=("$mount_point")
        
        # Get size and type info
        local size_info=$(df -h "$mount_point" 2>/dev/null | tail -1 | awk '{print $2}' || echo "Unknown")
        local drive_type="Storage"
        
        if [[ "$device" =~ nvme ]]; then
            drive_type="NVMe"
        elif [[ -b "$device" ]]; then
            local rotational=$(cat "/sys/block/$(basename ${device%[0-9]*})/queue/rotational" 2>/dev/null || echo "1")
            if [[ "$rotational" == "0" ]]; then
                drive_type="SSD"
            else
                drive_type="HDD"
            fi
        fi
        
        drive_info+=("$mount_point|$device|$drive_type|$size_info")
        
        # Check if already selected
        if [[ -f "${PROJECT_ROOT}/config/storage.conf" ]] && grep -Fxq "$mount_point" "${PROJECT_ROOT}/config/storage.conf" 2>/dev/null; then
            selected_drives+=("$mount_point")
        fi
        
    done < <(mount | grep -v -E '^(sysfs|proc|udev|devpts|tmpfs) ')
    
    if [[ ${#available_drives[@]} -eq 0 ]]; then
        warning "No suitable drives found for storage pool"
        return 1
    fi
    
    # Display selection interface
    print "${COLOR_GREEN}Select drives to include in media storage pool:${COLOR_RESET}"
    print "${COLOR_BLUE}These drives will be accessible to all media services (Sonarr, Radarr, Jellyfin, etc.)${COLOR_RESET}\n"
    
    local changed=false
    
    while true; do
        # Clear screen and show current selection
        print "\033[H\033[2J"  # Clear screen
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print "🗄️  ${COLOR_GREEN}USENET MEDIA STACK - DRIVE SELECTION${COLOR_RESET}"
        print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        print ""
        print "${COLOR_YELLOW}Select drives for your media storage pool:${COLOR_RESET}"
        print "${COLOR_BLUE}All selected drives will be accessible to Sonarr, Radarr, Jellyfin, Tdarr, etc.${COLOR_RESET}"
        print ""
        
        local index=1
        for info in "${drive_info[@]}"; do
            IFS='|' read -r mount_point device drive_type size_info <<< "$info"
            
            local status_icon="${COLOR_RED}[ ]${COLOR_RESET}"
            if [[ " ${selected_drives[@]} " =~ " $mount_point " ]]; then
                status_icon="${COLOR_GREEN}[✓]${COLOR_RESET}"
            fi
            
            printf "%s [%d] %-20s %s (%s) - %s\n" "$status_icon" "$index" "$mount_point" "$drive_type" "$device" "$size_info"
            ((index++))
        done
        
        print ""
        print "${COLOR_YELLOW}Commands:${COLOR_RESET}"
        print "  1-${#available_drives[@]}  Toggle drive selection"
        print "  a     Select all drives"
        print "  n     Select none"
        print "  s     Save and apply configuration"
        print "  q     Quit without saving"
        print ""
        print -n "Choice: "
        
        read -r choice
        
        case "$choice" in
            [1-9]*) 
                if [[ "$choice" -le ${#available_drives[@]} ]]; then
                    local drive_to_toggle="${available_drives[$((choice-1))]}"
                    if [[ " ${selected_drives[@]} " =~ " $drive_to_toggle " ]]; then
                        # Remove from selection
                        selected_drives=("${selected_drives[@]/$drive_to_toggle}")
                    else
                        # Add to selection
                        selected_drives+=("$drive_to_toggle")
                    fi
                    changed=true
                fi
                ;;
            a|A)
                selected_drives=("${available_drives[@]}")
                changed=true
                ;;
            n|N)
                selected_drives=()
                changed=true
                ;;
            s|S)
                if [[ ${#selected_drives[@]} -eq 0 ]]; then
                    warning "No drives selected. Storage pool will be empty."
                    if ! confirm "Continue anyway?"; then
                        continue
                    fi
                fi
                
                # Save configuration
                local config_file="${PROJECT_ROOT}/config/storage.conf"
                local config_dir="${PROJECT_ROOT}/config"
                
                [[ ! -d "$config_dir" ]] && mkdir -p "$config_dir"
                
                cat > "$config_file" <<EOF
# Usenet Media Stack Storage Configuration
# Auto-generated by interactive drive selection
# Created: $(date)
#
# Selected drives for media storage pool:
$(for drive in "${selected_drives[@]}"; do echo "$drive"; done)
EOF
                
                success "Storage configuration saved with ${#selected_drives[@]} drives"
                
                # Update Docker Compose configuration
                update_compose_mounts
                
                print ""
                print "${COLOR_GREEN}Selected drives:${COLOR_RESET}"
                for drive in "${selected_drives[@]}"; do
                    print "  ✓ $drive"
                done
                
                print ""
                if confirm "Apply changes and restart services now?"; then
                    apply_storage_changes
                fi
                
                return 0
                ;;
            q|Q)
                if [[ "$changed" == "true" ]]; then
                    if ! confirm "Discard changes and quit?"; then
                        continue
                    fi
                fi
                return 1
                ;;
        esac
    done
}

#=============================================================================
# Function: apply_storage_changes
# Description: Apply storage configuration changes and restart services
#
# Arguments:
#   None
#
# Returns:
#   0 - Changes applied successfully
#   1 - Error applying changes
#=============================================================================
apply_storage_changes() {
    info "Applying storage configuration changes..."
    
    # Update compose configuration
    if ! update_compose_mounts; then
        error "Failed to update Docker Compose configuration"
        return 1
    fi
    
    # Check if Docker services are running
    if docker ps --format "table {{.Names}}" | grep -q "sonarr\|radarr\|jellyfin"; then
        info "Restarting Docker services with new storage configuration..."
        
        # Use the main manage script to restart services
        if [[ -x "${PROJECT_ROOT}/usenet" ]]; then
            cd "$PROJECT_ROOT" && ./usenet restart
        else
            # Fallback to direct docker-compose
            if [[ -f "${PROJECT_ROOT}/docker-compose.storage.yml" ]]; then
                docker-compose -f "${PROJECT_ROOT}/docker-compose.yml" -f "${PROJECT_ROOT}/docker-compose.storage.yml" up -d
            else
                docker-compose -f "${PROJECT_ROOT}/docker-compose.yml" up -d
            fi
        fi
        
        success "Services restarted with new storage configuration"
    else
        info "No running services detected. Configuration ready for next startup."
    fi
    
    return 0
}

##############################################################################
#                               MAIN FUNCTION                               #
##############################################################################

#=============================================================================
# Function: main
# Description: Main entry point for storage management
#
# Arguments:
#   $@ - All command line arguments
#
# Returns:
#   Exit code from the executed action
#=============================================================================
main() {
    local action="${1:-help}"
    shift || true
    
    case "$action" in
        status)
            show_storage_status
            ;;
        discover)
            discover_all_drives
            ;;
        select)
            interactive_drive_selection
            ;;
        add)
            add_storage_drive "$@"
            ;;
        remove)
            remove_storage_drive "$@"
            ;;
        apply)
            apply_storage_changes
            ;;
        health)
            check_storage_health
            ;;
        balance)
            info "Storage balancing not yet implemented"
            return 1
            ;;
        mount|unmount)
            info "Mount/unmount operations not yet implemented"
            return 1
            ;;
        help|--help|-h)
            show_storage_help
            ;;
        *)
            error "Unknown storage action: $action"
            show_storage_help
            return 1
            ;;
    esac
}

# Run if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80: