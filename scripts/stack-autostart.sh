#!/usr/bin/env bash
# stack-autostart.sh - Automatic boot mode detection for media stack
#
# Called by systemd at boot to:
# 1. Detect if external drive bays are attached
# 2. Start appropriate stack mode (full vs local)
# 3. Log decision for debugging
#
# Design philosophy:
# - NEVER block boot or gaming
# - Default to local mode if uncertain
# - Video/transcode tools only start with explicit full mode
# - Fast, non-interactive, systemd-friendly

set -euo pipefail

STACK_ROOT="/var/home/deck/Documents/Code/media-automation/usenet-media-stack"
LOG_FILE="/tmp/media-stack/autostart.log"
STATE_DIR="/tmp/media-stack"

# External drive labels (from your mergerfs setup)
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

# Minimum drives required for "full mode" (at least one bay)
MIN_DRIVES_FOR_FULL=3

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Logging function (also writes to journal via stdout)
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

# =============================================================================
# DETECTION FUNCTIONS
# =============================================================================

# Check if Docker daemon is accessible (with retry for boot race condition)
check_docker() {
    if ! command -v docker &>/dev/null; then
        log "ERROR: Docker not found"
        return 1
    fi

    local max_attempts=5
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        # Try without sudo first (rootless Docker)
        if docker ps &>/dev/null 2>&1; then
            [[ $attempt -gt 1 ]] && log "Docker ready after $attempt attempts"
            return 0
        fi

        # Try with sudo
        if sudo docker ps &>/dev/null 2>&1; then
            [[ $attempt -gt 1 ]] && log "Docker ready after $attempt attempts (sudo)"
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log "Docker not ready, waiting... (attempt $attempt/$max_attempts)"
            sleep $((attempt * 2))  # Exponential backoff: 2, 4, 6, 8 seconds
        fi
        ((attempt++))
    done

    log "ERROR: Cannot access Docker daemon after $max_attempts attempts"
    return 1
}

# Count how many external drives are attached (block devices exist)
count_attached_drives() {
    local count=0
    for label in "${EXTERNAL_DRIVE_LABELS[@]}"; do
        if [[ -e "/dev/disk/by-label/$label" ]]; then
            ((count++)) || true
        fi
    done
    echo "$count"
}

# Count how many external drives are mounted
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

# Check if MergerFS pool is mounted
check_pool_mounted() {
    if mountpoint -q /var/mnt/pool 2>/dev/null; then
        return 0
    fi
    return 1
}

# =============================================================================
# BOOT MODE DECISION
# =============================================================================

decide_boot_mode() {
    local attached mounted
    attached=$(count_attached_drives)
    mounted=$(count_mounted_drives)

    log "Drive detection: $attached attached, $mounted mounted (need $MIN_DRIVES_FOR_FULL for full mode)"

    # Decision tree:
    # 1. No drives attached → LOCAL mode (portable/gaming setup)
    # 2. Drives attached but not mounted → try to mount, then decide
    # 3. Enough drives mounted → FULL mode
    # 4. Some drives but not enough → LOCAL mode (partial bay connection)

    if [[ "$attached" -eq 0 ]]; then
        log "DECISION: LOCAL mode (no external drives detected)"
        echo "local"
        return 0
    fi

    if [[ "$attached" -ge "$MIN_DRIVES_FOR_FULL" ]]; then
        # Drives attached - try to ensure they're mounted
        if [[ "$mounted" -lt "$attached" ]]; then
            log "Drives attached but not all mounted, attempting mount..."
            sudo systemctl start mergerfs-pool.service 2>/dev/null || true
            sleep 2
            mounted=$(count_mounted_drives)
        fi

        if [[ "$mounted" -ge "$MIN_DRIVES_FOR_FULL" ]] && check_pool_mounted; then
            log "DECISION: FULL mode ($mounted drives mounted, pool available)"
            echo "full"
            return 0
        fi
    fi

    log "DECISION: LOCAL mode (insufficient drives: $mounted mounted of $attached attached)"
    echo "local"
    return 0
}

# =============================================================================
# STACK STARTUP
# =============================================================================

start_local_stack() {
    log "Starting LOCAL stack (no video/transcode services)..."

    cd "$STACK_ROOT"

    # Record mode
    echo "local" > "$STATE_DIR/stack-mode"
    echo "autostart" > "$STATE_DIR/start-method"
    date +%s > "$STATE_DIR/stack-started"

    # Start local-only services
    if "$STACK_ROOT/scripts/stack-up-local.sh" --quiet 2>&1 | tee -a "$LOG_FILE"; then
        log "LOCAL stack started successfully"
        return 0
    else
        log "WARNING: LOCAL stack start had issues (non-fatal)"
        return 0  # Don't fail boot
    fi
}

start_full_stack() {
    log "Starting FULL stack (all services including video/transcode)..."

    cd "$STACK_ROOT"

    # Record mode
    echo "full" > "$STATE_DIR/stack-mode"
    echo "autostart" > "$STATE_DIR/start-method"
    date +%s > "$STATE_DIR/stack-started"

    # Start full stack (skip interactive prompts)
    if "$STACK_ROOT/scripts/stack-up-full.sh" --force 2>&1 | tee -a "$LOG_FILE"; then
        log "FULL stack started successfully"
        return 0
    else
        log "WARNING: FULL stack start had issues, falling back to LOCAL"
        start_local_stack
        return 0  # Don't fail boot
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    log "=========================================="
    log "Media Stack Autostart Beginning"
    log "=========================================="

    # Sanity checks
    if ! check_docker; then
        log "Docker not available, skipping stack start"
        echo "none" > "$STATE_DIR/stack-mode"
        exit 0  # Don't fail boot
    fi

    # Decide mode based on hardware detection
    local mode
    mode=$(decide_boot_mode)

    # Start appropriate stack
    case "$mode" in
        full)
            start_full_stack
            ;;
        local|*)
            start_local_stack
            ;;
    esac

    log "=========================================="
    log "Media Stack Autostart Complete (mode: $mode)"
    log "=========================================="
}

main "$@"
