# Storage Management

Hot-swappable JBOD architecture with universal drive support.

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