#!/bin/bash
###############################################################################
#  init-sabnzbd.sh - Initialize SABnzbd configuration
#  Bypasses wizard mode and ensures proper directory permissions
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config/sabnzbd"
SABNZBD_INI="$CONFIG_DIR/sabnzbd.ini"

echo "Initializing SABnzbd configuration..."

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# Check if sabnzbd.ini exists
if [[ ! -f "$SABNZBD_INI" ]]; then
    echo "Creating initial sabnzbd.ini..."
    cat > "$SABNZBD_INI" << 'EOF'
__version__ = 19
__encoding__ = utf-8
[misc]
first_cfg_step = 0
config_conversion_version = 4
helpful_warnings = 1
queue_complete = ""
queue_complete_pers = 0
bandwidth_perc = 100
refresh_rate = 0
interface_settings = ""
queue_limit = 20
config_lock = 0
fixed_ports = 1
notified_new_skin = 0
direct_unpack_tested = 0
sorters_converted = 1
check_new_rel = 1
auto_browser = 0
language = en
enable_https_verification = 1
host = ::
port = 8080
https_port = ""
username = ""
password = ""
bandwidth_max = ""
cache_limit = 1G
web_dir = Glitter
web_color = Auto
https_cert = server.cert
https_key = server.key
https_chain = ""
enable_https = 0
inet_exposure = 0
api_key = 
nzb_key = 
socks5_proxy_url = ""
permissions = ""
download_dir = /downloads/incomplete
download_free = ""
complete_dir = /downloads/complete
complete_free = ""
fulldisk_autoresume = 0
script_dir = ""
nzb_backup_dir = ""
admin_dir = admin
backup_dir = ""
dirscan_dir = ""
dirscan_speed = 5
password_file = ""
[categories]
[[*]]
pp = 3
script = None
dir = ""
[[movies]]
pp = 3
script = None  
dir = movies
[[tv]]
pp = 3
script = None
dir = tv
[[music]]
pp = 3
script = None
dir = music
[[books]]
pp = 3
script = None
dir = books
[[comics]]
pp = 3
script = None
dir = comics
EOF
else
    echo "sabnzbd.ini exists, updating wizard settings..."
    # Update existing config to bypass wizard
    sed -i 's/^auto_browser = .*/auto_browser = 0/' "$SABNZBD_INI"
    
    # Add first_cfg_step if not present
    if ! grep -q "first_cfg_step" "$SABNZBD_INI"; then
        sed -i '/\[misc\]/a first_cfg_step = 0' "$SABNZBD_INI"
    else
        sed -i 's/^first_cfg_step = .*/first_cfg_step = 0/' "$SABNZBD_INI"
    fi
fi

# Ensure download directories exist with correct permissions
echo "Creating download directories..."
mkdir -p "$SCRIPT_DIR/../downloads/complete"
mkdir -p "$SCRIPT_DIR/../downloads/incomplete"
chmod 777 "$SCRIPT_DIR/../downloads/complete"
chmod 777 "$SCRIPT_DIR/../downloads/incomplete"

# Create directories for each category
for category in movies tv music books comics; do
    mkdir -p "$SCRIPT_DIR/../downloads/complete/$category"
    chmod 777 "$SCRIPT_DIR/../downloads/complete/$category"
done

echo "SABnzbd initialization complete!"