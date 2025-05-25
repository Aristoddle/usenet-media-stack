---
layout: page
---

<AnimatedHero />

## 🎯 **What This Actually Does**

**The Problem**: Media automation tools break when you move drives around. I take portable drives camping, switch between different computers, and need my media stack to just work everywhere.

**The Solution**: A smart media stack that automatically adapts to whatever storage you plug in. Add a drive, and all your services immediately see it. No manual configuration, no breaking things.

### **Real Example**
```bash
# At home: Working from 29 drives (ZFS + cloud + external)
usenet storage list  # Shows everything: Dropbox, 8TB exFAT, local drives

# Going camping: Grab portable drive  
usenet storage add /media/camping-drive
# → Sonarr, Radarr, Jellyfin automatically see new storage
# → Downloads continue seamlessly
# → No service restarts needed

# Back home: Plug drive back in
# → Everything syncs automatically
```

<InteractiveCLIDemo />

---

## 🤝 **Who Built This**

<div style="display: grid; grid-template-columns: 1fr 1fr; gap: 2rem; margin: 2rem 0; align-items: center;">

<div style="text-align: center;">
  <img src="/images/avatar.jpg" alt="Joe Lanzone" style="width: 120px; height: 120px; border-radius: 50%; border: 3px solid #f093fb; margin-bottom: 1rem;">
  <h3 style="color: #f093fb; margin-bottom: 0.5rem;">👨‍💻 Joe</h3>
  <p style="color: #64748b; font-size: 0.9rem; margin-bottom: 1rem;">Built this for myself, sharing with friends</p>
  <p style="font-size: 0.85rem; line-height: 1.5;">I actually use this daily. Started because I was tired of reconfiguring everything when I moved drives around.</p>
  <a href="mailto:j3lanzone@gmail.com?subject=Media%20Stack%20Question" style="display: inline-block; background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 0.5rem 1rem; border-radius: 8px; text-decoration: none; margin-top: 0.5rem; font-size: 0.85rem;">📧 Ask a Question</a>
</div>

<div style="text-align: center;">
  <img src="https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png" alt="Monty - Your Guide" style="width: 120px; height: 120px; border-radius: 50%; border: 3px solid #667eea; margin-bottom: 1rem;">
  <h3 style="color: #667eea; margin-bottom: 0.5rem;">🧠 Monty</h3>
  <p style="color: #64748b; font-size: 0.9rem; margin-bottom: 1rem;">Your setup assistant</p>
  <p style="font-size: 0.85rem; line-height: 1.5;">Guides you through the more complex parts. Think of him as the helpful documentation that actually makes sense.</p>
</div>

</div>

---

## 🚀 **Getting Started**

### **Want to try it?** 

<div style="background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(240, 147, 251, 0.1) 100%); padding: 2rem; border-radius: 12px; margin: 2rem 0;">

**Quick setup (if you already know Docker):**
```bash
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy --auto
```

**New to this?** → [**Full Setup Guide**](/getting-started/) walks you through everything.

**Just curious?** → [**See the Architecture**](/architecture/) to understand how it works.

</div>

### **What You Get**

- **Media Automation**: Sonarr, Radarr, Prowlarr handle downloading
- **Media Server**: Jellyfin streams everything with GPU acceleration  
- **Smart Storage**: Add/remove drives without breaking anything
- **Remote Access**: Secure Cloudflare tunnels (no port forwarding)
- **One Command**: `./usenet deploy --auto` sets up everything

---

## 💡 **Why I Built This**

**My Setup**: 
- Main workstation with 29 different drives (mix of ZFS, cloud storage, external drives)
- AMD laptop with Radeon GPU (needs hardware acceleration for 4K)
- Take portable drives camping for offline media
- Switch between different machines regularly

**The Problem**: 
Every media stack tutorial assumes you have one static setup. But I need flexibility - drives come and go, machines change, and everything should just work.

**What Makes This Different**:
- **Actually handles drive changes** (most setups break)
- **Real GPU optimization** (60+ FPS 4K transcoding vs 2 FPS CPU-only)
- **Professional CLI** (no more editing YAML files manually)
- **Works everywhere** (same stack from camping to data center)

---

## 🛠️ **Advanced Features**

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin: 2rem 0;">

<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1.5rem; border-radius: 12px;">
  <h3 style="margin-top: 0; color: white;">🗄️ Smart Storage</h3>
  <p>Automatically detects ZFS, cloud mounts, external drives. Add storage and all services see it immediately.</p>
</div>

<div style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 1.5rem; border-radius: 12px;">
  <h3 style="margin-top: 0; color: white;">⚡ GPU Acceleration</h3>
  <p>Real hardware optimization. Tested 29x faster 4K transcoding with proper GPU drivers.</p>
</div>

<div style="background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); color: #333; padding: 1.5rem; border-radius: 12px;">
  <h3 style="margin-top: 0;">💻 Professional CLI</h3>
  <p>Clean commands like `usenet storage list`. Tab completion, helpful errors, works like real tools.</p>
</div>

<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1.5rem; border-radius: 12px;">
  <h3 style="margin-top: 0; color: white;">🔧 Actually Reliable</h3>
  <p>Built by someone who uses it daily. Real error handling, backup system, validation checks.</p>
</div>

</div>

---

## 📚 **Community Resources**

Part of what makes this useful is connecting to the broader community:

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 1.5rem; margin: 2rem 0;">

<div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1.5rem; border-radius: 12px; cursor: pointer;" onclick="window.open('https://annas-archive.org/', '_blank')">
  <h3 style="margin-top: 0; color: white;">📚 Free Books & Papers</h3>
  <p style="margin-bottom: 0;">Anna's Archive: 70M+ books, papers, comics. MIT OpenCourseWare. All the good academic stuff.</p>
</div>

<div style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 1.5rem; border-radius: 12px; cursor: pointer;" onclick="window.open('/free-media/', '_self')">
  <h3 style="margin-top: 0; color: white;">🎮 Gaming Resources</h3>
  <p style="margin-bottom: 0;">EmuDeck integration, RetroArch setup, ROM organization for comprehensive gaming libraries.</p>
</div>

<div style="background: linear-gradient(135deg, #a8edea 0%, #fed6e3 100%); color: #333; padding: 1.5rem; border-radius: 12px; cursor: pointer;" onclick="window.open('mailto:j3lanzone@gmail.com?subject=Question%20About%20Setup', '_self')">
  <h3 style="margin-top: 0;">🤝 Need Help?</h3>
  <p style="margin-bottom: 0;">Stuck on something? I actually respond to emails. Happy to help with setup questions.</p>
</div>

</div>

---

## 🔧 **Technical Details**

**What's Running**: 19 integrated services (Sonarr, Radarr, Jellyfin, Prowlarr, SABnzbd, etc.)
**Performance**: 67 FPS 4K HEVC transcoding (vs 2.3 FPS CPU-only)  
**Storage**: Works with any mix of ZFS, cloud storage, external drives
**Access**: Secure Cloudflare tunnels, no exposed ports
**Platform**: Linux (tested on AMD Ryzen + Radeon GPU)

**Real Performance Data**:
- **Hardware**: AMD Ryzen 7 7840HS + Radeon 780M Graphics
- **4K HEVC → 1080p**: 2.3 FPS CPU → 67 FPS GPU (29x improvement)
- **Power Usage**: 185W CPU → 48W GPU (74% reduction)
- **Storage**: 29 drives detected including 8TB portable + cloud storage

---

<div style="text-align: center; margin: 3rem 0; padding: 2rem; background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%); border-radius: 12px;">

**Ready to set up your own?**

This tool exists because I needed it. If you have similar problems (multiple drives, different machines, need reliability), it might help you too.

[🚀 **Setup Guide**](/getting-started/) • [🏗️ **How It Works**](/architecture/) • [💬 **Ask Questions**](mailto:j3lanzone@gmail.com?subject=Usenet%20Stack%20Question)

</div>

---

*Built with care for daily use. Shared because good tools should be shared.*