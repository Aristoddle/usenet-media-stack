# EmuDeck Emulation Stack Inventory

**System**: Bazzite (Fedora Atomic) on Steam Deck hardware
**Date**: December 29, 2025
**EmuDeck Version**: 2.5.0 (early branch)
**Storage**: 8TB NVMe (fast8tb) + MergerFS pool

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

### Storage Summary (by size)
| System | Size | ROM Count | Format |
|--------|------|-----------|--------|
| Switch | 399 GB | ~70 | NSP, XCI |
| Wii U | 221 GB | ~46 | WUX |
| PS2 | 139 GB | ~52 | CHD, ISO, ZSO |
| 3DS | 68 GB | ~59 | CIA, 3DS |
| PSX | 58 GB | ~226 | ZIP (Redump) |
| GameCube | 44 GB | ~57 | RVZ, ISO |
| Neo Geo CD | 43 GB | ~82 | CHD |
| NDS | 33 GB | ~485 | NDS |
| Wii | 28 GB | ~12 | RVZ, WBFS |
| New 3DS | 22 GB | ~31 | CIA |
| Dreamcast | 20 GB | ~61 | CHD |
| GBA | 19 GB | ~4,477 | GBA |
| Xbox | 17 GB | ~12 | ISO |
| PS3 | 16 GB | ~4 | ISO |
| MAME | 16 GB | ~2,561 | ZIP |
| Arcade | 11 GB | ~2,418 | ZIP |
| Naomi | 9 GB | ~69 | ZIP |
| PSP | 8.7 GB | ~10 | ISO, CHD |
| N64 | 5.6 GB | ~332 | N64, Z64 |
| Genesis | 5.5 GB | varies | ZIP |
| SNES | 4.5 GB | ~5,119 | SFC, SMC |
| GBC | 4.1 GB | ~4,231 | GBC |
| Saturn | 3.9 GB | ~7 | CHD |
| NES | 3.6 GB | ~7,011 | NES |
| Atomiswave | 2.9 GB | ~37 | ZIP |
| Neo Geo | 2.6 GB | ~162 | ZIP |

### Notable Collections

#### PlayStation 2 (52 titles, 139 GB)
High-quality CHD format, includes:
- Devil May Cry trilogy
- Dragon Quest VIII
- Final Fantasy X, X-2, XII
- God of War 1 & 2
- Kingdom Hearts series
- Persona 3 FES, Persona 4
- Shin Megami Tensei: Nocturne, Digital Devil Saga 1-2, Raidou 1-2
- Sly Cooper trilogy
- Xenosaga trilogy
- Ico, Shadow of the Colossus, Okami

#### Nintendo Switch (70+ titles, 399 GB)
Mixed NSP/XCI format with updates and DLC:
- Animal Crossing: New Horizons (with DLC)
- Bayonetta 1 & 2
- Fire Emblem: Three Houses, Engage
- Super Mario 3D All-Stars/World
- Super Mario Odyssey
- Zelda: Breath of the Wild, Skyward Sword HD
- Pokemon Scarlet/Violet
- Hades, Hollow Knight, Cuphead
- Luigi's Mansion 2 HD, 3

#### Wii U (46 titles, 221 GB)
WUX format, includes:
- Zelda: Breath of the Wild, Wind Waker HD, Twilight Princess HD
- Bayonetta 1 & 2
- Mario Kart 8
- Donkey Kong Country: Tropical Freeze
- Xenoblade Chronicles X

#### GameCube (57 titles, 44 GB)
Efficient RVZ format:
- Metroid Prime 1 & 2
- Zelda: Wind Waker, Twilight Princess
- Metal Gear Solid: The Twin Snakes
- Fire Emblem: Path of Radiance
- Paper Mario: TTYD
- Pokemon Colosseum, XD
- Resident Evil series
- Luigi's Mansion
- Mario Party 4-7

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
- N64: `007 - GoldenEye (USA).n64`
- GameCube: `Fire Emblem - Path of Radiance (US).rvz`
- PS2: `Shin Megami Tensei - Nocturne (USA).chd`

### Mixed Naming Conventions
- PSX: URL-encoded filenames from full Redump set
- Switch: Mixed bracket notation `[Title ID][Version]`
- Some ISOs use underscores instead of spaces

### Recommendations
1. PSX set has many regional duplicates - could filter to USA-only for space savings
2. Some PS2 games use inconsistent formats (ISO vs CHD vs ZSO)
3. Switch ROMs use varied naming schemes - could standardize

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

### Systems with Few ROMs
| System | Count | Notes |
|--------|-------|-------|
| Xbox 360 | 8 | Limited emulation support |
| PS Vita | 0 | Vita3K installed but no ROMs |
| PS4 | 0 | ShadPS4 in early stages |

### Enhancement Opportunities
- N64 HD texture packs (many available)
- GameCube HD texture packs (Dolphin supports)
- 3DS HD texture packs (via Azahar)
- Wii HD texture packs (Dolphin supports)

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

## Next Steps / Wishlist

### High Priority
1. **PS Vita ROMs** - Vita3K is installed but empty
2. **N64 HD Textures** - Many classics would benefit
3. **GameCube Textures** - Dolphin supports high-res packs

### Enhancement Research
- Widescreen patches for 4:3 games
- 60fps patches for 30fps games
- Translation patches for Japan-only titles

### Organization Tasks
- Standardize Switch ROM naming
- Convert remaining PS2 ISOs to CHD
- Clean up PSX duplicates (region filtering)

---

*Generated by EmuDeck Deep Enrichment Agent*
*Last Updated: December 29, 2025*
