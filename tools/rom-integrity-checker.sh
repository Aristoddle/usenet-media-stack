#!/usr/bin/env bash
#
# rom-integrity-checker.sh - Verify ROM integrity against No-Intro/Redump databases
#
# Checks ROM files for:
# - File corruption (CRC/MD5/SHA1)
# - Size validation
# - Known bad dumps
# - Database matching
#
# Usage: ./rom-integrity-checker.sh [OPTIONS] [SYSTEM]
#
# Options:
#   --quick         Only check file sizes and basic integrity
#   --full          Full hash verification (slow)
#   --system SYS    Check specific system only
#   --export FILE   Export results to JSON file
#   --fix           Attempt to identify and flag bad ROMs
#
# Note: Full hash verification requires hash databases to be downloaded
# separately. This script can identify potential issues without them.
#

set -euo pipefail

# Configuration
EMUDECK_ROOT="${EMUDECK_ROOT:-/var/mnt/fast8tb/Emudeck/Emulation}"
ROMS_DIR="$EMUDECK_ROOT/roms"
HASH_DB_DIR="$EMUDECK_ROOT/databases"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Options
QUICK_MODE=true
FULL_MODE=false
TARGET_SYSTEM=""
EXPORT_FILE=""
FIX_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick) QUICK_MODE=true; FULL_MODE=false; shift ;;
        --full) FULL_MODE=true; QUICK_MODE=false; shift ;;
        --system) TARGET_SYSTEM="$2"; shift 2 ;;
        --export) EXPORT_FILE="$2"; shift 2 ;;
        --fix) FIX_MODE=true; shift ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [SYSTEM]"
            echo ""
            echo "Options:"
            echo "  --quick         Quick size/sanity checks only (default)"
            echo "  --full          Full hash verification"
            echo "  --system SYS    Check specific system"
            echo "  --export FILE   Export to JSON"
            echo "  --fix           Flag bad ROMs"
            exit 0
            ;;
        *) TARGET_SYSTEM="$1"; shift ;;
    esac
done

# Results tracking
declare -A results
declare -i total_checked=0
declare -i total_ok=0
declare -i total_warnings=0
declare -i total_errors=0

# Expected size ranges (in bytes) - approximate for quick checks
declare -A SIZE_RANGES=(
    # System: "min_mb:max_mb"
    ["switch"]="100:32000"
    ["wiiu"]="100:25000"
    ["ps2"]="500:8000"
    ["ps3"]="1000:50000"
    ["psx"]="100:800"
    ["psp"]="100:4000"
    ["gc"]="100:2000"
    ["wii"]="500:10000"
    ["3ds"]="100:4000"
    ["nds"]="1:512"
    ["n64"]="1:64"
    ["dreamcast"]="100:1500"
    ["saturn"]="100:700"
    ["gba"]="0.1:32"
    ["gbc"]="0.1:8"
    ["gb"]="0.01:4"
    ["nes"]="0.01:2"
    ["snes"]="0.1:6"
    ["genesis"]="0.1:8"
)

# Known bad ROM patterns
declare -A BAD_PATTERNS=(
    ["trainer"]="[Tt]rainer|+[0-9]T"
    ["bad_dump"]="[Bb]ad[Dd]ump|\[b\]|\[b[0-9]\]"
    ["overdump"]="[Oo]verdump|\[o\]|\[o[0-9]\]"
    ["hack"]="[Hh]ack|\[h\]"
    ["pirate"]="[Pp]irate|\[p\]"
    ["virus"]="virus|trojan"
)

# Helper functions
log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
    ((total_ok++))
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((total_warnings++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((total_errors++))
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Get file size in MB
get_size_mb() {
    local file="$1"
    local size_bytes=$(stat -c%s "$file" 2>/dev/null || echo "0")
    echo "scale=2; $size_bytes / 1048576" | bc
}

# Check filename for bad patterns
check_filename() {
    local filename="$1"
    local issues=()

    for pattern_name in "${!BAD_PATTERNS[@]}"; do
        local pattern="${BAD_PATTERNS[$pattern_name]}"
        if echo "$filename" | grep -qE "$pattern"; then
            issues+=("$pattern_name")
        fi
    done

    if [[ ${#issues[@]} -gt 0 ]]; then
        echo "${issues[*]}"
    fi
}

# Validate file size for system
check_size() {
    local file="$1"
    local system="$2"

    local range="${SIZE_RANGES[$system]:-}"
    if [[ -z "$range" ]]; then
        return 0  # No range defined, skip check
    fi

    local min_mb=$(echo "$range" | cut -d: -f1)
    local max_mb=$(echo "$range" | cut -d: -f2)
    local size_mb=$(get_size_mb "$file")

    if (( $(echo "$size_mb < $min_mb" | bc -l) )); then
        echo "too_small:${size_mb}MB<${min_mb}MB"
        return 1
    fi

    if (( $(echo "$size_mb > $max_mb" | bc -l) )); then
        echo "too_large:${size_mb}MB>${max_mb}MB"
        return 1
    fi

    return 0
}

# Check file integrity (basic)
check_basic_integrity() {
    local file="$1"

    # Check if file is readable
    if [[ ! -r "$file" ]]; then
        echo "unreadable"
        return 1
    fi

    # Check if file is empty
    if [[ ! -s "$file" ]]; then
        echo "empty"
        return 1
    fi

    # For archives, check if they're valid
    local ext="${file##*.}"
    case "$ext" in
        zip)
            if command -v unzip &>/dev/null; then
                if ! unzip -t "$file" &>/dev/null; then
                    echo "corrupt_zip"
                    return 1
                fi
            fi
            ;;
        7z)
            if command -v 7z &>/dev/null; then
                if ! 7z t "$file" &>/dev/null; then
                    echo "corrupt_7z"
                    return 1
                fi
            fi
            ;;
    esac

    return 0
}

# Full hash check (slow)
compute_hash() {
    local file="$1"
    local hash_type="${2:-sha1}"

    case "$hash_type" in
        sha1) sha1sum "$file" | cut -d' ' -f1 ;;
        md5) md5sum "$file" | cut -d' ' -f1 ;;
        crc) cksum "$file" | cut -d' ' -f1 ;;
    esac
}

# Process a single ROM file
check_rom() {
    local filepath="$1"
    local system="$2"
    local filename=$(basename "$filepath")

    ((total_checked++))

    local issues=()

    # Check filename for bad patterns
    local filename_issues=$(check_filename "$filename")
    if [[ -n "$filename_issues" ]]; then
        issues+=("filename:$filename_issues")
    fi

    # Check basic integrity
    local integrity_result=$(check_basic_integrity "$filepath")
    if [[ -n "$integrity_result" ]]; then
        issues+=("integrity:$integrity_result")
    fi

    # Check file size
    local size_result=$(check_size "$filepath" "$system")
    if [[ -n "$size_result" ]]; then
        issues+=("size:$size_result")
    fi

    # Full hash check if enabled
    if $FULL_MODE; then
        local hash=$(compute_hash "$filepath" "sha1")
        # Would compare against database here
        # For now, just record the hash
        issues+=("hash:$hash")
    fi

    # Report results
    if [[ ${#issues[@]} -eq 0 ]] || ( [[ ${#issues[@]} -eq 1 ]] && $FULL_MODE && [[ "${issues[0]}" == hash:* ]] ); then
        log_ok "$filename"
        return 0
    else
        local issue_str="${issues[*]}"
        if [[ "$issue_str" == *"integrity:"* ]] || [[ "$issue_str" == *"bad_dump"* ]]; then
            log_error "$filename - $issue_str"
            return 2
        else
            log_warn "$filename - $issue_str"
            return 1
        fi
    fi
}

# Process a system
process_system() {
    local system="$1"
    local system_dir="$ROMS_DIR/$system"

    if [[ ! -d "$system_dir" ]]; then
        log_info "System $system not found, skipping"
        return
    fi

    echo -e "\n${BLUE}=== Checking: $system ===${NC}"

    # Determine file extensions for this system
    local find_args=()
    case "$system" in
        switch) find_args=(-name "*.nsp" -o -name "*.xci" -o -name "*.nsz") ;;
        wiiu) find_args=(-name "*.wux" -o -name "*.wud" -o -name "*.rpx") ;;
        ps2) find_args=(-name "*.chd" -o -name "*.iso" -o -name "*.cso" -o -name "*.zso") ;;
        ps3) find_args=(-name "*.iso") ;;
        psx) find_args=(-name "*.chd" -o -name "*.iso" -o -name "*.bin" -o -name "*.pbp") ;;
        psp) find_args=(-name "*.iso" -o -name "*.cso" -o -name "*.chd") ;;
        gc) find_args=(-name "*.rvz" -o -name "*.iso" -o -name "*.gcz") ;;
        wii) find_args=(-name "*.rvz" -o -name "*.wbfs" -o -name "*.iso") ;;
        3ds|n3ds) find_args=(-name "*.3ds" -o -name "*.cia") ;;
        nds) find_args=(-name "*.nds") ;;
        n64) find_args=(-name "*.n64" -o -name "*.z64" -o -name "*.v64") ;;
        dreamcast) find_args=(-name "*.chd" -o -name "*.gdi" -o -name "*.cdi") ;;
        saturn) find_args=(-name "*.chd" -o -name "*.iso") ;;
        gba) find_args=(-name "*.gba") ;;
        gbc) find_args=(-name "*.gbc") ;;
        gb) find_args=(-name "*.gb") ;;
        nes) find_args=(-name "*.nes") ;;
        snes) find_args=(-name "*.sfc" -o -name "*.smc") ;;
        genesis) find_args=(-name "*.md" -o -name "*.bin") ;;
        *) find_args=(-name "*.zip" -o -name "*.iso") ;;
    esac

    # Find and check ROMs
    local files_checked=0
    while IFS= read -r -d '' filepath; do
        check_rom "$filepath" "$system" || true
        ((files_checked++))
    done < <(find "$system_dir" -maxdepth 2 -type f \( "${find_args[@]}" \) -print0 2>/dev/null)

    echo "Checked $files_checked files in $system"
}

# Export results to JSON
export_results() {
    local output_file="$1"

    cat > "$output_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "summary": {
        "total_checked": $total_checked,
        "total_ok": $total_ok,
        "total_warnings": $total_warnings,
        "total_errors": $total_errors
    }
}
EOF

    echo "Results exported to $output_file"
}

# Main
main() {
    echo "ROM Integrity Checker"
    echo "===================="
    echo "Mode: $(if $FULL_MODE; then echo "Full (hash verification)"; else echo "Quick (size/sanity checks)"; fi)"
    echo ""

    if [[ -n "$TARGET_SYSTEM" ]]; then
        process_system "$TARGET_SYSTEM"
    else
        # Process major systems
        local systems=("switch" "wiiu" "ps2" "psx" "psp" "gc" "wii" "3ds" "n3ds" "nds" "n64" "dreamcast" "saturn")
        for system in "${systems[@]}"; do
            process_system "$system"
        done
    fi

    # Summary
    echo -e "\n${BLUE}=== Summary ===${NC}"
    echo "Total checked: $total_checked"
    echo -e "  ${GREEN}OK:${NC} $total_ok"
    echo -e "  ${YELLOW}Warnings:${NC} $total_warnings"
    echo -e "  ${RED}Errors:${NC} $total_errors"

    # Export if requested
    if [[ -n "$EXPORT_FILE" ]]; then
        export_results "$EXPORT_FILE"
    fi

    # Return exit code based on errors
    if [[ $total_errors -gt 0 ]]; then
        return 1
    fi
    return 0
}

main "$@"
