#!/usr/bin/env python3
"""
Unified API client for Usenet Media Stack services.

Provides consistent HTTP request patterns for:
- ARR services (Prowlarr, Sonarr, Radarr, Lidarr) with X-Api-Key auth
- SABnzbd with apikey query param
- Komga/Kavita with Basic Auth or JWT

Usage:
    from lib.python.api_client import ArrClient, SabClient, KomgaClient

    # ARR services
    arr = ArrClient("http://localhost:8989", api_key="...")
    status = arr.get("/api/v3/system/status")

    # SABnzbd
    sab = SabClient("http://localhost:8080", api_key="...")
    queue = sab.call("mode=queue&output=json")

    # Komga
    komga = KomgaClient("http://localhost:8081", user="...", password="...")
    series = komga.get("/api/v1/series")
"""

import base64
import json
import os
import pathlib
import urllib.request
import urllib.error
import xml.etree.ElementTree as ET
from typing import Optional, Dict, Any, Tuple


class HTTPClient:
    """Base HTTP client with timeout and error handling."""

    def __init__(self, base_url: str, timeout: int = 10):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    def _request(
        self,
        method: str,
        endpoint: str,
        headers: Optional[Dict[str, str]] = None,
        data: Optional[bytes] = None,
    ) -> Tuple[Optional[int], str]:
        """
        Make an HTTP request.

        Returns:
            Tuple of (status_code, response_body)
            status_code is None on connection errors
        """
        url = f"{self.base_url}{endpoint}"
        req = urllib.request.Request(url, data=data, headers=headers or {}, method=method)

        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as resp:
                body = resp.read().decode("utf-8", errors="replace")
                return resp.status, body
        except urllib.error.HTTPError as e:
            return e.code, e.read().decode("utf-8", errors="replace")
        except Exception as e:
            return None, str(e)

    def get(self, endpoint: str, headers: Optional[Dict[str, str]] = None) -> Tuple[Optional[int], str]:
        return self._request("GET", endpoint, headers)

    def post(
        self,
        endpoint: str,
        data: Optional[str] = None,
        headers: Optional[Dict[str, str]] = None,
    ) -> Tuple[Optional[int], str]:
        encoded = data.encode("utf-8") if data else None
        return self._request("POST", endpoint, headers, encoded)


class ArrClient(HTTPClient):
    """
    Client for ARR services (Prowlarr, Sonarr, Radarr, Lidarr, Bazarr).

    Uses X-Api-Key header for authentication.
    """

    def __init__(self, base_url: str, api_key: str, timeout: int = 10):
        super().__init__(base_url, timeout)
        self.api_key = api_key
        self._headers = {
            "X-Api-Key": api_key,
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def get(self, endpoint: str) -> Tuple[Optional[int], str]:
        return super().get(endpoint, self._headers)

    def post(self, endpoint: str, data: Optional[str] = None) -> Tuple[Optional[int], str]:
        return super().post(endpoint, data, self._headers)

    def get_json(self, endpoint: str) -> Optional[Dict[str, Any]]:
        """GET request returning parsed JSON or None on error."""
        status, body = self.get(endpoint)
        if status == 200:
            try:
                return json.loads(body)
            except json.JSONDecodeError:
                return None
        return None

    def post_json(self, endpoint: str, payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """POST request with JSON payload, returning parsed response."""
        status, body = self.post(endpoint, json.dumps(payload))
        if status in (200, 201):
            try:
                return json.loads(body)
            except json.JSONDecodeError:
                return None
        return None

    def is_healthy(self) -> bool:
        """Check if service is responding."""
        data = self.get_json("/api/v3/system/status")
        return data is not None and "version" in data


class SabClient(HTTPClient):
    """
    Client for SABnzbd.

    Uses apikey query parameter for authentication.
    """

    def __init__(self, base_url: str, api_key: str, timeout: int = 10):
        super().__init__(base_url, timeout)
        self.api_key = api_key

    def call(self, params: str) -> Tuple[Optional[int], str]:
        """
        Make SABnzbd API call.

        Args:
            params: URL-encoded parameters (e.g., "mode=queue&output=json")

        Returns:
            Tuple of (status_code, response_body)
        """
        endpoint = f"/api?apikey={self.api_key}&{params}"
        return self.get(endpoint)

    def call_json(self, params: str) -> Optional[Dict[str, Any]]:
        """API call returning parsed JSON."""
        status, body = self.call(params)
        if status == 200:
            try:
                return json.loads(body)
            except json.JSONDecodeError:
                return None
        return None

    def is_healthy(self) -> bool:
        """Check if SABnzbd is responding."""
        status, body = self.call("mode=version")
        return status == 200 and body.strip() != ""


class KomgaClient(HTTPClient):
    """
    Client for Komga.

    Uses Basic Auth for authentication.
    """

    def __init__(self, base_url: str, user: str, password: str, timeout: int = 10):
        super().__init__(base_url, timeout)
        auth_str = base64.b64encode(f"{user}:{password}".encode()).decode()
        self._headers = {
            "Authorization": f"Basic {auth_str}",
            "Accept": "application/json",
        }

    def get(self, endpoint: str) -> Tuple[Optional[int], str]:
        return super().get(endpoint, self._headers)

    def get_json(self, endpoint: str) -> Optional[Dict[str, Any]]:
        """GET request returning parsed JSON."""
        status, body = self.get(endpoint)
        if status == 200:
            try:
                return json.loads(body)
            except json.JSONDecodeError:
                return None
        return None

    def is_healthy(self) -> bool:
        """Check if Komga is responding."""
        status, _ = self.get("/api/v1/libraries")
        return status == 200


# Config reading utilities

def read_api_key_xml(path: pathlib.Path) -> Optional[str]:
    """Read API key from ARR service config.xml file."""
    if not path.exists():
        return None
    try:
        tree = ET.parse(path)
        api_elem = tree.find(".//ApiKey")
        return api_elem.text.strip() if api_elem is not None else None
    except ET.ParseError:
        return None


def read_sab_key(path: pathlib.Path) -> Optional[str]:
    """Read API key from sabnzbd.ini file."""
    if not path.exists():
        return None
    for line in path.read_text().splitlines():
        if line.strip().startswith("api_key"):
            return line.split("=", 1)[1].strip()
    return None


def get_config_root() -> pathlib.Path:
    """Get config root from environment or default."""
    return pathlib.Path(os.environ.get("CONFIG_ROOT", "/srv/usenet/config"))
