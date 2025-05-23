#!/bin/bash
# Media Server Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if docker-compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    else
        log_error "Neither docker-compose nor 'docker compose' found. Please install Docker Compose."
        exit 1
    fi
}

# Main functions
start_stack() {
    log_info "Starting media server stack..."
    $COMPOSE_CMD up -d
    log_success "Media server stack started!"
    
    echo
    log_info "Services available at:"
    echo "• SABnzbd:     http://localhost:8080"
    echo "• Transmission: http://localhost:9092"
    echo "• Sonarr:      http://localhost:8989"
    echo "• Radarr:      http://localhost:7878"
    echo "• Bazarr:      http://localhost:6767"
    echo "• Prowlarr:    http://localhost:9696"
    echo "• Whisparr:    http://localhost:6969"
    echo "• Readarr:     http://localhost:8787"
    echo "• Mylar3:      http://localhost:8090"
    echo "• YacReader:   http://localhost:8082"
    echo "• Jackett:     http://localhost:9117"
}

stop_stack() {
    log_info "Stopping media server stack..."
    $COMPOSE_CMD down
    log_success "Media server stack stopped!"
}

restart_stack() {
    log_info "Restarting media server stack..."
    $COMPOSE_CMD restart
    log_success "Media server stack restarted!"
}

update_stack() {
    log_info "Updating media server stack..."
    $COMPOSE_CMD pull
    $COMPOSE_CMD up -d
    log_success "Media server stack updated!"
}

show_status() {
    log_info "Media server stack status:"
    $COMPOSE_CMD ps
}

show_logs() {
    local service=$1
    if [ -n "$service" ]; then
        log_info "Showing logs for $service..."
        $COMPOSE_CMD logs -f --tail=50 "$service"
    else
        log_info "Showing logs for all services..."
        $COMPOSE_CMD logs -f --tail=50
    fi
}

restart_service() {
    local service=$1
    if [ -z "$service" ]; then
        log_error "Please specify a service name"
        exit 1
    fi
    
    log_info "Restarting $service..."
    $COMPOSE_CMD restart "$service"
    log_success "$service restarted!"
}

show_help() {
    echo "Media Server Management Script"
    echo
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo
    echo "Commands:"
    echo "  start           Start all services"
    echo "  stop            Stop all services"
    echo "  restart         Restart all services"
    echo "  update          Update and restart all services"
    echo "  status          Show service status"
    echo "  logs [service]  Show logs (optionally for specific service)"
    echo "  restart-service <service>  Restart specific service"
    echo "  help            Show this help message"
    echo
    echo "Available services:"
    echo "  sabnzbd, transmission, sonarr, radarr, bazarr, prowlarr,"
    echo "  whisparr, readarr, mylar, yacreader, jackett"
    echo
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 logs sonarr"
    echo "  $0 restart-service radarr"
}

# Check docker-compose availability
check_docker_compose

# Main script logic
case "${1:-help}" in
    start)
        start_stack
        ;;
    stop)
        stop_stack
        ;;
    restart)
        restart_stack
        ;;
    update)
        update_stack
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$2"
        ;;
    restart-service)
        restart_service "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac 