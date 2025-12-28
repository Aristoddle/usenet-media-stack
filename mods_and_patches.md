# Emulator Mods, Texture Packs, and Patches Guide

A comprehensive guide to well-regarded mods, texture packs, and patches for classic games on PCSX2, Dolphin, and other emulators.

---

## Table of Contents

1. [Persona 3 FES (PS2)](#persona-3-fes-ps2)
2. [Persona 4 (PS2)](#persona-4-ps2)
3. [Xenoblade Chronicles (Wii)](#xenoblade-chronicles-wii)
4. [Castlevania: Symphony of the Night (PSX)](#castlevania-symphony-of-the-night-psx)
5. [ICO (PS2)](#ico-ps2)
6. [Shadow of the Colossus (PS2)](#shadow-of-the-colossus-ps2)
7. [Kingdom Hearts Series (PS2)](#kingdom-hearts-series-ps2)
8. [General Resources](#general-resources)

---

## Persona 3 FES (PS2)

### Community Enhancement Pack (CEP) - RECOMMENDED

The P3F CEP is the definitive all-in-one modding solution for Persona 3 FES.

**Features:**
- Pre-configured PCSX2 emulator
- Aemulus Package Manager for easy mod management
- HD textures, combat rebalancing, improved textboxes
- Fully compatible with unmodded save data
- All mods individually toggleable

**Requirements:**
- Clean North American Persona 3 FES ISO (CRC: 94A82AAA)
- PCSX2 v1.7.5397 (last mod-supported build)

**Download Sources:**
- [P3F CEP Official Site](https://p3f.cep.one/)
- [GameBanana - P3F CEP](https://gamebanana.com/mods/50322)
- [GitHub Documentation](https://github.com/iisGmoney/P3F-CEP-docs)

---

### Undub Patch (Japanese Voice Audio)

Replaces English dub with original Japanese audio while keeping English text.

**Options:**
1. **Original BGM** - Standard Japanese audio replacement
2. **Remixed BGM** - Uses tracks from "Burn My Dread - Reincarnation" OST

**Download Sources:**
- [GameBanana - P3FES Undub (Aemulus Compatible)](https://gamebanana.com/mods/292547)
- [CDRomance - P3 FES Undub Pre-Patched ISO](https://cdromance.org/ps2-iso/shin-megami-tensei-persona-3-fes-usaundub/)

**Note:** The CEP requires an unmodified NA ISO for initial setup, but you can add the Japanese dub mod later via Aemulus.

---

### HD Texture Pack

AI upscaled textures for PCSX2.

**Features:**
- HD Personas, portraits, menus, fonts
- ~90% of textures upscaled
- Widescreen patch compatible
- UNDUB version compatible
- Main story: 100% complete | The Answer: 60% complete

**Installation:**
1. Download PCSX2 nightly build (v1.7.2404+)
2. Extract to: `PCSX2/textures/SLUS-21621/replacements`
3. Enable in Config > Graphics Settings > Advanced:
   - Load Texture: ON
   - Async Texture Loading: ON
4. SSD strongly recommended

**Download Sources:**
- [GBAtemp - P3 FES HD Remaster](https://gbatemp.net/threads/persona-3-fes-usa-hd-remaster.614009/)

---

### Widescreen & Quality Patches

**Widescreen Patch:**
- [GitHub - P3 FES Widescreen Patches for PCSX2](https://gist.github.com/LOuroboros/1b8768b4d349e16c8cebd7140f355790)

**Note:** The outdated built-in widescreen patches should be disabled; use the one provided with CEP or the GitHub link above.

---

### Additional Mods

- **Controllable Party Members Hack** - Control all party members instead of AI
  - [CDRomance - Controllable Characters Hack](https://cdromance.org/ps2-iso/persona-3-fes-controllable-characters-hack/)

**Modding Resources:**
- [Persona 3 FES Modding Guide](https://persona-3-fes-modding-guide.readthedocs.io/en/latest/)
- [ShrineFox - P3 FES Mods](https://shrinefox.com/browse?game=p3fes&type=mod)
- [GameBanana - P3FES Hub](https://gamebanana.com/games/8502)

---

## Persona 4 (PS2)

### HD Texture Pack - Panda Venom's Remaster

**Features:**
- HD UI and most textures
- NPC portraits and Personas upscaled 4x
- Missing: Some S.Link portraits, enemy textures, some 2D assets

**Installation:**
1. Download PCSX2 nightly build (v1.7.2404+)
2. Extract to: `PCSX2/textures/SLUS-21782/replacements`
3. Enable in Config > Graphics Settings > Advanced:
   - Load Texture: ON
   - Precache Texture: ON
4. SSD strongly recommended

**Download Sources:**
- [GBAtemp - Persona 4 HD Texture Pack Beta](https://gbatemp.net/threads/persona-4-hd-texture-pack-beta-by-panda_venom.609641/)

---

### HD Remaster (Widescreen)

A more recent HD texture pack with widescreen support.

**Status:** Posted December 2025

**Notes:** Some minor shadow glitches reported.

**Download Sources:**
- [GBAtemp - Persona 4 USA HD Remaster (Widescreen)](https://gbatemp.net/threads/persona-4-usa-hd-remaster-widescreen.620665/)

---

### Additional Resources

- [GameBanana - Persona 4 PS2 Hub](https://gamebanana.com/games/8761)
- [ShrineFox - P4 Mods](https://shrinefox.com/browse?game=p4&type=mod)

---

## Xenoblade Chronicles (Wii)

### HD Texture Pack v8.52 - RECOMMENDED

The definitive HD texture pack for Xenoblade Chronicles on Dolphin.

**Features:**
- All textures upscaled (128x128 -> 512x512, etc.)
- HD button icon packs available:
  - Wii Remote
  - Classic Controller
  - Xbox 360
  - PlayStation
- Runs 1080p-4K at 60fps on modern PCs

**Installation:**
1. Extract to: `Dolphin Emulator/Load/Textures/[GAME_ID]`
2. Enable in Graphics Settings > Advanced:
   - Load Custom Textures: ON
   - Prefetch Custom Textures: ON (recommended for performance)

**Download Sources:**
- [Dolphin Forums - Xenoblade Chronicles HD Texture Pack v8.52](https://forums.dolphin-emu.org/Thread-xenoblade-chronicles-hd-texture-pack-v8-52-august-21-2018)
- [GBAtemp - Xenoblade Chronicles 4K](https://gbatemp.net/threads/xenoblade-chronicles-4k-dolphin.388186/)

**Note:** The community consensus is that Xenoblade on Dolphin with HD textures looks substantially better than the Switch Definitive Edition in terms of graphical fidelity, though DE has QoL improvements and extra content.

---

### Dolphin Texture Pack Installation Guide

**Texture Folder Locations:**
- Windows: `C:\Users\<Username>\AppData\Roaming\Dolphin Emulator\Load\Textures\`
- macOS: `~/Library/Application Support/Dolphin/Load/Textures/`
- Linux: `~/.local/share/dolphin-emu/Load/Textures/`

---

## Castlevania: Symphony of the Night (PSX)

### Quality Hack - RECOMMENDED

Brings quality fixes to the original PlayStation version.

**Features:**
- Improved/expanded screen area for better visibility
- Improved menus
- Loading rooms marked as white on map
- Stereo sound enabled by default
- Bug fixes

**Requirements:**
- NTSC-U version only: SLUS-00067

**Download Sources:**
- [Romhacking.net - Quality Hack](https://www.romhacking.net/hacks/3606/)
- [Archive.org - Pre-Patched HardType + Quality Hack](https://archive.org/details/psx-castlevania-symphony-of-the-night)

---

### Ultimate Patch Fork (2025)

A fork of the Ultimate patch with restored PSX elements.

**Features:**
- Original PSX script and voice acting restored
- Title/loading screens reverted to "Castlevania: Symphony of the Night"
- Bug fixes from Ultimate v1.5 included
- Wrong weapon palettes fixed
- Missing Richter sprite frames added

**Released:** November 2, 2025 by DraculaX350

**Download Sources:**
- [GBAtemp - Ultimate Patch Fork Discussion](https://gbatemp.net/threads/castlevania-symphony-of-the-night-ultimate-patch-gets-an-updated-forked-hack-with-the-psx-title-and-script.676830/)

---

### Widescreen Patch

**Note:** True widescreen patches for SOTN can be problematic - they modify assets and stats, potentially making the game slower or buggier. Use with caution.

**Resources:**
- [GBAtemp - PS1 Widescreen Patches](https://gbatemp.net/threads/ps1-games-widescreen-patches.499905/)

---

### Other Notable Hacks

**Rondo of the Night (2024)**
- Play as Richter Belmont with full RPG elements (stats, leveling, equipment)
- Released: December 13, 2024
- [CDRomance - Rondo of the Night](https://cdromance.org/psx-iso/castlevania-rondo-of-the-night-hack/)

---

## ICO (PS2)

### HD Texture Pack - Panda Venom

**Features:**
- HD upscaled textures for PAL and NTSC versions
- Compatible with PCSX2 and NetherSX2 1.9

**Installation:**
1. Download PCSX2 nightly build (v1.7.4000+)
2. Extract to texture folder:
   - PAL: `PCSX2/textures/SCES-50760/replacements`
   - USA: `PCSX2/textures/SCUS-97113/replacements`
3. Enable in Config > Graphics Settings > Advanced:
   - Load Texture: ON
   - Async Texture Loading: ON
4. SSD recommended

**Known Issues:**
- Some texture flickering and lighting glitches
- PAL version may miss some upscaled text
- NTSC version has more issues than PAL (PAL recommended)

**Download Sources:**
- [GBAtemp - ICO USA/EU HD Remaster](https://gbatemp.net/threads/ico-usa-eu-hd-remaster.630164/)
- [GBAtemp - ICO HD Texture Both PAL and NTSC](https://gbatemp.net/threads/ico-hd-texture-both-pal-and-nstc-pcsx2-and-nethersx2-1-9.657834/)
- [Internet Archive - PCSX2 HD Texture Packs](https://archive.org/details/pcsx2-hd-texture-packs)

**Recommendation:** Use PAL version (SCES-50760) for best results with HD textures.

---

## Shadow of the Colossus (PS2)

### Origami Remaster by Sad Origami - RECOMMENDED

A hand-edited, faithful texture remaster preserving the original art style.

**Features:**
- 8K textures (downscaled to 4K) for colossi and environments
- Remade menus and subtitles with high-quality font
- Restored pixel art UI icons
- Enhanced Wander deterioration (mud, bruises)
- Enhanced menu contrast for accessibility
- Optimized performance with smart texture sizing
- Compatible with PCSX2 and Android emulators

**Extras Included:**
- Custom outfits
- Weapon skins
- Custom weather modes
- ReShade presets

**Download Sources:**
- [Ko-fi - Sad Origami's SOTC Pack](https://ko-fi.com/s/cd666fdf9d)
- [GBAtemp - Shadow of the Colossus Origami Remaster](https://gbatemp.net/threads/shadow-of-the-colossus-origami-remaster.641597/)

---

### Panda Venom's EU HD Remaster

**Features:**
- UI and font: Complete
- World textures: 95% complete
- All 16 Colossi: Complete

**Installation:**
1. Extract to: `PCSX2/textures/SCES-53326/replacements`
2. Enable in Config > Graphics Settings > Advanced:
   - Dump Textures: OFF
   - Load Texture: ON
   - Async Texture Loading: ON
3. SSD recommended

**Download Sources:**
- [GBAtemp - Shadow of the Colossus EU HD Remaster](https://gbatemp.net/threads/shadow-of-the-colossus-eu-hd-remaster.624038/)

---

### Android/NetherSX2 Optimized Pack

Based on Origami's release, optimized for mobile.

**Features:**
- Colossi/characters resized from 8x to 4x/2x for performance
- Colorized and optimized

**Download Sources:**
- [GBAtemp - SOTC HD Texture Pack for NetherSX2](https://gbatemp.net/threads/shadows-of-the-colossus-hd-texture-pack-pcsx2-and-android-nethersx2-1-9.667144/)

**Technical Note:** Unlike the PS3 remaster, the PS2 version emulated at 60fps via 300% CPU overclock in PCSX2 does not have physics issues.

---

## Kingdom Hearts Series (PS2)

### Kingdom Hearts 1 - Updated Textures Superpatch

Textures from KH2, BBS, and 1.5 formatted for original PS2 models.

**Download Sources:**
- [GameBanana - Updated Textures Superpatch (KH:FM)](https://gamebanana.com/mods/443308)

---

### Kingdom Hearts HD Remaster Texture Pack

**Features:**
- HD upscaled textures for PCSX2

**Known Limitations:**
- Character icons cannot be upscaled (emulator dump issue)
- Screen menu and font also affected

**Download Sources:**
- [GBAtemp - Kingdom Hearts HD Remaster](https://gbatemp.net/threads/kingdom-hearts-hd-remaster.630308/)

---

### Kingdom Hearts 2 Final Mix

**2.5 HD Remix Shaders**
- Shader file to replicate the 2.5 HD Remix visual style
- [PCSX2 Forums - 2.5 HD Remix Shaders](https://forums.pcsx2.net/Thread-2-5-HD-Remix-Shaders-for-Kingdom-Hearts-2-Final-Mix)

**HD Textures**
- [GBAtemp - Kingdom Hearts II HD Textures](https://gbatemp.net/threads/kingdom-hearts-ii-hd-textures.637758/)

---

### Kingdom Hearts: Birth by Sleep (PSP)

HD texture pack for PPSSPP emulator.

**Download Sources:**
- [GitHub - Birth by Sleep HD ReMix](https://github.com/AkiraJkr/Birth-by-Sleep-HD-ReMix)

---

### Additional Resources

- [KH-Vids - KH 1.5 Porting Thread](https://kh-vids.net/threads/kingdom-hearts-1-5-porting-thread-hd-assets-in-pcsx2-a-discussion.140143/)

---

## General Resources

### PCSX2 Widescreen & 60fps Patch Collections

**Official PCSX2 Patches Repository:**
- [GitHub - PCSX2 Official Patches](https://github.com/PCSX2/pcsx2_patches)
- Syncs with main PCSX2 builds
- Includes Widescreen, No Interlace patches

**Gabominated's Collection:**
- [GitHub - Gabominated PCSX2 Patches](https://github.com/Gabominated/PCSX2)
- Compilation of 50/60 FPS, widescreen, and improvement patches
- Installation: Place .pnach files in PCSX2 cheats folder

**PeterDelta's Patches:**
- [GitHub - PeterDelta PCSX2](https://github.com/PeterDelta/PCSX2)
- 50/60fps and widescreen patches
- Includes speed corrections for frame unlocking

**Organized Patch List:**
- [PCSX2 Patches List](https://krystianlesniak.github.io/pcsx2_patches_list/)
- Up-to-date list of all integrated patches

**TechieSaru's Enhancement Patches:**
- [GBAtemp - TechieSaru's Patches](https://gbatemp.net/threads/techiesarus-retro-game-enhancement-patches.648804/)
- Widescreen, 2D/FMV fixes, effect removals, 60fps patches

**PCSX2 Forums:**
- [PCSX2 Widescreen Game Patches Thread](https://forums.pcsx2.net/Thread-PCSX2-Widescreen-Game-Patches)

---

### Dolphin Texture Pack Resources

**Official Dolphin Forums:**
- [Dolphin Forums - Custom Texture Projects](https://forums.dolphin-emu.org/Forum-custom-texture-projects)

**Community Lists:**
- [GBAtemp - List of Texture Packs from Dolphin Forums](https://gbatemp.net/threads/list-of-texture-packs-from-dolphin-forums.655861/)
- [GitHub - dolphin-emu-textures Topic](https://github.com/topics/dolphin-emu-textures)

**General Wiki:**
- [Emulation General Wiki - Texture Packs](https://emulation.gametechwiki.com/index.php/Texture_packs)

---

### Fan Translation Resources

**Major Repositories:**
- [CDRomance - Translation Patches](https://cdromance.org/translations/)
- [Romhacking.net](https://www.romhacking.net/)

**Recent Notable Translations (2024-2025):**
- Tales of Rebirth (PS2) - Full English patch released December 2024
- PopoloCrois trilogy (PS1) - Completed 2024
- Mobile Suit Gundam (Saturn) - English patch finished
- Saturn Bomberman Fight! - English patch December 2024
- Princess Crown (Saturn) - English patch v1.0

**Ongoing Projects:**
- Shin Megami Tensei: Devil Summoner
- Tales of Destiny 2
- Growlanser 1

**News Sites:**
- [Time Extension - Fan Translations News](https://www.timeextension.com/tags/fan-translations)
- [RetroRGB - Translation Tag](https://www.retrorgb.com/tag/translation)

---

### PCSX2 HD Texture Pack Hub

**GBAtemp Groups:**
- [PCSX2 HD Texture Pack Group](https://gbatemp.net/forums/pcsx2-hd-texture-pack-group.549/)
- [PCSX2 HD Texture Packs Resources Hub](https://gbatemp.net/threads/pcsx2-hd-texture-packs-save-files-resources-hub.643280/)

**Internet Archive:**
- [PCSX2 HD Texture Packs Collection](https://archive.org/details/pcsx2-hd-texture-packs)

---

## Installation Quick Reference

### PCSX2 Texture Pack Installation

1. Locate your PCSX2 installation
2. Navigate to: `PCSX2/textures/[GAME_SERIAL]/replacements/`
3. Extract texture pack contents there
4. Enable in PCSX2: Settings > Graphics > Advanced
   - Load Textures: ON
   - Async Texture Loading: ON
5. **SSD highly recommended** for texture loading performance

### PCSX2 Patch Installation (.pnach files)

1. Navigate to: `PCSX2/cheats/`
2. Place .pnach file named with game's CRC (e.g., `94A82AAA.pnach`)
3. Enable cheats in PCSX2 game properties

### Dolphin Texture Pack Installation

1. Navigate to texture folder:
   - Windows: `%APPDATA%\Dolphin Emulator\Load\Textures\`
   - Linux: `~/.local/share/dolphin-emu/Load/Textures/`
2. Create folder with game ID if needed
3. Extract textures there
4. Enable in Graphics > Advanced:
   - Load Custom Textures: ON
   - Prefetch Custom Textures: ON (recommended)

---

*Last Updated: December 2025*
*Note: Always verify download sources and scan files for safety. Some links may become outdated.*
