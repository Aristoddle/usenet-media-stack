# Local Endpoints (loopback only)

> Quick launcher for services when running the stack locally on this machine. All links are `http://localhost` and assume default ports and the current compose files. If a link 404s, check that the service is up with `docker ps` and that Traefik isn’t overriding ports.

## Core automation
- Prowlarr: [http://localhost:9696](http://localhost:9696)
- Sonarr: [http://localhost:8989](http://localhost:8989)
- Radarr: [http://localhost:7878](http://localhost:7878)
- Lidarr: [http://localhost:8686](http://localhost:8686)
- Whisparr: [http://localhost:6969](http://localhost:6969)
- SABnzbd: [http://localhost:8080](http://localhost:8080)
- Transmission (via gluetun VPN): [http://localhost:9093](http://localhost:9093) (UI proxied through gluetun)

## Comics / books
- Mylar: [http://localhost:8090](http://localhost:8090)
- Komga: [http://localhost:8081](http://localhost:8081)
- Komf: [http://localhost:8085](http://localhost:8085)
- Calibre-web (stack calibre): [http://localhost:18080](http://localhost:18080)
- Audiobookshelf: [http://localhost:13378](http://localhost:13378)

## Requests / oversight
- Overseerr: [http://localhost:5055](http://localhost:5055)
- Bazarr: [http://localhost:6767](http://localhost:6767)
- Netdata: [http://localhost:19999](http://localhost:19999)
- Portainer: [http://localhost:9000](http://localhost:9000)
- Tdarr server: [http://localhost:8265](http://localhost:8265)
- Tdarr node: [http://localhost:8266](http://localhost:8266)

## Ingress / docs
- Traefik dashboard: [http://localhost:8082](http://localhost:8082) (insecure, for local only)
- Docs (VitePress dev/preview): [http://localhost:4173](http://localhost:4173)
- Usenet Docs container: [http://localhost:4173](http://localhost:4173) (nginx serving built docs)

## Media servers
- Jellyfin (if enabled): [http://localhost:8096](http://localhost:8096)
- Stash: [http://localhost:9998](http://localhost:9998)

### Notes
- Torrent traffic is routed through Mullvad via gluetun; if gluetun is down, Transmission UI may be unreachable.
- If you override ports or enable Traefik host rules, update this page accordingly.
