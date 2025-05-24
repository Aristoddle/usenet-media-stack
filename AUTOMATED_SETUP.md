# 🚀 Automated Usenet Stack Setup

## One-Command Setup

After cloning this repository, you can set up your entire Usenet stack with a single command:

```bash
./one-click-setup.sh
```

This will:
1. Start all Docker containers
2. Wait for services to be ready
3. Configure SABnzbd with all Usenet providers
4. Add all indexers to Prowlarr
5. Connect all *arr apps to Prowlarr and SABnzbd
6. Test all connections
7. Create a backup of configurations

## What Gets Configured

### Usenet Providers (in SABnzbd)
- **Newshosting** (Primary) - 30 connections
- **UsenetExpress** (Secondary) - 20 connections  
- **Frugalusenet** (Backup) - 10 connections

### Indexers (in Prowlarr)
- **NZBgeek** - Full API integration
- **NZB Finder** - Full API integration
- **NZB.su** - Full API integration
- **NZBPlanet** - Full API integration

### Applications
- **Sonarr** - TV shows management
- **Radarr** - Movies management
- **Readarr** - Books management
- **Mylar3** - Comics management
- **Bazarr** - Subtitles management

## Manual Setup Options

If you prefer more control, you can run individual steps:

```bash
# 1. Start the stack
./manage.sh start

# 2. Wait for services
./wait-for-services.sh

# 3. Configure everything
./setup-all.sh --configure

# 4. Test connections
./setup-all.sh --test

# 5. Check health
./setup-all.sh --health
```

## Credentials Management

All credentials are managed through:
- **1Password integration** - Automatically pulls credentials
- **.env file** - Local storage for Docker
- **Secure extraction** - No credentials in code

To update credentials from 1Password:
```bash
./setup-all.sh --update
```

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Prowlarr   │────▶│   Sonarr    │────▶│  SABnzbd    │
│ (Indexers)  │     │ (TV Shows)  │     │ (Downloader)│
└─────────────┘     └─────────────┘     └─────────────┘
       │                   │                     │
       │            ┌─────────────┐             │
       └───────────▶│   Radarr    │─────────────┘
                    │  (Movies)   │
                    └─────────────┘
```

## Module Structure

```
/home/joe/usenet/
├── setup-all.sh           # Main setup script
├── one-click-setup.sh     # One-command wrapper
├── wait-for-services.sh   # Service readiness checker
├── op-helper.sh           # 1Password integration
├── modules/
│   ├── api.sh            # API interaction functions
│   ├── credentials.sh    # Credential management
│   └── services.sh       # Service orchestration
├── .env                  # Environment variables
└── config/               # Service configurations
```

## Troubleshooting

### Services not starting
```bash
# Check logs
./manage.sh logs [service-name]

# Restart specific service
./manage.sh restart-service [service-name]

# Check Docker status
docker ps
```

### API key issues
```bash
# Extract API keys from configs
./setup-all.sh --health

# Force credential update
./setup-all.sh --update
```

### Connection failures
```bash
# Test all connections
./setup-all.sh --test

# Check network
docker network ls
```

## Advanced Usage

### Dry run (see what would happen)
```bash
./setup-all.sh --configure --dry-run
```

### Verbose output
```bash
./setup-all.sh --configure --verbose
```

### Backup configurations
```bash
./manage.sh backup-configs
```

## Next Steps

After setup completes:

1. **Access Prowlarr** at http://localhost:9696
   - Verify all indexers show green status
   - Check sync with apps

2. **Access Sonarr/Radarr** at ports 8989/7878
   - Search for content
   - Monitor download progress

3. **Access SABnzbd** at http://localhost:8080
   - Verify all servers connected
   - Check download speed

## Security Notes

- All API keys are stored securely
- Credentials are never logged
- .env file has 600 permissions
- 1Password integration uses session tokens

## Contributing

To add new indexers or providers:
1. Update credentials in CLAUDE.md
2. Add to INDEXERS/PROVIDERS arrays in setup-all.sh
3. Test with --dry-run flag

---

Built with ❤️ for automated media management