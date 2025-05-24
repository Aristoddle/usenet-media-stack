# Usenet Media Stack - Architecture Overview

## Unified Command Interface

The entire stack is managed through a single entry point with rich subcommands:

```bash
./usenet <command> [options]
```

### Available Commands

| Command | Description | Example |
|---------|-------------|---------|
| `setup` | Deploy and configure entire stack | `./usenet setup --test-only` |
| `manage` | Service management operations | `./usenet manage status` |
| `test` | Run various test suites | `./usenet test quick` |
| `validate` | Pre-deployment validation | `./usenet validate` |
| `creds` | Extract 1Password credentials | `./usenet creds` |
| `backup` | Backup configuration | `./usenet backup` |
| `restore` | Restore from backup | `./usenet restore <file>` |
| `update` | Update containers | `./usenet update` |

## Modular Organization

```
/home/joe/usenet/
├── usenet                    # Main unified entry point
├── one-click-setup.sh        # Full deployment script
├── manage.sh                 # Service management
├── modules/                  # Shared functionality
│   ├── api.sh               # API helper functions
│   ├── credentials.sh       # Credential management
│   └── services.sh          # Service configuration
├── scripts/                  # Supporting scripts
│   ├── configure-services.sh
│   ├── init-sabnzbd.sh
│   └── automated-full-test.py
└── tests/                    # Test suites
    ├── test-quick.sh
    ├── test-essential.sh
    └── test-full-stack.sh
```

## Key Design Principles

1. **Single Entry Point**: All operations go through `./usenet` command
2. **Modular Design**: Shared code in `modules/` directory
3. **Clear Separation**: Each script has a single responsibility
4. **Rich CLI**: Comprehensive argument parsing and help
5. **Test Integration**: Testing built into the main workflow

## Autocomplete Support

Bash completion is available for rich command-line experience:

```bash
# Install for current session
source usenet-completion.bash

# Install permanently (add to ~/.bashrc)
echo "source $HOME/usenet/usenet-completion.bash" >> ~/.bashrc
```

## Alternative Entry Points

While the unified `./usenet` command is recommended, individual scripts can still be called directly:

- `./one-click-setup.sh` - Direct deployment
- `./manage.sh` - Direct service management
- `./validate-deployment.sh` - Direct validation

## Command Examples

```bash
# Full deployment with tests
./usenet setup

# Test-only mode
./usenet setup --test-only

# Check all services
./usenet manage status

# View logs for specific service
./usenet manage logs prowlarr

# Run quick tests
./usenet test quick

# Run all tests
./usenet test all

# Backup configuration
./usenet backup

# Update all containers
./usenet update
```

## Benefits of This Architecture

1. **Discoverability**: Single command with clear subcommands
2. **Consistency**: Uniform interface for all operations
3. **Modularity**: Shared code reduces duplication
4. **Maintainability**: Clear structure makes updates easier
5. **Extensibility**: Easy to add new commands/features
6. **User-Friendly**: Autocomplete and help at every level