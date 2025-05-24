#!/bin/bash
# Extract full Usenet credentials and check for API keys

source /home/joe/usenet/op-helper.sh

echo "=== USENET CREDENTIALS EXTRACTION ==="
echo "Generated: $(date)"
echo "===================================="
echo

# Function to get complete item details
get_full_details() {
    local title="$1"
    local category="$2"
    
    echo "### $title ($category) ###"
    
    # Get all matching items
    item_ids=$(op_run item list --format json | jq -r --arg title "$title" '.[] | select(.title == $title) | .id')
    
    if [ -z "$item_ids" ]; then
        echo "❌ Not found in 1Password"
        echo
        return
    fi
    
    # Process each matching item
    echo "$item_ids" | while read -r item_id; do
        if [ -n "$item_id" ]; then
            echo "Item ID: $item_id"
            
            # Get full item details
            item_json=$(op_run item get "$item_id" --format json 2>/dev/null)
            
            if [ -n "$item_json" ]; then
                # Extract basic info
                echo "$item_json" | jq -r '
                    "URL: \(.urls[0].href // "N/A")"
                '
                
                # Extract all fields
                echo "$item_json" | jq -r '
                    .fields[] | 
                    "  \(.label // .type): \(.value // "N/A")"
                '
                
                # Check specifically for API keys
                api_key=$(echo "$item_json" | jq -r '
                    .fields[] | 
                    select(.label | test("api|key|token"; "i")) | 
                    .value // empty
                ' | head -1)
                
                if [ -n "$api_key" ]; then
                    echo "✅ API Key found: $api_key"
                else
                    echo "⚠️  No API key stored - manual retrieval needed"
                fi
            fi
            echo "---"
        fi
    done
    echo
}

# Extract Usenet Providers
echo "=== USENET PROVIDERS ==="
echo
get_full_details "UsenetExpress" "Provider"
get_full_details "Newshosting" "Provider"
get_full_details "Frugalusenet" "Provider"

# Extract Usenet Indexers
echo "=== USENET INDEXERS ==="
echo
get_full_details "Nzbgeek" "Indexer"
get_full_details "NZB Finder" "Indexer"
get_full_details "Nzb.su" "Indexer"
get_full_details "Nzbplanet" "Indexer"

# Extract Download Clients
echo "=== DOWNLOAD CLIENTS ==="
echo
get_full_details "SABnzbd" "Client"
get_full_details "SABnzbd One-off Creds" "Client"

# Summary of what needs manual retrieval
echo "=== SUMMARY ==="
echo
echo "Sites needing manual API key retrieval:"
op_run item list --format json | jq -r '.[] | select(.title | test("nzb|usenet|sab"; "i")) | .title' | while read -r title; do
    item_json=$(op_run item get "$title" --format json 2>/dev/null)
    if [ -n "$item_json" ]; then
        api_key=$(echo "$item_json" | jq -r '.fields[] | select(.label | test("api|key|token"; "i")) | .value // empty' | head -1)
        if [ -z "$api_key" ]; then
            echo "  - $title"
        fi
    fi
done