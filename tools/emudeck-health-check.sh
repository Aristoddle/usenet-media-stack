#!/usr/bin/env bash
#
# emudeck-health-check.sh - Full EmuDeck system verification
#
# Performs comprehensive health checks on the EmuDeck installation:
# - ROM inventory by system
# - BIOS verification
# - Storage analysis
# - Duplicate detection
# - Format optimization opportunities
# - Missing BIOS detection
#
# Usage: ./emudeck-health-check.sh [--json] [--quick]
#
# Options:
#   --json    Output in JSON format
#   --quick   Skip slow operations (duplicate detection)
#

set -euo pipefail

# Configuration
EMUDECK_ROOT="${EMUDECK_ROOT:-/var/mnt/fast8tb/Emudeck/Emulation}"
ROMS_DIR="$EMUDECK_ROOT/roms"
BIOS_DIR="$EMUDECK_ROOT/bios"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Parse arguments
JSON_OUTPUT=false
QUICK_MODE=false
for arg in "$@"; do
    case $arg in
        --json) JSON_OUTPUT=true ;;
        --quick) QUICK_MODE=true ;;
    esac
done

# Helper functions
print_header() {
    if ! $JSON_OUTPUT; then
        echo -e "\n${BLUE}=== $1 ===${NC}\n"
    fi
}

print_ok() {
    if ! $JSON_OUTPUT; then
        echo -e "${GREEN}[OK]${NC} $1"
    fi
}

print_warn() {
    if ! $JSON_OUTPUT; then
        echo -e "${YELLOW}[WARN]${NC} $1"
    fi
}

print_error() {
    if ! $JSON_OUTPUT; then
        echo -e "${RED}[ERROR]${NC} $1"
    fi
}

# ROM extensions by system type
declare -A ROM_EXTENSIONS=(
    ["switch"]="nsp|xci|nsz|xcz"
    ["wiiu"]="wux|wud|rpx|wua"
    ["ps2"]="chd|iso|cso|zso"
    ["ps3"]="iso"
    ["ps4"]="pkg"
    ["psx"]="chd|iso|bin|pbp|zip"
    ["psp"]="iso|cso|chd|pbp"
    ["psvita"]="vpk|zip"
    ["gc"]="rvz|iso|gcz"
    ["wii"]="rvz|wbfs|iso"
    ["3ds"]="3ds|cia|cxi"
    ["n3ds"]="3ds|cia|cxi"
    ["nds"]="nds"
    ["n64"]="n64|z64|v64"
    ["snes"]="sfc|smc|zip"
    ["nes"]="nes|zip"
    ["gba"]="gba|zip"
    ["gbc"]="gbc|zip"
    ["gb"]="gb|zip"
    ["genesis"]="md|bin|zip"
    ["dreamcast"]="chd|gdi|cdi"
    ["saturn"]="chd|iso|cue"
    ["arcade"]="zip"
    ["mame"]="zip"
    ["neogeo"]="zip"
)

# Required BIOS files by system
declare -A REQUIRED_BIOS=(
    ["psx"]="scph1001.bin|scph5501.bin"
    ["ps2"]="SCPH30004R.bin|scph39001.bin"
    ["ps3"]="PS3UPDAT.PUP"
    ["dreamcast"]="dc_boot.bin dc_flash.bin"
    ["saturn"]="saturn_bios.bin"
    ["nds"]="bios7.bin bios9.bin firmware.bin"
    ["gba"]="gba_bios.bin"
    ["gbc"]="gbc_bios.bin"
    ["gb"]="gb_bios.bin"
    ["neogeo"]="neogeo.zip"
    ["3do"]="panafz1.bin"
    ["pcengine"]="syscard3.pce"
)

# Count ROMs for a system
count_roms() {
    local system="$1"
    local dir="$ROMS_DIR/$system"

    if [[ ! -d "$dir" ]]; then
        echo "0"
        return
    fi

    local extensions="${ROM_EXTENSIONS[$system]:-zip|iso|bin}"
    find "$dir" -type f -regextype posix-extended -regex ".*\.($extensions)$" 2>/dev/null | wc -l
}

# Get directory size
get_size() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        du -sh "$dir" 2>/dev/null | cut -f1
    else
        echo "0"
    fi
}

# Main health check
main() {
    local total_issues=0
    local total_warnings=0

    print_header "EmuDeck Health Check"
    echo "Root: $EMUDECK_ROOT"
    echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"

    # Check if directories exist
    print_header "Directory Structure"
    for dir in "$ROMS_DIR" "$BIOS_DIR" "$EMUDECK_ROOT/saves"; do
        if [[ -d "$dir" ]]; then
            print_ok "$(basename "$dir") directory exists"
        else
            print_error "Missing: $dir"
            ((total_issues++))
        fi
    done

    # ROM Inventory
    print_header "ROM Inventory (Major Systems)"

    declare -A rom_counts
    local major_systems=("switch" "wiiu" "ps2" "ps3" "psx" "psp" "psvita" "gc" "wii" "3ds" "n3ds" "nds" "n64" "dreamcast" "saturn")

    for system in "${major_systems[@]}"; do
        local count=$(count_roms "$system")
        local size=$(get_size "$ROMS_DIR/$system")
        rom_counts[$system]=$count

        if [[ $count -gt 0 ]]; then
            printf "%-12s: %4d ROMs (%s)\n" "$system" "$count" "$size"
        else
            printf "%-12s: %4d ROMs (empty)\n" "$system" "$count"
        fi
    done

    # Empty critical systems warning
    for system in "psvita"; do
        if [[ ${rom_counts[$system]:-0} -eq 0 ]]; then
            print_warn "$system has no ROMs - Vita3K is installed"
            ((total_warnings++))
        fi
    done

    # BIOS Verification
    print_header "BIOS Status"

    for system in psx ps2 ps3 dreamcast saturn nds gba neogeo; do
        local required="${REQUIRED_BIOS[$system]:-}"
        if [[ -z "$required" ]]; then
            continue
        fi

        local all_found=true
        for bios in $required; do
            # Handle alternatives (pipe-separated)
            if [[ "$bios" == *"|"* ]]; then
                local found_alt=false
                IFS='|' read -ra alts <<< "$bios"
                for alt in "${alts[@]}"; do
                    if [[ -f "$BIOS_DIR/$alt" ]]; then
                        found_alt=true
                        break
                    fi
                done
                if ! $found_alt; then
                    all_found=false
                fi
            else
                if [[ ! -f "$BIOS_DIR/$bios" ]]; then
                    all_found=false
                fi
            fi
        done

        if $all_found; then
            print_ok "$system BIOS complete"
        else
            print_error "$system BIOS missing: $required"
            ((total_issues++))
        fi
    done

    # Switch keys check
    if [[ -d "$BIOS_DIR/ryujinx" ]]; then
        if [[ -f "$BIOS_DIR/ryujinx/system/prod.keys" ]] || [[ -f "$BIOS_DIR/switch/prod.keys" ]]; then
            print_ok "Switch keys present"
        else
            print_warn "Switch prod.keys may be missing"
            ((total_warnings++))
        fi
    fi

    # Storage Analysis
    print_header "Storage Usage"

    local total_roms=$(get_size "$ROMS_DIR")
    local total_bios=$(get_size "$BIOS_DIR")
    local total_saves=$(get_size "$EMUDECK_ROOT/saves")
    local total_emudeck=$(get_size "$EMUDECK_ROOT")

    echo "ROMs:   $total_roms"
    echo "BIOS:   $total_bios"
    echo "Saves:  $total_saves"
    echo "Total:  $total_emudeck"

    # Top 10 systems by size
    echo ""
    echo "Top 10 systems by size:"
    du -sh "$ROMS_DIR"/*/ 2>/dev/null | sort -hr | head -10 | while read size dir; do
        printf "  %8s  %s\n" "$size" "$(basename "$dir")"
    done

    # Format Optimization Opportunities
    print_header "Format Optimization Opportunities"

    # Check for ISOs that could be CHD/RVZ
    local ps2_isos=$(find "$ROMS_DIR/ps2" -name "*.iso" 2>/dev/null | wc -l)
    local gc_isos=$(find "$ROMS_DIR/gc" -name "*.iso" 2>/dev/null | wc -l)
    local wii_isos=$(find "$ROMS_DIR/wii" -name "*.iso" 2>/dev/null | wc -l)

    if [[ $ps2_isos -gt 0 ]]; then
        print_warn "PS2: $ps2_isos ISOs could be converted to CHD (40-60% smaller)"
        ((total_warnings++))
    fi

    if [[ $gc_isos -gt 0 ]]; then
        print_warn "GameCube: $gc_isos ISOs could be converted to RVZ (40-60% smaller)"
        ((total_warnings++))
    fi

    if [[ $wii_isos -gt 0 ]]; then
        print_warn "Wii: $wii_isos ISOs could be converted to RVZ (40-60% smaller)"
        ((total_warnings++))
    fi

    # Duplicate Detection (skip in quick mode)
    if ! $QUICK_MODE; then
        print_header "Cross-Platform Duplicates"

        # Common duplicates
        local duplicates=()

        # Bayonetta
        local bayonetta_switch=$(find "$ROMS_DIR/switch" -maxdepth 1 -name "*[Bb]ayonetta*" -type f 2>/dev/null | wc -l)
        local bayonetta_wiiu=$(find "$ROMS_DIR/wiiu" -maxdepth 1 -name "*[Bb]ayonetta*" -type f 2>/dev/null | wc -l)
        if [[ $bayonetta_switch -gt 0 ]] && [[ $bayonetta_wiiu -gt 0 ]]; then
            print_warn "Bayonetta exists on both Switch ($bayonetta_switch) and Wii U ($bayonetta_wiiu)"
            ((total_warnings++))
        fi

        # Breath of the Wild
        local botw_switch=$(find "$ROMS_DIR/switch" -maxdepth 2 -name "*[Bb]reath*[Ww]ild*" -type f 2>/dev/null | wc -l)
        local botw_wiiu=$(find "$ROMS_DIR/wiiu" -maxdepth 1 -name "*[Bb]reath*[Ww]ild*" -type f 2>/dev/null | wc -l)
        if [[ $botw_switch -gt 0 ]] && [[ $botw_wiiu -gt 0 ]]; then
            print_warn "Breath of the Wild exists on both Switch ($botw_switch) and Wii U ($botw_wiiu)"
            ((total_warnings++))
        fi

        # Tropical Freeze
        local tf_switch=$(find "$ROMS_DIR/switch" -maxdepth 1 -name "*[Tt]ropical*[Ff]reeze*" -type f 2>/dev/null | wc -l)
        local tf_wiiu=$(find "$ROMS_DIR/wiiu" -maxdepth 1 -name "*[Tt]ropical*[Ff]reeze*" -type f 2>/dev/null | wc -l)
        if [[ $tf_switch -gt 0 ]] && [[ $tf_wiiu -gt 0 ]]; then
            print_warn "DK Tropical Freeze exists on both Switch ($tf_switch) and Wii U ($tf_wiiu)"
            ((total_warnings++))
        fi

        # Same-platform duplicates check for Switch
        print_header "Potential Same-Platform Duplicates (Switch)"

        # Find games that might have multiple versions
        local switch_dupes=$(find "$ROMS_DIR/switch" -maxdepth 1 -type f \( -name "*.nsp" -o -name "*.xci" \) 2>/dev/null | \
            sed 's/\[.*//g' | sort | uniq -d | head -5)

        if [[ -n "$switch_dupes" ]]; then
            echo "$switch_dupes" | while read game; do
                print_warn "Possible duplicate: $(basename "$game")"
                ((total_warnings++))
            done
        else
            print_ok "No obvious duplicates detected"
        fi
    fi

    # HD Texture Pack Status
    print_header "HD Texture Pack Status"

    if [[ -d "$BIOS_DIR/HdPacks" ]]; then
        local hdpack_count=$(find "$BIOS_DIR/HdPacks" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
        if [[ $hdpack_count -gt 0 ]]; then
            print_ok "NES HD Packs: $hdpack_count games"
        else
            print_warn "HdPacks directory exists but is empty"
            ((total_warnings++))
        fi
    else
        print_warn "No NES HD texture packs installed"
        ((total_warnings++))
    fi

    if [[ -d "$BIOS_DIR/Mupen64plus" ]]; then
        local n64_textures=$(find "$BIOS_DIR/Mupen64plus" -name "*.htc" -o -name "*.hts" 2>/dev/null | wc -l)
        if [[ $n64_textures -gt 0 ]]; then
            print_ok "N64 texture packs: $n64_textures files"
        else
            print_warn "Mupen64plus directory exists but no texture packs found"
            ((total_warnings++))
        fi
    else
        print_warn "No N64 HD texture packs installed"
        ((total_warnings++))
    fi

    # Summary
    print_header "Summary"

    if [[ $total_issues -eq 0 ]] && [[ $total_warnings -eq 0 ]]; then
        print_ok "All checks passed! EmuDeck is healthy."
    else
        if [[ $total_issues -gt 0 ]]; then
            print_error "Issues found: $total_issues"
        fi
        if [[ $total_warnings -gt 0 ]]; then
            print_warn "Warnings: $total_warnings"
        fi
    fi

    echo ""
    echo "Run with --quick to skip duplicate detection"

    return $total_issues
}

main "$@"
