#!/usr/bin/env python3
"""
Lightweight health checker for local stack services.
Reads API keys from existing configs (no secrets committed)
and hits status endpoints on localhost.
"""
import json
import os
import pathlib
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET

CONFIG_ROOT = pathlib.Path(os.environ.get("CONFIG_ROOT", "/home/deck/usenet/config"))


def read_api_key_xml(path):
    if not path.exists():
        return None
    try:
        tree = ET.parse(path)
        api = tree.find(".//ApiKey")
        return api.text.strip() if api is not None else None
    except ET.ParseError:
        return None


def read_sab_key(path):
    if not path.exists():
        return None
    for line in path.read_text().splitlines():
        if line.strip().startswith("api_key"):
            return line.split("=", 1)[1].strip()
    return None


def get_json(url, headers=None):
    req = urllib.request.Request(url, headers=headers or {})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            return resp.status, body
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace")
    except Exception as e:
        return None, str(e)


def main():
    prowlarr_key = read_api_key_xml(CONFIG_ROOT / "prowlarr" / "config.xml")
    sonarr_key = read_api_key_xml(CONFIG_ROOT / "sonarr" / "config.xml")
    radarr_key = read_api_key_xml(CONFIG_ROOT / "radarr" / "config.xml")
    sab_key = read_sab_key(CONFIG_ROOT / "sabnzbd" / "sabnzbd.ini")
    results = {}

    # Traefik dashboard (insecure for now) - tolerate 200/401/403
    status, body = get_json("http://localhost:8082/dashboard/")
    results["traefik"] = {"status": status, "body": body[:200]}

    if prowlarr_key:
        status, body = get_json(
            "http://localhost:9696/api/v1/system/status",
            {"X-Api-Key": prowlarr_key, "Accept": "application/json"},
        )
        results["prowlarr"] = {"status": status, "body": body[:500]}

    if sonarr_key:
        status, body = get_json(
            "http://localhost:8989/api/v3/system/status",
            {"X-Api-Key": sonarr_key, "Accept": "application/json"},
        )
        results["sonarr"] = {"status": status, "body": body[:500]}

    if radarr_key:
        status, body = get_json(
            "http://localhost:7878/api/v3/system/status",
            {"X-Api-Key": radarr_key, "Accept": "application/json"},
        )
        results["radarr"] = {"status": status, "body": body[:500]}

    if sab_key:
        status, body = get_json(
            f"http://localhost:8080/api?mode=queue&output=json&apikey={sab_key}"
        )
        results["sabnzbd"] = {"status": status, "body": body[:500]}

    # Transmission over VPN: expect 409 (missing session id) or 200
    t_status, t_body = get_json("http://localhost:9091/transmission/rpc")
    results["transmission"] = {"status": t_status, "body": t_body[:200]}

    print(json.dumps(results, indent=2))


if __name__ == "__main__":
    main()
