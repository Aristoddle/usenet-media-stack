# EmuDeck Acquisition Plan

**Generated**: December 29, 2025
**Based on**: Deep audit of `/var/mnt/fast8tb/Emudeck/Emulation/`

This document outlines prioritized acquisition opportunities identified during the EmuDeck ecosystem audit.

---

## Priority 1: PS Vita (CRITICAL - Empty System)

Vita3K is fully installed and configured but has **zero ROMs**. This is the highest priority acquisition.

### Essential Titles (Top 10)

| Title | Genre | Notes |
|-------|-------|-------|
| Persona 4 Golden | JRPG | Definitive version of P4, must-have |
| Gravity Rush | Action | Vita exclusive (later ported to PS4) |
| Soul Sacrifice Delta | Action RPG | Excellent Monster Hunter style game |
| Freedom Wars | Action | Anime-styled hunting game |
| Danganronpa 1: Trigger Happy Havoc | Visual Novel | Mystery essential |
| Danganronpa 2: Goodbye Despair | Visual Novel | Superior sequel |
| Trails of Cold Steel | JRPG | Falcom excellence |
| Trails of Cold Steel II | JRPG | Continuation |
| Muramasa Rebirth | Action | Vanillaware's beautiful action game |
| Ys VIII: Lacrimosa of Dana | Action JRPG | One of the best Ys games |

### Secondary Vita Titles

| Title | Genre | Notes |
|-------|-------|-------|
| Dragon's Crown | Action RPG | Vanillaware beat-em-up |
| Odin Sphere Leifthrasir | Action RPG | Vanillaware remake |
| Uncharted: Golden Abyss | Action Adventure | Vita exclusive Uncharted |
| Killzone: Mercenary | FPS | Best handheld FPS |
| Tearaway | Platformer | Creative platformer |
| LittleBigPlanet PS Vita | Platformer | Excellent port |
| Wipeout 2048 | Racing | Fast anti-grav racing |
| Zero Escape: Virtue's Last Reward | Visual Novel | Essential VN |
| Zero Escape: Zero Time Dilemma | Visual Novel | Trilogy conclusion |
| Steins;Gate | Visual Novel | Classic sci-fi VN |

### Format Notes
- Vita ROMs typically `.vpk` format
- Vita3K compatible, game-by-game basis
- Check Vita3K compatibility list before acquiring

---

## Priority 2: HD Texture Packs

Currently no HD texture packs are installed despite directories existing.

### N64 HD Texture Packs (High Priority)

| Game | Pack Name | Status |
|------|-----------|--------|
| Legend of Zelda: Ocarina of Time | OoT HD Texture Pack | Community maintained |
| Legend of Zelda: Majora's Mask | MM HD Texture Pack | Community maintained |
| Super Mario 64 | SM64 HD Texture Project | Very active |
| Paper Mario | Paper Mario HD | Beautiful upscale |
| Mario Kart 64 | MK64 HD | Popular pack |
| Banjo-Kazooie | BK HD | Quality pack available |
| Banjo-Tooie | BT HD | Quality pack available |
| Donkey Kong 64 | DK64 HD | Available |

**Installation Path**: `/var/mnt/fast8tb/Emudeck/Emulation/bios/Mupen64plus/`

### GameCube HD Texture Packs

| Game | Notes |
|------|-------|
| Wind Waker | High quality packs exist |
| Twilight Princess | Multiple packs available |
| Metroid Prime 1 & 2 | Community packs |
| Paper Mario TTYD | Beautiful HD pack |
| Resident Evil 4 | HD project exists |
| Super Mario Sunshine | Upscale packs |

**Installation Path**: Dolphin user directory `Load/Textures/[GAME_ID]/`

### NES HD Packs (Mesen-style)

| Game | Notes |
|------|-------|
| Super Mario Bros 1-3 | HD redraws exist |
| Mega Man series | Popular packs |
| Castlevania | Quality packs |
| Zelda 1 & 2 | HD versions |

**Installation Path**: `/var/mnt/fast8tb/Emudeck/Emulation/bios/HdPacks/`

---

## Priority 3: Wii Library Expansion

Currently only 6 games. Missing many essentials.

### Essential Missing Titles

| Title | Genre | Notes |
|-------|-------|-------|
| Super Mario Galaxy | Platformer | One of the best ever |
| Super Mario Galaxy 2 | Platformer | Superior sequel |
| Metroid Prime 3: Corruption | FPS | Trilogy conclusion |
| Super Smash Bros. Brawl | Fighting | Essential |
| Mario Kart Wii | Racing | Most popular MK |
| Donkey Kong Country Returns | Platformer | Excellent revival |
| Kirby's Epic Yarn | Platformer | Charming |
| Kirby's Return to Dream Land | Platformer | Classic Kirby |
| Punch-Out!! | Sports | Boxing fun |
| New Super Mario Bros. Wii | Platformer | Co-op classic |
| Super Paper Mario | RPG | Unique entry |
| The Last Story | JRPG | Mistwalker gem |
| Pandora's Tower | Action RPG | Overlooked gem |

### Currently Have
- Fire Emblem: Radiant Dawn
- Disney Epic Mickey
- No More Heroes 1 & 2
- Zelda: Skyward Sword
- Xenoblade Chronicles

---

## Priority 4: 3DS Library Expansion

Only 7 games on base 3DS, 27 on N3DS. Some gaps remain.

### Missing 3DS Essentials

| Title | Genre | Notes |
|-------|-------|-------|
| Zelda: A Link Between Worlds | Adventure | Top 3DS game |
| Zelda: Ocarina of Time 3D | Adventure | Definitive OoT |
| Zelda: Majora's Mask 3D | Adventure | Definitive MM |
| Kid Icarus: Uprising | Action | Unique shooter |
| Fire Emblem: Fates | Strategy | Three versions |
| Fire Emblem Echoes: SoV | Strategy | Quality remake |
| Bravely Default | JRPG | Spiritual FF successor |
| Bravely Second | JRPG | Sequel |
| Dragon Quest VII | JRPG | Massive adventure |
| Dragon Quest VIII | JRPG | 3DS exclusive content |
| Shin Megami Tensei IV | JRPG | Excellent entry |
| Shin Megami Tensei IV: Apocalypse | JRPG | Enhanced sequel |
| Etrian Odyssey series | JRPG | Dungeon crawlers |
| Professor Layton series | Puzzle | Multiple entries |
| Phoenix Wright: Dual Destinies | Adventure | AA continuation |
| Phoenix Wright: Spirit of Justice | Adventure | Latest mainline |

---

## Priority 5: Format Conversions (No Acquisition Needed)

These are optimization tasks for existing ROMs.

### PS2 Conversions (ISO/ZSO to CHD)
```
8 ISOs to convert:
- Killer7_PS2_NTSC-U.iso
- Odin_Sphere_USA.iso
- Onimusha_3_Demon_Siege_USA.iso
- Onimusha_Warlords_USA.iso
- Shin Megami Tensei - Persona 3 FES (USA).iso
- Shin Megami Tensei - Persona 4 (USA).iso
- Kingdom Hearts II - Final Mix [English Patch].iso
- VIEWTIFUL_JOE2 (PAL).iso

3 ZSOs to convert:
- Dragon_Quest_VIII_USA.zso
- Katamari_Damacy_USA.zso
- Shadow_of_the_Colossus_USA.zso
```

### GameCube Conversions (ISO to RVZ)
```
2 ISOs to convert:
- Legend of Zelda, The - The Wind Waker (USA).iso
- Legend of Zelda, The - Twilight Princess.iso
```

### Wii Conversions (ISO to RVZ)
```
3 ISOs to convert:
- Disney Epic Mickey.iso
- Fire Emblem - Radiant Dawn (USA) (Rev 1).iso
- Xenoblade Chronicles (USA).iso
```

**Conversion Command** (using chdman for PS2):
```bash
chdman createcd -i "Game.iso" -o "Game.chd"
```

**Conversion Command** (using DolphinTool for GC/Wii):
```bash
dolphin-tool convert -i "Game.iso" -o "Game.rvz" -f rvz -b 131072 -c lzma2 -l 9
```

---

## Duplicate Cleanup Opportunities

### Cross-Platform Duplicates (Consider Keeping One)

| Game | Switch | Wii U | Recommendation |
|------|--------|-------|----------------|
| Bayonetta 1 | Yes (~9GB) | Yes (~14GB) | Keep Switch (newer, better emulation) |
| Bayonetta 2 | Yes (~13GB) | Yes (~17GB) | Keep Switch (newer, better emulation) |
| Breath of the Wild | Yes (~12GB) | Yes (~14GB) | Keep Switch OR Wii U (mods) |
| DK Tropical Freeze | Yes (~7GB) | Yes (~13GB) | Keep Switch (Funky mode) |

**Potential Space Savings**: ~40-60 GB by removing Wii U versions

### Same-Platform Switch Duplicates

| Game | Issue | Action |
|------|-------|--------|
| Mario Tennis Aces | 3 versions | Keep XCI with updates only |
| Link's Awakening | 2 versions | Keep one |
| Super Mario 3D World | Multiple versions | Keep XCI only |

---

## Acquisition Workflow

Using the `emudeck-rom-manager` skill:

1. **Check indexer health**:
   ```bash
   # Verify Prowlarr connectivity
   curl -s "http://localhost:9696/api/v1/health" -H "X-Api-Key: $PROWLARR_API_KEY"
   ```

2. **Search for ROM**:
   - Use Prowlarr to search appropriate indexers
   - Prefer No-Intro/Redump verified sets
   - Check for region (prefer USA)

3. **Download via SABnzbd** (category: `roms`):
   ```bash
   # SABnzbd should have 'roms' category configured
   # Post-processing should move to staging
   ```

4. **Verify before placing**:
   - Check file integrity
   - Verify hash against databases if available
   - Test in emulator before final placement

5. **Organize**:
   - Rename to No-Intro/Redump standard
   - Place in correct system folder
   - Update inventory documentation

---

## Notes

- Always verify ROM compatibility with target emulator before acquiring
- Prefer highest quality sources (No-Intro for cartridge, Redump for disc)
- Check Vita3K, Azahar, Ryujinx compatibility lists for newer systems
- HD texture packs are separate from ROMs - legal gray area but generally accepted

---

*Generated by EmuDeck Deep Audit Agent*
*December 29, 2025*
