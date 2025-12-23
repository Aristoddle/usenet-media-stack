# Design Philosophy

**Why this stack is built the way it is — and why it's different from enterprise solutions**

## The Fundamental Insight

This system is designed for **home users who iteratively grow their storage**, not enterprises planning rack deployments. That one distinction drives every architectural decision.

```
ENTERPRISE MINDSET              HOME USER REALITY
┌────────────────────┐          ┌────────────────────┐
│ "I need 40TB"      │          │ "I bought a drive" │
│ "Plan the RAID"    │          │ "Oh cool, another" │
│ "Buy it all now"   │          │ "Found one on sale" │
│ "Configure once"   │          │ "This one's bigger" │
└────────────────────┘          └────────────────────┘
        ↓                               ↓
  ZFS/UnRAID pool                JBOD + btrfs-per-drive
  (fixed, pooled)                (flexible, independent)
```

## Core Principle: JBOD Over Pools

**JBOD** (Just a Bunch of Disks) means each drive is an independent filesystem. No pooling. No striping. No parity.

### Why Not ZFS Pools?

ZFS is incredible technology — for enterprises. Here's why it's often wrong for home users:

| ZFS Pool Assumption | Home User Reality |
|---------------------|-------------------|
| Buy all drives upfront | Acquire drives over years, opportunistically |
| Same capacity per vdev | "I got a 4TB on sale, then an 8TB, then..." |
| Never remove drives | "I want to take this drive camping" |
| Plan redundancy from day 1 | "Maybe I'll add a second drive someday" |
| Expansion = new vdevs | "Wait, I can't just add a bigger drive?" |

**The ZFS rigidity problem**: A ZFS raidz vdev cannot:
- Add a single drive to expand capacity
- Replace a drive with a larger one and reclaim the extra space (without rebuilding)
- Remove a drive from the array without data loss

You're locked into the geometry you chose at creation time.

### Why JBOD Works Better

With JBOD + btrfs-per-drive:
- **Buy any drive, any time** — plug it in, mount it, done
- **Take drives anywhere** — yank an exFAT drive, use it on your laptop, bring it back
- **No rigid pool geometry** — each drive is independent
- **Transparent organization** — "TV is on the 8TB, Movies on the 4TB" is simple mental model
- **Graceful degradation** — one drive fails, you lose one drive's worth of data (not the whole pool)

```
JBOD MENTAL MODEL

Drive 1: 8TB             Drive 2: 4TB             Drive 3: 4TB
┌────────────────┐       ┌────────────────┐       ┌────────────────┐
│ /tv            │       │ /movies        │       │ /music         │
│ /downloads     │       │ /books         │       │ /backups       │
└────────────────┘       └────────────────┘       └────────────────┘

Loss of Drive 2 = You lose movies and books
                  TV, downloads, music, backups = FINE
```

### Trade-offs We Accept

**What we give up:**
- No automatic redundancy (solution: cloud backup, important stuff on multiple drives)
- No pooled capacity ("I need 12TB contiguous" requires manual balancing)
- Manual organization (you decide what goes where)

**What we gain:**
- Complete flexibility
- Zero lock-in
- Hot-swap anything
- Simple mental model
- Use any drive from any source

## Core Principle: Gaming-First, NAS-Attached

This isn't an UnRAID box that can run VMs for gaming. This is a **gaming PC that happens to have storage attached**.

### The Bazzite Choice

```
UnRAID/TrueNAS                    Bazzite
┌──────────────────────────────┐  ┌──────────────────────────────┐
│         NAS OS               │  │      Fedora Atomic OS        │
│  ┌────────────────────────┐  │  │  ┌────────────────────────┐  │
│  │     VM Hypervisor      │  │  │  │    Steam/Gamescope     │  │
│  │  ┌──────────────────┐  │  │  │  │  (NATIVE, no VM)       │  │
│  │  │   Gaming VM      │  │  │  │  └────────────────────────┘  │
│  │  │   (Windows?)     │  │  │  │                              │
│  │  │   GPU passthru   │  │  │  │  ┌────────────────────────┐  │
│  │  └──────────────────┘  │  │  │  │   Docker containers    │  │
│  └────────────────────────┘  │  │  │   (Arr stack, Plex)    │  │
└──────────────────────────────┘  │  └────────────────────────────┘
                                  └──────────────────────────────┘
```

### Why Native Gaming Matters

| Feature | UnRAID VM Gaming | Bazzite Native |
|---------|------------------|----------------|
| Latency | +2-5ms (hypervisor overhead) | Native |
| GPU utilization | ~95% (passthrough loss) | 100% |
| Proton/Gamescope | Requires Windows VM | Native Linux |
| Steam Deck mode | No | Yes (Gamescope session) |
| Setup complexity | GPU IOMMU groups, vfio-pci | Just works |
| Emulation | RetroArch in Windows VM | Native EmuDeck |

**Bottom line**: If gaming is primary, start with a gaming OS. Attach storage around it.

## Core Principle: Btrfs for Data Integrity

Every drive in this system uses btrfs with these mount options:

```bash
-o noatime,compress=zstd:1,discard=async
```

### Why Btrfs?

1. **Checksums** — Every block is checksummed. Silent corruption is detected.
2. **Compression** — zstd:1 gives ~20-40% space savings on video with near-zero CPU cost
3. **Copy-on-Write** — Snapshots are instant and free (same data, different pointer)
4. **Modern kernel support** — Linux 6.1+ with btrfs-progs 6.1+ is rock-solid

### Why Not ext4?

ext4 is reliable, but:
- No checksums (corruption goes undetected)
- No compression (waste space)
- No native snapshots (need LVM complexity)

For media storage where you're writing large files and reading them repeatedly, btrfs' trade-offs make sense.

## Core Principle: Docker for Services, Native for Gaming

```
┌─────────────────────────────────────────────────────────────────┐
│                        BAZZITE HOST                            │
│                                                                │
│  ┌─────────────────────────┐  ┌─────────────────────────────┐  │
│  │    NATIVE PROCESSES     │  │    DOCKER CONTAINERS        │  │
│  │                         │  │                             │  │
│  │  • Steam                │  │  • Sonarr, Radarr, Prowlarr │  │
│  │  • Gamescope            │  │  • SABnzbd, Transmission    │  │
│  │  • EmuDeck              │  │  • Plex, Komga, Kavita      │  │
│  │  • Sunshine streaming   │  │  • Overseerr, Bazarr        │  │
│  │                         │  │  • Portainer, Netdata       │  │
│  └─────────────────────────┘  └─────────────────────────────┘  │
│                                                                │
│  Gaming = bare metal performance                               │
│  Services = isolated, reproducible, restartable                │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Split?

**Native gaming** because:
- Zero latency overhead
- Full GPU access (no containerized graphics)
- Steam/Proton expect native environment
- Gamescope needs direct DRM access

**Containerized services** because:
- Isolation (one bad app doesn't take down others)
- Reproducibility (docker-compose.yml is the config)
- Easy updates (pull new image, restart)
- No dependency conflicts

## The Resulting System

```
Your Workflow:
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   ACQUIRE          PROCESS           SERVE            ENJOY     │
│                                                                  │
│   ┌─────────┐      ┌─────────┐      ┌─────────┐      ┌────────┐ │
│   │ Prowlarr│─────▶│ SABnzbd │─────▶│ Sonarr/ │─────▶│  Plex  │ │
│   │ indexes │      │downloads│      │ Radarr  │      │ streams│ │
│   └─────────┘      └─────────┘      │ imports │      └────────┘ │
│                                     └─────────┘           │     │
│                                          │                │     │
│                                          ▼                ▼     │
│                                     ┌─────────────────────────┐ │
│                                     │   JBOD Storage          │ │
│                                     │   /mnt/drive1/tv        │ │
│                                     │   /mnt/drive2/movies    │ │
│                                     │   /mnt/drive3/music     │ │
│                                     └─────────────────────────┘ │
│                                                                  │
│   Meanwhile:  ┌─────────────────────────────────────────────┐   │
│               │ Steam + Gamescope + EmuDeck running native  │   │
│               │ Full GPU, full performance, same machine    │   │
│               └─────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

## Summary

| Decision | Choice | Why |
|----------|--------|-----|
| Storage architecture | JBOD (independent drives) | Flexibility for organic growth |
| Filesystem | btrfs per drive | Checksums, compression, CoW |
| Base OS | Bazzite (Fedora Atomic) | Native gaming + immutable core |
| Gaming | Native Steam/Gamescope | Zero-overhead, full GPU |
| Services | Docker containers | Isolation, reproducibility |
| Pooling | None (manual organization) | No lock-in, hot-swap anything |
| Redundancy | Cloud backup, not RAID | Accept single-drive failure risk |

**This is a gaming machine that runs a media server, not a NAS that tries to game.**

---

*Built for home users who accumulate drives over time and want to play games without compromise.*
