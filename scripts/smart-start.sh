#!/usr/bin/env bash
# smart-start.sh - Intelligent media stack startup based on available storage
# Detects which drives are mounted and starts appropriate services
#
# Usage: ./smart-start.sh [up|down|status]
#
# Profiles:
#   - core: Always runs (portainer, netdata, prowlarr, uptime-kuma)
#   - portable: Reading stack (audiobookshelf, kavita, komga, komf, suwayomi)
#   - full: Heavy media (plex, sonarr, radarr, tdarr, downloaders, etc)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_MAIN="$STACK_DIR/docker-compose.yml"
COMPOSE_READING="$STACK_DIR/docker-compose.reading.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =============================================================================
# DRIVE DETECTION
# =============================================================================

# Check if internal 8TB drive is mounted
check_fast8tb() {
    if mountpoint -q /var/mnt/fast8tb 2>/dev/null; then
        return 0
    fi
    return 1
}

# Check if mergerfs pool is mounted (external drive bays)
check_pool() {
    if mountpoint -q /var/mnt/pool 2>/dev/null; then
        return 0
    fi
    # Also check if mergerfs is in the mount list
    if mount | grep -q "mergerfs.*/var/mnt/pool"; then
        return 0
    fi
    return 1
}

# Check if individual pool drives are available (for pre-mergerfs detection)
check_pool_drives() {
    local pool_drives=0
    # Look for drives that would be part of the pool
    # These are typically labeled or in specific paths
    for drive in /var/mnt/bay1 /var/mnt/bay2 /var/mnt/bay3 /var/mnt/bay4; do
        if mountpoint -q "$drive" 2>/dev/null; then
            ((pool_drives++))
        fi
    done

    # Also check by label pattern if using labeled drives
    for label in pool-* POOL-*; do
        if ls /dev/disk/by-label/$label 2>/dev/null | head -1 >/dev/null; then
            ((pool_drives++))
        fi
    done

    echo "$pool_drives"
}

# Determine which profile to use
detect_profile() {
    local profile="core"  # Always start with core

    if check_fast8tb; then
        log_success "Internal 8TB drive mounted at /var/mnt/fast8tb"
        profile="core,portable"
    else
        log_warn "Internal 8TB drive NOT mounted - portable services unavailable"
    fi

    if check_pool; then
        log_success "MergerFS pool mounted at /var/mnt/pool"
        profile="core,portable,full"
    else
        local pool_drives
        pool_drives=$(check_pool_drives)
        if [[ "$pool_drives" -gt 0 ]]; then
            log_warn "Found $pool_drives pool drives but mergerfs not mounted"
            log_info "Run: sudo systemctl start mergerfs-pool.service"
        else
            log_info "External drive bays not connected - full stack unavailable"
        fi
    fi

    echo "$profile"
}

# =============================================================================
# DOCKER COMPOSE OPERATIONS
# =============================================================================

compose_up() {
    local profile
    profile=$(detect_profile)

    echo ""
    log_info "Starting media stack with profile: ${GREEN}$profile${NC}"
    echo ""

    cd "$STACK_DIR"

    # Always start the reading stack if internal drive is available
    if [[ "$profile" == *"portable"* ]] || [[ "$profile" == *"full"* ]]; then
        log_info "Starting reading stack (audiobookshelf, kavita, komga, etc)..."
        docker compose -f "$COMPOSE_READING" up -d --remove-orphans
    fi

    # Start full media stack only if pool is available
    if [[ "$profile" == *"full"* ]]; then
        log_info "Starting full media stack (plex, sonarr, radarr, tdarr, etc)..."
        docker compose -f "$COMPOSE_MAIN" up -d --remove-orphans
    else
        log_info "Pool not available - skipping heavy media services"
    fi

    echo ""
    log_success "Media stack started!"
    compose_status
}

compose_down() {
    log_info "Stopping media stack..."
    cd "$STACK_DIR"

    # Stop both stacks
    docker compose -f "$COMPOSE_MAIN" down --remove-orphans 2>/dev/null || true
    docker compose -f "$COMPOSE_READING" down --remove-orphans 2>/dev/null || true

    log_success "Media stack stopped"
}

compose_status() {
    echo ""
    log_info "=== Storage Status ==="

    if check_fast8tb; then
        local fast8tb_usage
        fast8tb_usage=$(df -h /var/mnt/fast8tb | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
        log_success "Internal 8TB: $fast8tb_usage"
    else
        log_warn "Internal 8TB: NOT MOUNTED"
    fi

    if check_pool; then
        local pool_usage
        pool_usage=$(df -h /var/mnt/pool | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')
        log_success "MergerFS Pool: $pool_usage"
    else
        log_warn "MergerFS Pool: NOT MOUNTED (external bays disconnected)"
    fi

    echo ""
    log_info "=== Running Containers ==="
    docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null | head -30 || true
}

compose_restart() {
    compose_down
    sleep 2
    compose_up
}

# =============================================================================
# MAIN
# =============================================================================

case "${1:-status}" in
    up|start)
        compose_up
        ;;
    down|stop)
        compose_down
        ;;
    restart)
        compose_restart
        ;;
    status|ps)
        compose_status
        ;;
    detect)
        detect_profile
        ;;
    *)
        echo "Usage: $0 {up|down|restart|status|detect}"
        echo ""
        echo "Commands:"
        echo "  up, start    Start services based on detected storage"
        echo "  down, stop   Stop all services"
        echo "  restart      Stop and start services"
        echo "  status, ps   Show storage and container status"
        echo "  detect       Just detect available storage profile"
        exit 1
        ;;
esac
