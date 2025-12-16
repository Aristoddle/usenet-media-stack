#!/usr/bin/env zsh
set -e
SCRIPT_DIR=${0:A:h}

python3 "$SCRIPT_DIR/validate-services.py"
