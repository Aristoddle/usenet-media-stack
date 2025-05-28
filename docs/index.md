---
layout: page
---

# Usenet Media Stack

**Working media services with honest documentation and visual validation.**

7 confirmed operational services providing media streaming, automation, and management.

<ServiceStatus />

<div style="text-align: center; margin: 3rem 0;">
  <a href="/getting-started/" style="display: inline-block; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 1rem 2rem; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 1.1rem; margin: 0.5rem;">🚀 Deploy Working Services</a>
  <a href="/docs/SERVICES/" style="display: inline-block; background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); color: white; padding: 1rem 2rem; border-radius: 8px; text-decoration: none; font-weight: bold; font-size: 1.1rem; margin: 0.5rem;">📸 View Screenshots</a>
</div>

<p style="text-align: center; color: #64748b; font-size: 0.9rem;">Tested on 2025-05-28 • Visual validation • Real functionality</p>

---

## ✅ What Actually Works

### **Core Media Stack (Validated)**
- **🎬 Jellyfin** - Full media streaming with GPU transcoding
- **🔍 Prowlarr** - Indexer management and search 
- **🐳 Portainer** - Container management interface

### **Content Automation (Working)**
- **📚 Readarr** - Book and audiobook automation
- **📝 Bazarr** - Subtitle automation (40+ languages)
- **🎞️ Tdarr** - Video transcoding and optimization  
- **📖 YACReader** - Comic and manga library

### **Known Issues**
- ❌ **Sonarr/Radarr** - .NET startup errors (TV/Movie automation)
- ❌ **SABnzbd** - Configuration issues (downloader)
- ❌ **Overseerr** - Setup loop problems (request management)

---

## 🔧 How It Works

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 2rem; margin: 2rem 0;">

<div style="text-align: center; padding: 1.5rem;">
  <div style="font-size: 3rem; margin-bottom: 1rem;">1️⃣</div>
  <h3>One-Command Deploy</h3>
  <p>Automated deployment with port conflict resolution and validation</p>
</div>

<div style="text-align: center; padding: 1.5rem;">
  <div style="font-size: 3rem; margin-bottom: 1rem;">2️⃣</div>
  <h3>Visual Validation</h3>
  <p>Playwright testing confirms services work - not just containers running</p>
</div>

<div style="text-align: center; padding: 1.5rem;">
  <div style="font-size: 3rem; margin-bottom: 1rem;">3️⃣</div>
  <h3>Honest Documentation</h3>
  <p>Real functionality over aspirational claims with proof screenshots</p>
</div>

</div>

```bash
# Actually tested deployment
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy --auto

# Result: 7 working services with visual confirmation
```

---

## 🎯 Technical Validation

**Testing Methodology**:
- ✅ **Playwright automated testing** - Visual confirmation of web interfaces
- ✅ **Docker health checks** - Container status validation
- ✅ **Port accessibility** - Network connectivity verification
- ✅ **Screenshot capture** - Visual proof of functionality

**Performance Confirmed**:
- **AMD GPU acceleration** - VAAPI transcoding working
- **Port conflict resolution** - Automatic cleanup of orphaned processes
- **Storage discovery** - 28+ drives detected automatically

---

## 💬 Honest Assessment

<div style="background: #f0fdf4; padding: 1.5rem; border-radius: 8px; border-left: 4px solid #10b981; margin: 1rem 0;">
<p style="font-style: italic; margin-bottom: 0.5rem;">"This is what I actually use. 7 services provide real value: media streaming + search + automation for books/subtitles/comics."</p>
<p style="color: #64748b; font-size: 0.9rem; margin: 0;">— Tested and validated 2025-05-28</p>
</div>

<div style="background: #fef2f2; padding: 1.5rem; border-radius: 8px; border-left: 4px solid #ef4444; margin: 1rem 0;">
<p style="font-style: italic; margin-bottom: 0.5rem;">"TV/Movie automation (Sonarr/Radarr) is broken due to .NET startup errors. Working on fixes but documenting reality."</p>
<p style="color: #64748b; font-size: 0.9rem; margin: 0;">— Known issues documented with evidence</p>
</div>

---

## 🚀 Ready to Deploy?

<div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem; margin: 2rem 0;">

<div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
  <h3 style="margin-top: 0; color: white;">✅ Working Services</h3>
  <p>Deploy the 7 confirmed working services</p>
  <a href="/getting-started/" style="display: inline-block; background: rgba(255,255,255,0.2); color: white; padding: 0.5rem 1rem; border-radius: 4px; text-decoration: none; margin-top: 0.5rem;">Deploy Now →</a>
</div>

<div style="background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
  <h3 style="margin-top: 0; color: white;">📸 Visual Proof</h3>
  <p>See screenshots of all working services</p>
  <a href="/docs/SERVICES/" style="display: inline-block; background: rgba(255,255,255,0.2); color: white; padding: 0.5rem 1rem; border-radius: 4px; text-decoration: none; margin-top: 0.5rem;">View Screenshots →</a>
</div>

<div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: white; padding: 1.5rem; border-radius: 12px; text-align: center;">
  <h3 style="margin-top: 0; color: white;">🔧 Contribute</h3>
  <p>Help fix the broken services</p>
  <a href="https://github.com/Aristoddle/usenet-media-stack/issues" style="display: inline-block; background: rgba(255,255,255,0.2); color: white; padding: 0.5rem 1rem; border-radius: 4px; text-decoration: none; margin-top: 0.5rem;">GitHub Issues →</a>
</div>

</div>

---

## 🤝 About

<div style="display: grid; grid-template-columns: 120px 1fr; gap: 1.5rem; align-items: center; margin: 2rem 0;">
  <img src="/images/avatar.jpg" alt="Joe" style="width: 120px; height: 120px; border-radius: 50%; border: 3px solid #10b981;">
  <div>
    <h3 style="margin-top: 0; color: #10b981;">Built by Joe</h3>
    <p style="margin-bottom: 0;">Honest documentation over marketing claims. I use these 7 working services daily. The broken ones are documented as such with plans to fix them.</p>
  </div>
</div>

**Contact**: [j3lanzone@gmail.com](mailto:j3lanzone@gmail.com?subject=Media%20Stack%20Question)

---

<details style="margin: 2rem 0;">
<summary style="cursor: pointer; font-weight: bold; padding: 1rem; background: #f8f9fa; border-radius: 4px;">🔧 Technical Details (click to expand)</summary>

<div style="padding: 1rem;">

**Validated Services**: 7/19 total services working (37% success rate)

**Testing Infrastructure**: 
- Playwright browser automation for UI validation
- Docker health checks for container status
- Network connectivity testing for all ports
- Screenshot capture for visual proof

**Performance Verified**: 
- AMD GPU VAAPI acceleration working
- 28+ storage devices detected automatically
- Port conflict resolution handles orphaned processes

**Platform**: Linux (Ubuntu 24.04 tested)
**Security**: All sensitive data in environment variables
**Documentation**: Real screenshots and validated claims only

</div>
</details>

---

*Real functionality over aspirational claims. Tested 2025-05-28.*