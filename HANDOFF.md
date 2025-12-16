# Beppe's Arr Stack — Live Handoff (Dec 16, 2025)

## Current snapshot
- Repo: /var/home/deck/Documents/Code/media-automation/usenet-media-stack (branch main, clean).
- Long-running job: rclone copy onedrive_personal:Books/Comics → /var/mnt/fast8tb/Cloud/OneDrive/Books/Comics, PID 131980, still running. **Do not restart the whole stack or move/rename comics paths until it finishes.**
- Services: Prowlarr, Sonarr, Radarr, Whisparr, Lidarr, SABnzbd, Transmission (via gluetun), Komga/Komf, Mylar, Overseerr, Bazarr, Tdarr, Portainer, Netdata. Traefik container exists but routes are not wired; services are loopback-only.
- Branding: Docs/site now “Beppe’s Arr Stack”. README and homepage reflect truthful status. Cloudflare Pages redeploys on push.

## Latest changes (already pushed)
- Switched gluetun to Mullvad **OpenVPN** using only the Mullvad account number; host port now 9091→9091.
- Restarted gluetun + transmission; both healthy. Transmission reachable at http://localhost:9091/transmission/.
- Transmission port normalization and docs updated earlier; homepage rewritten; README updated.
- Commits on main: d5e3638 (gluetun OpenVPN), d000aa2 (README refresh), 6e6b1e1 (branding), plus earlier transmission/landing updates. Repo is clean.

## Wiring snapshot
- Transmission: host 9091, urlBase /transmission/, behind gluetun. Categories: Sonarr `tv-sonarr`; Radarr also using tv-sonarr style; Whisparr `whisparr`; Lidarr `music`.
- SABnzbd: 8080.
- Arrs: Sonarr 8989, Radarr 7878, Whisparr 6969, Lidarr 8686.
- Prowlarr: 9696 (indexers: NZB.su, NZBFinder, NZBgeek, NZBPlanet, Nyaa).
- Komga 8081 (published 25600), Komf 8085 (RW bind /mnt/fast8tb/Cloud/OneDrive/Comics), Mylar 8090.
- Overseerr 5055, Bazarr 6767, Tdarr 8265/8266, Portainer 9000, Netdata 19999.
- Traefik: present, not routing.

## After rclone finishes (execute in order)
1) **Libraries & paths**
   - Set comics root to `/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics` in Komga, Komf, Mylar; rescan Komga.
   - Remove `/var/mnt/fast8tb/Cloud/OneDrive/Comics` and `/Comics_mirror` if empty/duplicated.
2) **Compose/.env normalization**
   - Canonical roots:
     - CONFIG_ROOT=/var/mnt/fast8tb/config
     - DOWNLOADS_ROOT=/var/mnt/fast8tb/Local/downloads
     - MEDIA_ROOT=/var/mnt/fast8tb/Local/media
     - COMICS_ROOT=/var/mnt/fast8tb/Cloud/OneDrive/Books/Comics
   - Update binds across compose files; add mount-gating; `docker compose up -d`.
3) **Traefik**
   - Add host rules + DOMAIN; secure dashboard; keep loopback fallback.
4) **Secret hygiene**
   - git filter-repo to purge old CF token; add gitleaks + pre-commit; keep .env in 1Password only.
5) **Service verifications**
   - Restart VPN/torrent if needed: `docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.vpn-mullvad.yml up -d gluetun transmission`.
   - Transmission health: `curl -s http://localhost:9091/transmission/rpc -H 'X-Transmission-Session-Id: dummy'` → expect 409 with session id.
   - Test end-to-end grabs via Prowlarr → Arrs → SAB/Transmission.

## Known issues
- nfs-server failing (missing kernel module) — disable or fix.
- usenet-docs container serves empty root (403) — disable or mount built docs.
- Traefik routes pending (loopback only).
- rclone copy in progress — avoid restarts/path changes until done.

## Secrets / creds (already configured)
- Mullvad: MULLVAD_ACCOUNT in .env (OpenVPN mode). No WireGuard keys needed now.
- Prowlarr 5aa12f5b88be4e648b937096f44ee512
- SABnzbd 3cd4df0dca5c4f7186761cc94aab6644
- Sonarr 4da8f9d97b0449ad8cfc7dcca2362287
- Radarr e2c1b4e03d0749bb822409d59ef2de07
- Whisparr d6d55600f4434cbfa5c43134f069b971
- Lidarr 1af2219c143c46b9a5677ef9c46a4991
- Mylar cad4f40858c77c4177c99bebae4f3e17
- Komga admin: j3lanzone@gmail.com / fishing123; API key 41e5ff7d4af44ea6a836ca63ebcf194c (usable for Komf)
- Cloudflare token rotated; stored in repo secrets for deploy.yml.

## Files to consult
- docker-compose.vpn-mullvad.yml (VPN/Torrent)
- docs/index.md, docs/.vitepress/config.js (branding/state)
- docs/local-endpoints.md (ports)
- docs/runbook/WIRING_NOTES.md (wiring summary)
- docs/SERVICES.md (authoritative service status)
- README.md (current snapshot)
- PAST_AGENT_NOTES.md (port list & earlier notes)

## Optional follow-ups
- Add missing/paid indexers to Prowlarr (pull creds from 1Password) and add torrent trackers as allowed.
- Lidarr: set root folder & profiles after path normalization.
- Komf: rerun metadata refresh after path switch; ensure write perms.
- Traefik labels + DNS-01 once ready.
- Secret scanning CI (gitleaks) and git history scrub.

