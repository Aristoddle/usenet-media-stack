# Volume Safety Model

**Why this stack's volume layout prevents data corruption**

## The Core Principle

```
┌─────────────────────────────────────────────────────────────────────┐
│  Docker Daemon (single runtime)                                    │
│                                                                    │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐              │
│  │ Sonarr  │  │ Radarr  │  │ SABnzbd │  │  Plex   │              │
│  └────┬────┘  └────┬────┘  └────┬────┘  └────┬────┘              │
│       │            │            │            │                    │
│  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐  ┌────┴────┐              │
│  │/config/ │  │/config/ │  │/config/ │  │/config/ │              │
│  │ sonarr  │  │ radarr  │  │ sabnzbd │  │  plex   │              │
│  │EXCLUSIVE│  │EXCLUSIVE│  │EXCLUSIVE│  │EXCLUSIVE│              │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘              │
│                                                                    │
│       └────────────┬────────────┴────────────┘                    │
│                    │                                               │
│            ┌───────┴───────┐                                      │
│            │   /media/     │                                      │
│            │    SHARED     │                                      │
│            │  (files only) │                                      │
│            └───────────────┘                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Volume Types

### Exclusive Volumes (Database-Safe)

Each container has its **own** config directory with its **own** SQLite database:

| Container | Config Path | Contains |
|-----------|-------------|----------|
| Sonarr | `/var/mnt/fast8tb/config/sonarr/` | sonarr.db |
| Radarr | `/var/mnt/fast8tb/config/radarr/` | radarr.db |
| Prowlarr | `/var/mnt/fast8tb/config/prowlarr/` | prowlarr.db |
| SABnzbd | `/var/mnt/fast8tb/config/sabnzbd/` | sabnzbd.ini |
| Kavita | `/var/mnt/fast8tb/config/kavita/` | kavita.db |
| Komga | `/var/mnt/fast8tb/config/komga/` | database.sqlite |

**Rule:** No two containers ever mount the same `/config` directory.

### Shared Volumes (File-Based Handoff)

Multiple containers access the same directories for **file handoff**, not database access:

```
/downloads/
├── incomplete/     ← SABnzbd writes (exclusive during download)
├── complete/       ← SABnzbd writes, Sonarr/Radarr read
│   ├── tv/
│   └── movies/
└── torrents/       ← Transmission writes

/media/
├── tv/             ← Sonarr writes, Plex/Jellyfin read
├── movies/         ← Radarr writes, Plex/Jellyfin read
├── music/          ← Lidarr writes, Plex read
└── comics/         ← Mylar writes, Komga read
```

**Why this is safe:** Files are written atomically (move from incomplete → complete), and readers only access completed files.

## The Handoff Pattern

```
Download                   Import                    Serve
┌─────────┐              ┌─────────┐              ┌─────────┐
│ SABnzbd │──(file)─────▶│ Sonarr  │──(file)─────▶│  Plex   │
│         │              │         │              │         │
│ writes  │              │ moves   │              │ reads   │
│ to temp │              │ to lib  │              │ streams │
└─────────┘              └─────────┘              └─────────┘
     │                        │                        │
     ▼                        ▼                        ▼
/downloads/incomplete  /downloads/complete      /media/tv
     (exclusive)         (handoff point)        (read-only)
```

**Key insight:** At each handoff point, ownership transfers cleanly. No two processes write to the same file simultaneously.

## Why SQLite Is Safe

SQLite uses file-level locking to prevent concurrent write corruption. This works correctly when:

1. **Single daemon:** All containers share the same Docker daemon
2. **Same namespace:** File locks are visible across all containers
3. **Exclusive config:** Each database file is accessed by exactly one container

The Docker daemon ensures file locks are properly coordinated across all containers it manages.

## Path Reference

```bash
# From .env
CONFIG_ROOT=/var/mnt/fast8tb/config        # Exclusive per-container
MEDIA_ROOT=/var/mnt/fast8tb/Local/media    # Shared (files)
DOWNLOADS_ROOT=/var/mnt/fast8tb/Local/downloads  # Shared (handoff)
```

## Validation

Check that no two containers share a config path:

```bash
# List all config mounts
sudo docker inspect --format '{{.Name}}: {{range .Mounts}}{{if eq .Destination "/config"}}{{.Source}}{{end}}{{end}}' $(sudo docker ps -q)

# Should show unique paths per container
```

---

*This architecture ensures database integrity while enabling efficient file-based workflows between services.*
