#!/usr/bin/env bash
# stack-down.sh - Gracefully shut down the media stack
#
# This script handles graceful shutdown with special handling for:
# - Active Tdarr transcodes (wait or kill)
# - Active downloads (SABnzbd, Transmission)
# - Plex sessions
#
# Usage:
#   stack-down.sh                    # Graceful shutdown with prompts
#   stack-down.sh --quick            # Stop without waiting for jobs
#   stack-down.sh --force            # Kill everything immediately
#   stack-down.sh --wait-transcodes  # Wait for transcodes to complete
#
# Exit codes:
#   0 - Success
#   1 - Partial failure (some services didn't stop)
#   2 - Critical error

set -euo pipefail

STACK_ROOT="/var/home/deck/Documents/Code/media-automation/usenet-media-stack"
TDARR_URL="http://localhost:8265"
SABNZBD_URL="http://192.168.6.167:8080"
STATE_DIR="/tmp/media-stack"

# ANSI colors (only if stdout is a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

log() { echo -e "${BLUE}[stack-down]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }

# =============================================================================
# JOB DETECTION
# =============================================================================

# Check for active Tdarr workers
check_tdarr_activity() {
    if ! curl -s --connect-timeout 2 "${TDARR_URL}/api/v2/status" >/dev/null 2>&1; then
        echo "unreachable"
        return
    fi

    local workers
    workers=$(curl -s "${TDARR_URL}/api/v2/get-nodes" 2>/dev/null | python3 -c "
import json, sys
try:
    nodes = json.load(sys.stdin)
    total_workers = 0
    for nid, node in nodes.items():
        workers = node.get('workers', {})
        total_workers += len(workers)
    print(total_workers)
except:
    print(0)
" 2>/dev/null || echo "0")

    echo "$workers"
}

# Check for active SABnzbd downloads
check_sabnzbd_activity() {
    local queue_slots
    queue_slots=$(curl -s --connect-timeout 2 "${SABNZBD_URL}/api?mode=queue&output=json&apikey=${SABNZBD_API_KEY:-}" 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    slots = data.get('queue', {}).get('slots', [])
    downloading = [s for s in slots if s.get('status') == 'Downloading']
    print(len(downloading))
except:
    print(0)
" 2>/dev/null || echo "0")

    echo "$queue_slots"
}

# Check for active Transmission torrents
check_transmission_activity() {
    local active
    active=$(sudo docker exec transmission transmission-remote -l 2>/dev/null | grep -c "Downloading\|Seeding" || echo "0")
    echo "$active"
}

# Check for active Plex sessions
check_plex_sessions() {
    local sessions
    sessions=$(curl -s --connect-timeout 2 "http://localhost:32400/status/sessions?X-Plex-Token=${PLEX_TOKEN:-}" 2>/dev/null | grep -c "<Video" || echo "0")
    echo "$sessions"
}

# Aggregate all activity checks
show_activity_summary() {
    echo -e "${BOLD}=== Active Jobs ===${NC}"
    echo ""

    local tdarr_workers
    tdarr_workers=$(check_tdarr_activity)
    if [[ "$tdarr_workers" == "unreachable" ]]; then
        echo "  Tdarr: (not reachable)"
    elif [[ "$tdarr_workers" -gt 0 ]]; then
        echo -e "  Tdarr: ${YELLOW}$tdarr_workers active transcode(s)${NC}"
    else
        echo "  Tdarr: idle"
    fi

    local sab_downloads
    sab_downloads=$(check_sabnzbd_activity)
    if [[ "$sab_downloads" -gt 0 ]]; then
        echo -e "  SABnzbd: ${YELLOW}$sab_downloads downloading${NC}"
    else
        echo "  SABnzbd: idle"
    fi

    local transmission_active
    transmission_active=$(check_transmission_activity)
    if [[ "$transmission_active" -gt 0 ]]; then
        echo -e "  Transmission: ${YELLOW}$transmission_active active torrent(s)${NC}"
    else
        echo "  Transmission: idle"
    fi

    local plex_sessions
    plex_sessions=$(check_plex_sessions)
    if [[ "$plex_sessions" -gt 0 ]]; then
        echo -e "  Plex: ${YELLOW}$plex_sessions active session(s)${NC}"
    else
        echo "  Plex: idle"
    fi

    echo ""

    # Return count of active jobs
    local total=0
    [[ "$tdarr_workers" =~ ^[0-9]+$ ]] && ((total += tdarr_workers)) || true
    ((total += sab_downloads)) || true
    ((total += transmission_active)) || true
    ((total += plex_sessions)) || true

    echo "$total"
}

# =============================================================================
# GRACEFUL SHUTDOWN ACTIONS
# =============================================================================

# Pause Tdarr nodes (let current jobs finish)
pause_tdarr() {
    log "Pausing Tdarr nodes..."

    if ! curl -s --connect-timeout 2 "${TDARR_URL}/api/v2/status" >/dev/null 2>&1; then
        warn "Tdarr not reachable, skipping pause"
        return 0
    fi

    local nodes
    nodes=$(curl -s "${TDARR_URL}/api/v2/get-nodes" 2>/dev/null | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
for nid in nodes.keys():
    print(nid)
" 2>/dev/null || true)

    for node_id in $nodes; do
        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"data\": {\"nodeID\": \"$node_id\", \"nodeUpdates\": {\"nodePaused\": true}}}" \
            "${TDARR_URL}/api/v2/update-node" >/dev/null 2>&1 || true
    done

    success "Tdarr nodes paused (current jobs will complete)"
}

# Kill active Tdarr transcodes
kill_tdarr_transcodes() {
    log "Killing active transcodes..."

    sudo docker exec tdarr-node pkill -f "ffmpeg" 2>/dev/null || true
    sudo docker exec tdarr pkill -f "ffmpeg" 2>/dev/null || true

    success "Transcode processes killed"
}

# Pause SABnzbd queue
pause_sabnzbd() {
    log "Pausing SABnzbd queue..."

    curl -s "${SABNZBD_URL}/api?mode=pause&apikey=${SABNZBD_API_KEY:-}" >/dev/null 2>&1 || true

    success "SABnzbd paused"
}

# Wait for transcodes to complete
wait_for_transcodes() {
    local max_wait="${1:-600}"  # Default 10 minutes
    local waited=0
    local interval=10

    log "Waiting for transcodes to complete (max ${max_wait}s)..."

    while [[ $waited -lt $max_wait ]]; do
        local workers
        workers=$(check_tdarr_activity)

        if [[ "$workers" == "unreachable" || "$workers" -eq 0 ]]; then
            success "All transcodes complete"
            return 0
        fi

        echo -e "  ${YELLOW}$workers transcode(s) still running... (${waited}s/${max_wait}s)${NC}"
        sleep "$interval"
        ((waited += interval))
    done

    warn "Timeout waiting for transcodes"
    return 1
}

# =============================================================================
# SHUTDOWN
# =============================================================================

stop_all_services() {
    log "Stopping all services..."

    cd "$STACK_ROOT"

    # Stop via docker compose
    if sudo docker compose down; then
        success "All services stopped"
    else
        warn "Some services may not have stopped cleanly"
    fi

    # Clear state
    rm -f "$STATE_DIR/stack-mode"
    rm -f "$STATE_DIR/stack-started"
}

stop_with_timeout() {
    local timeout="${1:-30}"

    log "Stopping services (${timeout}s timeout per container)..."

    cd "$STACK_ROOT"

    if sudo docker compose down --timeout "$timeout"; then
        success "All services stopped"
    else
        warn "Some services required force stop"
    fi

    rm -f "$STATE_DIR/stack-mode"
    rm -f "$STATE_DIR/stack-started"
}

force_stop() {
    log "Force stopping all services..."

    cd "$STACK_ROOT"

    # Kill all containers immediately
    sudo docker compose kill 2>/dev/null || true
    sudo docker compose down --timeout 0 2>/dev/null || true

    success "All services force stopped"

    rm -f "$STATE_DIR/stack-mode"
    rm -f "$STATE_DIR/stack-started"
}

# =============================================================================
# MAIN
# =============================================================================

show_help() {
    cat << 'EOF'
Usage: stack-down.sh [OPTIONS]

Gracefully shut down the usenet media stack.

Options:
  --quick             Stop quickly (30s timeout, no waiting for jobs)
  --force             Kill all containers immediately
  --wait-transcodes   Wait for Tdarr transcodes to complete (max 10 min)
  --status            Show current activity without stopping
  -h, --help          Show this help message

Behavior:
  Default mode checks for active jobs and offers choices:
  - Active transcodes: option to wait, kill, or pause
  - Active downloads: pause queue before stop
  - Active Plex sessions: warning before stop

Examples:
  stack-down.sh                    # Interactive graceful shutdown
  stack-down.sh --quick            # Stop with default timeout
  stack-down.sh --force            # Emergency stop (data loss possible)
  stack-down.sh --wait-transcodes  # Wait for transcodes, then stop
EOF
}

main() {
    local mode="interactive"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quick)
                mode="quick"
                shift
                ;;
            --force)
                mode="force"
                shift
                ;;
            --wait-transcodes)
                mode="wait"
                shift
                ;;
            --status)
                mode="status"
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

    echo -e "${BOLD}=== Media Stack - Shutdown ===${NC}"
    echo ""

    # Load API keys from .env if available
    if [[ -f "$STACK_ROOT/.env" ]]; then
        # shellcheck source=/dev/null
        set +u  # .env may have unset variables
        source "$STACK_ROOT/.env"
        set -u
    fi

    case "$mode" in
        status)
            show_activity_summary >/dev/null  # Suppress the count output
            exit 0
            ;;

        force)
            warn "Force stopping all services (may cause data loss)..."
            force_stop
            exit 0
            ;;

        quick)
            log "Quick shutdown mode"
            pause_tdarr
            pause_sabnzbd
            stop_with_timeout 30
            exit 0
            ;;

        wait)
            pause_tdarr
            if wait_for_transcodes 600; then
                stop_all_services
            else
                echo "Transcodes did not complete in time."
                echo "  1) Kill transcodes and stop"
                echo "  2) Wait longer (10 more minutes)"
                echo "  3) Cancel shutdown"

                read -r -p "Choice [1-3]: " choice
                case "$choice" in
                    1)
                        kill_tdarr_transcodes
                        stop_all_services
                        ;;
                    2)
                        if wait_for_transcodes 600; then
                            stop_all_services
                        else
                            warn "Still not complete. Force stopping..."
                            force_stop
                        fi
                        ;;
                    *)
                        log "Shutdown cancelled"
                        exit 1
                        ;;
                esac
            fi
            exit 0
            ;;

        interactive)
            # Check for active jobs
            local active_jobs
            active_jobs=$(show_activity_summary)

            if [[ "$active_jobs" -gt 0 ]]; then
                echo -e "${YELLOW}There are active jobs running.${NC}"
                echo ""
                echo "Options:"
                echo "  1) Graceful stop (pause queues, let current jobs finish briefly)"
                echo "  2) Wait for transcodes to complete (may take a while)"
                echo "  3) Quick stop (30s timeout, may interrupt jobs)"
                echo "  4) Force stop (immediate, may cause data loss)"
                echo "  5) Cancel"
                echo ""

                read -r -p "Choice [1-5]: " choice

                case "$choice" in
                    1)
                        pause_tdarr
                        pause_sabnzbd
                        stop_with_timeout 60
                        ;;
                    2)
                        pause_tdarr
                        pause_sabnzbd
                        if wait_for_transcodes 600; then
                            stop_all_services
                        else
                            warn "Timeout reached, stopping anyway..."
                            stop_with_timeout 30
                        fi
                        ;;
                    3)
                        pause_tdarr
                        pause_sabnzbd
                        stop_with_timeout 30
                        ;;
                    4)
                        force_stop
                        ;;
                    *)
                        log "Shutdown cancelled"
                        exit 1
                        ;;
                esac
            else
                # No active jobs, just stop
                log "No active jobs detected"
                stop_all_services
            fi
            ;;
    esac

    echo ""
    success "Stack shutdown complete"

    # Show reminder about pool
    if mountpoint -q "/var/mnt/pool" 2>/dev/null; then
        echo ""
        log "Note: MergerFS pool is still mounted at /var/mnt/pool"
        log "To unmount: sudo systemctl stop mergerfs-pool.service"
    fi
}

main "$@"
