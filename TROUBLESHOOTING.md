# Troubleshooting Guide

## Common Issues and Solutions

### 🔴 "Docker is not installed"

**Solution:**
```bash
# Ubuntu/Debian:
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
# Log out and back in

# Or use our auto-installer:
./auto-install-deps.sh
```

### 🔴 "Docker daemon is not running"

**Solution:**
```bash
# Start Docker:
sudo systemctl start docker

# Enable on boot:
sudo systemctl enable docker

# Check status:
sudo systemctl status docker
```

### 🔴 "Permission denied" errors

**Solutions:**
1. Add user to docker group:
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

2. Fix file permissions:
```bash
sudo chown -R $USER:$USER .
```

### 🔴 Services not starting

**Debug steps:**
1. Check container status:
```bash
docker ps -a
```

2. View logs:
```bash
./usenet manage logs sabnzbd
./usenet manage logs prowlarr
```

3. Check port conflicts:
```bash
sudo lsof -i :8080  # SABnzbd
sudo lsof -i :9696  # Prowlarr
```

4. Restart services:
```bash
./usenet manage restart
```

### 🔴 "No space left on device"

**Solutions:**
1. Check disk space:
```bash
df -h
```

2. Clean Docker:
```bash
docker system prune -a
```

3. Remove old downloads:
```bash
rm -rf downloads/incomplete/*
```

### 🔴 Can't access web interfaces

**Check:**
1. Services running:
```bash
./usenet manage status
```

2. Firewall:
```bash
# Ubuntu/Debian
sudo ufw status

# If blocking, allow ports:
sudo ufw allow 8080  # SABnzbd
sudo ufw allow 9696  # Prowlarr
```

3. Correct URLs:
- SABnzbd: http://localhost:8080
- Prowlarr: http://localhost:9696
- Note: Some services add `/` at the end

### 🔴 1Password errors

**If you don't use 1Password:**
- Skip credential extraction
- Manually configure services
- The system works without it

**If you do use 1Password:**
```bash
# Install CLI:
https://1password.com/downloads/command-line

# Sign in:
op signin
```

### 🔴 Tests failing

**This is normal if:**
- Services just started (wait 1-2 minutes)
- You haven't configured anything yet
- Running in test-only mode

**To fix:**
```bash
# Wait for services
sleep 60

# Run quick test
./usenet test quick

# Check specific service
curl http://localhost:8080
```

## Reset Everything

If all else fails, clean start:

```bash
# Stop everything
./usenet manage stop

# Remove containers and volumes
docker compose down -v

# Remove config (CAREFUL!)
rm -rf config/*

# Fresh start
./usenet setup
```

## Getting Help

1. **Check logs first:**
```bash
./usenet manage logs
```

2. **Run diagnostics:**
```bash
./usenet deps
./usenet validate
```

3. **GitHub Issues:**
https://github.com/Aristoddle/usenet-media-stack/issues

## Debug Mode

Run with verbose output:
```bash
# Verbose setup
./usenet setup --verbose

# Debug specific service
docker logs -f sabnzbd

# Check compose file
docker compose config
```

## FAQ

**Q: How do I update?**
```bash
git pull
./usenet update
```

**Q: Can I run this on Raspberry Pi?**
A: Yes, but use ARM images in docker-compose.yml

**Q: How much RAM do I need?**
A: Minimum 4GB, recommended 8GB+

**Q: Can I change ports?**
A: Edit docker-compose.yml and restart

**Q: Is this secure?**
A: Local-only by default. See SECURITY_GUIDE.md for hardening.