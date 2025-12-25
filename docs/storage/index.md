# Storage Management

Hot-swappable JBOD architecture with universal drive support.

## Documentation

| Document | Purpose |
|----------|---------|
| [Architecture](/storage/architecture) | Complete mergerfs + btrfs design for travel-ready media server |
| [btrfs Migration Plan](/storage/BTRFS_MIGRATION_PLAN) | Migrating exFAT drives to btrfs |
| [Hot-Swap Procedures](/advanced/hot-swap) | Safely connecting/disconnecting drives |

## Supported Storage

- **ZFS/Btrfs**: Native filesystem support
- **Cloud Storage**: Dropbox, OneDrive, Google Drive
- **Network Storage**: NFS, Samba shares
- **External Drives**: USB, eSATA, Thunderbolt

## Quick Start

```bash
# Discover all available drives
./usenet --storage discover

# Interactive drive selection
./usenet --storage select

# Apply storage configuration
./usenet --storage apply
```

## Hot-Swap Workflow

1. Plug in new drive
2. Run `./usenet --storage discover`
3. Select drive in TUI
4. All services gain instant access

## Key Concepts

### mergerfs Pooling

mergerfs presents multiple drives as a single unified path:
- `/mnt/pool` appears as one filesystem
- Content automatically distributes across drives
- Hardlinks work within each underlying drive
- Graceful degradation when drives disconnect

See [Architecture](/storage/architecture) for complete configuration.

### btrfs Per-Drive

Each drive uses btrfs individually (not btrfs RAID):
- Checksums catch silent corruption
- zstd compression saves 20-40% on video
- Independent drives = flexible hot-swap
- No lock-in to pool geometry

### Travel Mode

The internal drive works standalone when external bays are disconnected:
- Books, comics, emulation travel with you
- Movies/TV stay on external (home-only)
- Services continue with reduced content