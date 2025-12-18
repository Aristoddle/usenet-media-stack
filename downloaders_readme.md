# Downloader & Indexer Endpoints (local stack)

All services are on the seed host; replace `localhost` with the host IP for LAN access.

## Download clients
- **SABnzbd** – http://localhost:8080  
  - API key: in `/var/mnt/fast8tb/config/sabnzbd/sabnzbd.ini` (`api_key`); categories map to `/downloads/sabnzbd/{incomplete,complete}` (comics → `/downloads/sabnzbd/complete/comics`).  
  - Quick test: `curl -s 'http://localhost:8080/api?mode=queue&output=json&apikey=<API>'`
- **Transmission** – http://localhost:9091 (web) / RPC at `http://localhost:9091/transmission/rpc`  
  - No auth. Downloads: `/downloads/transmission/complete`; partials: `/downloads/transmission/incomplete`; watch: `/downloads/transmission/watch`.  
  - Test RPC: `sid=$(curl -si http://localhost:9091/transmission/rpc | awk -F': ' 'tolower($1)==\"x-transmission-session-id:\"{print $2;exit}'|tr -d '\\r'); curl -s -H \"X-Transmission-Session-Id: $sid\" -d '{\"method\":\"session-get\"}' http://localhost:9091/transmission/rpc`
- **Aria2** – JSON-RPC at `http://localhost:6800/rpc` (Prowlarr) or `/jsonrpc` (manual)  
  - Auth: first param `token:${ARIA2_SECRET}` from `.env`. Downloads: `/downloads/aria2/complete`.  
  - Test: `curl -s -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":\"v\",\"method\":\"aria2.getVersion\",\"params\":[\"token:${ARIA2_SECRET}\"]}' http://localhost:6800/jsonrpc`

## Indexer/front-end
- **Prowlarr** – http://localhost:9696 (API key in `/var/mnt/fast8tb/config/prowlarr/config.xml`).  
  - Download clients registered: SABnzbd, Transmission, Aria2 (rpcPath `/rpc`).  
  - Indexers: NZBgeek, NZBFinder, NZB.su, NZBPlanet, Nyaa.

## Media managers (for context)
- **Sonarr** http://localhost:8989, **Radarr** http://localhost:7878, **Lidarr** http://localhost:8686, **Bazarr** http://localhost:6767, **Overseerr** http://localhost:5055, **Mylar** http://localhost:8090.

## Comics/Reading
- **Komga** – http://localhost:8081 (internal port 25600).  
  - If login fails, reset credentials via Komga admin CLI or create a new user in the UI; config at `/var/mnt/fast8tb/config/komga`.
- **Komf** – http://localhost:8085 (metadata helper).

## Ops/monitoring
- **Portainer** http://localhost:9000, **Netdata** http://localhost:19999.

## Paths (host)
- Downloads root: `/var/mnt/fast8tb/Local/downloads` mounted as `/downloads` in all downloader containers.
- Per-client folders: `transmission/{complete,incomplete,watch}`, `aria2/{complete,incomplete,watch}`, `sabnzbd/{complete,incomplete}`.

## Notes on Prowlarr + Aria2
- Prowlarr’s Aria2 connector defaults to rpcPath `/rpc`. We set the client with `/rpc`; manual curl uses `/jsonrpc`. If tests fail, flip rpcPath to `/jsonrpc` in Prowlarr and retest.

