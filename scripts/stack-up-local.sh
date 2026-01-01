#!/usr/bin/env bash
# stack-up-local.sh - Start local-only media services (no external pool required)
#
# This script starts services that work entirely from the internal NVMe:
# - Komga (comics)
# - Kavita (books/comics)
# - Audiobookshelf (audiobooks)
# - Komf (metadata)
# - Suwayomi (manga sources)
# - Infrastructure (Portainer, Netdata, Uptime-Kuma)
# - Request management (Prowlarr, Overseerr - for browsing, no downloads)
#
# Explicitly EXCLUDED (pool-dependent):
# - Sonarr, Radarr, Lidarr, Bazarr, Readarr, Whisparr (media management)
# - Tdarr, Tdarr-node (transcoding)
# - Plex (media server - partial pool dependency)
# - SABnzbd, Transmission (downloads go to pool)
# - MakeMKV (reads from pool)
#
# Usage:
#   stack-up-local.sh           # Start local services
#   stack-up-local.sh --status  # Show which services are running
#
# Exit codes:
#   0 - Success
#   1 - Partial failure
#   2 - Critical error

set -euo pipefail

STACK_ROOT="/var/home/deck/Documents/Code/media-automation/usenet-media-stack"
FAST8TB_MOUNT="/var/mnt/fast8tb"
STATE_DIR="/tmp/media-stack"

# ANSI colors (only if stdout is a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

log() { echo -e "${BLUE}[stack-local]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# =============================================================================
# SERVICE DEFINITIONS
# =============================================================================

# Services that work without the pool (internal NVMe only)
LOCAL_SERVICES=(
    # Infrastructure (always needed)
    "portainer"
    "netdata"
    "uptime-kuma"
    # Indexer/request (config-only, useful for browsing)
    "prowlarr"
    "overseerr"
    # Book/comics readers (local storage on fast8tb)
    "komga"
    "kavita"
    "komf"
    "audiobookshelf"
    "suwayomi"
)

# Services that REQUIRE the pool (explicitly excluded)
POOL_SERVICES=(
    "sonarr"
    "radarr"
    "lidarr"
    "bazarr"
    "readarr"
    "whisparr"
    "mylar"
    "tdarr"
    "tdarr-node"
    "plex"
    "tautulli"
    "stash"
    "sabnzbd"
    "transmission"
    "aria2"
    "makemkv"
    "samba"
    "recyclarr"
)

# =============================================================================
# CHECKS
# =============================================================================

check_docker() {
    if ! command -v docker &>/dev/null; then
        error "Docker not found in PATH"
        return 1
    fi
    if ! docker ps &>/dev/null 2>&1; then
        if ! sudo docker ps &>/dev/null 2>&1; then
            error "Cannot access Docker daemon"
            return 1
        fi
    fi
    return 0
}

check_fast8tb() {
    if mountpoint -q "$FAST8TB_MOUNT" 2>/dev/null; then
        local nvme_free
        nvme_free=$(df -h "$FAST8TB_MOUNT" 2>/dev/null | tail -1 | awk '{print $4}')
        success "Internal NVMe: $FAST8TB_MOUNT ($nvme_free free)"
        return 0
    else
        error "Internal NVMe not mounted at $FAST8TB_MOUNT"
        return 1
    fi
}

# Check if pool happens to be available (bonus)
check_pool_available() {
    if mountpoint -q "/var/mnt/pool" 2>/dev/null; then
        return 0
    fi
    return 1
}

# =============================================================================
# SERVICE MANAGEMENT
# =============================================================================

start_local_services() {
    log "Starting local-only services..."
    echo ""

    cd "$STACK_ROOT"

    # Record stack mode
    echo "local" > "$STATE_DIR/stack-mode"
    date +%s > "$STATE_DIR/stack-started"

    # Start only local services
    if sudo -E docker compose up -d "${LOCAL_SERVICES[@]}"; then
        echo ""
        success "Local services started!"
        echo ""

        # Verify services are running
        echo -e "${BOLD}Service Status:${NC}"
        for svc in "${LOCAL_SERVICES[@]}"; do
            local status
            status=$(sudo docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "not found")
            if [[ "$status" == "running" ]]; then
                echo -e "  $svc: ${GREEN}running${NC}"
            else
                echo -e "  $svc: ${YELLOW}$status${NC}"
            fi
        done

        echo ""
        echo -e "${BOLD}Access Points:${NC}"
        echo "  Portainer:      http://localhost:9000"
        echo "  Komga:          http://localhost:8081"
        echo "  Kavita:         http://localhost:5000"
        echo "  Audiobookshelf: http://localhost:13378"
        echo "  Suwayomi:       http://localhost:4567"
        echo "  Komf:           http://localhost:8085"
        echo "  Prowlarr:       http://localhost:9696 (browse only)"
        echo "  Overseerr:      http://localhost:5055 (browse only)"

        echo ""
        echo -e "${YELLOW}Note: Download/media management services are NOT running.${NC}"
        echo "Connect external drives and run stack-up-full.sh for full functionality."

        return 0
    else
        error "Failed to start local services"
        return 1
    fi
}

stop_pool_services() {
    log "Ensuring pool-dependent services are stopped..."

    local stopped=0
    for svc in "${POOL_SERVICES[@]}"; do
        if sudo docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${svc}$"; then
            sudo docker stop "$svc" >/dev/null 2>&1 && ((stopped++)) || true
        fi
    done

    if [[ $stopped -gt 0 ]]; then
        log "Stopped $stopped pool-dependent services"
    fi
}

show_status() {
    echo -e "${BOLD}=== Local Stack Status ===${NC}"
    echo ""

    # Current mode
    if [[ -f "$STATE_DIR/stack-mode" ]]; then
        local mode
        mode=$(cat "$STATE_DIR/stack-mode")
        echo -e "Stack mode: ${BOLD}$mode${NC}"
    else
        echo "Stack mode: unknown (not started via scripts)"
    fi

    echo ""
    echo -e "${BOLD}Local Services:${NC}"
    for svc in "${LOCAL_SERVICES[@]}"; do
        local status
        status=$(sudo docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "not found")
        if [[ "$status" == "running" ]]; then
            echo -e "  $svc: ${GREEN}running${NC}"
        elif [[ "$status" == "not found" ]]; then
            echo -e "  $svc: ${RED}not created${NC}"
        else
            echo -e "  $svc: ${YELLOW}$status${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}Pool Services (should be stopped in local mode):${NC}"
    local pool_running=0
    for svc in "${POOL_SERVICES[@]}"; do
        local status
        status=$(sudo docker inspect -f '{{.State.Status}}' "$svc" 2>/dev/null || echo "not found")
        if [[ "$status" == "running" ]]; then
            echo -e "  $svc: ${YELLOW}running (unexpected)${NC}"
            ((pool_running++))
        fi
    done

    if [[ $pool_running -eq 0 ]]; then
        echo "  (all stopped or not created)"
    else
        echo ""
        warn "$pool_running pool-dependent services are running without pool!"
        warn "This may cause errors. Run stack-down.sh and restart."
    fi

    # Check storage
    echo ""
    echo -e "${BOLD}Storage:${NC}"
    check_fast8tb || true

    if check_pool_available; then
        echo -e "  Pool: ${GREEN}available${NC} (could upgrade to full stack)"
    else
        echo -e "  Pool: ${YELLOW}not mounted${NC}"
    fi
}

# =============================================================================
# MAIN
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: stack-up-local.sh [OPTIONS]

Start local-only media services that work without the external drive pool.

Services Started:
  - Komga (comics reader)
  - Kavita (books/comics reader)
  - Audiobookshelf (audiobooks)
  - Komf (metadata fetcher)
  - Suwayomi (manga sources)
  - Portainer, Netdata, Uptime-Kuma (infrastructure)
  - Prowlarr, Overseerr (browse-only, no downloads)

Services NOT Started:
  - *arr apps (Sonarr, Radarr, etc.) - need pool for media
  - Tdarr - needs pool for transcoding
  - Plex - needs pool for christmas directories
  - Download clients - downloads go to pool

Options:
  --status    Show current service status
  --upgrade   If pool available, upgrade to full stack
  -h, --help  Show this help message

Examples:
  stack-up-local.sh          # Start local services
  stack-up-local.sh --status # Check what's running
EOF
}

main() {
    local show_status_only=false
    local upgrade=false
    local quiet=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --status)
                show_status_only=true
                shift
                ;;
            --upgrade)
                upgrade=true
                shift
                ;;
            --quiet|-q)
                quiet=true
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

    # In quiet mode, suppress interactive prompts
    if [[ "$quiet" == "true" ]]; then
        export MEDIA_STACK_QUIET=1
    fi

    echo -e "${BOLD}=== Media Stack - Local Mode ===${NC}"
    echo ""

    if ! check_docker; then
        exit 2
    fi

    if [[ "$show_status_only" == "true" ]]; then
        show_status
        exit 0
    fi

    # Check if pool is available (offer upgrade - but not in quiet mode)
    if check_pool_available && [[ "$quiet" != "true" ]]; then
        echo -e "${GREEN}Notice: External pool IS available!${NC}"
        echo ""

        if [[ "$upgrade" == "true" ]]; then
            log "Upgrading to full stack..."
            exec "$STACK_ROOT/scripts/stack-up-full.sh"
        fi

        echo "You could run the full stack instead."
        echo "  1) Start local stack anyway"
        echo "  2) Upgrade to full stack"
        echo ""

        read -r -p "Choice [1-2]: " choice

        if [[ "$choice" == "2" ]]; then
            exec "$STACK_ROOT/scripts/stack-up-full.sh"
        fi
    fi

    # Verify NVMe
    if ! check_fast8tb; then
        error "Internal NVMe unavailable - cannot proceed"
        exit 2
    fi

    echo ""

    # Stop any pool services that might be running in a bad state
    stop_pool_services

    # Start local services
    start_local_services
}

main "$@"
