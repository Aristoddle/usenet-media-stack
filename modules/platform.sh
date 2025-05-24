#!/bin/bash
###############################################################################
# platform.sh - Cross-platform compatibility layer
# 
# Works on: Linux, macOS, WSL2, and other Unix-like systems
###############################################################################

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            echo "wsl"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        echo "windows"
    elif [[ "$OSTYPE" == "freebsd"* ]]; then
        echo "freebsd"
    else
        echo "unknown"
    fi
}

# Get total RAM (cross-platform)
get_total_ram_mb() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl)
            free -m 2>/dev/null | awk 'NR==2{print $2}' || echo "0"
            ;;
        macos)
            # macOS uses different command
            local ram_bytes=$(sysctl -n hw.memsize 2>/dev/null || echo "0")
            echo $((ram_bytes / 1024 / 1024))
            ;;
        freebsd)
            local ram_bytes=$(sysctl -n hw.physmem 2>/dev/null || echo "0")
            echo $((ram_bytes / 1024 / 1024))
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get disk usage percentage (cross-platform)
get_disk_usage_percent() {
    local path="${1:-.}"
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl)
            df "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}' || echo "0"
            ;;
        macos|freebsd)
            # macOS/BSD df has different column layout
            df "$path" 2>/dev/null | awk 'NR==2 {gsub(/%/,"",$5); print $5}' || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get free disk space in GB (cross-platform)
get_disk_free_gb() {
    local path="${1:-.}"
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl)
            df -BG "$path" 2>/dev/null | awk 'NR==2 {gsub(/G/,"",$4); print $4}' || echo "0"
            ;;
        macos|freebsd)
            # macOS doesn't have -B flag
            local free_kb=$(df -k "$path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "0")
            echo $((free_kb / 1024 / 1024))
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Start Docker service (cross-platform)
start_docker_service() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux)
            # Try systemctl first (systemd)
            if command -v systemctl &>/dev/null; then
                sudo systemctl start docker 2>/dev/null && return 0
            fi
            # Try service (init.d)
            if command -v service &>/dev/null; then
                sudo service docker start 2>/dev/null && return 0
            fi
            # Try direct init.d
            if [[ -x /etc/init.d/docker ]]; then
                sudo /etc/init.d/docker start 2>/dev/null && return 0
            fi
            ;;
        macos)
            # On macOS, Docker Desktop manages the daemon
            echo "Please start Docker Desktop application"
            open -a Docker 2>/dev/null || echo "Docker Desktop not found"
            return 1
            ;;
        wsl)
            # WSL2 might use Windows Docker Desktop
            if command -v docker.exe &>/dev/null; then
                echo "Using Docker Desktop from Windows"
                return 0
            else
                # Try Linux methods
                sudo service docker start 2>/dev/null && return 0
            fi
            ;;
    esac
    
    return 1
}

# Install package (cross-platform)
install_package() {
    local package="$1"
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl)
            if command -v apt &>/dev/null; then
                sudo apt update && sudo apt install -y "$package"
            elif command -v yum &>/dev/null; then
                sudo yum install -y "$package"
            elif command -v dnf &>/dev/null; then
                sudo dnf install -y "$package"
            elif command -v pacman &>/dev/null; then
                sudo pacman -S --noconfirm "$package"
            else
                echo "No supported package manager found"
                return 1
            fi
            ;;
        macos)
            if command -v brew &>/dev/null; then
                brew install "$package"
            else
                echo "Please install Homebrew first: https://brew.sh"
                return 1
            fi
            ;;
        freebsd)
            if command -v pkg &>/dev/null; then
                sudo pkg install -y "$package"
            else
                echo "pkg not found"
                return 1
            fi
            ;;
        *)
            echo "Unsupported platform for package installation"
            return 1
            ;;
    esac
}

# Check if running with sudo/admin (cross-platform)
check_sudo_available() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl|freebsd)
            # Check if we can sudo
            if sudo -n true 2>/dev/null; then
                return 0
            elif [[ $EUID -eq 0 ]]; then
                return 0
            else
                # Try to get sudo
                sudo -v 2>/dev/null
            fi
            ;;
        macos)
            # macOS always has sudo for admin users
            sudo -v 2>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Get number of CPU cores (cross-platform)
get_cpu_cores() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl)
            nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo "1"
            ;;
        macos|freebsd)
            sysctl -n hw.ncpu 2>/dev/null || echo "1"
            ;;
        *)
            echo "1"
            ;;
    esac
}

# Check Docker installation method
get_docker_install_method() {
    local platform=$(detect_platform)
    
    case "$platform" in
        linux|wsl)
            echo "curl -fsSL https://get.docker.com | sh"
            ;;
        macos)
            echo "Download Docker Desktop from https://www.docker.com/products/docker-desktop"
            ;;
        *)
            echo "See https://docs.docker.com/get-docker/"
            ;;
    esac
}

# Use GNU tools on macOS if available
setup_gnu_tools() {
    local platform=$(detect_platform)
    
    if [[ "$platform" == "macos" ]]; then
        # Check for GNU coreutils
        if command -v ggrep &>/dev/null; then
            alias grep='ggrep'
        fi
        if command -v gsed &>/dev/null; then
            alias sed='gsed'
        fi
        if command -v gawk &>/dev/null; then
            alias awk='gawk'
        fi
    fi
}

# Export all functions
export -f detect_platform get_total_ram_mb get_disk_usage_percent
export -f get_disk_free_gb start_docker_service install_package
export -f check_sudo_available get_cpu_cores get_docker_install_method
export -f setup_gnu_tools