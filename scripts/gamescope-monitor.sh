#!/usr/bin/env bash
# gamescope-monitor.sh - Auto-pause media stack when Gamescope is active
#
# Monitors for Gamescope (Bazzite/Steam Game Mode) and automatically:
# - Enables gaming mode when Gamescope starts
# - Disables gaming mode when Gamescope exits
#
# This is OPTIONAL behavior - the media stack can run fine during gaming
# on a beefy system like SER7 (16 cores, 78GB RAM). This is for when you
# want MAXIMUM gaming performance.
#
# Usage:
#   gamescope-monitor.sh         # Run in foreground (for testing)
#   gamescope-monitor.sh daemon  # Run as daemon (for systemd)
#   gamescope-monitor.sh status  # Check current state
#   gamescope-monitor.sh enable  # Enable auto-pause behavior
#   gamescope-monitor.sh disable # Disable auto-pause (monitor still runs)
#
# Config: ~/.config/media-stack/gamescope-auto-pause (enabled/disabled)

set -euo pipefail

STACK_ROOT="/var/home/deck/Documents/Code/media-automation/usenet-media-stack"
CONFIG_DIR="$HOME/.config/media-stack"
CONFIG_FILE="$CONFIG_DIR/gamescope-auto-pause"
STATE_FILE="/tmp/media-stack/gamescope-paused"
POLL_INTERVAL=5  # seconds

# Colors (only if terminal)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
else
    GREEN=''; YELLOW=''; BLUE=''; NC=''
fi

log() { echo -e "${BLUE}[gamescope-monitor]${NC} $*"; }
warn() { echo -e "${YELLOW}[warning]${NC} $*"; }

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"
mkdir -p "/tmp/media-stack"

# Check if auto-pause is enabled
is_auto_pause_enabled() {
    [[ -f "$CONFIG_FILE" ]] && [[ "$(cat "$CONFIG_FILE")" == "enabled" ]]
}

# Check if Gamescope is running
is_gamescope_running() {
    pgrep -x gamescope >/dev/null 2>&1
}

# Check if we triggered the pause (vs user manually pausing)
did_we_pause() {
    [[ -f "$STATE_FILE" ]]
}

# Enable gaming mode (pause heavy services)
pause_for_gaming() {
    if did_we_pause; then
        return 0  # Already paused by us
    fi

    log "Gamescope detected - enabling gaming mode..."

    if "$STACK_ROOT/scripts/gaming-mode.sh" enable 2>&1 | head -5; then
        echo "gamescope" > "$STATE_FILE"
        log "Media stack paused for gaming"
    else
        warn "Failed to enable gaming mode"
    fi
}

# Disable gaming mode (resume services)
resume_after_gaming() {
    if ! did_we_pause; then
        return 0  # We didn't pause it, don't resume
    fi

    log "Gamescope exited - disabling gaming mode..."

    if "$STACK_ROOT/scripts/gaming-mode.sh" disable 2>&1 | head -5; then
        rm -f "$STATE_FILE"
        log "Media stack resumed"
    else
        warn "Failed to disable gaming mode"
    fi
}

# Main monitoring loop
monitor_loop() {
    local was_running=false

    log "Starting Gamescope monitor (poll interval: ${POLL_INTERVAL}s)"
    log "Auto-pause: $(is_auto_pause_enabled && echo 'ENABLED' || echo 'DISABLED')"

    while true; do
        if is_gamescope_running; then
            if [[ "$was_running" == false ]]; then
                log "Gamescope started"
                was_running=true

                if is_auto_pause_enabled; then
                    pause_for_gaming
                else
                    log "Auto-pause disabled - stack continues running"
                fi
            fi
        else
            if [[ "$was_running" == true ]]; then
                log "Gamescope exited"
                was_running=false

                if is_auto_pause_enabled; then
                    resume_after_gaming
                fi
            fi
        fi

        sleep "$POLL_INTERVAL"
    done
}

# Show current status
show_status() {
    echo -e "${BLUE}=== Gamescope Monitor Status ===${NC}"
    echo ""

    echo -n "Auto-pause: "
    if is_auto_pause_enabled; then
        echo -e "${GREEN}ENABLED${NC}"
    else
        echo -e "${YELLOW}DISABLED${NC}"
    fi

    echo -n "Gamescope: "
    if is_gamescope_running; then
        echo -e "${GREEN}RUNNING${NC}"
    else
        echo "not running"
    fi

    echo -n "We paused stack: "
    if did_we_pause; then
        echo -e "${YELLOW}YES${NC} (will auto-resume when Gamescope exits)"
    else
        echo "no"
    fi

    echo ""
    echo "Monitor service:"
    systemctl --user status gamescope-monitor.service 2>&1 | head -5 || echo "  (not installed as service)"
}

# Main
case "${1:-}" in
    daemon)
        monitor_loop
        ;;
    status|"")
        show_status
        ;;
    enable)
        echo "enabled" > "$CONFIG_FILE"
        log "Auto-pause ENABLED - stack will pause when Gamescope starts"
        ;;
    disable)
        echo "disabled" > "$CONFIG_FILE"
        log "Auto-pause DISABLED - stack will continue during Gamescope"
        ;;
    -h|--help|help)
        cat << 'EOF'
Usage: gamescope-monitor.sh [COMMAND]

Monitor for Gamescope and optionally auto-pause media stack.

Commands:
  (none)    Show current status
  status    Show current status
  enable    Enable auto-pause when Gamescope runs
  disable   Disable auto-pause (monitor still runs, just observes)
  daemon    Run monitoring loop (for systemd service)

The auto-pause feature is OPTIONAL. Your SER7 has plenty of resources
to run media stack + games simultaneously. Use auto-pause only when
you want MAXIMUM gaming performance.

Examples:
  gamescope-monitor.sh enable   # Turn on auto-pause
  gamescope-monitor.sh status   # Check current state
EOF
        ;;
    *)
        echo "Unknown command: $1"
        echo "Usage: gamescope-monitor.sh {status|enable|disable|daemon}"
        exit 1
        ;;
esac
