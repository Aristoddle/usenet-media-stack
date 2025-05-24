#!/bin/bash
###############################################################################
#  configure-services.sh - Configure services via direct API/config manipulation
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/../config"

echo "=== Configuring Usenet Services ==="

# Function to update INI file values
update_ini() {
    local file="$1"
    local section="$2"
    local key="$3"
    local value="$4"
    
    if grep -q "^\[$section\]" "$file"; then
        # Update existing key or add if not exists
        if grep -q "^$key = " "$file"; then
            sed -i "/^\[$section\]/,/^\[/{s/^$key = .*/$key = $value/}" "$file"
        else
            sed -i "/^\[$section\]/a $key = $value" "$file"
        fi
    fi
}

# Configure SABnzbd for local passwordless access
configure_sabnzbd() {
    echo "Configuring SABnzbd..."
    local config_file="$CONFIG_DIR/sabnzbd/sabnzbd.ini"
    
    if [[ -f "$config_file" ]]; then
        # Disable authentication for local network
        update_ini "$config_file" "misc" "username" ""
        update_ini "$config_file" "misc" "password" ""
        update_ini "$config_file" "misc" "inet_exposure" "2"  # Local network only
        update_ini "$config_file" "misc" "auto_browser" "0"
        update_ini "$config_file" "misc" "first_cfg_step" "0"
        
        # Add servers section if not exists
        if ! grep -q "^\[servers\]" "$config_file"; then
            cat >> "$config_file" << 'EOF'

[servers]
[[Newshosting]]
name = Newshosting
host = news.newshosting.com
port = 563
username = j3lanzone@gmail.com
password = @Kirsten123
connections = 30
ssl = 1
enable = 1
priority = 0

[[UsenetExpress]]
name = UsenetExpress  
host = usenetexpress.com
port = 563
username = une3226253
password = kKqzQXPeN
connections = 20
ssl = 1
enable = 1
priority = 1

[[Frugalusenet]]
name = Frugalusenet
host = newswest.frugalusenet.com
port = 563
username = aristoddle
password = fishing123
connections = 10
ssl = 1
enable = 1
priority = 2
EOF
        fi
        
        echo "✓ SABnzbd configured for local passwordless access"
    else
        echo "✗ SABnzbd config not found"
    fi
}

# Configure Prowlarr for local passwordless access
configure_prowlarr() {
    echo "Configuring Prowlarr..."
    local config_file="$CONFIG_DIR/prowlarr/config.xml"
    
    if [[ -f "$config_file" ]]; then
        # Disable authentication
        sed -i 's/<AuthenticationMethod>.*<\/AuthenticationMethod>/<AuthenticationMethod>None<\/AuthenticationMethod>/' "$config_file"
        
        echo "✓ Prowlarr configured for local passwordless access"
    else
        echo "✗ Prowlarr config not found"
    fi
}

# Configure Sonarr for local passwordless access
configure_sonarr() {
    echo "Configuring Sonarr..."
    local config_file="$CONFIG_DIR/sonarr/config.xml"
    
    if [[ -f "$config_file" ]]; then
        # Disable authentication
        sed -i 's/<AuthenticationMethod>.*<\/AuthenticationMethod>/<AuthenticationMethod>None<\/AuthenticationMethod>/' "$config_file"
        
        echo "✓ Sonarr configured for local passwordless access"
    else
        echo "✗ Sonarr config not found"
    fi
}

# Configure Radarr for local passwordless access
configure_radarr() {
    echo "Configuring Radarr..."
    local config_file="$CONFIG_DIR/radarr/config.xml"
    
    if [[ -f "$config_file" ]]; then
        # Disable authentication
        sed -i 's/<AuthenticationMethod>.*<\/AuthenticationMethod>/<AuthenticationMethod>None<\/AuthenticationMethod>/' "$config_file"
        
        echo "✓ Radarr configured for local passwordless access"
    else
        echo "✗ Radarr config not found"
    fi
}

# Configure Readarr for local passwordless access
configure_readarr() {
    echo "Configuring Readarr..."
    local config_file="$CONFIG_DIR/readarr/config.xml"
    
    if [[ -f "$config_file" ]]; then
        # Disable authentication
        sed -i 's/<AuthenticationMethod>.*<\/AuthenticationMethod>/<AuthenticationMethod>None<\/AuthenticationMethod>/' "$config_file"
        
        echo "✓ Readarr configured for local passwordless access"
    else
        echo "✗ Readarr config not found"
    fi
}

# Configure Bazarr for local passwordless access
configure_bazarr() {
    echo "Configuring Bazarr..."
    local config_file="$CONFIG_DIR/bazarr/config/config.ini"
    
    if [[ -f "$config_file" ]]; then
        # Update authentication settings
        update_ini "$config_file" "auth" "type" "None"
        update_ini "$config_file" "auth" "username" ""
        update_ini "$config_file" "auth" "password" ""
        
        echo "✓ Bazarr configured for local passwordless access"
    else
        echo "✗ Bazarr config not found"
    fi
}

# Main execution
main() {
    configure_sabnzbd
    configure_prowlarr
    configure_sonarr
    configure_radarr
    configure_readarr
    configure_bazarr
    
    echo ""
    echo "=== Configuration Complete ==="
    echo "Services configured for passwordless access from local network."
    echo "Restart services to apply changes:"
    echo "  cd /home/joe/usenet && ./manage.sh restart"
}

main "$@"