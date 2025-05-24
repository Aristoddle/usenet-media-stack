#!/usr/bin/env zsh
##############################################################################
# File: ./lib/storage-example.zsh
# Project: Usenet Media Stack
# Description: JBOD storage management and drive pooling functions
# Author: Joseph Lanzone <j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# This module handles all storage-related operations for the media stack,
# including JBOD (Just a Bunch Of Disks) management, drive addition/removal,
# capacity monitoring, and intelligent media distribution across drives.
#
# The system supports unlimited drive expansion without RAID, making it
# perfect for home media servers where drives are added over time.
##############################################################################

##############################################################################
#                              DEPENDENCIES                                  #
##############################################################################

# Ensure we have required modules
source "${0:A:h}/platform.zsh" || {
    print -u2 "ERROR: Cannot load platform.zsh"
    exit 1
}

##############################################################################
#                               CONSTANTS                                    #
##############################################################################

# Storage paths - all relative to project root
readonly STORAGE_CONFIG="${PROJECT_ROOT}/config/storage.json"
readonly MEDIA_ROOT="/media"
readonly DEFAULT_CATEGORIES=(tv movies music books comics downloads)

# Minimum free space to maintain on each drive (GB)
readonly MIN_FREE_SPACE_GB=50

# File size thresholds for intelligent placement
readonly SMALL_FILE_MB=100
readonly LARGE_FILE_GB=10

##############################################################################
#                          STORAGE DETECTION                                 #
##############################################################################

#=============================================================================
# Function: detect_drives
# Description: Detect all available drives and their mount points
#
# This function scans the system for mounted drives, excluding system
# partitions and virtual filesystems. It returns a list of potential
# storage locations suitable for media storage.
#
# Arguments:
#   None
#
# Returns:
#   0 - Success (drives found)
#   1 - No suitable drives found
#
# Output:
#   Prints drive information to stdout in format:
#   <mount_point>|<total_gb>|<free_gb>|<used_percent>
#
# Example:
#   while IFS='|' read -r mount total free used; do
#       echo "Drive: $mount - ${free}GB free"
#   done < <(detect_drives)
#=============================================================================
detect_drives() {
    local platform=$(detect_platform)
    local min_size_gb=100  # Ignore drives smaller than this
    
    # Platform-specific mount detection
    case "$platform" in
        linux|wsl)
            # Use findmnt for reliable mount detection
            findmnt -rno TARGET,SIZE,AVAIL,USE% -t ext4,xfs,btrfs,ntfs | \
            while IFS=' ' read -r target size avail use; do
                # Convert sizes to GB
                local size_gb=$(numfmt --from=iec --to-unit=1G "$size" 2>/dev/null || echo 0)
                local avail_gb=$(numfmt --from=iec --to-unit=1G "$avail" 2>/dev/null || echo 0)
                
                # Skip small drives and system mounts
                if (( size_gb >= min_size_gb )) && \
                   [[ ! "$target" =~ ^/(sys|proc|dev|run|boot|var|tmp) ]]; then
                    echo "${target}|${size_gb}|${avail_gb}|${use}"
                fi
            done
            ;;
            
        macos)
            # macOS uses different tools
            df -g | awk 'NR>1 && $2 >= 100 && $9 !~ /^\/System/ {
                gsub(/%/, "", $5)
                print $9 "|" $2 "|" $4 "|" $5
            }'
            ;;
            
        *)
            print -u2 "WARNING: Unsupported platform for drive detection"
            return 1
            ;;
    esac
}

##############################################################################
#                           DRIVE MANAGEMENT                                 #
##############################################################################

#=============================================================================
# Function: add_storage_drive
# Description: Add a new drive to the media storage pool
#
# This function adds a drive to the JBOD pool, creating the necessary
# directory structure and updating the configuration. It ensures the drive
# is suitable for media storage and has sufficient free space.
#
# Arguments:
#   $1 - mount_path (required)
#        Mount point of the drive to add (e.g., /mnt/disk2)
#   
#   $2 - label (optional)
#        Human-readable label for the drive
#
# Returns:
#   0 - Drive added successfully
#   1 - Invalid mount point
#   2 - Insufficient space
#   3 - Already in pool
#   4 - Write permission denied
#
# Side Effects:
#   - Creates media directories on the drive
#   - Updates storage configuration file
#   - Restarts relevant Docker containers
#
# Example:
#   if add_storage_drive "/mnt/8tb-wd" "Media Drive 2"; then
#       echo "Drive added to pool"
#   fi
#=============================================================================
add_storage_drive() {
    local mount_path="${1:?ERROR: Mount path required}"
    local label="${2:-$(basename "$mount_path")}"
    
    # Validate mount point exists and is mounted
    if [[ ! -d "$mount_path" ]]; then
        print -u2 "ERROR: Mount point does not exist: $mount_path"
        return 1
    fi
    
    if ! mountpoint -q "$mount_path" 2>/dev/null; then
        print -u2 "ERROR: $mount_path is not a mount point"
        return 1
    fi
    
    # Check available space
    local avail_gb=$(df -BG "$mount_path" | awk 'NR==2 {gsub(/G/, "", $4); print $4}')
    if (( avail_gb < MIN_FREE_SPACE_GB )); then
        print -u2 "ERROR: Insufficient space: ${avail_gb}GB (need ${MIN_FREE_SPACE_GB}GB)"
        return 2
    fi
    
    # Check if already in pool
    if grep -q "\"$mount_path\"" "$STORAGE_CONFIG" 2>/dev/null; then
        print -u2 "ERROR: Drive already in storage pool"
        return 3
    fi
    
    # Test write permissions
    local test_file="${mount_path}/.storage_test_$$"
    if ! touch "$test_file" 2>/dev/null; then
        print -u2 "ERROR: Cannot write to $mount_path"
        return 4
    fi
    rm -f "$test_file"
    
    # Create media directory structure
    print "Creating media directories..."
    local category
    for category in "${DEFAULT_CATEGORIES[@]}"; do
        local dir="${mount_path}/media/${category}"
        if mkdir -p "$dir"; then
            print "  ✓ Created $dir"
        else
            print -u2 "  ✗ Failed to create $dir"
        fi
    done
    
    # Update configuration
    print "Updating storage configuration..."
    update_storage_config "$mount_path" "$label" "$avail_gb"
    
    # Restart affected services
    print "Restarting services..."
    restart_media_services
    
    print "\n✅ Successfully added drive to pool:"
    print "   Path: $mount_path"
    print "   Label: $label"
    print "   Available: ${avail_gb}GB"
    
    return 0
}

##############################################################################
#                        CAPACITY MANAGEMENT                                 #
##############################################################################

#=============================================================================
# Function: get_storage_status
# Description: Display current storage pool status and statistics
#
# Shows a comprehensive overview of all drives in the pool, including
# usage statistics, health status, and content distribution.
#
# Arguments:
#   $1 - format (optional, default: human)
#        Output format: human, json, csv
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   Formatted storage information to stdout
#
# Example:
#   get_storage_status
#   get_storage_status json | jq '.total_capacity_gb'
#=============================================================================
get_storage_status() {
    local format="${1:-human}"
    
    # Gather statistics
    local total_capacity_gb=0
    local total_used_gb=0
    local total_free_gb=0
    local drive_count=0
    
    # Read configuration and check each drive
    local drives=()
    while IFS='|' read -r path label capacity; do
        if [[ -d "$path" ]] && mountpoint -q "$path" 2>/dev/null; then
            local used_gb=$(df -BG "$path" | awk 'NR==2 {gsub(/G/, "", $3); print $3}')
            local free_gb=$(df -BG "$path" | awk 'NR==2 {gsub(/G/, "", $4); print $4}')
            
            drives+=("${path}|${label}|${used_gb}|${free_gb}")
            
            (( total_capacity_gb += used_gb + free_gb ))
            (( total_used_gb += used_gb ))
            (( total_free_gb += free_gb ))
            (( drive_count++ ))
        fi
    done < <(read_storage_config)
    
    # Format output based on requested format
    case "$format" in
        json)
            print -r "{
  \"drive_count\": $drive_count,
  \"total_capacity_gb\": $total_capacity_gb,
  \"total_used_gb\": $total_used_gb,
  \"total_free_gb\": $total_free_gb,
  \"usage_percent\": $(( total_used_gb * 100 / total_capacity_gb )),
  \"drives\": ["
            
            local first=true
            for drive in "${drives[@]}"; do
                IFS='|' read -r path label used free <<< "$drive"
                [[ "$first" == "true" ]] && first=false || print ","
                print -r "    {
      \"path\": \"$path\",
      \"label\": \"$label\",
      \"used_gb\": $used,
      \"free_gb\": $free,
      \"total_gb\": $(( used + free ))
    }"
            done
            
            print "  ]\n}"
            ;;
            
        human|*)
            print "╔════════════════════════════════════════════════════════════╗"
            print "║                   STORAGE POOL STATUS                      ║"
            print "╚════════════════════════════════════════════════════════════╝"
            print
            print "Total Capacity: ${total_capacity_gb}GB"
            print "Used: ${total_used_gb}GB ($(( total_used_gb * 100 / total_capacity_gb ))%)"
            print "Free: ${total_free_gb}GB"
            print "Drives: $drive_count"
            print
            print "Individual Drives:"
            print "─────────────────────────────────────────────────────────────"
            
            for drive in "${drives[@]}"; do
                IFS='|' read -r path label used free <<< "$drive"
                local total=$(( used + free ))
                local percent=$(( used * 100 / total ))
                
                printf "%-20s %8sGB / %8sGB (%3d%%) - %s\n" \
                    "$label" "$used" "$total" "$percent" "$path"
            done
            ;;
    esac
    
    return 0
}

##############################################################################
#                               HELPERS                                      #
##############################################################################

# Additional helper functions would go here...

# vim: set ts=4 sw=4 et tw=80: