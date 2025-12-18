#!/usr/bin/env bash
set -euo pipefail

LIST_FILE="${1:-docs/komga-corrupt-cbz.md}"
ROOT_PREFIX="/comics/"
QUARANTINE_DIR="${QUARANTINE_DIR:-}"
DO_QUARANTINE="${DO_QUARANTINE:-0}"

if [[ ! -f "$LIST_FILE" ]]; then
  echo "List file not found: $LIST_FILE" >&2
  exit 1
fi

# Extract file paths from markdown list
mapfile -t paths < <(awk '/^-[[:space:]]+\/comics\// {sub(/^- /, ""); print}' "$LIST_FILE")

if [[ ${#paths[@]} -eq 0 ]]; then
  echo "No /comics paths found in $LIST_FILE" >&2
  exit 0
fi

python - <<'PY'
import os, sys, zipfile
paths = [line.strip() for line in sys.stdin if line.strip()]
failed = []
for p in paths:
    if not os.path.exists(p):
        failed.append((p, "MISSING"))
        continue
    try:
        with zipfile.ZipFile(p, 'r') as z:
            bad = z.testzip()
            if bad:
                failed.append((p, f"BAD:{bad}"))
    except Exception as e:
        failed.append((p, f"ERROR:{e}"))

if failed:
    print("\nCorrupt/missing files:")
    for p, err in failed:
        print(f"- {p} :: {err}")
    sys.exit(2)
else:
    print("All listed files validated OK")
PY
<<EOF
$(printf '%s\n' "${paths[@]}")
EOF

if [[ "$DO_QUARANTINE" == "1" ]]; then
  if [[ -z "$QUARANTINE_DIR" ]]; then
    echo "Set QUARANTINE_DIR to use quarantine mode" >&2
    exit 1
  fi
  mkdir -p "$QUARANTINE_DIR"
  for p in "${paths[@]}"; do
    if [[ -f "$p" ]]; then
      mv -n "$p" "$QUARANTINE_DIR/"
    fi
  done
  echo "Moved listed files to $QUARANTINE_DIR"
fi
