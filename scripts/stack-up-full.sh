#!/usr/bin/env bash
# stack-up-full.sh - Start the complete media stack (requires external pool)
#
# This script performs safety checks before starting pool-dependent services:
# 1. Checks if external drives are attached (block devices exist)
# 2. Checks if drives are mounted
# 3. Checks if MergerFS pool is mounted
# 4. Offers to start local-only stack if pool unavailable
#
# Usage:
#   stack-up-full.sh              # Interactive - prompts on failure
#   stack-up-full.sh --force      # Skip safety checks (dangerous)
#   stack-up-full.sh --local-on-fail  # Auto-fallback to local stack
#
# Exit codes:
#   0 - Success
#   1 - Pool not available, user declined local stack
#   2 - Critical error (Docker not available, etc)

set -euo pipefail

STACK_ROOT="/var/home/deck/Documents/Code/media-automation/usenet-media-stack"
POOL_MOUNT="/var/mnt/pool"
FAST8TB_MOUNT="/var/mnt/fast8tb"
STATE_DIR="/tmp/media-stack"

# External drive mount points (from mergerfs-pool.service)
EXTERNAL_MOUNTS=(
    "/var/mnt/Fast_4TB_1"
    "/var/mnt/Fast_4TB_2"
    "/var/mnt/Fast_4TB_3"
    "/var/mnt/Fast_4TB_4"
    "/var/mnt/Fast_4TB_5"
    "/var/mnt/Fast_8TB_1"
    "/var/mnt/Fast_8TB_2"
    "/var/mnt/Fast_8TB_3"
)

# ANSI colors (only if stdout is a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

log() { echo -e "${BLUE}[stack-up]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# =============================================================================
# SAFETY CHECKS
# =============================================================================

check_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker not found in PATH"
        return 1
    fi

    # Check if we can access Docker daemon
    if ! docker ps &>/dev/null 2>&1; then
        if ! sudo docker ps &>/dev/null 2>&1; then
            error "Cannot access Docker daemon (tried with and without sudo)"
            return 1
        fi
    fi
    return 0
}

# Check if external drive block devices exist (drives attached to USB/dock)
check_drives_attached() {
    local attached=0
    local total=${#EXTERNAL_MOUNTS[@]}
    local missing=()

    for mount_point in "${EXTERNAL_MOUNTS[@]}"; do
        # Extract drive label from mount point (e.g., Fast_4TB_1)
        local label
        label=$(basename "$mount_point")

        # Check if block device exists by looking for it in /dev/disk/by-label
        if [[ -e "/dev/disk/by-label/$label" ]]; then
            ((attached++))
        else
            missing+=("$label")
        fi
    done

    if [[ $attached -eq 0 ]]; then
        warn "No external drives detected (0/$total)"
        warn "Drive bay may be disconnected or powered off"
        return 1
    elif [[ $attached -lt $total ]]; then
        warn "Partial drive attachment: $attached/$total drives detected"
        warn "Missing: ${missing[*]}"
        return 2
    else
        success "All $total external drives attached"
        return 0
    fi
}

# Check if external drives are mounted
check_drives_mounted() {
    local mounted=0
    local total=${#EXTERNAL_MOUNTS[@]}
    local unmounted=()

    for mount_point in "${EXTERNAL_MOUNTS[@]}"; do
        if mountpoint -q "$mount_point" 2>/dev/null; then
            ((mounted++))
        else
            unmounted+=("$(basename "$mount_point")")
        fi
    done

    if [[ $mounted -eq 0 ]]; then
        warn "No external drives mounted (0/$total)"
        return 1
    elif [[ $mounted -lt $total ]]; then
        warn "Partial mount: $mounted/$total drives mounted"
        warn "Unmounted: ${unmounted[*]}"
        return 2
    else
        success "All $total external drives mounted"
        return 0
    fi
}

# Check if MergerFS pool is mounted
check_pool_mounted() {
    if mountpoint -q "$POOL_MOUNT" 2>/dev/null; then
        # Verify it's actually MergerFS
        if mount | grep -q "mergerfs.*$POOL_MOUNT"; then
            local pool_size
            pool_size=$(df -h "$POOL_MOUNT" 2>/dev/null | tail -1 | awk '{print $2}')
            success "MergerFS pool mounted at $POOL_MOUNT ($pool_size total)"
            return 0
        else
            warn "$POOL_MOUNT is mounted but NOT as MergerFS"
            return 1
        fi
    else
        warn "MergerFS pool not mounted at $POOL_MOUNT"
        return 1
    fi
}

# Check internal NVMe
check_fast8tb() {
    if mountpoint -q "$FAST8TB_MOUNT" 2>/dev/null; then
        local nvme_free
        nvme_free=$(df -h "$FAST8TB_MOUNT" 2>/dev/null | tail -1 | awk '{print $4}')
        success "Internal NVMe mounted at $FAST8TB_MOUNT ($nvme_free free)"
        return 0
    else
        error "Internal NVMe not mounted at $FAST8TB_MOUNT - critical failure!"
        return 1
    fi
}

# Attempt to mount the MergerFS pool via systemd
try_mount_pool() {
    log "Attempting to start mergerfs-pool.service..."

    if sudo systemctl start mergerfs-pool.service; then
        sleep 3
        if check_pool_mounted; then
            success "Successfully mounted MergerFS pool"
            return 0
        fi
    fi

    error "Failed to mount MergerFS pool"
    return 1
}

# Run all safety checks
run_safety_checks() {
    local issues=0

    echo -e "${BOLD}=== Storage Safety Checks ===${NC}"
    echo ""

    # Check internal NVMe (always required)
    if ! check_fast8tb; then
        error "Internal NVMe unavailable - cannot proceed"
        return 2
    fi

    echo ""

    # Check external drives
    local drives_status=0
    check_drives_attached || drives_status=$?

    echo ""

    # Check mounts
    local mount_status=0
    check_drives_mounted || mount_status=$?

    echo ""

    # Check MergerFS pool
    local pool_status=0
    check_pool_mounted || pool_status=$?

    echo ""

    # Analyze results
    if [[ $pool_status -eq 0 ]]; then
        success "All checks passed - ready for full stack"
        return 0
    elif [[ $drives_status -ne 0 ]]; then
        warn "External drives not attached"
        warn "This typically means the USB drive bay is disconnected"
        warn "Connect the drive bay and retry, or use stack-up-local.sh"
        return 1
    elif [[ $mount_status -ne 0 && $drives_status -eq 0 ]]; then
        warn "Drives attached but not mounted"
        warn "Attempting auto-mount via systemd..."
        echo ""
        if try_mount_pool; then
            return 0
        fi
        return 1
    else
        warn "Pool not available"
        return 1
    fi
}

# =============================================================================
# SERVICE MANAGEMENT
# =============================================================================

# Full stack services (all services)
FULL_STACK_SERVICES=(
    # Infrastructure (always first)
    "portainer"
    "netdata"
    "uptime-kuma"
    # Indexers/request management
    "prowlarr"
    "overseerr"
    "recyclarr"
    # Download clients
    "sabnzbd"
    "transmission"
    "aria2"
    # *arr apps (pool-dependent)
    "sonarr"
    "radarr"
    "lidarr"
    "bazarr"
    "readarr"
    "whisparr"
    "mylar"
    # Media servers
    "plex"
    "tautulli"
    "stash"
    # Transcoding
    "tdarr"
    "tdarr-node"
    "makemkv"
    # Book readers (local storage)
    "komga"
    "kavita"
    "komf"
    "audiobookshelf"
    "suwayomi"
    # Network shares
    "samba"
)

start_full_stack() {
    log "Starting full media stack..."
    echo ""

    cd "$STACK_ROOT"

    # Record stack mode
    echo "full" > "$STATE_DIR/stack-mode"
    date +%s > "$STATE_DIR/stack-started"

    # Use docker compose with env file
    if sudo -E docker compose up -d; then
        echo ""
        success "Full stack started successfully!"
        echo ""
        echo -e "${BOLD}Services Status:${NC}"
        sudo docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | head -30

        echo ""
        echo -e "${BOLD}Access Points:${NC}"
        echo "  Portainer:      http://localhost:9000"
        echo "  Prowlarr:       http://localhost:9696"
        echo "  Sonarr:         http://localhost:8989"
        echo "  Radarr:         http://localhost:7878"
        echo "  Plex:           http://localhost:32400/web"
        echo "  Tdarr:          http://localhost:8265"
        echo "  Komga:          http://localhost:8081"
        echo "  Kavita:         http://localhost:5000"
        echo "  Audiobookshelf: http://localhost:13378"
        return 0
    else
        error "Failed to start stack"
        return 1
    fi
}

# =============================================================================
# MAIN
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: stack-up-full.sh [OPTIONS]

Start the complete usenet media stack with external pool storage.

Options:
  --force           Skip safety checks (dangerous - may cause container errors)
  --local-on-fail   Automatically fall back to local stack if pool unavailable
  --check-only      Run safety checks without starting services
  -h, --help        Show this help message

Safety Checks:
  1. Docker daemon accessibility
  2. Internal NVMe mount (/var/mnt/fast8tb)
  3. External drive attachment (USB dock detection)
  4. External drive mounts (/var/mnt/Fast_*)
  5. MergerFS pool mount (/var/mnt/pool)

Exit Codes:
  0 - Success
  1 - Pool unavailable, user declined local fallback
  2 - Critical failure (Docker unavailable, NVMe unmounted)

Examples:
  stack-up-full.sh                    # Interactive with safety checks
  stack-up-full.sh --local-on-fail    # Auto-fallback to local services
  stack-up-full.sh --check-only       # Just verify storage status
EOF
}

main() {
    local force=false
    local local_on_fail=false
    local check_only=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force)
                force=true
                shift
                ;;
            --local-on-fail)
                local_on_fail=true
                shift
                ;;
            --check-only)
                check_only=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 2
                ;;
        esac
    done

    echo -e "${BOLD}=== Media Stack - Full Boot ===${NC}"
    echo ""

    # Check Docker first
    if ! check_docker; then
        exit 2
    fi

    if [[ "$force" == "true" ]]; then
        warn "Skipping safety checks (--force specified)"
        echo ""
        start_full_stack
        exit $?
    fi

    # Run safety checks
    local check_result=0
    run_safety_checks || check_result=$?

    if [[ "$check_only" == "true" ]]; then
        exit $check_result
    fi

    echo ""

    if [[ $check_result -eq 0 ]]; then
        start_full_stack
        exit $?
    elif [[ $check_result -eq 2 ]]; then
        error "Critical failure - cannot proceed"
        exit 2
    else
        # Pool unavailable
        echo ""
        echo -e "${YELLOW}Pool storage is not available.${NC}"
        echo ""

        if [[ "$local_on_fail" == "true" ]]; then
            warn "Auto-fallback enabled: starting local stack only"
            exec "$STACK_ROOT/scripts/stack-up-local.sh"
        fi

        echo "Options:"
        echo "  1) Start LOCAL stack only (comics, books, audiobooks)"
        echo "  2) Retry after connecting external drives"
        echo "  3) Exit"
        echo ""

        read -r -p "Choice [1-3]: " choice

        case "$choice" in
            1)
                exec "$STACK_ROOT/scripts/stack-up-local.sh"
                ;;
            2)
                echo ""
                warn "Please connect external drive bay, then press Enter..."
                read -r
                exec "$0" "$@"
                ;;
            *)
                log "Exiting without starting services"
                exit 1
                ;;
        esac
    fi
}

main "$@"
