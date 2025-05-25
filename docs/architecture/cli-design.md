# CLI Design Architecture

The Usenet Media Stack CLI embodies modern command-line interface design principles, following patterns established by industry-leading tools like Git, Docker, and Pyenv while maintaining professional standards taught by Stan Eisenstat.

## Design Philosophy

### Pure Subcommand Architecture

**Inspiration**: Following `pyenv` patterns rather than traditional flag-based tools

```bash
# WORKFLOW TOOL (our model) - Action-oriented
usenet storage list              # ✓ Clear action verb
usenet hardware optimize         # ✓ Component + action
usenet services restart          # ✓ Intuitive workflow

# vs CONFIGURATION TOOL - Status-oriented  
systemctl --status docker        # Different paradigm
networkctl --list               # Status-focused
```

### Three-Tier Help System

```bash
# Level 1: Main help
usenet help                      # Overview of all components

# Level 2: Component help  
usenet help storage              # Storage-specific actions
usenet storage --help           # Same as above

# Level 3: Action help
usenet storage list --help       # Detailed action documentation
```

## Command Structure

### Primary Architecture

```
usenet <component> <action> [options]
│      │           │        │
│      │           │        └─ Flags and arguments
│      │           └─ Action verb (list, add, optimize, etc.)
│      └─ Component (storage, hardware, services, etc.)
└─ Entry point
```

### Component Mapping

| Component | Purpose | Key Actions |
|-----------|---------|-------------|
| `deploy` | Orchestrated deployment | `deploy`, `deploy --auto` |
| `storage` | Hot-swappable JBOD | `list`, `add`, `remove`, `sync` |
| `hardware` | GPU optimization | `list`, `optimize`, `install-drivers` |
| `services` | Service management | `list`, `start`, `stop`, `logs` |
| `backup` | Configuration management | `create`, `restore`, `list` |
| `validate` | System health | `validate`, `validate --fix` |

## Argument Parsing Implementation

### Main Entry Point (`usenet`)

```bash
#!/usr/bin/env zsh
# Modern CLI with pure subcommand routing

main() {
    # Handle immediate exit cases first
    case "${1:-}" in
        --version|-v) show_version; exit 0 ;;
        --help|-h|help|"") show_help "${2:-}"; exit 0 ;;
    esac
    
    # Route to component handlers
    local command="$1"
    shift
    route_command "$command" "$@"
}

route_command() {
    local command="$1"
    shift
    
    case "$command" in
        # Pure subcommands (preferred)
        storage)   exec "${COMMANDS_DIR}/storage.zsh" "$@" ;;
        hardware)  exec "${COMMANDS_DIR}/hardware.zsh" "$@" ;;
        services)  exec "${COMMANDS_DIR}/services.zsh" "$@" ;;
        
        # Legacy compatibility (deprecated)
        --storage) 
            warning "Flag-based syntax deprecated. Use: usenet storage $*"
            exec "${COMMANDS_DIR}/storage.zsh" "$@" 
            ;;
            
        # Error handling
        *)
            error "Unknown command: $command"
            echo "Available commands: storage, hardware, services, backup, deploy, validate"
            echo "Run 'usenet help' for detailed information"
            exit 2
            ;;
    esac
}
```

### Component Handler Pattern

Each component follows a consistent pattern:

```bash
#!/usr/bin/env zsh
# Component: storage.zsh

# Initialize environment
source "$(dirname "$0")/../core/init.zsh"

main() {
    local action="${1:-}"
    shift 2>/dev/null || true
    
    case "$action" in
        list|discover)          # Support new + legacy verbs
            [[ "$action" == "discover" ]] && 
                warning "Action 'discover' deprecated, use 'list'"
            discover_all_drives "$@"
            ;;
        add)     add_storage_drive "$@" ;;
        remove)  remove_storage_drive "$@" ;;
        sync)    sync_service_apis "$@" ;;
        status)  show_storage_status "$@" ;;
        --help|help|"")
            show_storage_help
            ;;
        *)
            error "Unknown storage action: $action"
            echo "Available actions: list, add, remove, sync, status"
            echo "Run 'usenet storage --help' for details"
            exit 2
            ;;
    esac
}

main "$@"
```

## Action Verb Consistency

### Standardized Action Verbs

Following industry patterns across all components:

| Verb | Purpose | Examples |
|------|---------|----------|
| `list` | Show available items | `storage list`, `hardware list`, `services list` |
| `add` | Add item to system | `storage add /path`, `services add custom-app` |
| `remove` | Remove item | `storage remove /path`, `services remove app` |
| `start` | Start services/processes | `services start sonarr` |
| `stop` | Stop services/processes | `services stop jellyfin` |
| `restart` | Restart services | `services restart --all` |
| `status` | Show current state | `storage status`, `services status` |
| `sync` | Synchronize/update | `storage sync`, `services sync` |
| `optimize` | Improve performance | `hardware optimize --auto` |
| `install` | Install components | `hardware install-drivers` |

### Legacy Verb Support

Maintaining backward compatibility:

```bash
case "$action" in
    list|discover)  # New verb: list, Legacy: discover
        if [[ "$action" == "discover" ]]; then
            warning "Action 'discover' deprecated, use 'list' instead"
        fi
        discover_all_drives "$@"
        ;;
    status|show)    # New verb: status, Legacy: show
        if [[ "$action" == "show" ]]; then
            warning "Action 'show' deprecated, use 'status' instead"  
        fi
        show_current_status "$@"
        ;;
esac
```

## Help System Architecture

### Multi-Level Help Implementation

```bash
show_help() {
    local component="${1:-}"
    
    case "$component" in
        "")
            show_main_help
            ;;
        storage|hardware|services|backup|deploy|validate)
            show_component_help "$component"
            ;;
        *)
            error "No help available for: $component"
            echo "Available components: storage, hardware, services, backup, deploy, validate"
            exit 1
            ;;
    esac
}

show_main_help() {
    cat << 'EOF'
Usenet Media Stack - Professional Hot-Swap JBOD Media Automation

USAGE:
    usenet <command> <action> [options]

COMMANDS:
    deploy      Orchestrated deployment with optimization
    storage     Hot-swappable JBOD drive management  
    hardware    GPU optimization and driver installation
    services    19-service management and monitoring
    backup      Configuration backup and restore
    validate    System health checks and troubleshooting

EXAMPLES:
    usenet deploy --auto                 # Fully automated deployment
    usenet storage list                  # Show available drives
    usenet hardware optimize --auto      # Generate optimized configs
    usenet services status               # Check service health
    usenet backup create                 # Create configuration backup
    usenet validate --fix                # Fix common issues

Use 'usenet help <command>' for detailed information about a specific command.
EOF
}
```

### Component-Specific Help

```bash
show_component_help() {
    local component="$1"
    
    case "$component" in
        storage)
            cat << 'EOF'
STORAGE MANAGEMENT:
    Hot-swappable JBOD drive management with cross-platform support

ACTIONS:
    list                     List all available storage devices
    add <path>              Add drive to media pool
    remove <path>           Remove drive from pool  
    sync                    Update service APIs with current pool
    status                  Show current pool configuration

EXAMPLES:
    usenet storage list                    # Discover available drives
    usenet storage add /media/external     # Add USB drive to pool
    usenet storage sync                    # Update Sonarr/Radarr APIs
    usenet storage status                  # Show pool summary

OPTIONS:
    --interactive           Use TUI for drive selection
    --dry-run              Show what would be done
    --force                Skip safety checks
EOF
            ;;
    esac
}
```

## Error Handling Architecture

### Smart Error Messages

```bash
error_with_suggestions() {
    local error_msg="$1"
    local command="$2"
    
    error "$error_msg"
    
    # Provide context-aware suggestions
    case "$command" in
        storag*|stora*)
            echo "Did you mean: usenet storage list?"
            ;;
        hardwar*|gpu*)
            echo "Did you mean: usenet hardware list?"
            ;;
        service*|status*)
            echo "Did you mean: usenet services list?"
            ;;
    esac
    
    echo "Run 'usenet help' for available commands"
}
```

### Validation and Auto-Fix

```bash
validate_arguments() {
    local component="$1"
    local action="$2"
    
    case "$component" in
        storage)
            case "$action" in
                add)
                    [[ -z "$3" ]] && {
                        error "Storage path required"
                        echo "Usage: usenet storage add <path>"
                        echo "Example: usenet storage add /media/external"
                        exit 1
                    }
                    [[ ! -d "$3" ]] && {
                        error "Path does not exist: $3"
                        echo "Available drives:"
                        usenet storage list
                        exit 1
                    }
                    ;;
            esac
            ;;
    esac
}
```

## Completion System Architecture

### Zsh Completion Implementation

```bash
# completions/_usenet
#compdef usenet

_usenet() {
    local context state line
    typeset -A opt_args
    
    _arguments \
        '1: :_usenet_commands' \
        '*: :_usenet_subcommand_args'
}

_usenet_commands() {
    local commands=(
        'deploy:Orchestrated deployment with optimization'
        'storage:Hot-swappable JBOD drive management'
        'hardware:GPU optimization and driver installation'
        'services:19-service management and monitoring'
        'backup:Configuration backup and restore'
        'validate:System health checks and troubleshooting'
        'help:Show help information'
    )
    _describe 'commands' commands
}

_usenet_subcommand_args() {
    case $words[2] in
        storage)
            _usenet_storage_actions
            ;;
        hardware)
            _usenet_hardware_actions
            ;;
        services)
            _usenet_services_actions
            ;;
    esac
}

_usenet_storage_actions() {
    local actions=(
        'list:List all available storage devices'
        'add:Add drive to media pool'
        'remove:Remove drive from pool'
        'sync:Update service APIs with current pool'
        'status:Show current pool configuration'
    )
    _describe 'storage actions' actions
}
```

### Context-Aware Completions

```bash
# Complete available drives for 'add' action
_usenet_storage_add() {
    local available_drives
    available_drives=($(usenet storage list --parseable 2>/dev/null | grep -v "^ACTIVE"))
    _describe 'available drives' available_drives
}

# Complete active drives for 'remove' action  
_usenet_storage_remove() {
    local active_drives
    active_drives=($(usenet storage status --parseable 2>/dev/null | grep "^ACTIVE"))
    _describe 'active drives' active_drives
}
```

## Backward Compatibility

### Legacy Flag Support

```bash
# Support old flag-based syntax with deprecation warnings
case "$1" in
    --storage)
        warning "Flag syntax deprecated. Use: usenet storage ${*:2}"
        shift
        exec "${COMMANDS_DIR}/storage.zsh" "$@"
        ;;
    --hardware)
        warning "Flag syntax deprecated. Use: usenet hardware ${*:2}"
        shift  
        exec "${COMMANDS_DIR}/hardware.zsh" "$@"
        ;;
esac
```

### Migration Guidance

```bash
show_migration_help() {
    cat << 'EOF'
MIGRATION FROM v1.x TO v2.x:

Old Syntax → New Syntax:
usenet --storage discover     → usenet storage list
usenet --hardware detect     → usenet hardware list
usenet --backup create       → usenet backup create
usenet status                → usenet services status

The old syntax still works but shows deprecation warnings.
Update your scripts to use the new subcommand syntax.
EOF
}
```

## Configuration Integration

### Environment Loading

```bash
# lib/core/init.zsh - Zero circular dependencies
load_configuration() {
    # Load environment from .env
    [[ -f "${PROJECT_ROOT}/.env" ]] && source "${PROJECT_ROOT}/.env"
    
    # Set intelligent defaults
    export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-usenet-stack}"
    export COMPOSE_FILE="${PROJECT_ROOT}/docker-compose.yml"
    
    # Component-specific configuration
    case "$COMPONENT" in
        storage)
            export STORAGE_CONFIG="${PROJECT_ROOT}/config/storage.conf"
            ;;
        hardware)
            export HARDWARE_PROFILE="${PROJECT_ROOT}/config/hardware_profile.conf"
            ;;
    esac
}
```

### Global Options

```bash
# Global options available across all components
parse_global_options() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose|-v)
                export VERBOSE=1
                ;;
            --dry-run|-n)
                export DRY_RUN=1
                ;;
            --yes|-y)
                export AUTO_CONFIRM=1
                ;;
            --profile)
                export PERFORMANCE_PROFILE="$2"
                shift
                ;;
            --quiet|-q)
                export QUIET=1
                ;;
            --)
                shift
                break
                ;;
            *)
                break
                ;;
        esac
        shift
    done
}
```

## Performance Considerations

### Fast Command Dispatch

```bash
# Minimal overhead for command routing
route_command() {
    # Direct exec to avoid subprocess overhead
    case "$1" in
        storage)   exec "${COMMANDS_DIR}/storage.zsh" "${@:2}" ;;
        hardware)  exec "${COMMANDS_DIR}/hardware.zsh" "${@:2}" ;;
        services)  exec "${COMMANDS_DIR}/services.zsh" "${@:2}" ;;
    esac
}
```

### Lazy Loading

```bash
# Only load components when needed
load_component() {
    local component="$1"
    
    # Load component-specific libraries only when required
    case "$component" in
        storage)
            source "${LIB_DIR}/storage/discovery.zsh"
            source "${LIB_DIR}/storage/management.zsh"
            ;;
        hardware)
            source "${LIB_DIR}/hardware/detection.zsh"
            source "${LIB_DIR}/hardware/optimization.zsh"
            ;;
    esac
}
```

## Testing Architecture

### CLI Testing Framework

```bash
# Test framework for CLI components
test_cli_component() {
    local component="$1"
    local action="$2"
    local expected_output="$3"
    
    # Capture output
    local output
    output=$(usenet "$component" "$action" 2>&1)
    
    # Validate output
    if [[ "$output" == *"$expected_output"* ]]; then
        echo "✓ Test passed: $component $action"
        return 0
    else
        echo "❌ Test failed: $component $action"
        echo "Expected: $expected_output"
        echo "Got: $output"
        return 1
    fi
}

# Integration tests
test_cli_integration() {
    test_cli_component "storage" "list" "DISCOVERED STORAGE"
    test_cli_component "hardware" "list" "HARDWARE CAPABILITIES"
    test_cli_component "services" "list" "SERVICES STATUS"
}
```

## Quality Standards

### Stan Eisenstat's Principles Applied

1. **80-character lines** - All CLI code respects terminal width
2. **Function contracts** - Every function documented with purpose, args, returns
3. **Error handling** - Comprehensive error messages with helpful suggestions
4. **Clear naming** - Function and variable names explain their purpose

```bash
# Example: Function contract following Stan's standards
# Purpose: Discover all mounted storage devices and classify by type
# Args: None
# Returns: 0 on success, 1 on error
# Output: Formatted list of storage devices
discover_all_drives() {
    local drives_found=0
    
    info "Discovering storage devices..."
    
    # Scan for local drives
    while IFS= read -r line; do
        process_drive_entry "$line" || continue
        ((drives_found++))
    done < <(find_mounted_drives)
    
    if [[ $drives_found -eq 0 ]]; then
        warning "No storage devices found"
        return 1
    fi
    
    success "Found $drives_found storage devices"
    return 0
}
```

## Related Documentation

- [Architecture Overview](./index) - System design principles
- [Storage Architecture](./storage) - JBOD implementation details
- [Hardware Architecture](./hardware) - GPU optimization system
- [Service Architecture](./services) - 19-service integration