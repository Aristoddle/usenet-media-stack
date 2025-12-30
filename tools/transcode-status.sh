#!/bin/bash
# Quick transcode status checker
# Run: ./tools/transcode-status.sh

echo "=== SVT-AV1 Transcode Status ==="
echo "Time: $(date)"
echo ""

echo "--- System Load ---"
uptime
echo ""

echo "--- Active FFmpeg Processes ---"
pgrep -a ffmpeg | grep -v grep | while read pid rest; do
    cpu=$(ps -p $pid -o %cpu= 2>/dev/null || echo "0")
    file=$(echo "$rest" | grep -oP '(?<=-i )[^ ]+' | xargs basename 2>/dev/null)
    echo "PID $pid: ${cpu}% CPU - $file"
done
echo ""

echo "--- Output Files ---"
for f in \
    "/var/mnt/pool/movies/Dogma (1999)/Dogma.AV1.mkv" \
    "/var/mnt/pool/downloads/makemkv-output/A Bug's Life (1998)/A Bug's Life.AV1.mkv" \
    "/var/mnt/pool/downloads/makemkv-output/A.Haunting.In.Venice.2023.COMPLETE.BLURAY-BDA/A Haunting in Venice.AV1.mkv"; do
    if [[ -f "$f" ]]; then
        size=$(du -h "$f" 2>/dev/null | cut -f1)
        echo "$size - $(basename "$f")"
    fi
done
echo ""

echo "--- Latest Progress (last line per log) ---"
for log in /tmp/ffmpeg-dogma.log /tmp/transcode-logs/*.log; do
    if [[ -f "$log" ]]; then
        name=$(basename "$log" .log)
        progress=$(tail -1 "$log" 2>/dev/null | grep -oP 'frame=\s*\d+' | tail -1)
        echo "$name: $progress"
    fi
done
