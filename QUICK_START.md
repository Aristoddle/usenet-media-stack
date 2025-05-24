# Quick Start Guide - Usenet Media Stack

## 🚀 5-Minute Setup

### Prerequisites Check
```bash
# Check if Docker is installed
docker --version

# Check if you have sudo access
sudo whoami

# Check available disk space
df -h
```

### One-Command Installation
```bash
# Clone and setup everything
git clone https://github.com/yourusername/usenet-media-stack.git
cd usenet-media-stack
./one-click-setup.sh
```

That's it! Your media stack is now running.

## 🎯 First Steps After Installation

### 1. Access Your Services
Open these URLs in your browser:
- **Jellyfin** (Watch Media): http://localhost:8096
- **Overseerr** (Request Media): http://localhost:5055
- **Prowlarr** (Manage Indexers): http://localhost:9696
- **Sonarr** (TV Shows): http://localhost:8989
- **Radarr** (Movies): http://localhost:7878

### 2. Complete Jellyfin Setup (5 minutes)
1. Open http://localhost:8096
2. Click "Next" through the wizard
3. Skip creating a user (for local access)
4. Add your media folders when prompted
5. Click "Finish"

### 3. Request Your First Movie/Show
1. Open http://localhost:5055 (Overseerr)
2. Search for any movie or TV show
3. Click "Request"
4. Watch it download automatically!

## 📺 Watching Your Media

### On Your Computer
- Just open http://localhost:8096 in any browser

### On Your TV
- **Roku**: Install Jellyfin channel from store
- **Android TV**: Install Jellyfin from Play Store
- **Apple TV**: Install Jellyfin from App Store
- **Fire TV**: Install Jellyfin from Amazon Store

### On Your Phone
- **iPhone**: Download "Jellyfin Mobile" from App Store
- **Android**: Download "Jellyfin" from Play Store

## 🎬 Common Tasks

### Request a Movie
1. Go to Overseerr: http://localhost:5055
2. Search for the movie
3. Click "Request"
4. It will automatically download and appear in Jellyfin

### Request a TV Show
1. Go to Overseerr: http://localhost:5055
2. Search for the show
3. Choose which seasons you want
4. Click "Request"
5. New episodes will download automatically

### Check Download Progress
- Visit SABnzbd: http://localhost:8080
- You'll see all active downloads and their progress

### Find Something to Watch
- Open Jellyfin: http://localhost:8096
- Browse your library or use search
- Click play on anything!

## 🛠️ Basic Troubleshooting

### "Service not accessible"
```bash
# Restart all services
cd usenet-media-stack
./manage.sh restart
```

### "No media showing in Jellyfin"
1. Make sure downloads have completed
2. In Jellyfin, go to Dashboard → Libraries
3. Click "Scan All Libraries"

### "Downloads not starting"
1. Check SABnzbd: http://localhost:8080
2. Make sure it shows "Connected" to servers
3. Check if you have API credits on your indexers

### Check if everything is running
```bash
cd usenet-media-stack
./test-media-services.sh
```

## 📱 Remote Access Setup (Optional)

### Easy Way - Tailscale
1. Install Tailscale on your server
2. Install Tailscale on your devices
3. Access using your Tailscale IP

### Advanced Way - Domain + Reverse Proxy
See ADVANCED_SETUP.md for full instructions

## 🎯 What's Next?

### Customize Your Experience
- **Add more indexers**: Go to Prowlarr settings
- **Change quality settings**: In Sonarr/Radarr profiles
- **Set up user accounts**: In Jellyfin dashboard
- **Enable 4K**: Add 4K categories in Sonarr/Radarr

### Explore Advanced Features
- **Subtitle downloads**: Already configured in Bazarr
- **Music library**: Use Lidarr (port 8686)
- **Book library**: Use Readarr (port 8787)
- **Comic books**: Use Mylar3 (port 8090)

## 💡 Tips for New Users

### Storage Management
- Fast drives = New/Active content
- Slow drives = Older/Archived content
- The system manages this automatically!

### Quality Settings
- Default is "Any" quality (balanced)
- For 4K: Create new quality profiles
- For space saving: Limit to 1080p

### Organization
- Movies go to: `/media/movies/`
- TV Shows go to: `/media/tv/`
- Everything is auto-organized!

## 🆘 Getting Help

### Check Status
```bash
# See what's running
docker ps

# Check logs for issues
./manage.sh logs [service-name]
```

### Common Services to Check
- **Not downloading?** Check SABnzbd logs
- **Can't find content?** Check Prowlarr logs
- **Media not showing?** Check Sonarr/Radarr logs

### Still Stuck?
1. Check TROUBLESHOOTING.md
2. Search the logs for "error"
3. Check service forums

## 🎉 Congratulations!

You now have a fully automated media system that:
- ✅ Downloads content automatically
- ✅ Organizes everything perfectly
- ✅ Streams to all your devices
- ✅ Manages subtitles
- ✅ Tracks what you watch

Enjoy your media! 🍿📺🎵📚