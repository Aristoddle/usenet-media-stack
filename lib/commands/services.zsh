#!/usr/bin/env zsh
# services.zsh - Service management commands
# Part of usenet media stack CLI

# Load core utilities  
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
source "$SCRIPT_DIR/../core/common.zsh"

# Help text
show_help() {
    cat << 'EOF'
Service Management Commands

USAGE:
    usenet services <action> [options]

ACTIONS:
    list                    Show all service status with URLs
    start [service]         Start all services or specific service
    stop [service]          Stop all services or specific service  
    restart [service]       Restart all services or specific service
    logs <service>          Show logs for specific service
    health                  Run health checks on all services

FLAGS:
    --verbose              Show detailed output
    --format <type>        Output format: table, json, brief (default: table)

EXAMPLES:
    usenet services list                # Show all service status
    usenet services start sonarr       # Start specific service
    usenet services logs plex      # View service logs
    usenet services health             # Health check all services

EOF
}

# Main entry point
main() {
    local action="$1"
    shift

    case "$action" in
        list|status)
            # Use existing manage.zsh functionality but with clean interface
            exec "$SCRIPT_DIR/manage.zsh" list "$@"
            ;;
        start)
            if [[ -n "$1" ]]; then
                exec "$SCRIPT_DIR/manage.zsh" start "$1"
            else
                exec "$SCRIPT_DIR/manage.zsh" start
            fi
            ;;
        stop)
            if [[ -n "$1" ]]; then
                exec "$SCRIPT_DIR/manage.zsh" stop "$1"
            else
                exec "$SCRIPT_DIR/manage.zsh" stop
            fi
            ;;
        restart)
            if [[ -n "$1" ]]; then
                exec "$SCRIPT_DIR/manage.zsh" restart "$1"
            else
                exec "$SCRIPT_DIR/manage.zsh" restart
            fi
            ;;
        logs)
            if [[ -z "$1" ]]; then
                error "Service name required for logs command"
                return 1
            fi
            exec "$SCRIPT_DIR/manage.zsh" logs "$1"
            ;;
        health)
            # Future: implement health checks
            exec "$SCRIPT_DIR/manage.zsh" list "$@"
            ;;
        --help|-h)
            show_help
            ;;
        "")
            show_help
            ;;
        *)
            error "Unknown services action: $action"
            echo "Run 'usenet services --help' for available actions."
            return 1
            ;;
    esac
}

# Execute if called directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    main "$@"
fi