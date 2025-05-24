# 🔑 Credential Inventory

## Usenet Providers

### Primary Provider - Newshosting
- **Type**: Unlimited backbone provider
- **Server**: news.newshosting.com
- **Port**: 563 (SSL)
- **Username**: j3lanzone@gmail.com
- **Connections**: 30
- **Retention**: 4500+ days
- **Speed**: Unlimited

### Backup Provider - UsenetExpress
- **Type**: Independent backbone
- **Server**: usenetexpress.com
- **Port**: 563 (SSL)
- **Username**: une3226253
- **Connections**: 20
- **Retention**: 3500+ days
- **Notes**: Good for content Newshosting misses

### Block Provider - Frugal Usenet
- **Type**: Block account (non-expiring GB)
- **Server**: newswest.frugalusenet.com
- **Port**: 563 (SSL)
- **Username**: aristoddle
- **Connections**: 10
- **Notes**: Used as fill provider

## Indexers

### NZBgeek
- **URL**: https://api.nzbgeek.info
- **API Key**: SsjwpN541AHYvbti4ZZXtsAH0l3wyc8a
- **VIP**: Unknown
- **Categories**: Full spectrum (2000-8000)

### NZB Finder
- **URL**: https://nzbfinder.ws
- **API Key**: 14b3d53dbd98adc79fed0d336998536a
- **VIP**: Unknown
- **Categories**: Full spectrum

### NZB.su
- **URL**: https://api.nzb.su
- **API Key**: 25ba450623c248e2b58a3c0dc54aa019
- **VIP**: Unknown
- **Categories**: Full spectrum

### NZBPlanet
- **URL**: https://api.nzbplanet.net
- **API Key**: 046863416d824143c79b6725982e293d
- **VIP**: Unknown
- **Categories**: Full spectrum

## Provider Strategy

1. **Newshosting** (Primary) - Main unlimited provider
2. **UsenetExpress** (Backup) - Different backbone for missing content
3. **Frugal** (Block) - Fill provider for rare content

This gives excellent coverage across multiple backbones for maximum completion rates.

## Security Notes

- All credentials should be moved to `.env` file
- Never commit actual credentials to git
- Use environment variable substitution in all scripts
- Consider using Docker secrets for production