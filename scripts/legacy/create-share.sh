#!/bin/bash
# Script to create a new Samba share

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <share_name> <path>"
    exit 1
fi

SHARE_NAME="$1"
SHARE_PATH="$2"

if [ ! -d "$SHARE_PATH" ]; then
    echo "Error: Directory $SHARE_PATH does not exist"
    exit 1
fi

net usershare add "$SHARE_NAME" "$SHARE_PATH" "" everyone:F guest_ok=y

if [ $? -eq 0 ]; then
    echo "Share '$SHARE_NAME' created successfully"
    echo "Windows: \\\\$(hostname)\\$SHARE_NAME"
    echo "macOS:   smb://$(hostname)/$SHARE_NAME"
    echo "Linux:   mount -t cifs //$(hostname)/$SHARE_NAME /mnt/point -o guest"
else
    echo "Error creating share"
fi
