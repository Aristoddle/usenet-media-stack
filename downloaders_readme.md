# Downloader & Indexer Endpoints (local stack)

All services are on the seed host; replace `localhost` with the host IP for LAN access.

## Download clients
- **SABnzbd** – http://localhost:8080  
  - API key: in `/var/mnt/fast8tb/config/sabnzbd/sabnzbd.ini` (`api_key`); categories map to `/downloads/sabnzbd/{incomplete,complete}` (comics → `/downloads/sabnzbd/complete/comics`).  
  - Quick test: `curl -s 'http://localhost:8080/api?mode=queue&output=json&apikey=<API>'`
- **Transmission** – http://localhost:9091 (web) / RPC at `http://localhost:9091/transmission/rpc`  
  - No auth. Downloads: `/downloads/transmission/complete`; partials: `/downloads/transmission/incomplete`; watch: `/downloads/transmission/watch`.  
  - Test RPC: `sid=$(curl -si http://localhost:9091/transmission/rpc | awk -F': ' 'tolower($1)==\"x-transmission-session-id:\"{print $2;exit}'|tr -d '\\r'); curl -s -H \"X-Transmission-Session-Id: $sid\" -d '{\"method\":\"session-get\"}' http://localhost:9091/transmission/rpc`
- **Aria2** – XML-RPC at `http://localhost:6800/rpc` (Prowlarr) or JSON-RPC at `/jsonrpc` (manual)  
  - Auth: Prowlarr expects the raw secret (it prepends `token:`); manual JSON-RPC uses `token:${ARIA2_SECRET}`. Downloads: `/downloads/aria2/complete`.  
  - Test: `curl -s -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":\"v\",\"method\":\"aria2.getVersion\",\"params\":[\"token:${ARIA2_SECRET}\"]}' http://localhost:6800/jsonrpc`

## Indexer/front-end
- **Prowlarr** – http://localhost:9696 (API key in `/var/mnt/fast8tb/config/prowlarr/config.xml`).  
  - Download clients registered: SABnzbd, Transmission, Aria2 (rpcPath `/rpc`).  
  - Indexers: NZBgeek, NZBFinder, NZB.su, NZBPlanet, Nyaa.

## Usenet providers (FrugalUsenet details)
- Primary/IPv4 servers: `news.frugalusenet.com`, `newswest.frugalusenet.com`, `eunews.frugalusenet.com`, `aunews.frugalusenet.com`, `asnews.frugalusenet.com`, `sanews.frugalusenet.com`.
- Bonus server: `bonus.frugalusenet.com` (backup/fill; 500–1000 GB/mo limit).
- IPv6 variants: `news-v6.frugalusenet.com`, `newswest-v6.frugalusenet.com`, `eunews-v6.frugalusenet.com`, `aunews-v6.frugalusenet.com`, `asnews-v6.frugalusenet.com`, `sanews-v6.frugalusenet.com`.
- Ports: Standard 20, 23, 53, 119, 443, 2000, 8080, 9000, 9001, 9002. SSL 563 or 5563. Bonus server ports 80/119 (SSL 443/563). Recommended connections: 50–100 (support often suggests ~75 for high speed).
- Retention: 2000–3000 days depending on spool; bonus server historically higher. Posting allowed on main servers; bonus server may be no-post.

## Usenet providers (Newshosting)
- Host: `news.newshosting.com` (geo-auto); regionals `news.eu.newshosting.com`, `news.us.newshosting.com`.
- Ports: non-SSL 119/23/25/80/3128; SSL 563/443. Connections: typically 60–100 depending on plan; start with 30 and increase.
- Retention: ~5,000+ days (Highwinds backbone). Posting allowed.

## Usenet providers (UsenetExpress)
- Hosts: `news.usenetexpress.com`, `news-eu.usenetexpress.com`.
- Ports: non-SSL 119/23/80; SSL 563/443 (564 legacy). Default ~50 connections; some plans up to 150.
- Retention: ~4,000+ days; independent backbone; posting allowed.

## Media managers (for context)
- **Sonarr** http://localhost:8989, **Radarr** http://localhost:7878, **Lidarr** http://localhost:8686, **Bazarr** http://localhost:6767, **Overseerr** http://localhost:5055, **Mylar** http://localhost:8090.

## Comics/Reading
- **Komga** – http://localhost:8081 (internal port 25600).  
  - If login fails, reset credentials via Komga admin CLI or create a new user in the UI; config at `/var/mnt/fast8tb/config/komga`.
- **Komf** – http://localhost:8085 (metadata helper; UI title shows **Komelia**).
- **Kavita** – http://localhost:5000 (set admin creds on first login; config at `/var/mnt/fast8tb/config/kavita`).

## Ops/monitoring
- **Portainer** http://localhost:9000, **Netdata** http://localhost:19999.

## Paths (host)
- Downloads root: `/var/mnt/fast8tb/Local/downloads` mounted as `/downloads` in all downloader containers.
- Per-client folders: `transmission/{complete,incomplete,watch}`, `aria2/{complete,incomplete,watch}`, `sabnzbd/{complete,incomplete}`.

## Credentials (current defaults)
- Komga/Komf: `j3lanzone@gmail.com` / `fishing123`
- Kavita: `j3lanzone@gmail.com` / `fishing123` (API key stored in Komf config)
- Mylar: user `j3lanzone@gmail.com`, password `fishing123`, API key `cad4f40858c77c4177c99bebae4f3e17`
- SABnzbd: API key in sabnzbd.ini (no UI password)
- Aria2: secret token from `.env` (`ARIA2_SECRET`)
- Transmission: no auth
- Prowlarr/Sonarr/Radarr/Bazarr/Lidarr/Overseerr: no auth (LAN only)

## Notes on Prowlarr + Aria2
- Prowlarr uses **XML-RPC** at `/rpc` and expects the secret **without** the `token:` prefix (it adds it). Manual curl uses JSON-RPC at `/jsonrpc`.
