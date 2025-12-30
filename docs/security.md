# 🔒 Security Guide

## Overview

This guide covers security best practices for the Usenet Media Stack, including credential management, network security, and access control.

## 🚨 Current Security Status

**⚠️ WARNING**: This repository contains hardcoded credentials and should remain **PRIVATE**.

To make it public-ready, significant refactoring is required (see below).

## 🛡️ Recommended Architecture (2024)

### 1. Cloudflare Tunnel (Recommended)

**Why it's the best choice:**
- Zero exposed ports - no port forwarding needed
- Free tier sufficient for personal use
- Enterprise-grade DDoS protection
- Automatic SSL/TLS certificates
- Modern QUIC protocol (faster than TCP)
- Zero Trust security model

**Setup:**
```bash
# 1. Create tunnel at https://one.dash.cloudflare.com/
# 2. Copy token to .env
# 3. Deploy with:
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d
```

### 2. Alternative: Tailscale

For private-only access (no public sharing):
```yaml
tailscale:
  image: tailscale/tailscale:latest
  hostname: media-stack
  environment:
    - TS_AUTHKEY=${TAILSCALE_KEY}
    - TS_ROUTES=192.168.1.0/24
```

## 🔐 Credential Management

### Current State

Credentials are managed via environment variables in `.env`. The configuration module
`lib/commands/configure.zsh` reads API keys from service config files (not hardcoded).

Configuration files that contain generated API keys (gitignored):
- `config/*/config.xml` (ARR services)
- `config/sabnzbd/sabnzbd.ini`

### Making it Public-Ready

1. **Move all credentials to environment variables:**
```bash
# Copy example env file
cp .env.example .env

# Edit with your values
nano .env
```

2. **Update `.gitignore`:**
```gitignore
# Secrets
.env
*.key
*.pem
*.crt
secrets/

# Configs with API keys
config/*/config.xml
config/*/config.ini
config/sabnzbd/sabnzbd.ini

# Logs
*.log
logs/
```

3. **Use Docker secrets for production:**
```yaml
secrets:
  nzbgeek_api:
    file: ./secrets/nzbgeek_api.txt
    
services:
  prowlarr:
    secrets:
      - nzbgeek_api
```

## 🌐 Network Security

### Internal Network Isolation

```yaml
networks:
  # Public-facing services
  proxy:
    name: proxy_network
    
  # Internal services only
  internal:
    internal: true
    
services:
  sonarr:
    networks:
      - internal  # Can't be accessed directly
      - proxy     # Only through reverse proxy
```

### Service-to-Service Communication

```yaml
# Good: Use service names
http://sonarr:8989

# Bad: Don't use localhost/IPs
http://localhost:8989
http://192.168.1.100:8989
```

## 👤 Access Control

### Option 1: Authentik (Enterprise-grade SSO)

Included in `docker-compose.tunnel.yml`:
- Single Sign-On for all services
- 2FA/MFA support
- LDAP/OAuth integration
- User groups and permissions

### Option 2: Basic Authentication

For simpler setups:
```bash
# Generate password
echo $(htpasswd -nb username password) | sed -e s/\\$/\\$\\$/g

# Add to .env
BASIC_AUTH_USERS=username:$2y$10$...
```

## 🔍 Security Checklist

> This checklist is a pre-exposure hardening guide. Track active items in the KG under `task-secrets`, `task-traefik`, and `task-ops-monitoring` to avoid drift.

- [ ] All credentials in `.env` file
- [ ] `.env` added to `.gitignore`
- [ ] No ports exposed to internet (using Cloudflare Tunnel)
- [ ] Authentication enabled on all services
- [ ] Regular updates: `./usenet update`
- [ ] Backup configurations: `./usenet backup`
- [ ] Monitor logs: `./usenet logs`
- [ ] Use HTTPS for all external access
- [ ] Implement rate limiting
- [ ] Enable fail2ban for SSH (if applicable)

## 🚀 Quick Security Setup

```bash
# 1. Copy and configure environment
cp .env.example .env
nano .env

# 2. Deploy with security stack
docker compose -f docker-compose.yml -f docker-compose.tunnel.yml up -d

# 3. Configure Cloudflare routes
# Visit: https://one.dash.cloudflare.com/

# 4. Test security
./usenet test security
```

## 📊 Security Monitoring

### Recommended Tools

1. **Uptime Kuma** - Service monitoring
2. **Crowdsec** - Intrusion detection
3. **Grafana + Loki** - Log aggregation
4. **Netdata** - Real-time metrics

### Alerts

Configure alerts for:
- Failed login attempts
- Unusual download patterns
- Service outages
- High resource usage
- Certificate expiration

## 🆘 Incident Response

If you suspect a breach:

1. **Immediate Actions:**
   ```bash
   # Stop all services
   ./usenet stop
   
   # Rotate all credentials
   # Update .env with new values
   
   # Clear sessions
   docker volume prune
   ```

2. **Investigation:**
   - Check logs: `./usenet logs`
   - Review access logs in Cloudflare
   - Check for unauthorized API usage

3. **Recovery:**
   - Restore from clean backup
   - Update all credentials
   - Enable additional security measures

## 📚 Additional Resources

- [Cloudflare Zero Trust Docs](https://developers.cloudflare.com/cloudflare-one/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
- [OWASP Docker Security](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)

---

**Remember**: Security is a journey, not a destination. Keep your stack updated and monitor regularly!
