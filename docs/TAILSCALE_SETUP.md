# Tailscale Setup for Plex Remote Access

> **Status**: Tailscale daemon is already installed and running, just needs authentication.
>
> **Why Tailscale?** Your ISP (LIVEOAK-FIBER) uses CGNAT (100.64.x.x addresses), blocking traditional port forwarding. Tailscale creates a private mesh network that bypasses CGNAT entirely.

---

## Quick Setup (5 minutes)

### 1. Create Tailscale Account
Go to [https://login.tailscale.com/start](https://login.tailscale.com/start) and sign up with:
- Google
- GitHub
- Microsoft
- Or email

### 2. Login on Steambox

```bash
# Set yourself as the operator (one-time setup)
sudo tailscale set --operator=deck

# Authenticate - opens browser
sudo tailscale login
```

Follow the browser prompt to authorize this machine.

### 3. Verify Connection

```bash
tailscale status
# Should show: steambox  100.x.x.x  linux  -
```

### 4. Install Tailscale on Your Other Devices

- **iPhone/iPad**: [App Store](https://apps.apple.com/app/tailscale/id1470499037)
- **Mac**: [Mac App Store](https://apps.apple.com/app/tailscale/id1475387142)
- **Android**: [Play Store](https://play.google.com/store/apps/details?id=com.tailscale.ipn)
- **Windows**: [Download](https://tailscale.com/download/windows)

Login with the same account on each device.

---

## Accessing Plex Remotely

Once Tailscale is running on both machines:

1. Find your server's Tailscale IP:
   ```bash
   tailscale ip
   # Example: 100.84.123.45
   ```

2. Access Plex at: `http://100.84.123.45:32400/web`

3. **Optional**: Add the Tailscale IP to Plex's custom connections:
   - Settings → Network → Custom server access URLs
   - Add: `http://100.x.x.x:32400`

---

## Troubleshooting

### "Logged out" status
```bash
sudo tailscale login
```

### Can't reach server from phone
1. Ensure Tailscale is connected on BOTH devices
2. Check `tailscale status` shows both machines
3. Try `tailscale ping <server-ip>`

### Alternative: MagicDNS
Once enabled (Tailscale admin console → DNS), access via:
```
http://steambox:32400/web
```

---

## Security Notes

- Tailscale is zero-config WireGuard - encrypted end-to-end
- Only devices on YOUR Tailscale network can access the server
- No ports exposed to the public internet
- Free tier supports up to 100 devices

---

*Created: 2025-12-25 | For: steambox media server*
