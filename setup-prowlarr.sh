#!/bin/bash
# Extract Usenet indexer credentials for Prowlarr setup

source /home/joe/usenet/op-helper.sh

echo "=== Usenet Indexer Credentials ==="
echo

# Function to get item details
get_indexer_details() {
    local title="$1"
    echo "--- $title ---"
    
    # Get the item ID first
    item_id=$(op_run item list --format json | jq -r --arg title "$title" '.[] | select(.title == $title) | .id' | head -1)
    
    if [ -n "$item_id" ]; then
        # Get full item details
        op_run item get "$item_id" --format json | jq -r '
            "URL: \(.urls[0].href // "N/A")",
            "Username: \(.fields[] | select(.label == "username" or .label == "email" or .type == "email") | .value // "N/A")",
            "Password: \(.fields[] | select(.label == "password" or .type == "concealed") | .value // "N/A")",
            "API Key: \(.fields[] | select(.label | test("api|key"; "i")) | .value // "Check website")"
        '
    else
        echo "Could not find item details"
    fi
    echo
}

# Get details for each indexer
for indexer in "Nzbgeek" "NZB Finder" "Nzb.su" "Nzbplanet"; do
    get_indexer_details "$indexer"
done

echo "=== Usenet Providers ==="
echo

for provider in "UsenetExpress" "Newshosting" "Frugalusenet"; do
    get_indexer_details "$provider"
done