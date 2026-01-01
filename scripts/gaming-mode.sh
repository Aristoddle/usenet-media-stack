#!/usr/bin/env bash
# gaming-mode.sh - Toggle between gaming and media server modes
#
# Usage:
#   gaming-mode.sh enable [--kill-transcodes]   # Switch to gaming mode
#   gaming-mode.sh disable                      # Switch to media mode
#   gaming-mode.sh status                       # Show current mode
#
# What this does:
#   Gaming mode (enable):
#     - Pauses all Tdarr nodes (graceful - in-progress jobs finish unless --kill-transcodes)
#     - Stops CPU-heavy containers (makemkv)
#     - Frees ~14 CPU cores and 36GB RAM for gaming
#
#   Media mode (disable):
#     - Unpauses Tdarr nodes
#     - Starts stopped containers
#     - Resumes transcode queue processing
#
# State is saved to /tmp/gaming-mode-state for resume-from-suspend handling

set -euo pipefail

STACK_ROOT="/var/home/deck/Documents/Code/media-automation/usenet-media-stack"
TDARR_URL="http://localhost:8265"
STATE_FILE="/tmp/gaming-mode-state"

# ANSI colors (only if stdout is a terminal)
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; NC=''
fi

log() { echo -e "${BLUE}[gaming-mode]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }
error() { echo -e "${RED}[error]${NC} $*" >&2; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }

# Check if Tdarr is reachable
check_tdarr() {
    if ! curl -s --connect-timeout 2 "${TDARR_URL}/api/v2/status" >/dev/null 2>&1; then
        warn "Tdarr not reachable at ${TDARR_URL} - skipping Tdarr operations"
        return 1
    fi
    return 0
}

# Get Tdarr node IDs and info
get_tdarr_nodes() {
    curl -s "${TDARR_URL}/api/v2/get-nodes" 2>/dev/null || echo "{}"
}

# Check if any Tdarr workers are actively transcoding
get_active_workers() {
    get_tdarr_nodes | python3 -c "
import json, sys
try:
    nodes = json.load(sys.stdin)
    for nid, node in nodes.items():
        workers = node.get('workers', {})
        if workers:
            name = node.get('nodeName', nid)
            print(f'  {name}: {len(workers)} active worker(s)')
except:
    pass
" 2>/dev/null
}

# Pause all Tdarr nodes
pause_tdarr_nodes() {
    local nodes
    nodes=$(get_tdarr_nodes | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
for nid in nodes.keys():
    print(nid)
" 2>/dev/null)

    if [[ -z "$nodes" ]]; then
        warn "No Tdarr nodes found"
        return 0
    fi

    for node_id in $nodes; do
        local node_name
        node_name=$(get_tdarr_nodes | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
print(nodes.get('$node_id', {}).get('nodeName', '$node_id'))
" 2>/dev/null)

        log "Pausing Tdarr node: $node_name"

        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"data\": {\"nodeID\": \"$node_id\", \"nodeUpdates\": {\"nodePaused\": true}}}" \
            "${TDARR_URL}/api/v2/update-node" >/dev/null 2>&1 || warn "Failed to pause $node_name"
    done

    success "All Tdarr nodes paused"
}

# Unpause all Tdarr nodes
unpause_tdarr_nodes() {
    local nodes
    nodes=$(get_tdarr_nodes | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
for nid in nodes.keys():
    print(nid)
" 2>/dev/null)

    if [[ -z "$nodes" ]]; then
        warn "No Tdarr nodes found"
        return 0
    fi

    for node_id in $nodes; do
        local node_name
        node_name=$(get_tdarr_nodes | python3 -c "
import json, sys
nodes = json.load(sys.stdin)
print(nodes.get('$node_id', {}).get('nodeName', '$node_id'))
" 2>/dev/null)

        log "Unpausing Tdarr node: $node_name"

        curl -s -X POST -H "Content-Type: application/json" \
            -d "{\"data\": {\"nodeID\": \"$node_id\", \"nodeUpdates\": {\"nodePaused\": false}}}" \
            "${TDARR_URL}/api/v2/update-node" >/dev/null 2>&1 || warn "Failed to unpause $node_name"
    done

    success "All Tdarr nodes unpaused"
}

# Kill any active ffmpeg transcode processes (nuclear option)
kill_transcodes() {
    log "Killing active transcode processes..."

    # Kill Tdarr-spawned ffmpeg processes (inside containers)
    sudo docker exec tdarr-node pkill -f "ffmpeg.*libsvtav1" 2>/dev/null || true
    sudo docker exec tdarr pkill -f "ffmpeg.*libsvtav1" 2>/dev/null || true

    # Kill any manual ffmpeg SVT-AV1 processes on host
    pkill -f "ffmpeg.*libsvtav1" 2>/dev/null || true

    success "Transcode processes killed"
}

# Stop high-CPU containers
stop_heavy_containers() {
    log "Stopping CPU-intensive containers..."

    # MakeMKV - ISO ripping (4 CPU cores)
    if sudo docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^makemkv$'; then
        sudo docker stop makemkv >/dev/null 2>&1 && success "Stopped makemkv" || true
    fi

    # Optionally stop sabnzbd (2 CPU cores) - uncomment if you want more aggressive pause
    # if sudo docker ps --format '{{.Names}}' 2>/dev/null | grep -q '^sabnzbd$'; then
    #     sudo docker stop sabnzbd >/dev/null 2>&1 && success "Stopped sabnzbd" || true
    # fi
}

# Start containers that were stopped
start_heavy_containers() {
    log "Starting containers..."

    sudo docker start makemkv >/dev/null 2>&1 && success "Started makemkv" || warn "makemkv start failed (may not exist)"

    # Uncomment if you stopped sabnzbd above
    # sudo docker start sabnzbd >/dev/null 2>&1 && success "Started sabnzbd" || true
}

# Enable gaming mode
cmd_enable() {
    local kill_flag="${1:-false}"

    echo -e "${BOLD}Enabling Gaming Mode${NC}"
    echo ""

    # Check for active workers
    if check_tdarr; then
        local active_workers
        active_workers=$(get_active_workers)

        if [[ -n "$active_workers" ]]; then
            warn "Active transcodes detected:"
            echo "$active_workers"
            echo ""

            if [[ "$kill_flag" == "true" ]]; then
                warn "Killing active transcodes (--kill-transcodes specified)"
                kill_transcodes
            else
                log "Transcodes will complete before workers fully pause"
                log "Use --kill-transcodes to stop them immediately"
            fi
        fi

        # Pause Tdarr nodes
        pause_tdarr_nodes
    fi

    # Stop heavy containers
    stop_heavy_containers

    # Save state
    echo "gaming" > "$STATE_FILE"

    echo ""
    success "Gaming mode enabled!"
    echo ""
    echo -e "${BOLD}Resources freed:${NC}"
    echo "  - Tdarr nodes: ~14 CPU cores, 36GB RAM (paused)"
    echo "  - MakeMKV: 4 CPU cores, 4GB RAM (stopped)"
    echo ""
    echo -e "To return to media mode: ${BOLD}gaming-mode disable${NC}"
}

# Disable gaming mode
cmd_disable() {
    echo -e "${BOLD}Disabling Gaming Mode${NC}"
    echo ""

    # Unpause Tdarr nodes
    if check_tdarr; then
        unpause_tdarr_nodes
    fi

    # Start containers
    start_heavy_containers

    # Clear state
    rm -f "$STATE_FILE"

    echo ""
    success "Media mode restored!"
    echo ""
    echo "Tdarr will resume processing the transcode queue."
}

# Show status
cmd_status() {
    echo -e "${BOLD}=== Gaming Mode Status ===${NC}"
    echo ""

    # Check state file
    if [[ -f "$STATE_FILE" ]]; then
        echo -e "Current mode: ${YELLOW}GAMING${NC} (paused)"
    else
        echo -e "Current mode: ${GREEN}MEDIA${NC} (active)"
    fi

    echo ""
    echo -e "${BOLD}=== System Load ===${NC}"
    uptime | sed 's/.*load average/Load average/'

    if check_tdarr; then
        echo ""
        echo -e "${BOLD}=== Tdarr Nodes ===${NC}"
        get_tdarr_nodes | python3 -c "
import json, sys
try:
    nodes = json.load(sys.stdin)
    for nid, node in nodes.items():
        name = node.get('nodeName', nid)
        paused = node.get('nodePaused', False)
        status = '${YELLOW}PAUSED${NC}' if paused else '${GREEN}ACTIVE${NC}'
        limits = node.get('workerLimits', {})
        cpu = limits.get('transcodecpu', 0)
        gpu = limits.get('transcodegpu', 0)
        print(f'  {name}: {status} (CPU workers: {cpu}, GPU workers: {gpu})')
except Exception as e:
    print(f'  Error: {e}')
" 2>/dev/null

        echo ""
        echo -e "${BOLD}=== Active Workers ===${NC}"
        local workers
        workers=$(get_active_workers)
        if [[ -n "$workers" ]]; then
            echo "$workers"
        else
            echo "  (none)"
        fi
    else
        echo ""
        echo -e "${YELLOW}Tdarr not reachable${NC}"
    fi

    echo ""
    echo -e "${BOLD}=== Heavy Containers ===${NC}"
    for container in tdarr tdarr-node makemkv sabnzbd; do
        if sudo docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            echo -e "  $container: ${GREEN}running${NC}"
        elif sudo docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            echo -e "  $container: ${YELLOW}stopped${NC}"
        else
            echo -e "  $container: ${RED}not found${NC}"
        fi
    done

    echo ""
    echo -e "${BOLD}=== Active ffmpeg Processes ===${NC}"
    local ffmpeg_count
    ffmpeg_count=$(pgrep -cf "ffmpeg.*svtav1" 2>/dev/null) || ffmpeg_count=0
    if [[ "$ffmpeg_count" -gt 0 ]]; then
        echo -e "  ${YELLOW}$ffmpeg_count SVT-AV1 encode(s) running${NC}"
    else
        echo "  (none)"
    fi
}

# Main
case "${1:-}" in
    enable|on|gaming|game)
        kill_flag="false"
        [[ "${2:-}" == "--kill-transcodes" || "${2:-}" == "-k" ]] && kill_flag="true"
        cmd_enable "$kill_flag"
        ;;
    disable|off|media)
        cmd_disable
        ;;
    status|"")
        cmd_status
        ;;
    -h|--help|help)
        echo "Usage: $(basename "$0") {enable|disable|status}"
        echo ""
        echo "Commands:"
        echo "  enable [--kill-transcodes]  Switch to gaming mode (pause media services)"
        echo "  disable                     Switch to media mode (resume services)"
        echo "  status                      Show current mode and service status"
        echo ""
        echo "Aliases:"
        echo "  enable, on, gaming, game    -> enable gaming mode"
        echo "  disable, off, media         -> disable gaming mode"
        echo ""
        echo "Examples:"
        echo "  gaming-mode enable              # Pause services, let transcodes finish"
        echo "  gaming-mode enable -k           # Pause services, kill active transcodes"
        echo "  gaming-mode disable             # Resume all services"
        ;;
    *)
        error "Unknown command: $1"
        echo "Usage: $(basename "$0") {enable|disable|status}"
        exit 1
        ;;
esac
