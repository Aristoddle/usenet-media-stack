#!/usr/bin/env bash
# pool-health-monitor.sh - Monitor mergerfs pool health and react to drive changes
#
# Purpose:
#   Detect external drive bay disconnection (hot-unplug) and gracefully
#   stop full-stack services before they encounter I/O errors or data corruption.
#
# Usage:
#   ./pool-health-monitor.sh [--daemon|--check|--status]
#
# Modes:
#   --daemon  Run continuously in background (for systemd)
#   --check   Single health check, exit with status code
#   --status  Show current pool and drive status
#
# Design philosophy:
#   - NEVER block gaming or other user activities
#   - Graceful degradation to portable mode on pool loss
#   - Fast detection (10s polling) to minimize I/O error window
#   - Log all events for post-mortem debugging

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"
STATE_DIR="/tmp/media-stack"
LOG_FILE="$STATE_DIR/pool-health.log"
POLL_INTERVAL=${POLL_INTERVAL:-10}  # Seconds between checks

# External drive labels (from stack-autostart.sh)
EXTERNAL_DRIVE_LABELS=(
    "Fast_4TB_1"
    "Fast_4TB_2"
    "Fast_4TB_3"
    "Fast_4TB_4"
    "Fast_4TB_5"
    "Fast_8TB_1"
    "Fast_8TB_2"
    "Fast_8TB_3"
)

# Minimum drives for pool to be considered healthy
MIN_DRIVES_HEALTHY=3

# Track previous state for change detection
PREV_POOL_STATE=""
PREV_DRIVE_COUNT=0

mkdir -p "$STATE_DIR"

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
    # Also log to systemd journal if running as service
    if [[ -n "${INVOCATION_ID:-}" ]]; then
        logger -t pool-health-monitor "$level: $*"
    fi
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }

# =============================================================================
# HEALTH CHECK FUNCTIONS
# =============================================================================

# Check if mergerfs pool is mounted and responding
check_pool_mounted() {
    if ! mountpoint -q /var/mnt/pool 2>/dev/null; then
        return 1
    fi

    # Verify pool is actually responsive (not stale/hung)
    # Use timeout to prevent hanging on I/O errors
    if ! timeout 5s ls /var/mnt/pool >/dev/null 2>&1; then
        return 2  # Mounted but not responsive
    fi

    return 0
}

# Count attached external drives
count_attached_drives() {
    local count=0
    for label in "${EXTERNAL_DRIVE_LABELS[@]}"; do
        if [[ -e "/dev/disk/by-label/$label" ]]; then
            ((count++)) || true
        fi
    done
    echo "$count"
}

# Count mounted external drives
count_mounted_drives() {
    local count=0
    for label in "${EXTERNAL_DRIVE_LABELS[@]}"; do
        local mount_point="/var/mnt/$label"
        if mountpoint -q "$mount_point" 2>/dev/null; then
            ((count++)) || true
        fi
    done
    echo "$count"
}

# Get list of attached drive labels
get_attached_drives() {
    local drives=()
    for label in "${EXTERNAL_DRIVE_LABELS[@]}"; do
        if [[ -e "/dev/disk/by-label/$label" ]]; then
            drives+=("$label")
        fi
    done
    echo "${drives[*]:-none}"
}

# =============================================================================
# REACTION FUNCTIONS
# =============================================================================

# Pause download clients to stop new writes (best-effort, don't block on failure)
pause_download_clients() {
    log_info "Pausing download clients to prevent new writes..."

    # SABnzbd - pause queue
    # API: http://localhost:8080/api?mode=pause&apikey=KEY
    local sab_api_key
    sab_api_key=$(grep -oP 'api_key\s*=\s*\K\S+' /var/mnt/fast8tb/config/sabnzbd/sabnzbd.ini 2>/dev/null || echo "")
    if [[ -n "$sab_api_key" ]]; then
        if curl -sf "http://localhost:8080/api?mode=pause&apikey=$sab_api_key" --max-time 5 >/dev/null 2>&1; then
            log_info "SABnzbd paused"
        else
            log_warn "SABnzbd pause failed (may not be running)"
        fi
    fi

    # Transmission - set speed limit to 0 (effectively pauses)
    # RPC: http://localhost:9091/transmission/rpc
    if curl -sf "http://localhost:9091/transmission/rpc" \
        -H "Content-Type: application/json" \
        -d '{"method":"session-set","arguments":{"speed-limit-down-enabled":true,"speed-limit-down":0,"speed-limit-up-enabled":true,"speed-limit-up":0}}' \
        --max-time 5 >/dev/null 2>&1; then
        log_info "Transmission paused"
    else
        log_warn "Transmission pause failed (may not be running)"
    fi

    # Tdarr - pause nodes (stop accepting new jobs)
    # Note: Tdarr doesn't have a simple pause API, but stopping the node containers
    # will prevent new transcodes from starting
    if docker stop tdarr-node --time 10 >/dev/null 2>&1; then
        log_info "Tdarr node stopped"
    fi
}

# Wait for active I/O to settle
wait_for_io_settle() {
    local max_wait=${1:-10}  # Default 10 seconds
    log_info "Waiting up to ${max_wait}s for I/O to settle..."

    # Sync filesystem buffers
    sync

    # Brief wait for in-flight operations
    local waited=0
    while [[ $waited -lt $max_wait ]]; do
        # Check if pool is still accessible (might already be gone)
        if ! timeout 2s ls /var/mnt/pool >/dev/null 2>&1; then
            log_warn "Pool already inaccessible, skipping I/O wait"
            break
        fi
        sleep 2
        ((waited+=2))
    done

    # Final sync attempt
    sync 2>/dev/null || true
}

# Stop full-stack services gracefully with drain
stop_full_stack() {
    log_warn "Stopping full stack services due to pool health issue..."

    # Record the event
    echo "pool-degraded" > "$STATE_DIR/stack-mode"
    date +%s > "$STATE_DIR/pool-degraded"

    # === GRACEFUL DRAIN PHASE ===
    # 1. Pause download clients to stop new writes
    pause_download_clients

    # 2. Wait for active I/O to settle (max 10s - don't wait too long, pool may be dying)
    wait_for_io_settle 10

    # === STOP PHASE ===
    cd "$STACK_ROOT"

    # 3. Stop containers with graceful timeout
    log_info "Stopping full stack containers..."
    if timeout 90s docker compose -f docker-compose.yml stop --timeout 30 2>&1 | tee -a "$LOG_FILE"; then
        log_info "Containers stopped gracefully"
    else
        log_warn "Graceful stop timed out, forcing..."
    fi

    # 4. Remove containers (faster since already stopped)
    if timeout 30s docker compose -f docker-compose.yml down --remove-orphans 2>&1 | tee -a "$LOG_FILE"; then
        log_info "Full stack stopped successfully"
    else
        log_error "Full stack stop failed - containers may need manual cleanup"
        # Force kill as last resort
        docker compose -f docker-compose.yml kill 2>/dev/null || true
    fi
}

# Notify user of pool state change (desktop notification if available)
notify_user() {
    local title="$1"
    local message="$2"

    # Try desktop notification
    if command -v notify-send &>/dev/null; then
        notify-send -u critical "$title" "$message" 2>/dev/null || true
    fi

    # Always log
    log_info "NOTIFICATION: $title - $message"
}

# =============================================================================
# MAIN MONITORING LOOP
# =============================================================================

do_health_check() {
    local pool_state="unknown"
    local attached mounted

    attached=$(count_attached_drives)
    mounted=$(count_mounted_drives)

    # Determine pool state
    if check_pool_mounted; then
        if [[ "$mounted" -ge "$MIN_DRIVES_HEALTHY" ]]; then
            pool_state="healthy"
        else
            pool_state="degraded"
        fi
    else
        local check_result=$?
        if [[ $check_result -eq 2 ]]; then
            pool_state="stale"  # Mounted but not responding
        else
            pool_state="unmounted"
        fi
    fi

    # Detect state changes
    if [[ "$pool_state" != "$PREV_POOL_STATE" ]]; then
        log_info "Pool state changed: $PREV_POOL_STATE -> $pool_state (drives: $mounted mounted, $attached attached)"

        case "$pool_state" in
            healthy)
                notify_user "Media Pool Healthy" "$mounted drives mounted, pool responsive"
                echo "$pool_state" > "$STATE_DIR/pool-state"
                ;;
            degraded)
                notify_user "Media Pool Degraded" "Only $mounted of $attached drives mounted"
                echo "$pool_state" > "$STATE_DIR/pool-state"
                ;;
            stale)
                notify_user "Media Pool Stale" "Pool mounted but not responding - stopping services"
                echo "$pool_state" > "$STATE_DIR/pool-state"
                stop_full_stack
                ;;
            unmounted)
                if [[ "$PREV_POOL_STATE" == "healthy" || "$PREV_POOL_STATE" == "degraded" ]]; then
                    notify_user "Media Pool Disconnected" "External drives removed - stopping full stack"
                    stop_full_stack
                fi
                echo "$pool_state" > "$STATE_DIR/pool-state"
                ;;
        esac

        PREV_POOL_STATE="$pool_state"
    fi

    # Detect drive count changes (even if state doesn't change)
    if [[ "$attached" -ne "$PREV_DRIVE_COUNT" ]]; then
        log_info "Drive count changed: $PREV_DRIVE_COUNT -> $attached ($(get_attached_drives))"
        PREV_DRIVE_COUNT="$attached"
    fi

    # Return appropriate exit code
    case "$pool_state" in
        healthy)  return 0 ;;
        degraded) return 1 ;;
        *)        return 2 ;;
    esac
}

show_status() {
    echo "=== Pool Health Status ==="
    echo ""

    local attached mounted
    attached=$(count_attached_drives)
    mounted=$(count_mounted_drives)

    echo "External Drives:"
    echo "  Attached: $attached"
    echo "  Mounted:  $mounted"
    echo "  Minimum for healthy: $MIN_DRIVES_HEALTHY"
    echo ""

    echo "Drive Details:"
    for label in "${EXTERNAL_DRIVE_LABELS[@]}"; do
        local status="not attached"
        if [[ -e "/dev/disk/by-label/$label" ]]; then
            if mountpoint -q "/var/mnt/$label" 2>/dev/null; then
                status="mounted at /var/mnt/$label"
            else
                status="attached but not mounted"
            fi
        fi
        printf "  %-15s %s\n" "$label:" "$status"
    done
    echo ""

    echo "MergerFS Pool:"
    if check_pool_mounted; then
        echo "  Status: MOUNTED and RESPONSIVE"
        df -h /var/mnt/pool 2>/dev/null | tail -1 | awk '{print "  Usage: " $3 "/" $2 " (" $5 " full)"}'
    else
        local check_result=$?
        if [[ $check_result -eq 2 ]]; then
            echo "  Status: MOUNTED but NOT RESPONSIVE (stale)"
        else
            echo "  Status: NOT MOUNTED"
        fi
    fi
    echo ""

    if [[ -f "$STATE_DIR/pool-state" ]]; then
        echo "Last recorded state: $(cat "$STATE_DIR/pool-state")"
    fi
    if [[ -f "$STATE_DIR/pool-degraded" ]]; then
        echo "Last degradation: $(date -d "@$(cat "$STATE_DIR/pool-degraded")" 2>/dev/null || cat "$STATE_DIR/pool-degraded")"
    fi
}

run_daemon() {
    log_info "Starting pool health monitor daemon (poll interval: ${POLL_INTERVAL}s)"

    # Initialize state
    PREV_POOL_STATE="unknown"
    PREV_DRIVE_COUNT=$(count_attached_drives)

    # Initial check
    do_health_check || true

    # Main loop
    while true; do
        sleep "$POLL_INTERVAL"
        do_health_check || true
    done
}

# =============================================================================
# MAIN
# =============================================================================

case "${1:---status}" in
    --daemon|-d)
        run_daemon
        ;;
    --check|-c)
        do_health_check
        exit $?
        ;;
    --status|-s|*)
        show_status
        ;;
esac
