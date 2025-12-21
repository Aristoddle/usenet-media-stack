# Local Endpoints (loopback / LAN)

> Quick launcher for services when running the stack locally on this machine. All links are `http://localhost` and assume default ports and the current compose files. If a link 404s, check that the service is up with `docker ps` and that Traefik isn't overriding ports.

## Core automation
- Prowlarr: [http://localhost:9696](http://localhost:9696)
- Sonarr: [http://localhost:8989](http://localhost:8989)
- Radarr: [http://localhost:7878](http://localhost:7878)
- Lidarr: [http://localhost:8686](http://localhost:8686)
- Whisparr: [http://localhost:6969](http://localhost:6969)
- SABnzbd: [http://localhost:8080](http://localhost:8080)
- Transmission: [http://localhost:9091](http://localhost:9091)
- Aria2 (RPC only): [http://localhost:6800/jsonrpc](http://localhost:6800/jsonrpc)

## Comics / manga / books
- Mylar: [http://localhost:8090](http://localhost:8090)
- Komga: [http://localhost:8081](http://localhost:8081)
- Komf (metadata fetcher): [http://localhost:8085](http://localhost:8085)
- Kavita: [http://localhost:5000](http://localhost:5000)
- Suwayomi (Tachidesk): [http://localhost:4567](http://localhost:4567)

## Requests / oversight / monitoring
- Overseerr: [http://localhost:5055](http://localhost:5055)
- Bazarr: [http://localhost:6767](http://localhost:6767)
- Netdata: [http://localhost:19999](http://localhost:19999)
- Portainer: [http://localhost:9000](http://localhost:9000)
- Uptime Kuma: [http://localhost:3001](http://localhost:3001)
- Tdarr server: [http://localhost:8265](http://localhost:8265)
- Tdarr node: [http://localhost:8266](http://localhost:8266)

## Media servers
- Plex (primary): [http://localhost:32400](http://localhost:32400)
- Stash: [http://localhost:9998](http://localhost:9998)

## Background services (no web UI)
- Recyclarr: TRaSH Guide quality profiles (CLI only)
- Samba: `smb://localhost` (ports 139, 445)

### Notes
- Torrent traffic is direct (no VPN) in this snapshot.
- If you override ports or enable Traefik host rules, update this page accordingly.
