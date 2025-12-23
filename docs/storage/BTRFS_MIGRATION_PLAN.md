# btrfs Migration Plan: 10-Drive Architecture

> **Status**: Active
> **Created**: 2025-12-22
> **Target**: Convert all exFAT JBOD drives to btrfs with optimal NVMe settings

## Executive Summary

This plan migrates 9 external NVMe drives from exFAT to btrfs, using one drive as a swap/staging area. The internal NVMe is already btrfs and serves as the reference configuration.

## Current State

| Drive | Size | Used | Free | Use% | Content | Filesystem |
|-------|------|------|------|------|---------|------------|
| **Internal** | 7.3TB | 2.7TB | 4.7TB | 37% | Docker, EmuDeck, manga | btrfs ✓ |
| Fast_8TB_1 | 7.3TB | 7.1TB | 264GB | 97% | Movies_1/2/3 | exFAT |
| Fast_8TB_2 | 7.3TB | 7.2TB | 138GB | 99% | TV, Music | exFAT |
| Fast_8TB_3 | 7.3TB | 2.6TB | 4.8TB | 36% | EmuDeck backup* | exFAT |
| Fast_4TB_1 | 3.7TB | 3.4TB | 286GB | 93% | More_Movies | exFAT |
| Fast_4TB_2 | 3.7TB | 2.8TB | 913GB | 76% | More_TV | exFAT |
| Fast_4TB_3 | 3.7TB | 3.5TB | 195GB | 95% | More_Movies_3 | exFAT |
| Fast_4TB_4 | 3.7TB | 3.5TB | 211GB | 95% | More_Movies_2 | exFAT |
| Fast_4TB_5 | 3.7TB | 3.5TB | 209GB | 95% | TV | exFAT |

**Total**: ~52TB raw, ~45TB used

*Fast_8TB_3 contains clearable backup content (Emudeck/, Slow_2TB_Bak/, scripts)

## Hardware Specs

| Resource | Available | Optimization |
|----------|-----------|--------------|
| RAM | 78GB (53GB free) | rclone buffer cache |
| CPU | 16 cores (Ryzen 7 7840HS) | 64 parallel transfers |
| Swap | 39GB | Fallback for large ops |
| I/O | All NVMe | 3-5 GB/s theoretical |

## Target End State

- **All drives**: btrfs with `block-group-tree` feature
- **Mount options**: `noatime,compress=zstd:1,discard=async`
- **Names**: Preserved (Fast_8TB_1, Fast_8TB_2, etc.)
- **Data**: 100% intact
- **Utilization**: 60-75% per drive after rebalancing

## Migration Strategy

### Phase 0: Prepare Swap Drive (Fast_8TB_3)

**Duration**: ~30 minutes

#### 0.1 Verify Backup Redundancy

```bash
# Compare active vs backup EmuDeck
echo "=== Active EmuDeck (Internal) ==="
ls -la /var/mnt/fast8tb/Emudeck/
du -sh /var/mnt/fast8tb/Emudeck/

echo "=== Backup EmuDeck (Fast_8TB_3) ==="
ls -la /run/media/deck/Fast_8TB_3/Emudeck/
```

#### 0.2 Clear Fast_8TB_3

```bash
# Archive unique scripts first
mkdir -p /var/mnt/fast8tb/archived_scripts
cp /run/media/deck/Fast_8TB_3/*.sh /var/mnt/fast8tb/archived_scripts/ 2>/dev/null

# Clear (ONLY after confirming redundancy!)
rm -rf /run/media/deck/Fast_8TB_3/Emudeck/
rm -rf /run/media/deck/Fast_8TB_3/Slow_2TB_Bak/
rm -rf /run/media/deck/Fast_8TB_3/Media/
rm -rf /run/media/deck/Fast_8TB_3/smart_rom_scraper_project/
rm -f /run/media/deck/Fast_8TB_3/*.sh

# Verify
df -h /run/media/deck/Fast_8TB_3
```

#### 0.3 Format to btrfs

```bash
# Unmount
sudo umount /run/media/deck/Fast_8TB_3

# Format with optimal NVMe options
sudo mkfs.btrfs -f -L Fast_8TB_3 -O block-group-tree /dev/nvme2n1p2

# Mount with optimal options
sudo mkdir -p /run/media/deck/Fast_8TB_3
sudo mount -o noatime,compress=zstd:1,discard=async /dev/nvme2n1p2 /run/media/deck/Fast_8TB_3
sudo chown deck:deck /run/media/deck/Fast_8TB_3

# Verify
df -Th /run/media/deck/Fast_8TB_3
```

### Phase 1: Migrate Fast_8TB_2 (99% Full)

**Duration**: ~8-10 hours round-trip

#### 1.1 Copy to Swap

```bash
rclone copy /run/media/deck/Fast_8TB_2/ /run/media/deck/Fast_8TB_3/ \
  --transfers 64 \
  --checkers 32 \
  --buffer-size 256M \
  --progress \
  --stats 10s \
  --log-file=/tmp/migrate_8tb2.log \
  --log-level INFO

# Verify file counts
echo "Source:" && find /run/media/deck/Fast_8TB_2 -type f | wc -l
echo "Dest:"   && find /run/media/deck/Fast_8TB_3 -type f | wc -l
```

#### 1.2 Format Fast_8TB_2

```bash
sudo umount /run/media/deck/Fast_8TB_2
sudo mkfs.btrfs -f -L Fast_8TB_2 -O block-group-tree /dev/nvme5n1p2
sudo mount -o noatime,compress=zstd:1,discard=async /dev/nvme5n1p2 /run/media/deck/Fast_8TB_2
sudo chown deck:deck /run/media/deck/Fast_8TB_2
```

#### 1.3 Copy Back

```bash
rclone copy /run/media/deck/Fast_8TB_3/ /run/media/deck/Fast_8TB_2/ \
  --transfers 64 \
  --checkers 32 \
  --buffer-size 256M \
  --progress \
  --stats 10s

# Verify and clear swap
find /run/media/deck/Fast_8TB_2 -type f | wc -l
rm -rf /run/media/deck/Fast_8TB_3/*
```

### Phase 2: Migrate Fast_8TB_1 (97% Full)

**Duration**: ~8-10 hours round-trip

Same process as Phase 1:

```bash
# Copy to swap
rclone copy /run/media/deck/Fast_8TB_1/ /run/media/deck/Fast_8TB_3/ \
  --transfers 64 --checkers 32 --buffer-size 256M --progress

# Format
sudo umount /run/media/deck/Fast_8TB_1
sudo mkfs.btrfs -f -L Fast_8TB_1 -O block-group-tree /dev/nvme3n1p2
sudo mount -o noatime,compress=zstd:1,discard=async /dev/nvme3n1p2 /run/media/deck/Fast_8TB_1
sudo chown deck:deck /run/media/deck/Fast_8TB_1

# Copy back
rclone copy /run/media/deck/Fast_8TB_3/ /run/media/deck/Fast_8TB_1/ \
  --transfers 64 --checkers 32 --buffer-size 256M --progress

# Clear swap
rm -rf /run/media/deck/Fast_8TB_3/*
```

### Phase 3: 4TB Drives (Sequential)

**Duration**: ~3-4 hours each (5 drives = 15-20 hours total)

```bash
# Device mapping (verify with lsblk before each operation!)
# Fast_4TB_1 = nvme8n1p1
# Fast_4TB_2 = nvme2n1p2
# Fast_4TB_3 = nvme6n1p2
# Fast_4TB_4 = nvme7n1p1
# Fast_4TB_5 = nvme9n1p2

for DRIVE in Fast_4TB_1 Fast_4TB_2 Fast_4TB_3 Fast_4TB_4 Fast_4TB_5; do
  echo "=== Processing $DRIVE ==="

  # Migrate to swap
  rclone copy /run/media/deck/$DRIVE/ /run/media/deck/Fast_8TB_3/ \
    --transfers 64 --checkers 32 --buffer-size 256M --progress

  # Get device (VERIFY THIS!)
  DEV=$(lsblk -no NAME,MOUNTPOINT | grep "$DRIVE" | awk '{print "/dev/"$1}')
  echo "Device for $DRIVE: $DEV"
  read -p "Confirm device is correct? [y/N] " confirm
  [[ "$confirm" != "y" ]] && continue

  # Format
  sudo umount /run/media/deck/$DRIVE
  sudo mkfs.btrfs -f -L $DRIVE -O block-group-tree $DEV
  sudo mount -o noatime,compress=zstd:1,discard=async $DEV /run/media/deck/$DRIVE
  sudo chown deck:deck /run/media/deck/$DRIVE

  # Migrate back
  rclone copy /run/media/deck/Fast_8TB_3/ /run/media/deck/$DRIVE/ \
    --transfers 64 --checkers 32 --buffer-size 256M --progress

  # Clear swap
  rm -rf /run/media/deck/Fast_8TB_3/*

  echo "=== $DRIVE complete ==="
done
```

### Phase 4: Update fstab

```bash
# Get UUIDs
sudo blkid | grep btrfs

# Add to /etc/fstab (adjust UUIDs):
# UUID=xxxxx /run/media/deck/Fast_8TB_1 btrfs noatime,compress=zstd:1,discard=async,nofail 0 0
# UUID=xxxxx /run/media/deck/Fast_8TB_2 btrfs noatime,compress=zstd:1,discard=async,nofail 0 0
# ... etc for all drives
```

## rclone Optimization

| Setting | Value | Rationale |
|---------|-------|-----------|
| `--transfers` | 64 | Parallel file transfers (scale with 16 cores) |
| `--checkers` | 32 | 25-50% of transfers |
| `--buffer-size` | 256M | Use available RAM |
| `--multi-thread-streams` | 4 | Per-file parallelism for large files |

For aggressive mode (monitor system load):
```bash
--transfers 128 --checkers 64 --buffer-size 512M
```

## btrfs Options Rationale

| Option | Why |
|--------|-----|
| `-O block-group-tree` | Reduces mount time from minutes to seconds on 8TB drives |
| `noatime` | Reduces write amplification (no access time updates) |
| `compress=zstd:1` | Level 1 is optimal for NVMe (higher levels CPU-bound) |
| `discard=async` | Async TRIM for SSD health without blocking I/O |

## Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Power loss mid-copy | `rclone copy` is idempotent and resumable |
| Data corruption | Run `rclone check` after each phase |
| Wrong drive formatted | Triple-check device with `lsblk` before `mkfs` |
| Symlinks break | Mount points and names stay same |

## Verification Commands

```bash
# File count comparison
find /source -type f | wc -l
find /dest -type f | wc -l

# Deep verification with checksums
rclone check /source /dest --one-way

# btrfs filesystem health
sudo btrfs scrub start /run/media/deck/Fast_8TB_X
sudo btrfs scrub status /run/media/deck/Fast_8TB_X
```

## Timeline Estimate

| Phase | Duration | Notes |
|-------|----------|-------|
| Phase 0 | 30 min | Clear + format swap |
| Phase 1 | 8-10 hrs | Fast_8TB_2 round-trip |
| Phase 2 | 8-10 hrs | Fast_8TB_1 round-trip |
| Phase 3 | 15-20 hrs | 5x 4TB drives |
| Phase 4 | 30 min | fstab updates |
| **Total** | ~36-48 hrs | Can run overnight |

## Sources

- [mkfs.btrfs Documentation](https://btrfs.readthedocs.io/en/latest/mkfs.btrfs.html)
- [Btrfs ArchWiki](https://wiki.archlinux.org/title/Btrfs)
- [Btrfs NVMe Best Practices](https://bbs.archlinux.org/viewtopic.php?id=294472)
- [rclone Global Flags](https://rclone.org/flags/)
- [rclone Transfers vs Checkers](https://forum.rclone.org/t/transfers-vs-checker-ratio/142)
