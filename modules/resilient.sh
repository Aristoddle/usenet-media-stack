#!/bin/bash
###############################################################################
# resilient.sh - Hardened functions for maximum reliability
###############################################################################

# Timeout for user input (seconds)
readonly INPUT_TIMEOUT=30

# Safe user input with timeout
safe_read() {
    local prompt="${1:-Continue? (y/n)}"
    local timeout="${2:-$INPUT_TIMEOUT}"
    local default="${3:-n}"
    
    echo -n "$prompt "
    
    # Read with timeout
    if read -r -t "$timeout" response; then
        echo "$response"
    else
        echo ""  # New line after timeout
        echo "⏰ Timeout - defaulting to '$default'" >&2
        echo "$default"
    fi
}

# Check if we have sudo without password or can get it
check_sudo() {
    # First check if we can sudo without password
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    
    # Check if we're root
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi
    
    # Try to get sudo
    echo "This operation requires sudo privileges."
    if sudo -v; then
        return 0
    else
        return 1
    fi
}

# Safely check if Docker is working
check_docker() {
    local max_attempts=3
    local attempt=1
    
    while [[ $attempt -le $max_attempts ]]; do
        if docker ps >/dev/null 2>&1; then
            return 0
        fi
        
        # If first attempt fails, try to start Docker
        if [[ $attempt -eq 1 ]] && check_sudo; then
            echo "Docker not responding, attempting to start..." >&2
            
            # Try systemctl first
            if command -v systemctl &>/dev/null; then
                sudo systemctl start docker 2>/dev/null || true
            # Try service
            elif command -v service &>/dev/null; then
                sudo service docker start 2>/dev/null || true
            fi
            
            # Wait a bit for Docker to start
            sleep 3
        fi
        
        ((attempt++))
    done
    
    return 1
}

# Check for Docker Compose v2 with fallback
check_docker_compose() {
    # Try v2 syntax first
    if docker compose version &>/dev/null; then
        echo "docker compose"
        return 0
    fi
    
    # Try standalone docker-compose
    if command -v docker-compose &>/dev/null; then
        echo "docker-compose"
        return 0
    fi
    
    return 1
}

# Safe script existence check and execute
safe_exec_script() {
    local script="$1"
    shift  # Remove script from args
    
    if [[ ! -f "$script" ]]; then
        echo "ERROR: Required script not found: $script" >&2
        return 1
    fi
    
    if [[ ! -x "$script" ]]; then
        echo "Making $script executable..." >&2
        chmod +x "$script"
    fi
    
    "$script" "$@"
}

# Get disk usage safely (works across different df implementations)
get_disk_usage_percent() {
    local path="${1:-.}"
    
    # Try to get percentage, handling different df formats
    local usage
    usage=$(df "$path" 2>/dev/null | awk 'NR==2 {
        # Handle both "Use%" and "Capacity" headers
        for(i=1;i<=NF;i++) {
            if($i ~ /^[0-9]+%$/) {
                gsub(/%/, "", $i)
                print $i
                exit
            }
        }
    }')
    
    # Default to 0 if we couldn't parse
    echo "${usage:-0}"
}

# Check internet connectivity with timeout
check_internet() {
    local timeout=3
    
    # Try multiple methods
    
    # Method 1: nc (netcat)
    if command -v nc &>/dev/null; then
        nc -zw"$timeout" google.com 443 2>/dev/null && return 0
    fi
    
    # Method 2: timeout + ping
    if command -v timeout &>/dev/null; then
        timeout "$timeout" ping -c 1 google.com &>/dev/null && return 0
    fi
    
    # Method 3: curl
    if command -v curl &>/dev/null; then
        curl -s --connect-timeout "$timeout" https://google.com &>/dev/null && return 0
    fi
    
    return 1
}

# Cleanup function for graceful exit
cleanup_on_exit() {
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        echo ""
        echo "⚠️  Setup did not complete successfully."
        echo ""
        echo "Troubleshooting:"
        echo "1. Check the error messages above"
        echo "2. Run './usenet deps' to verify dependencies"
        echo "3. Check Docker: docker ps"
        echo "4. See logs: ./usenet manage logs"
        echo ""
        echo "For help: https://github.com/Aristoddle/usenet-media-stack#troubleshooting"
    fi
    
    # Could add more cleanup here (remove temp files, etc)
    
    exit $exit_code
}

# Set up signal handlers
setup_signal_handlers() {
    trap cleanup_on_exit EXIT
    trap 'echo ""; echo "Interrupted by user"; exit 130' INT TERM
}

# Export all functions
export -f safe_read check_sudo check_docker check_docker_compose
export -f safe_exec_script get_disk_usage_percent check_internet
export -f cleanup_on_exit setup_signal_handlers