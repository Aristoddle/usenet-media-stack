# Additional Tools for Usenet Stack

## Current Stack Summary
You already have a comprehensive setup with:
- **Media Management**: Sonarr, Radarr, Lidarr, Readarr, Mylar3, Whisparr, Bazarr
- **Download Clients**: SABnzbd, Transmission
- **Indexer Management**: Prowlarr, Jackett
- **Media Servers**: YacReader
- **File Sharing**: Samba, NFS
- **Monitoring**: Netdata, Portainer

## Recommended Additions

### 1. **Jellyfin or Plex** - Media Streaming Server
```yaml
jellyfin:
  image: jellyfin/jellyfin:latest
  container_name: jellyfin
  ports:
    - "8096:8096"
  volumes:
    - jellyfin_config:/config
    - /media/joe:/media:ro
  environment:
    - JELLYFIN_PublishedServerUrl=http://localhost:8096
```
**Why**: Stream your media to any device (Roku, phones, tablets, smart TVs)

### 2. **Overseerr** - Media Request Management
```yaml
overseerr:
  image: lscr.io/linuxserver/overseerr:latest
  container_name: overseerr
  ports:
    - "5055:5055"
  volumes:
    - overseerr_config:/config
```
**Why**: Beautiful interface for users to request movies/shows, integrates with Sonarr/Radarr

### 3. **Tautulli** - Plex/Jellyfin Statistics
```yaml
tautulli:
  image: lscr.io/linuxserver/tautulli:latest
  container_name: tautulli
  ports:
    - "8181:8181"
  volumes:
    - tautulli_config:/config
```
**Why**: Monitor who's watching what, bandwidth usage, popular content

### 4. **Unpackerr** - Automated Archive Extraction
```yaml
unpackerr:
  image: golift/unpackerr:latest
  container_name: unpackerr
  volumes:
    - /home/joe/usenet/downloads:/downloads
  environment:
    - UN_SONARR_0_URL=http://sonarr:8989
    - UN_RADARR_0_URL=http://radarr:7878
```
**Why**: Automatically extracts archives that SABnzbd might miss

### 5. **Notifiarr** - Unified Notifications
```yaml
notifiarr:
  image: notifiarr/notifiarr:latest
  container_name: notifiarr
  ports:
    - "5454:5454"
  volumes:
    - notifiarr_config:/config
```
**Why**: Centralized notifications for all *arr apps, Discord/Telegram integration

### 6. **Organizr** - Unified Dashboard
```yaml
organizr:
  image: organizr/organizr:latest
  container_name: organizr
  ports:
    - "80:80"
  volumes:
    - organizr_config:/config
```
**Why**: Single dashboard to access all your services with tabs

### 7. **Recyclarr** - TRaSH Guides Automation
```yaml
recyclarr:
  image: recyclarr/recyclarr:latest
  container_name: recyclarr
  volumes:
    - recyclarr_config:/config
```
**Why**: Automatically applies best-practice quality profiles from TRaSH Guides

### 8. **Autobrr** - IRC Announce Automation
```yaml
autobrr:
  image: ghcr.io/autobrr/autobrr:latest
  container_name: autobrr
  ports:
    - "7474:7474"
  volumes:
    - autobrr_config:/config
```
**Why**: Race for releases using IRC announces, faster than RSS

### 9. **Flaresolverr** - Cloudflare Bypass
```yaml
flaresolverr:
  image: flaresolverr/flaresolverr:latest
  container_name: flaresolverr
  ports:
    - "8191:8191"
```
**Why**: Bypass Cloudflare protection on indexers

### 10. **Gaps** - Missing Media Finder
```yaml
gaps:
  image: housewrecker/gaps:latest
  container_name: gaps
  ports:
    - "8484:8484"
  volumes:
    - gaps_config:/config
```
**Why**: Find missing movies in your collections

## Storage & Backup Tools

### 11. **Duplicati** - Automated Backups
```yaml
duplicati:
  image: lscr.io/linuxserver/duplicati:latest
  container_name: duplicati
  ports:
    - "8200:8200"
  volumes:
    - duplicati_config:/config
    - /home/joe/usenet/config:/source/config:ro
    - /backup:/backups
```
**Why**: Automated encrypted backups to cloud storage

### 12. **Scrutiny** - S.M.A.R.T. Monitoring
```yaml
scrutiny:
  image: ghcr.io/analogj/scrutiny:master-omnibus
  container_name: scrutiny
  ports:
    - "8089:8080"
  volumes:
    - /run/udev:/run/udev:ro
  devices:
    - /dev/sda
    - /dev/sdb
    # Add all your drives
```
**Why**: Monitor drive health across your JBOD setup

## Implementation Priority

1. **High Priority**:
   - Jellyfin/Plex (media streaming)
   - Overseerr (request management)
   - Unpackerr (extraction automation)

2. **Medium Priority**:
   - Tautulli (statistics)
   - Organizr (dashboard)
   - Scrutiny (drive health)

3. **Low Priority**:
   - Recyclarr (quality profiles)
   - Autobrr (IRC racing)
   - Notifiarr (notifications)

## Quick Add Commands

To add any of these services, append their configuration to your docker-compose.yml and run:
```bash
cd /home/joe/usenet
docker compose up -d [service-name]
```