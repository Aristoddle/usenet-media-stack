#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-/mnt/fast8tb/Cloud/OneDrive/Books}"

if [[ ! -d "$ROOT" ]]; then
  echo "Books root not found: $ROOT" >&2
  exit 1
fi

echo "Inventory for: $ROOT"
echo
echo "Top-level sizes:"
du -sh "$ROOT"/* 2>/dev/null | sort -h
echo

python3 - <<'PY'
import os
import sys
from collections import Counter

root = os.environ.get("BOOKS_ROOT", "/mnt/fast8tb/Cloud/OneDrive/Books")
targets = ["Audiobooks", "Default", "Real Books", "Calibre", "Readarr", "Spoken", "eBooks"]
for name in targets:
    path = os.path.join(root, name)
    if not os.path.isdir(path):
        continue
    counter = Counter()
    file_count = 0
    for dirpath, _, filenames in os.walk(path):
        for filename in filenames:
            file_count += 1
            _, ext = os.path.splitext(filename)
            ext = (ext.lower().lstrip(".") or "<noext>")
            counter[ext] += 1
    print(f"{path}: {file_count} files")
    for ext, count in counter.most_common(10):
        print(f"  {ext}: {count}")
    print()
PY
