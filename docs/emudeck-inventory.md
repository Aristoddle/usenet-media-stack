# EmuDeck Emulation Stack Inventory

**System**: Bazzite (Fedora Atomic) on Steam Deck hardware
**Date**: December 29, 2025 (Verified by deep audit)
**EmuDeck Version**: 2.5.0 (early branch)
**Storage**: 8TB NVMe (fast8tb) + MergerFS pool
**Total Emulation Storage**: 1.4 TB

---

## Verified Audit Results (December 29, 2025)

This inventory was verified by a comprehensive bottom-up audit. File counts reflect actual ROM files verified against reality, not estimates.

---

## Installation Overview

### EmuDeck Location
- **App**: `/var/home/deck/Applications/EmuDeck.AppImage`
- **Config**: `/var/home/deck/.config/EmuDeck/`
- **Settings**: `/var/home/deck/.config/EmuDeck/settings.sh`
- **Emulation Root**: `/var/mnt/fast8tb/Emudeck/Emulation/`

### Directory Structure
```
/var/mnt/fast8tb/Emudeck/Emulation/
├── bios/           # BIOS files for all systems
├── docs/           # Documentation
├── hdpacks/        # HD texture packs (NES)
├── mods/           # Game modifications
├── patches/        # ROM patches
├── roms/           # Game ROMs by system
├── save-backups/   # Save state backups
├── saves/          # Active save files
├── storage/        # Emulator data storage
├── texturepacks/   # HD texture packs
└── tools/          # Steam ROM Manager, scraped media
```

---

## Installed Emulators

### Flatpak Emulators
| Emulator | App ID | Version | Systems |
|----------|--------|---------|---------|
| RetroArch | org.libretro.RetroArch | 1.22.2 | Multi-system |
| Dolphin | org.DolphinEmu.dolphin-emu | 2509 | GameCube, Wii |
| RPCS3 | net.rpcs3.RPCS3 | 0.0.38 | PlayStation 3 |
| PPSSPP | org.ppsspp.PPSSPP | 1.19.3 | PSP |
| melonDS | net.kuribo64.melonDS | 1.1 | Nintendo DS |
| xemu | app.xemu.xemu | 0.8.121 | Xbox |
| ScummVM | org.scummvm.ScummVM | 2.9.1 | Point-and-click |
| PrimeHack | io.github.shiiion.primehack | 1.0.8a | Metroid Prime |
| Supermodel | com.supermodel3.Supermodel | 0.3a | Model 3 Arcade |

### AppImage Emulators
| Emulator | Location | Systems |
|----------|----------|---------|
| Azahar | ~/Applications/azahar.AppImage | Nintendo 3DS |
| Cemu | ~/Applications/Cemu.AppImage | Wii U |
| DuckStation | ~/Applications/DuckStation.AppImage | PlayStation 1 |
| ES-DE | ~/Applications/ES-DE.AppImage | Frontend |
| mGBA | ~/Applications/mGBA.AppImage | GBA |
| PCSX2 | ~/Applications/pcsx2-Qt.AppImage | PlayStation 2 |
| RPCS3 | ~/Applications/rpcs3.AppImage | PlayStation 3 |
| ShadPS4 | ~/Applications/Shadps4-qt.AppImage | PlayStation 4 |
| Steam ROM Manager | (symlinked) | ROM organization |

### Standalone Applications
- **BigPEmu**: ~/Applications/BigPEmu/ (Atari Jaguar)
- **Vita3K**: ~/Applications/Vita3K/ (PS Vita)
- **Pegasus**: ~/Applications/pegasus-fe (Frontend)

---

## ROM Collections by System

### Storage Summary (by size) - VERIFIED

| System | Size | ROM Count | Format | Verified |
|--------|------|-----------|--------|----------|
| Switch | 399 GB | 59 games | NSP, XCI | Dec 29 |
| Wii U | 221 GB | 35 WUX files | WUX | Dec 29 |
| PS2 | 139 GB | 49 games | CHD (38), ISO (8), ZSO (3) | Dec 29 |
| 3DS | 68 GB | 7 games | CIA | Dec 29 |
| PSX | 58 GB | 200 games | ZIP (Redump) | Dec 29 |
| GameCube | 44 GB | 52 games | RVZ (50), ISO (2) | Dec 29 |
| Neo Geo CD | 43 GB | varies | CHD | Dec 29 |
| NDS | 33 GB | varies | NDS | Dec 29 |
| Wii | 28 GB | 6 games | RVZ, WBFS, ISO | Dec 29 |
| New 3DS | 22 GB | 27 games | CIA | Dec 29 |
| Dreamcast | 20 GB | varies | CHD | Dec 29 |
| GBA | 19 GB | varies | GBA | Dec 29 |
| Xbox | 17 GB | varies | ISO | Dec 29 |
| PS3 | 16 GB | 4 games | ISO | Dec 29 |
| MAME | 16 GB | varies | ZIP | Dec 29 |
| Arcade | 11 GB | varies | ZIP | Dec 29 |
| Naomi | 9 GB | varies | ZIP | Dec 29 |
| PSP | 8.7 GB | 7 games | ISO, CHD | Dec 29 |
| N64 | 5.6 GB | 300+ games | N64, Z64 | Dec 29 |
| Genesis | 5.5 GB | varies | ZIP | Dec 29 |
| SNES | 4.5 GB | varies | SFC, SMC | Dec 29 |
| GBC | 4.1 GB | varies | GBC | Dec 29 |
| Saturn | 3.9 GB | varies | CHD | Dec 29 |
| NES | 3.6 GB | varies | NES | Dec 29 |
| Atomiswave | 2.9 GB | varies | ZIP | Dec 29 |
| Neo Geo | 2.6 GB | varies | ZIP | Dec 29 |
| PS Vita | 0 | 0 games | (empty) | Dec 29 |

### Notable Collections (Verified December 29, 2025)

#### PlayStation 2 (49 titles, 139 GB)
Mixed format (38 CHD, 8 ISO, 3 ZSO), includes:
- Devil May Cry trilogy (1, 2-DVD1/DVD2, 3 Special Edition)
- Dragon Quest VIII
- Final Fantasy X, X-2, XII
- God of War 1 & 2
- God Hand, Odin Sphere, Viewtiful Joe 2
- Kingdom Hearts 1, 2, Re:Chain of Memories, KH2 Final Mix [English Patch]
- Persona 3 FES, Persona 4 (both ISO)
- Shin Megami Tensei: Nocturne, Digital Devil Saga 1-2, Raidou 1-2
- Sly Cooper trilogy
- Xenosaga trilogy (I single disc, II/III dual disc)
- Ico, Shadow of the Colossus (ZSO), Okami
- Onimusha 1, 3, Killer7

#### Nintendo Switch (59 games, 399 GB)
Mixed NSP/XCI format with updates and DLC:
- Animal Crossing: New Horizons (with DLC)
- Bayonetta 1 & 2
- Fire Emblem: Three Houses, Engage
- Super Mario 3D All-Stars, 3D World + Bowser's Fury
- Super Mario Odyssey, Wonder, RPG, Bros Wonder
- Paper Mario: Origami King, Thousand Year Door
- Zelda: Breath of the Wild, Tears of the Kingdom, Skyward Sword HD, Link's Awakening
- Pokemon: Scarlet, Violet, Legends Arceus, Brilliant Diamond, Sword, Let's Go Pikachu
- Hades, Hollow Knight, Cuphead, Dead Cells, Sea of Stars
- Luigi's Mansion 2 HD, 3
- Xenoblade Chronicles 1, 2, 3
- Metroid Dread, Red Dead Redemption

#### Wii U (35 WUX files, 221 GB)
WUX format, includes:
- Zelda: Breath of the Wild, Wind Waker HD, Twilight Princess HD, Hyrule Warriors
- Bayonetta 1 & 2
- Mario Kart 8, Mario Party 10, Mario Tennis Ultra Smash
- Donkey Kong Country: Tropical Freeze
- Pikmin 3, Splatoon, Star Fox Zero
- Captain Toad, Kirby Rainbow Curse, Paper Mario Color Splash
- New Super Mario Bros U, New Super Luigi U

#### GameCube (52 titles, 44 GB)
Efficient format (50 RVZ, 2 ISO):
- Metroid Prime 1 & 2
- Zelda: Wind Waker, Twilight Princess (both ISO)
- Metal Gear Solid: The Twin Snakes (2 disc)
- Fire Emblem: Path of Radiance
- Paper Mario: TTYD
- Pokemon Colosseum, XD, Box Ruby/Sapphire
- Resident Evil series (1, 2, 3, 4, Zero, Code Veronica X)
- Luigi's Mansion
- Mario Party 4, 5, 6, 7
- Mario Golf, Power Tennis, Superstar Baseball, Strikers
- Star Fox Adventures, Assault
- Viewtiful Joe trilogy
- F-Zero GX, Kirby Air Ride, WarioWare, Wario World

#### 3DS/New 3DS (34 games total, 90 GB)
3DS (7 games): Pokemon Sun/Moon, Ultra Sun/Moon, Monster Hunter 4U, RE Revelations, DK Country Returns 3D
N3DS (27 games): Fire Emblem Awakening, Metroid Samus Returns, Pokemon X/Y/OR/AS, Kingdom Hearts DDD, various Mario titles

#### PSP (7 games, 8.7 GB)
- Final Fantasy Tactics: War of the Lions
- Persona 3 Portable, SMT Persona
- Tactics Ogre: Let Us Cling Together
- Valkyria Chronicles 2 & 3 (JP with English patch)
- Boku no Natsuyasumi 4 (JP)

#### Wii (6 games, 28 GB)
- Fire Emblem: Radiant Dawn
- Disney Epic Mickey
- No More Heroes 1 & 2
- Zelda: Skyward Sword
- Xenoblade Chronicles

---

## BIOS Status

### Complete BIOS Sets
| System | Status | Files |
|--------|--------|-------|
| PlayStation 1 | OK | scph1001.bin, scph5500-5502.bin, scph7001.bin, scph101.bin |
| PlayStation 2 | OK | Multiple SCPH3xxxx.bin versions with NVM/MEC |
| PlayStation 3 | OK | PS3UPDAT.PUP (206 MB) |
| Dreamcast | OK | dc_boot.bin, dc_flash.bin + NAOMI/Atomiswave BIOS |
| Nintendo DS | OK | bios7.bin, bios9.bin, firmware.bin, DSi files |
| Saturn | OK | saturn_bios.bin |
| Neo Geo | OK | neogeo.zip |
| Game Boy/Color/Advance | OK | gb_bios.bin, gbc_bios.bin, gba_bios.bin |
| 3DO | OK | panafz1.bin, panafz10.bin, goldstar.bin |
| PC Engine | OK | syscard3.pce |
| Nintendo Switch | OK | prod.keys, title.keys, firmware in /bios/ryujinx/ |
| PS Vita | OK | PSP2UPDAT.PUP, PSVUPDAT.PUP |
| Xbox | OK | mcpx_1.0.bin, Complex_4627.bin |

### System-Specific BIOS Directories
- `/bios/3ds/` - Azahar system files
- `/bios/azahar/` - Symlink to Azahar sysdata
- `/bios/dc/` - Dreamcast/NAOMI/Atomiswave
- `/bios/gc/` - GameCube IPL
- `/bios/ps2/` - PlayStation 2 BIOS + patches
- `/bios/ryujinx/` - Switch keys and firmware
- `/bios/switch/` - Duplicate Switch keys

---

## Enhancements & Mods

### Wii U - Zelda: Breath of the Wild
**Location**: `/Emulation/mods/wiiu/zelda_botw/`

Ready-to-use Cemu Graphic Packs:
- 60 FPS (FPS++ mod)
- Resolution scaling (1080p to 8K)
- Shadow resolution (up to 300%)
- Clarity GFX (enhanced colors)
- Enhanced reflections
- Anisotropic filtering 16x
- Durability cheats (2x, 5x, 10x, infinite)
- Draw distance improvements

**Documentation**:
- `WHATS_READY_NOW.md` - Quick start guide
- `INSTALLATION_GUIDE.md` - Full setup
- `MARIO_MODS_STATUS.md` - Mario mod availability

### Texture Packs
**Location**: `/Emulation/texturepacks/`
- `/texturepacks/azahar/` - 3DS texture packs

### SNES Patches
**Location**: `/Emulation/patches/SNES/`
- Translation patches
- Improvement patches

---

## RetroAchievements Integration

**Status**: Enabled
**User**: J3lanzone
**Hardcore Mode**: Disabled

Configured in RetroArch for supported systems:
- NES, SNES, Genesis, Game Boy/GBC/GBA
- N64, PS1, Saturn, NDS
- MAME, Neo Geo, PC Engine
- And more...

---

## Configuration Highlights

### Resolution Settings
| Emulator | Resolution |
|----------|------------|
| Dolphin | 4K (1440P in JSON) |
| PCSX2 | 4K (1440P in JSON) |
| DuckStation | 4K (720P in JSON) |
| RPCS3 | 4K (1440P in JSON) |
| Ryujinx | 4K |
| PPSSPP | 1080P |
| Cemu | 1440P |
| xemu | 1080P |
| Azahar | 4K (1440P in JSON) |
| melonDS | 1440P |
| Vita3K | 1080P |

### Controller Layout
- **Type**: ABXY (Nintendo-style)
- **Bezels**: Enabled for RetroArch
- **Autosave**: Enabled

### Cloud Sync
- **Provider**: Emudeck-cloud
- **Status**: Active

---

## ROM Naming Observations

### Good Naming (No-Intro/Redump style)
- N64: `007 - GoldenEye (USA).n64` - Full No-Intro set, excellent naming
- GameCube: `Fire Emblem - Path of Radiance (US).rvz` - Clean Redump naming
- PS2: `Shin Megami Tensei - Nocturne (USA).chd` - Proper Redump naming
- Wii U: `Legend of Zelda, The - Breath of the Wild (USA) (En,Fr,Es)-018.wux` - Good Redump style

### Mixed Naming Conventions (Needs Work)
- **Switch**: Mixed bracket notation `[Title ID][Version]` - varies wildly
  - Example: `Animal Crossing New Horizons [01006F8002326000][v1441792](1G+1U+3D)(MOD11.0.0).xci`
  - Some have source site tags: `(nsw2u.com)` embedded
- **PS2**: Inconsistent case/underscore usage in some titles
  - `Killer7_PS2_NTSC-U.iso` vs `Kingdom Hearts (US).chd`
- **PSP**: Mixed underscore naming
  - `Final_Fantasy_Tactics_War_of_the_Lions.iso`

### Identified Issues

#### Switch Duplicates (Same Game, Multiple Versions)
- **Mario Tennis Aces**: Base NSP + Updated XCI + folder with base+update
- **Link's Awakening**: Two versions (apostrophe vs no apostrophe)
- **Super Mario 3D World**: XCI + multiple NSP files

#### Cross-Platform Duplicates (Space Optimization Opportunities)
- **Bayonetta 1 & 2**: Both Switch AND Wii U versions (~45 GB duplicated)
- **Breath of the Wild**: Both Switch AND Wii U versions (~26 GB duplicated)
- **DK Tropical Freeze**: Both Switch AND Wii U versions (~20 GB duplicated)

### Recommendations
1. **Switch cleanup**: Remove duplicate versions, standardize to XCI with updates
2. **Cross-platform**: Consider keeping only the better emulated version (usually newer console)
3. **PS2**: Convert remaining 8 ISOs and 3 ZSOs to CHD for consistency
4. **GameCube**: Convert 2 remaining ISOs to RVZ
5. **Wii**: Convert 3 ISOs to RVZ for consistency

---

## Storage Optimization Opportunities

### Format Conversion Candidates
| Current Format | Target | Potential Savings |
|----------------|--------|-------------------|
| PS2 ISOs | CHD | 40-60% compression |
| GameCube ISOs | RVZ | Already converted mostly |
| Wii U WUX | Already compressed | N/A |
| PSX ZIPs | CHD | Would need extraction first |

### Duplicate Reduction
- PSX Redump set includes all regions - filtering to USA could save ~40 GB
- Some games exist on multiple platforms (Bayonetta on Switch + Wii U)

---

## Missing or Incomplete

### Systems with Few ROMs (Acquisition Opportunities)
| System | Count | Status | Priority |
|--------|-------|--------|----------|
| PS Vita | 0 | Vita3K installed, NO ROMS | HIGH |
| PS4 | 0 | ShadPS4 in early stages | LOW |
| Wii | 6 | Missing many essentials | MEDIUM |
| 3DS | 7 | Missing many essentials | MEDIUM |
| PSP | 7 | Good selection, room for more | LOW |

### PS Vita Priority Acquisitions (Empty System!)
Vita3K is fully installed and configured but has zero ROMs. Priority titles:
1. **Persona 4 Golden** - Best version of P4
2. **Gravity Rush** - Vita exclusive (later ported)
3. **Soul Sacrifice Delta** - Excellent action RPG
4. **Freedom Wars** - Monster Hunter style
5. **Danganronpa 1 & 2** - Visual novel essentials
6. **Trails of Cold Steel 1 & 2** - JRPG essentials
7. **Muramasa Rebirth** - Beautiful action game
8. **Ys VIII: Lacrimosa of Dana** - Action JRPG
9. **Dragon's Crown** - Vanillaware classic
10. **Odin Sphere Leifthrasir** - Vanillaware classic

### HD Texture Pack Status
| System | Status | Location | Notes |
|--------|--------|----------|-------|
| NES | Empty | `/bios/HdPacks/` | Directory exists, no packs installed |
| N64 | Empty | `/bios/Mupen64plus/cache/` | Only cache dir, no actual packs |
| GameCube | Not installed | - | Dolphin supports, high potential |
| Wii | Not installed | - | Dolphin supports, high potential |
| 3DS | Exists | `/texturepacks/azahar/` | Some packs present |

### HD Texture Pack Priority Acquisitions
1. **N64 - Zelda OoT/MM** - Classic enhancement
2. **N64 - Paper Mario** - Beautiful upscale available
3. **N64 - Mario 64** - Essential upgrade
4. **GameCube - Wind Waker** - HD textures exist
5. **GameCube - Twilight Princess** - HD textures available
6. **GameCube - Metroid Prime** - Community packs available

---

## Quick Reference Paths

```
# ROMs
/var/mnt/fast8tb/Emudeck/Emulation/roms/[system]/

# BIOS
/var/mnt/fast8tb/Emudeck/Emulation/bios/

# Saves
/var/mnt/fast8tb/Emudeck/Emulation/saves/

# Mods
/var/mnt/fast8tb/Emudeck/Emulation/mods/

# Tools
/var/mnt/fast8tb/Emudeck/Emulation/tools/

# EmuDeck Config
/var/home/deck/.config/EmuDeck/

# Emulator Configs (Flatpak)
/var/home/deck/.var/app/[app.id]/

# AppImages
/var/home/deck/Applications/
```

---

## Management Tools

Three new shell scripts have been created for EmuDeck management:

### emudeck-health-check.sh
**Location**: `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/emudeck-health-check.sh`

Full system verification including:
- ROM inventory by system (actual game files, not all files)
- BIOS verification against required files
- Storage analysis
- Duplicate detection (cross-platform and same-platform)
- Format optimization opportunities
- HD texture pack status

```bash
# Quick check
./emudeck-health-check.sh

# Skip slow duplicate detection
./emudeck-health-check.sh --quick

# JSON output for automation
./emudeck-health-check.sh --json
```

### rom-organizer.sh
**Location**: `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/rom-organizer.sh`

Standardizes ROM naming to No-Intro/Redump conventions:
- Removes URL encoding
- Removes source site tags
- Standardizes spacing
- Identifies naming issues

```bash
# Generate report only
./rom-organizer.sh --report

# Dry run for specific system
./rom-organizer.sh --system switch --dry-run

# Apply changes (use with caution)
./rom-organizer.sh --system switch
```

### rom-integrity-checker.sh
**Location**: `/var/home/deck/Documents/Code/media-automation/usenet-media-stack/tools/rom-integrity-checker.sh`

Verifies ROM integrity:
- File size validation
- Bad dump pattern detection
- Archive integrity (zip/7z)
- Corrupt file detection

```bash
# Quick check (default)
./rom-integrity-checker.sh

# Check specific system
./rom-integrity-checker.sh --system ps2

# Full hash verification (slow)
./rom-integrity-checker.sh --full

# Export to JSON
./rom-integrity-checker.sh --export results.json
```

---

## Next Steps / Wishlist

### High Priority
1. **PS Vita ROMs** - Vita3K is installed but completely empty (see acquisition list above)
2. **N64 HD Textures** - Zelda, Mario 64, Paper Mario packs
3. **Switch Cleanup** - Remove duplicate versions, reclaim ~20+ GB

### Medium Priority
4. **Wii Library** - Only 6 games, missing many essentials
5. **3DS Library** - Only 7 games on base 3DS
6. **GameCube HD Textures** - Dolphin supports high-res packs

### Format Conversion Tasks
- Convert 8 PS2 ISOs to CHD
- Convert 3 PS2 ZSOs to CHD
- Convert 2 GameCube ISOs to RVZ
- Convert 3 Wii ISOs to RVZ

### Organization Tasks
- Run `rom-organizer.sh --system switch --dry-run` and review
- Remove Switch duplicate versions after review
- Consider cross-platform duplicate cleanup (Bayonetta, BOTW, etc.)

---

*Generated by EmuDeck Deep Audit Agent*
*Verified: December 29, 2025*
*Tools Created: emudeck-health-check.sh, rom-organizer.sh, rom-integrity-checker.sh*
