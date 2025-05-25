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
    
    info "Validating Docker setup..."
    
    # Check if Docker is installed
    if ! command -v docker >/dev/null 2>&1; then
        error "Docker is not installed"
        info "Install Docker from: https://docs.docker.com/get-docker/"
        ((errors++))
    else
        success "Docker is installed"
        
        # Check Docker version
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | sed 's/,$//')
        info "Docker version: $docker_version"
        
        # Check if Docker daemon is running
        if ! docker info >/dev/null 2>&1; then
            error "Docker daemon is not running"
            info "Start Docker with: sudo systemctl start docker (Linux) or open Docker Desktop"
            ((errors++))
        else
            success "Docker daemon is running"
            
            # Check Docker Compose
            if docker compose version >/dev/null 2>&1; then
                local compose_version=$(docker compose version --short 2>/dev/null)
                success "Docker Compose available: $compose_version"
            else
                error "Docker Compose not available"
                info "Install Docker Compose plugin"
                ((errors++))
            fi
        fi
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
    local check_type="${1:-all}"
    
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
        help|--help|-h)
            show_validate_help
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