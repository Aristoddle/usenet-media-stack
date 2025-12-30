#!/bin/bash
# Tdarr Configuration Sync Tool
# Export/Import flows and library settings from/to SQLite database
#
# Usage:
#   ./tdarr-config-sync.sh export   # Export from running Tdarr DB to git-tracked JSON
#   ./tdarr-config-sync.sh import   # Import git-tracked JSON to Tdarr DB (after fresh install)
#   ./tdarr-config-sync.sh status   # Show current Tdarr config state

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TDARR_DB="${TDARR_DB:-/var/mnt/fast8tb/config/tdarr/server/Tdarr/DB2/SQL/database.db}"
FLOWS_DIR="${SCRIPT_DIR}/flows"
LIBRARIES_DIR="${SCRIPT_DIR}/libraries"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_db() {
    if [[ ! -f "$TDARR_DB" ]]; then
        log_error "Tdarr database not found at: $TDARR_DB"
        log_info "Set TDARR_DB environment variable to point to your database"
        exit 1
    fi
}

export_flows() {
    log_info "Exporting flows to $FLOWS_DIR/"
    mkdir -p "$FLOWS_DIR"

    local count=0
    while IFS='|' read -r id name; do
        local filename
        filename=$(echo "$id" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')
        sqlite3 "$TDARR_DB" "SELECT json_data FROM flowsjsondb WHERE id='$id';" 2>/dev/null | \
            python3 -m json.tool > "${FLOWS_DIR}/${filename}.json" 2>/dev/null || {
                log_warn "Failed to export flow: $name ($id)"
                continue
            }
        log_info "  Exported: $name -> ${filename}.json"
        ((count++))
    done < <(sqlite3 "$TDARR_DB" "SELECT id, json_extract(json_data, '\$.name') FROM flowsjsondb;" 2>/dev/null)

    log_info "Exported $count flows"
}

export_libraries() {
    log_info "Exporting libraries to $LIBRARIES_DIR/"
    mkdir -p "$LIBRARIES_DIR"

    local count=0
    while IFS='|' read -r id name; do
        local filename
        filename=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd 'a-z0-9_')
        sqlite3 "$TDARR_DB" "SELECT json_data FROM librarysettingsjsondb WHERE id='$id';" 2>/dev/null | \
            python3 -m json.tool > "${LIBRARIES_DIR}/${filename}.json" 2>/dev/null || {
                log_warn "Failed to export library: $name ($id)"
                continue
            }
        log_info "  Exported: $name -> ${filename}.json"
        ((count++))
    done < <(sqlite3 "$TDARR_DB" "SELECT id, json_extract(json_data, '\$.name') FROM librarysettingsjsondb;" 2>/dev/null)

    log_info "Exported $count libraries"
}

import_flows() {
    log_info "Importing flows from $FLOWS_DIR/"

    if [[ ! -d "$FLOWS_DIR" ]]; then
        log_error "Flows directory not found: $FLOWS_DIR"
        exit 1
    fi

    local count=0
    for json_file in "$FLOWS_DIR"/*.json; do
        [[ -f "$json_file" ]] || continue

        local id
        id=$(python3 -c "import json; print(json.load(open('$json_file'))['_id'])" 2>/dev/null) || {
            log_warn "Failed to parse: $json_file"
            continue
        }

        local json_data
        json_data=$(cat "$json_file" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))")

        # Upsert - delete existing and insert new
        sqlite3 "$TDARR_DB" "DELETE FROM flowsjsondb WHERE id='$id';" 2>/dev/null
        sqlite3 "$TDARR_DB" "INSERT INTO flowsjsondb (id, json_data) VALUES ('$id', '$json_data');" 2>/dev/null || {
            log_warn "Failed to import flow: $id"
            continue
        }

        log_info "  Imported: $(basename "$json_file") -> $id"
        ((count++))
    done

    log_info "Imported $count flows"
}

import_libraries() {
    log_info "Importing libraries from $LIBRARIES_DIR/"

    if [[ ! -d "$LIBRARIES_DIR" ]]; then
        log_error "Libraries directory not found: $LIBRARIES_DIR"
        exit 1
    fi

    local count=0
    for json_file in "$LIBRARIES_DIR"/*.json; do
        [[ -f "$json_file" ]] || continue

        local id
        id=$(python3 -c "import json; print(json.load(open('$json_file'))['_id'])" 2>/dev/null) || {
            log_warn "Failed to parse: $json_file"
            continue
        }

        local json_data
        json_data=$(cat "$json_file" | python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin)))")

        # Upsert - delete existing and insert new
        sqlite3 "$TDARR_DB" "DELETE FROM librarysettingsjsondb WHERE id='$id';" 2>/dev/null
        sqlite3 "$TDARR_DB" "INSERT INTO librarysettingsjsondb (id, json_data) VALUES ('$id', '$json_data');" 2>/dev/null || {
            log_warn "Failed to import library: $id"
            continue
        }

        log_info "  Imported: $(basename "$json_file") -> $id"
        ((count++))
    done

    log_info "Imported $count libraries"
}

show_status() {
    log_info "Tdarr Configuration Status"
    echo ""

    check_db

    echo "Database: $TDARR_DB"
    echo ""

    echo "Flows in database:"
    sqlite3 "$TDARR_DB" "SELECT '  - ' || id || ': ' || json_extract(json_data, '\$.name') FROM flowsjsondb;" 2>/dev/null
    echo ""

    echo "Libraries in database:"
    sqlite3 "$TDARR_DB" "SELECT '  - ' || id || ': ' || json_extract(json_data, '\$.name') || ' (flow: ' || COALESCE(json_extract(json_data, '\$.flowId'), 'none') || ')' FROM librarysettingsjsondb;" 2>/dev/null
    echo ""

    echo "Git-tracked flows:"
    for f in "$FLOWS_DIR"/*.json 2>/dev/null; do
        [[ -f "$f" ]] && echo "  - $(basename "$f")"
    done || echo "  (none)"
    echo ""

    echo "Git-tracked libraries:"
    for f in "$LIBRARIES_DIR"/*.json 2>/dev/null; do
        [[ -f "$f" ]] && echo "  - $(basename "$f")"
    done || echo "  (none)"
}

case "${1:-status}" in
    export)
        check_db
        export_flows
        export_libraries
        log_info "Export complete. Don't forget to git commit!"
        ;;
    import)
        check_db
        log_warn "This will overwrite existing Tdarr configuration!"
        read -p "Continue? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            import_flows
            import_libraries
            log_info "Import complete. Restart Tdarr for changes to take effect."
        else
            log_info "Aborted."
        fi
        ;;
    status)
        show_status
        ;;
    *)
        echo "Tdarr Configuration Sync Tool"
        echo ""
        echo "Usage: $0 {export|import|status}"
        echo ""
        echo "Commands:"
        echo "  export  - Export Tdarr flows and libraries to git-tracked JSON files"
        echo "  import  - Import git-tracked JSON files into Tdarr database"
        echo "  status  - Show current configuration state"
        ;;
esac
