#!/usr/bin/env python3
"""
Komga gap report (uses Komga REST API, Basic Auth)

Usage:
  KOMGA_URL=http://127.0.0.1:8081 \
  KOMGA_USER=admin@example.com \
  KOMGA_PASS=secret \
  scripts/komga-gap-report.py > /tmp/komga_gap_report.md

Outputs a markdown report listing series with detected numeric gaps
(volumes or chapters) based on filenames in Komga.

Notes:
- Read-only: no writes to Komga.
- Only detects simple integer sequences like v01 / vol 1 / ch 12.
- Uses mirror/root currently configured in Komga; no filesystem access needed.
"""

import os
import re
import sys
import json
import urllib.request
import urllib.error
import base64
from typing import Dict, List

URL = os.environ.get("KOMGA_URL", "http://127.0.0.1:8081")
USER = os.environ.get("KOMGA_USER")
PWD = os.environ.get("KOMGA_PASS")
PAGE_SIZE = 500

if not USER or not PWD:
    sys.stderr.write("Error: KOMGA_USER and KOMGA_PASS must be set\n")
    sys.exit(1)

headers = {
    "Authorization": "Basic " + base64.b64encode(f"{USER}:{PWD}".encode()).decode(),
    "Accept": "application/json"
}


def fetch(url: str):
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())


def fetch_all_series():
    series = []
    page = 0
    while True:
        data = fetch(f"{URL}/api/v1/series?page={page}&size={PAGE_SIZE}")
        series.extend(data.get("content", []))
        if data.get("last", True):
            break
        page += 1
    return series


def fetch_books(series_id: str):
    # Komga supports sorting; use default order
    data = fetch(f"{URL}/api/v1/series/{series_id}/books?size={PAGE_SIZE}")
    return data.get("content", [])


vol_re = re.compile(r"(?:^|[^A-Za-z0-9])(v|vol|volume)\s*0*(\d+)", re.IGNORECASE)
ch_re = re.compile(r"(?:^|[^A-Za-z0-9])(ch|chapter)\s*0*(\d+)", re.IGNORECASE)
num_re = re.compile(r"(?:^|[^A-Za-z0-9])0*(\d+)(?![0-9])")


def extract_numbers(name: str) -> List[int]:
    nums = []
    for rx in (vol_re, ch_re, num_re):
        for m in rx.finditer(name):
            try:
                nums.append(int(m.group(2 if rx != num_re else 1)))
            except Exception:
                continue
        if nums:
            break  # prefer vol/ch patterns first
    return sorted(set(nums))


def find_gaps(nums: List[int]):
    if len(nums) < 2:
        return []
    gaps = []
    for a, b in zip(nums, nums[1:]):
        if b - a > 1:
            gaps.extend(range(a + 1, b))
    return gaps


def main():
    series_list = fetch_all_series()
    report = []
    for s in series_list:
        sid = s["id"]
        name = s.get("metadata", {}).get("title") or s["name"]
        books = fetch_books(sid)
        nums = []
        for b in books:
            fname = b.get("name") or b.get("url", "")
            nums.extend(extract_numbers(fname))
        nums = sorted(set(nums))
        gaps = find_gaps(nums)
        if gaps:
            report.append({"series": name, "have": nums, "gaps": gaps})

    # Output markdown
    print("# Komga Gap Report\n")
    print(f"Series scanned: {len(series_list)}")
    print(f"Series with gaps: {len(report)}\n")
    for item in report:
        print(f"## {item['series']}")
        print(f"Missing: {', '.join(map(str, item['gaps']))}\n")


if __name__ == "__main__":
    main()
