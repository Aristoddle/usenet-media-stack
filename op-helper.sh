#!/bin/bash
# 1Password CLI Helper Script
# Works around desktop integration issues on Ubuntu

# Disable biometric/desktop integration
export OP_BIOMETRIC_UNLOCK_ENABLED=false

# Store session token to avoid repeated logins
OP_SESSION_FILE="/tmp/.op_session_$(whoami)"

# Function to ensure we're signed in
op_ensure_signin() {
    # Check if we have a valid session
    if [ -f "$OP_SESSION_FILE" ]; then
        export OP_SESSION_my=$(cat "$OP_SESSION_FILE")
        if OP_BIOMETRIC_UNLOCK_ENABLED=false op whoami &>/dev/null; then
            return 0
        fi
    fi
    
    # Sign in and save session
    echo "Signing in to 1Password..." >&2
    local session=$(echo "rapid coffee politics lamp" | OP_BIOMETRIC_UNLOCK_ENABLED=false op signin --raw 2>/dev/null)
    if [ -n "$session" ]; then
        echo "$session" > "$OP_SESSION_FILE"
        chmod 600 "$OP_SESSION_FILE"
        export OP_SESSION_my="$session"
    else
        echo "Failed to sign in to 1Password" >&2
        return 1
    fi
}

# Function to run op commands with session
op_run() {
    op_ensure_signin || return 1
    OP_BIOMETRIC_UNLOCK_ENABLED=false op "$@"
}

# Export for use in other scripts
export -f op_ensure_signin
export -f op_run

# If script is sourced, just export functions
# If executed directly, run the command
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    op_run "$@"
fi