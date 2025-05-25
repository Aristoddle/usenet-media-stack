# CLI Reference

The Usenet Media Stack CLI follows a modern subcommand architecture inspired by tools like `git`, `docker`, and `pyenv`. All functionality is accessible through the single `usenet` entry point.

## Command Structure

```bash
usenet <subcommand> [action] [options]
```

## Core Commands

| Command | Description | Quick Example |
|---------|-------------|---------------|
| [`deploy`](./deploy) | Full stack deployment | `usenet deploy --auto` |
| [`storage`](./storage) | Hot-swappable drive management | `usenet storage list` |
| [`hardware`](./hardware) | GPU optimization & drivers | `usenet hardware optimize` |
| [`services`](./services) | Service management & logs | `usenet services status` |
| [`backup`](./backup) | Configuration backup/restore | `usenet backup create` |
| [`validate`](./validate) | System health checks | `usenet validate --fix` |

## Global Options

```bash
--verbose     # Detailed output for debugging
--quiet       # Suppress non-essential output
--dry-run     # Show what would be done without executing
--yes         # Auto-confirm all prompts
--profile X   # Use specific performance profile (light/balanced/high/dedicated)
```

## Quick Examples

::: code-group

```bash [Deployment]
# Interactive guided setup
usenet deploy

# Fully automated deployment
usenet deploy --auto

# Hardware-only optimization
usenet deploy --hardware-only
```

```bash [Storage Management]
# List all available drives
usenet storage list

# Add external drive to pool
usenet storage add /media/external

# Update service APIs with new storage
usenet storage sync
```

```bash [Hardware Optimization]
# Show GPU capabilities
usenet hardware list

# Auto-install optimal drivers
usenet hardware install-drivers

# Generate optimized configs
usenet hardware optimize --auto
```

:::

## Help System

The CLI features a comprehensive three-tier help system:

```bash
usenet help              # Main help screen
usenet help storage      # Component-specific help
usenet storage --help    # Action-specific help
```

## Legacy Compatibility

For backward compatibility, flag-based commands are supported with deprecation warnings:

```bash
# Legacy (deprecated)
usenet --storage discover

# Preferred
usenet storage list
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Command not found |
| 3 | Validation failure |
| 4 | Configuration error |
| 5 | Hardware/system issue |

## Next Steps

- Learn about [deployment workflows](./deploy)
- Explore [storage management](./storage)
- Optimize your [hardware setup](./hardware)