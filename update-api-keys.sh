#!/bin/bash
# Script to retrieve API keys from Usenet sites and update 1Password

source $HOME/usenet/op-helper.sh

echo "=== API KEY RETRIEVAL HELPER ==="
echo "This script will help you get API keys from sites that don't have them stored"
echo

# Function to update API key in 1Password
update_api_key() {
    local item_id="$1"
    local api_key="$2"
    local field_name="${3:-API Key}"
    
    echo "Updating item $item_id with API key..."
    
    # Create the field JSON
    field_json=$(cat <<EOF
[{"op": "add", "path": "/fields/-", "value": {"label": "$field_name", "value": "$api_key", "type": "STRING"}}]
EOF
)
    
    # Update the item
    op_run item edit "$item_id" --fields "$field_json" >/dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo "✅ API key added successfully"
    else
        echo "❌ Failed to update API key"
    fi
}

# Sites that need API keys
echo "Sites needing API keys:"
echo
echo "1. UsenetExpress - https://members.usenetexpress.com/"
echo "   Username: une3226253"
echo "   Password: kKqzQXPeN"
echo "   📋 Go to: Account Settings > API Access"
echo "   Item IDs: argf5fzsxvvaj4mxftg6idmyui, uitmnbszzx5hhsufelcptu7dkq"
echo
echo "2. Newshosting - https://controlpanel.newshosting.com"
echo "   Username: j3lanzone@gmail.com"
echo "   Password: @Kirsten123"
echo "   📋 Go to: Account > Server Details"
echo "   Item IDs: ji22mmzk73yadhsfsxo6gdz6x4, epudnf4wxntrrlwls6q65zyg4u"
echo
echo "3. Frugalusenet - https://billing.frugalusenet.com/login/"
echo "   Username: aristoddle"
echo "   Password: fishing123"
echo "   📋 Go to: Account > Server Details"
echo "   Item IDs: pdbkpzswyair562nf6xq3obzti, mlk6mwaxik6oyizesap7yjrdye"
echo

# Interactive mode
read -p "Would you like to update API keys now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    echo "For each site, login and get the API key, then paste it here."
    echo
    
    # UsenetExpress
    read -p "UsenetExpress API Key (or press Enter to skip): " usenet_express_key
    if [ -n "$usenet_express_key" ]; then
        update_api_key "argf5fzsxvvaj4mxftg6idmyui" "$usenet_express_key"
        update_api_key "uitmnbszzx5hhsufelcptu7dkq" "$usenet_express_key"
    fi
    
    # Newshosting
    read -p "Newshosting API Key (or press Enter to skip): " newshosting_key
    if [ -n "$newshosting_key" ]; then
        update_api_key "ji22mmzk73yadhsfsxo6gdz6x4" "$newshosting_key"
        update_api_key "epudnf4wxntrrlwls6q65zyg4u" "$newshosting_key"
    fi
    
    # Frugalusenet
    read -p "Frugalusenet API Key (or press Enter to skip): " frugal_key
    if [ -n "$frugal_key" ]; then
        update_api_key "pdbkpzswyair562nf6xq3obzti" "$frugal_key"
        update_api_key "mlk6mwaxik6oyizesap7yjrdye" "$frugal_key"
    fi
fi

echo
echo "Current API Keys:"
echo "✅ Nzbgeek: SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a"
echo "✅ NZB Finder: 14b3d53dbd98adc79fed0d336998536a"
echo "✅ Nzb.su: 25ba450623c248e2b58a3c0dc54aa019"
echo "✅ Nzbplanet: 046863416d824143c79b6725982e293d"
echo "✅ SABnzbd: 0b544ecf089649f0ba8905d869a88f22"