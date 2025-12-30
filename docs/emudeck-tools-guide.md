# EmuDeck Tools Guide

**Created**: December 29, 2025
**Location**: `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/`

This guide covers the three EmuDeck management tools created during the deep audit.

---

## Overview

| Tool | Purpose | Speed |
|------|---------|-------|
| `emudeck-health-check.sh` | Full system verification | Fast (--quick) / Medium (full) |
| `rom-organizer.sh` | Naming standardization | Fast |
| `rom-integrity-checker.sh` | File integrity verification | Fast (--quick) / Slow (--full) |

---

## emudeck-health-check.sh

### Purpose
Comprehensive health check of the entire EmuDeck installation, including ROM inventory, BIOS verification, storage analysis, and duplicate detection.

### Usage

```bash
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/

# Full check (includes duplicate detection)
./emudeck-health-check.sh

# Quick check (skips slow operations)
./emudeck-health-check.sh --quick

# JSON output for automation
./emudeck-health-check.sh --json
```

### What It Checks

1. **Directory Structure**: Verifies roms/, bios/, saves/ directories exist
2. **ROM Inventory**: Counts actual game ROMs per system (not total files)
3. **BIOS Verification**: Checks required BIOS files for each system
4. **Storage Analysis**: Shows total usage and top 10 systems by size
5. **Format Optimization**: Identifies ISOs that could be compressed
6. **Duplicate Detection**: Finds cross-platform and same-platform duplicates
7. **HD Texture Status**: Checks for installed texture packs

### Example Output

```
=== EmuDeck Health Check ===
Root: /var/mnt/fast8tb/Emudeck/Emulation
Date: 2025-12-29 15:30:00

=== Directory Structure ===
[OK] roms directory exists
[OK] bios directory exists
[OK] saves directory exists

=== ROM Inventory (Major Systems) ===
switch      :   59 ROMs (399G)
wiiu        :   35 ROMs (221G)
ps2         :   49 ROMs (139G)
...

=== BIOS Status ===
[OK] psx BIOS complete
[OK] ps2 BIOS complete
[WARN] psvita has no ROMs - Vita3K is installed

=== Summary ===
[WARN] Warnings: 5
```

### Environment Variables

- `EMUDECK_ROOT`: Override default emulation root (default: `/var/mnt/fast8tb/Emudeck/Emulation`)

---

## rom-organizer.sh

### Purpose
Standardizes ROM filenames to No-Intro/Redump naming conventions. Identifies and optionally fixes naming issues.

### Usage

```bash
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/

# Generate report only (safe, no changes)
./rom-organizer.sh --report

# Dry run for specific system
./rom-organizer.sh --system switch --dry-run

# Process all systems (dry run)
./rom-organizer.sh --all --dry-run

# Actually apply changes (use with caution!)
./rom-organizer.sh --system switch

# Convert to lowercase
./rom-organizer.sh --system switch --lowercase --dry-run
```

### What It Fixes

1. **URL Encoding**: `%20` -> space, `%28` -> `(`, etc.
2. **Underscores**: `Game_Name` -> `Game Name`
3. **Double Spaces**: Collapses to single space
4. **Site Tags**: Removes `(nsw2u.com)`, `(ziperto)`, etc.
5. **Trailing Spaces**: Removes spaces before extension

### Supported Systems

- switch, wiiu, ps2, psx, psp, gc, wii, 3ds, n3ds, nds, n64, dreamcast, saturn

### Example Output (--report)

```
=== ROM Organization Report ===
Date: 2025-12-29 15:30:00

switch: 59 files
  - URL encoded: 3
  - With underscores: 5

ps2: 49 files
  - With underscores: 8

=== Summary ===
Total files with potential issues: 16

Run with --system SYSTEM --dry-run to see proposed changes
```

### Safety

- Always use `--dry-run` first to preview changes
- Changes are irreversible - back up if unsure
- Report mode (`--report`) never modifies files

---

## rom-integrity-checker.sh

### Purpose
Verifies ROM file integrity, checking for corruption, bad dumps, and size anomalies.

### Usage

```bash
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/

# Quick check (size/sanity only) - DEFAULT
./rom-integrity-checker.sh

# Check specific system
./rom-integrity-checker.sh --system ps2

# Full hash verification (SLOW - computes SHA1 for every file)
./rom-integrity-checker.sh --full

# Export results to JSON
./rom-integrity-checker.sh --export /tmp/results.json

# Combined
./rom-integrity-checker.sh --system gc --full --export gc-results.json
```

### What It Checks

1. **File Readability**: Can the file be read?
2. **File Size**: Within expected range for system?
3. **Bad Patterns**: Filename contains `[b]`, `bad dump`, `overdump`?
4. **Archive Integrity**: ZIP/7z files are valid?
5. **Hash Verification** (--full): Compute SHA1 for database comparison

### Size Validation Ranges

| System | Min Size | Max Size |
|--------|----------|----------|
| Switch | 100 MB | 32 GB |
| Wii U | 100 MB | 25 GB |
| PS2 | 500 MB | 8 GB |
| PS3 | 1 GB | 50 GB |
| PSX | 100 MB | 800 MB |
| GC | 100 MB | 2 GB |
| N64 | 1 MB | 64 MB |
| GBA | 0.1 MB | 32 MB |

### Bad Dump Patterns

Files matching these patterns are flagged:
- `[b]`, `[b1]`, `[b2]` - Bad dump
- `[o]`, `[o1]` - Overdump
- `[h]` - Hack
- `[p]` - Pirate
- `Trainer`, `+3T` - Trainer ROM
- `virus`, `trojan` - Malware indicators

### Example Output

```
ROM Integrity Checker
====================
Mode: Quick (size/sanity checks)

=== Checking: ps2 ===
[OK] Devil May Cry (US).chd
[OK] Dragon Quest VIII Journey of the Cursed King (US).chd
[WARN] Killer7_PS2_NTSC-U.iso - filename:underscores
[OK] Kingdom Hearts (US).chd
...
Checked 49 files in ps2

=== Summary ===
Total checked: 49
  OK: 45
  Warnings: 4
  Errors: 0
```

---

## Common Workflows

### Weekly Health Check

```bash
cd /var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/
./emudeck-health-check.sh --quick | tee ~/emudeck-health-$(date +%Y%m%d).log
```

### Before Adding New ROMs

```bash
# Check current state
./emudeck-health-check.sh --quick

# After adding ROMs, verify integrity
./rom-integrity-checker.sh --system [system]

# Check naming
./rom-organizer.sh --system [system] --dry-run
```

### Preparing for Storage Cleanup

```bash
# Generate full report
./emudeck-health-check.sh > health-report.txt

# Review duplicates section
grep -A 20 "Cross-Platform Duplicates" health-report.txt

# Review naming issues
./rom-organizer.sh --report
```

### Full Audit

```bash
# Complete verification
./emudeck-health-check.sh
./rom-integrity-checker.sh --full --export integrity.json
./rom-organizer.sh --report > naming-report.txt
```

---

## Extending the Tools

### Adding New System Support

In `emudeck-health-check.sh`, add to `ROM_EXTENSIONS`:
```bash
declare -A ROM_EXTENSIONS=(
    ...
    ["newsystem"]="ext1|ext2|ext3"
)
```

In `REQUIRED_BIOS`:
```bash
declare -A REQUIRED_BIOS=(
    ...
    ["newsystem"]="bios1.bin bios2.bin"
)
```

### Adding Size Validation

In `rom-integrity-checker.sh`, add to `SIZE_RANGES`:
```bash
declare -A SIZE_RANGES=(
    ...
    ["newsystem"]="min_mb:max_mb"
)
```

---

## Troubleshooting

### "Permission denied"

```bash
chmod +x emudeck-health-check.sh rom-organizer.sh rom-integrity-checker.sh
```

### "bc: command not found"

```bash
# On Fedora/Bazzite
sudo rpm-ostree install bc
```

### Slow Performance

- Use `--quick` for routine checks
- Avoid `--full` on large collections unless needed
- Target specific systems with `--system`

---

*Tools created by EmuDeck Deep Audit Agent*
*December 29, 2025*
