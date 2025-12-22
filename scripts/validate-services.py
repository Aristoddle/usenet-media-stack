#!/usr/bin/env python3
"""
Lightweight health checker for local stack services.
Reads API keys from existing configs (no secrets committed)
and hits status endpoints on localhost.

Uses the shared api_client library for consistent HTTP handling.
"""
import json
import os
import pathlib
import sys

# Add lib to path for imports
sys.path.insert(0, str(pathlib.Path(__file__).parent.parent / "lib" / "python"))

from api_client import (
    ArrClient,
    SabClient,
    HTTPClient,
    read_api_key_xml,
    read_sab_key,
    get_config_root,
)


def main():
    config_root = get_config_root()
    results = {}

    # Read API keys
    prowlarr_key = read_api_key_xml(config_root / "prowlarr" / "config.xml")
    sonarr_key = read_api_key_xml(config_root / "sonarr" / "config.xml")
    radarr_key = read_api_key_xml(config_root / "radarr" / "config.xml")
    sab_key = read_sab_key(config_root / "sabnzbd" / "sabnzbd.ini")

    # Traefik dashboard (insecure for now) - tolerate 200/401/403
    traefik = HTTPClient("http://localhost:8082")
    status, body = traefik.get("/dashboard/")
    results["traefik"] = {"status": status, "body": body[:200] if body else ""}

    # Prowlarr - uses v1 API
    if prowlarr_key:
        prowlarr = ArrClient("http://localhost:9696", prowlarr_key)
        status, body = prowlarr.get("/api/v1/system/status")
        results["prowlarr"] = {"status": status, "body": body[:500] if body else ""}

    # Sonarr
    if sonarr_key:
        sonarr = ArrClient("http://localhost:8989", sonarr_key)
        results["sonarr"] = {
            "healthy": sonarr.is_healthy(),
            "status": 200 if sonarr.is_healthy() else None,
        }

    # Radarr
    if radarr_key:
        radarr = ArrClient("http://localhost:7878", radarr_key)
        results["radarr"] = {
            "healthy": radarr.is_healthy(),
            "status": 200 if radarr.is_healthy() else None,
        }

    # SABnzbd
    if sab_key:
        sab = SabClient("http://localhost:8080", sab_key)
        queue = sab.call_json("mode=queue&output=json")
        results["sabnzbd"] = {
            "healthy": sab.is_healthy(),
            "queue": queue.get("queue", {}).get("slots", [])[:5] if queue else [],
        }

    # Transmission over VPN: expect 409 (missing session id) or 200
    transmission = HTTPClient("http://localhost:9091")
    t_status, t_body = transmission.get("/transmission/rpc")
    results["transmission"] = {
        "status": t_status,
        "body": t_body[:200] if t_body else "",
    }

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
