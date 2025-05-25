#!/usr/bin/env zsh
##############################################################################
# File: ./lib/commands/validate.zsh
# Project: Usenet Media Stack
# Description: Pre-deployment validation and system checks
# Author: Joseph Lanzone <mailto:j3lanzone@gmail.com>
# Created: 2025-05-24
# Modified: 2025-05-24
# Version: 1.0.0
# License: MIT
#
# Performs comprehensive system validation before deployment. Checks Docker,
# disk space, network connectivity, configuration files, and dependencies
# to ensure a successful media stack deployment.
##############################################################################

##############################################################################
#                              INITIALIZATION                                #
##############################################################################

# Load core functions
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h:h}"
source "${SCRIPT_DIR:h}/core/common.zsh"
source "${SCRIPT_DIR:h}/core/init.zsh"

# Ensure config is loaded
load_stack_config || die 1 "Failed to load configuration"

##############################################################################
#                           DOCKER HELPER FUNCTIONS                          #
##############################################################################

#=============================================================================
# Function: install_docker_automatically
# Description: Attempt to install Docker based on the operating system
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker installed successfully
#   1 - Docker installation failed
#=============================================================================
install_docker_automatically() {
    local os_type=$(uname -s)
    local arch=$(uname -m)
    
    case "$os_type" in
        Linux)
            info "Detected Linux system - attempting Docker installation..."
            install_docker_linux
            ;;
        Darwin)
            info "Detected macOS system - attempting Docker Desktop installation..."
            install_docker_macos
            ;;
        CYGWIN*|MINGW*|MSYS*)
            info "Detected Windows system - please install Docker Desktop manually"
            info "Download from: https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
            return 1
            ;;
        *)
            warning "Unknown operating system: $os_type"
            return 1
            ;;
    esac
}

#=============================================================================
# Function: install_docker_linux
# Description: Install Docker on Linux systems
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker installed successfully
#   1 - Docker installation failed
#=============================================================================
install_docker_linux() {
    # Check if we have sudo access
    if ! sudo -n true 2>/dev/null; then
        error "Sudo access required for Docker installation"
        return 1
    fi
    
    # Detect Linux distribution
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        local distro=$ID
    else
        warning "Cannot detect Linux distribution"
        return 1
    fi
    
    case "$distro" in
        ubuntu|debian)
            info "Installing Docker via apt repository..."
            curl -fsSL https://download.docker.com/linux/$distro/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$distro $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            sudo apt update
            sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        fedora|centos|rhel)
            info "Installing Docker via dnf/yum..."
            sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        arch)
            info "Installing Docker via pacman..."
            sudo pacman -S --noconfirm docker docker-compose
            ;;
        *)
            warning "Unsupported Linux distribution: $distro"
            info "Please install Docker manually: https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac
    
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    success "Docker installed and started"
    warning "Please log out and back in for group changes to take effect"
    
    return 0
}

#=============================================================================
# Function: install_docker_macos
# Description: Install Docker Desktop on macOS
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker installed successfully
#   1 - Docker installation failed
#=============================================================================
install_docker_macos() {
    local arch=$(uname -m)
    
    # Check if Homebrew is available
    if command -v brew >/dev/null 2>&1; then
        info "Installing Docker Desktop via Homebrew..."
        brew install --cask docker
        return $?
    else
        # Direct download approach
        info "Downloading Docker Desktop for macOS..."
        local download_url
        
        if [[ "$arch" == "arm64" ]]; then
            download_url="https://desktop.docker.com/mac/main/arm64/Docker.dmg"
        else
            download_url="https://desktop.docker.com/mac/main/amd64/Docker.dmg"
        fi
        
        local temp_dmg="/tmp/Docker.dmg"
        
        if curl -L "$download_url" -o "$temp_dmg"; then
            info "Mounting Docker Desktop installer..."
            hdiutil attach "$temp_dmg"
            
            info "Installing Docker Desktop..."
            cp -R "/Volumes/Docker/Docker.app" "/Applications/"
            
            hdiutil detach "/Volumes/Docker"
            rm "$temp_dmg"
            
            success "Docker Desktop installed to /Applications/Docker.app"
            info "Please launch Docker Desktop to complete setup"
            
            return 0
        else
            error "Failed to download Docker Desktop"
            return 1
        fi
    fi
}

#=============================================================================
# Function: start_docker_daemon
# Description: Attempt to start Docker daemon/Desktop
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker started successfully
#   1 - Docker startup failed
#=============================================================================
start_docker_daemon() {
    local os_type=$(uname -s)
    
    case "$os_type" in
        Linux)
            # Try systemctl first
            if command -v systemctl >/dev/null 2>&1; then
                info "Starting Docker service..."
                if sudo systemctl start docker; then
                    success "Docker service started"
                    return 0
                fi
            fi
            
            # Try service command
            if command -v service >/dev/null 2>&1; then
                info "Starting Docker service (legacy)..."
                if sudo service docker start; then
                    success "Docker service started"
                    return 0
                fi
            fi
            
            error "Failed to start Docker service"
            return 1
            ;;
        Darwin)
            # Try to start Docker Desktop
            info "Starting Docker Desktop..."
            
            if [[ -f "/Applications/Docker.app/Contents/MacOS/Docker" ]]; then
                open /Applications/Docker.app
                info "Docker Desktop is starting... (this may take a minute)"
                
                # Wait for Docker to become available (up to 60 seconds)
                local count=0
                while [[ $count -lt 60 ]]; do
                    if docker ps >/dev/null 2>&1; then
                        success "Docker Desktop started successfully"
                        return 0
                    fi
                    sleep 2
                    ((count += 2))
                done
                
                warning "Docker Desktop is starting but not ready yet"
                return 1
            else
                error "Docker Desktop not found in /Applications/"
                return 1
            fi
            ;;
        *)
            warning "Cannot auto-start Docker on this operating system"
            return 1
            ;;
    esac
}

##############################################################################
#                           VALIDATION FUNCTIONS                             #
##############################################################################

#=============================================================================
# Function: show_validate_help
# Description: Display validation help
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#=============================================================================
show_validate_help() {
    cat <<'HELP'
✅ System Validation

USAGE
    usenet validate [check-type] [options]

CHECK TYPES
    all                Run all validation checks (default)
    docker             Docker installation and daemon status
    storage            Disk space and storage configuration
    network            Network connectivity and DNS
    config             Configuration files and credentials
    dependencies       Required tools and versions

OPTIONS
    --verbose, -v      Show detailed output for all checks
    --quiet, -q        Only show failures and summary
    --fix             Attempt to fix issues automatically where possible

EXAMPLES
    Full system validation:
        $ usenet validate
        
    Check only Docker setup:
        $ usenet validate docker
        
    Validate and attempt fixes:
        $ usenet validate --fix
        
    Quick check (errors only):
        $ usenet validate --quiet

VALIDATION CHECKS
    ✓ Docker installed and running
    ✓ Sufficient disk space (>50GB recommended)
    ✓ Network connectivity to indexers/providers
    ✓ All required configuration files present
    ✓ Valid API keys and credentials
    ✓ Port availability for services
    ✓ DNS resolution working
    ✓ Required tools installed (curl, jq, etc.)

HELP
}

#=============================================================================
# Function: validate_docker
# Description: Validate Docker installation and status
#
# Arguments:
#   None
#
# Returns:
#   0 - Docker validation passed
#   1 - Docker validation failed
#=============================================================================
validate_docker() {
    local errors=0
    local fix_issues=${FIX_ISSUES:-false}
    
    info "Validating Docker setup..."
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        if [[ "$fix_issues" == "true" ]]; then
            warning "Attempting to install Docker automatically..."
            install_docker_automatically
            if [[ $? -eq 0 ]]; then
                success "Docker installed successfully"
            else
                error "Failed to install Docker automatically"
                info "Please install Docker from: https://docs.docker.com/get-docker/"
                ((errors++))
            fi
        else
            info "Run with --fix to attempt automatic installation"
            info "Or install Docker from: https://docs.docker.com/get-docker/"
            ((errors++))
        fi
    else
        success "Docker is installed"
        
        # Check Docker version
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
        info "Docker version: $docker_version"
    fi
    
    # Check if Docker daemon is accessible
    local docker_running=false
    local docker_context=""
    
    # Method 1: Try current Docker context
    if docker ps >/dev/null 2>&1; then
        docker_running=true
        docker_context=$(docker context show 2>/dev/null || echo "default")
        success "Docker daemon is accessible (context: $docker_context)"
    else
        warning "Docker daemon not accessible with current context"
        
        # Method 2: Try different contexts if available
        local contexts=($(docker context ls --format "{{.Name}}" 2>/dev/null || echo ""))
        for context in "${contexts[@]}"; do
            if [[ "$context" != "$(docker context show 2>/dev/null)" ]]; then
                info "Trying Docker context: $context"
                if docker context use "$context" >/dev/null 2>&1 && docker ps >/dev/null 2>&1; then
                    docker_running=true
                    docker_context="$context"
                    success "Docker daemon accessible with context: $context"
                    break
                fi
            fi
        done
        
        # Method 3: Try to start Docker Desktop if it exists
        if [[ "$docker_running" == "false" ]]; then
            if [[ "$fix_issues" == "true" ]]; then
                warning "Attempting to start Docker..."
                start_docker_daemon
                # Re-test after start attempt
                if docker ps >/dev/null 2>&1; then
                    docker_running=true
                    success "Docker daemon started successfully"
                fi
            fi
        fi
        
        if [[ "$docker_running" == "false" ]]; then
            error "Docker daemon is not accessible"
            info "Try one of these solutions:"
            info "  • Start Docker Desktop application"
            info "  • Run: sudo systemctl start docker (Linux)"
            info "  • Add user to docker group: sudo usermod -aG docker \$USER"
            info "  • Use --fix flag to attempt automatic startup"
            ((errors++))
        fi
    fi
        
        # Check Docker Compose (only if Docker daemon is accessible)
        if [[ "$docker_running" == "true" ]] && docker compose version >/dev/null 2>&1; then
            local compose_version=$(docker compose version --short 2>/dev/null)
            success "Docker Compose available: $compose_version"
        elif [[ "$docker_running" == "true" ]]; then
            error "Docker Compose not available"
            info "Install Docker Compose plugin"
            ((errors++))
        else
            info "Skipping Docker Compose check (daemon not accessible)"
        fi
    
    return $errors
}

#=============================================================================
# Function: validate_storage
# Description: Validate storage and disk space requirements
#
# Arguments:
#   None
#
# Returns:
#   0 - Storage validation passed
#   1 - Storage validation failed
#=============================================================================
validate_storage() {
    local errors=0
    
    info "Validating storage configuration..."
    
    # Check available disk space
    local available_gb=$(df -BG "$PROJECT_ROOT" | tail -1 | awk '{print $4}' | sed 's/G$//')
    
    if [[ $available_gb -lt 50 ]]; then
        warning "Low disk space: ${available_gb}GB available (50GB+ recommended)"
        ((errors++))
    else
        success "Sufficient disk space: ${available_gb}GB available"
    fi
    
    # Check required directories
    local required_dirs=("downloads" "media" "config")
    
    for dir in $required_dirs; do
        local dir_path="${PROJECT_ROOT}/$dir"
        if [[ ! -d "$dir_path" ]]; then
            error "Missing required directory: $dir"
            info "Create with: mkdir -p $dir_path"
            ((errors++))
        else
            # Check write permissions
            if [[ ! -w "$dir_path" ]]; then
                error "Directory not writable: $dir"
                ((errors++))
            else
                success "Directory exists and writable: $dir"
            fi
        fi
    done
    
    # Check storage pool configuration if it exists
    local storage_config="${PROJECT_ROOT}/config/storage.conf"
    if [[ -f "$storage_config" ]]; then
        info "Checking storage pool configuration..."
        local invalid_drives=0
        
        while IFS= read -r drive_path; do
            [[ -z "$drive_path" || "$drive_path" =~ ^# ]] && continue
            
            if [[ ! -d "$drive_path" ]]; then
                error "Storage drive not found: $drive_path"
                ((invalid_drives++))
            elif [[ ! -w "$drive_path" ]]; then
                error "Storage drive not writable: $drive_path"
                ((invalid_drives++))
            fi
        done < "$storage_config"
        
        if [[ $invalid_drives -eq 0 ]]; then
            success "All configured storage drives are accessible"
        else
            ((errors += invalid_drives))
        fi
    fi
    
    return $errors
}

#=============================================================================
# Function: validate_network
# Description: Validate network connectivity and DNS
#
# Arguments:
#   None
#
# Returns:
#   0 - Network validation passed
#   1 - Network validation failed
#=============================================================================
validate_network() {
    local errors=0
    
    info "Validating network connectivity..."
    
    # Test basic internet connectivity
    if curl -s --connect-timeout 5 --max-time 10 https://google.com >/dev/null; then
        success "Internet connectivity working"
    else
        error "No internet connectivity"
        ((errors++))
        return $errors
    fi
    
    # Test DNS resolution
    if nslookup google.com >/dev/null 2>&1; then
        success "DNS resolution working"
    else
        error "DNS resolution failed"
        ((errors++))
    fi
    
    # Test Docker Hub connectivity
    if curl -s --connect-timeout 5 --max-time 10 https://registry-1.docker.io >/dev/null; then
        success "Docker Hub accessible"
    else
        warning "Docker Hub connectivity issues (may affect image pulls)"
        ((errors++))
    fi
    
    # Check port availability for common services
    local services=(
        "8989:Sonarr"
        "7878:Radarr" 
        "8080:SABnzbd"
        "9696:Prowlarr"
        "8096:Jellyfin"
    )
    
    info "Checking port availability..."
    for service in $services; do
        local port=${service%%:*}
        local name=${service##*:}
        
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            warning "Port $port already in use (needed for $name)"
            ((errors++))
        else
            success "Port $port available for $name"
        fi
    done
    
    return $errors
}

#=============================================================================
# Function: validate_config
# Description: Validate configuration files and credentials
#
# Arguments:
#   None
#
# Returns:
#   0 - Configuration validation passed
#   1 - Configuration validation failed
#=============================================================================
validate_config() {
    local errors=0
    
    info "Validating configuration..."
    
    # Check for .env file
    local env_file="${PROJECT_ROOT}/.env"
    if [[ ! -f "$env_file" ]]; then
        error "Configuration file missing: .env"
        info "Copy from .env.example and configure: cp .env.example .env"
        ((errors++))
        return $errors
    else
        success ".env file exists"
    fi
    
    # Check required environment variables
    local required_vars=(
        "DOMAIN"
    )
    
    # Source .env for validation
    set -a
    source "$env_file"
    set +a
    
    for var in $required_vars; do
        if [[ -z "${(P)var}" ]]; then
            error "Required environment variable not set: $var"
            ((errors++))
        else
            success "Environment variable set: $var"
        fi
    done
    
    # Check for provider credentials
    local provider_count=0
    if [[ -n "$NEWSHOSTING_USER" && -n "$NEWSHOSTING_PASS" ]]; then
        ((provider_count++))
    fi
    if [[ -n "$USENETEXPRESS_USER" && -n "$USENETEXPRESS_PASS" ]]; then
        ((provider_count++))
    fi
    if [[ -n "$FRUGAL_USER" && -n "$FRUGAL_PASS" ]]; then
        ((provider_count++))
    fi
    
    if [[ $provider_count -eq 0 ]]; then
        error "No Usenet provider credentials configured"
        info "Configure at least one provider in .env"
        ((errors++))
    else
        success "$provider_count Usenet provider(s) configured"
    fi
    
    # Check for indexer API keys
    local indexer_count=0
    [[ -n "$NZBGEEK_API" ]] && ((indexer_count++))
    [[ -n "$NZBFINDER_API" ]] && ((indexer_count++))
    [[ -n "$NZBSU_API" ]] && ((indexer_count++))
    [[ -n "$NZBPLANET_API" ]] && ((indexer_count++))
    
    if [[ $indexer_count -eq 0 ]]; then
        warning "No indexer API keys configured"
        info "Add indexer API keys to .env for better search results"
    else
        success "$indexer_count indexer(s) configured"
    fi
    
    return $errors
}

#=============================================================================
# Function: validate_dependencies
# Description: Validate required tools and dependencies
#
# Arguments:
#   None
#
# Returns:
#   0 - Dependencies validation passed
#   1 - Dependencies validation failed
#=============================================================================
validate_dependencies() {
    local errors=0
    
    info "Validating dependencies..."
    
    # Required tools
    local required_tools=(
        "curl:HTTP client for API calls"
        "jq:JSON processor for API responses"
        "docker:Container runtime"
    )
    
    for tool_desc in $required_tools; do
        local tool=${tool_desc%%:*}
        local desc=${tool_desc##*:}
        
        if command -v "$tool" >/dev/null 2>&1; then
            success "$tool available ($desc)"
        else
            error "$tool not found ($desc)"
            ((errors++))
        fi
    done
    
    # Optional but recommended tools
    local optional_tools=(
        "smartctl:Disk health monitoring"
        "netstat:Network port checking"
        "nslookup:DNS resolution testing"
    )
    
    for tool_desc in $optional_tools; do
        local tool=${tool_desc%%:*}
        local desc=${tool_desc##*:}
        
        if command -v "$tool" >/dev/null 2>&1; then
            success "$tool available ($desc)"
        else
            info "$tool not found ($desc) - optional but recommended"
        fi
    done
    
    return $errors
}

#=============================================================================
# Function: run_all_validations
# Description: Run all validation checks
#
# Arguments:
#   None
#
# Returns:
#   0 - All validations passed
#   1 - Some validations failed
#=============================================================================
run_all_validations() {
    local total_errors=0
    
    print "🔍 Usenet Media Stack Validation"
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Run all validation checks
    validate_docker || ((total_errors += $?))
    print ""
    
    validate_storage || ((total_errors += $?))
    print ""
    
    validate_network || ((total_errors += $?))
    print ""
    
    validate_config || ((total_errors += $?))
    print ""
    
    validate_dependencies || ((total_errors += $?))
    print ""
    
    # Summary
    print "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $total_errors -eq 0 ]]; then
        success "All validation checks passed! 🎉"
        info "System is ready for deployment"
        info "Run 'usenet setup' to deploy the media stack"
    else
        error "$total_errors validation issue(s) found"
        info "Fix the issues above before deployment"
        info "Run 'usenet validate --fix' to attempt automatic fixes"
    fi
    
    return $((total_errors > 0 ? 1 : 0))
}

##############################################################################
#                               MAIN FUNCTION                               #
##############################################################################

#=============================================================================
# Function: main
# Description: Main entry point for validation
#
# Arguments:
#   $@ - All command line arguments
#
# Returns:
#   Exit code from the executed validation
#=============================================================================
main() {
    local check_type="all"
    local verbose=false
    local quiet=false
    export FIX_ISSUES=false
    
    # Parse command line options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fix)
                FIX_ISSUES=true
                shift
                ;;
            --verbose|-v)
                verbose=true
                shift
                ;;
            --quiet|-q)
                quiet=true
                shift
                ;;
            --help|-h|help)
                show_validate_help
                return 0
                ;;
            all|docker|storage|network|config|dependencies)
                check_type="$1"
                shift
                ;;
            *)
                error "Unknown option: $1"
                show_validate_help
                return 1
                ;;
        esac
    done
    
    # Set verbosity
    if [[ "$verbose" == "true" ]]; then
        export VERBOSE=true
    elif [[ "$quiet" == "true" ]]; then
        export QUIET=true
    fi
    
    case "$check_type" in
        all)
            run_all_validations
            ;;
        docker)
            validate_docker
            ;;
        storage)
            validate_storage
            ;;
        network)
            validate_network
            ;;
        config)
            validate_config
            ;;
        dependencies)
            validate_dependencies
            ;;
        *)
            error "Unknown validation check: $check_type"
            show_validate_help
            return 1
            ;;
    esac
}

# Run if called directly
if [[ "${ZSH_ARGZERO:-${(%):-%x}}" == "${0}" ]]; then
    main "$@"
fi

# vim: set ts=4 sw=4 et tw=80: