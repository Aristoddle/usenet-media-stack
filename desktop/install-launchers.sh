#!/usr/bin/env bash
# install-launchers.sh - Install desktop launchers for KDE/gamescope
#
# This script:
# 1. Makes launcher scripts executable
# 2. Copies .desktop files to ~/.local/share/applications/
# 3. Updates the desktop database
#
# Run once after cloning or updating the repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_ROOT="$(dirname "$SCRIPT_DIR")"
DESKTOP_DIR="${HOME}/.local/share/applications"

echo "=== Installing Media Stack Desktop Launchers ==="
echo ""

# Ensure scripts are executable
echo "Making scripts executable..."
chmod +x "$STACK_ROOT/scripts/stack-up-full.sh"
chmod +x "$STACK_ROOT/scripts/stack-up-local.sh"
chmod +x "$STACK_ROOT/scripts/stack-down.sh"
chmod +x "$STACK_ROOT/scripts/gaming-mode.sh"
echo "  Done"

# Create applications directory if needed
mkdir -p "$DESKTOP_DIR"

# Copy desktop files
echo ""
echo "Installing .desktop files..."
for desktop_file in "$SCRIPT_DIR"/*.desktop; do
    if [[ -f "$desktop_file" ]]; then
        filename=$(basename "$desktop_file")
        cp "$desktop_file" "$DESKTOP_DIR/$filename"
        chmod +x "$DESKTOP_DIR/$filename"
        echo "  Installed: $filename"
    fi
done

# Update desktop database
echo ""
echo "Updating desktop database..."
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Launchers installed to: $DESKTOP_DIR"
echo ""
echo "You should now see these in your application menu:"
echo "  - Media Stack - Full (start everything with pool)"
echo "  - Media Stack - Local (start local services only)"
echo "  - Media Stack - Stop (graceful shutdown)"
echo ""
echo "Right-click on launchers for additional actions."
echo ""
echo "If launchers don't appear immediately:"
echo "  1. Log out and log back in, or"
echo "  2. Run: kbuildsycoca5 (for KDE)"
