// Comprehensive documentation capture for 22 confirmed working services
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT_DIR = __dirname;
const IMAGE_DIR = path.join(ROOT_DIR, 'docs', 'public', 'images', 'services');
const REGISTRY_PATH = path.join(ROOT_DIR, 'docs', 'service-registry.json');

const workingServices = [
    { name: 'jellyfin', url: 'http://localhost:8096', desc: 'Media Server', features: 'Stream movies, TV shows, music with hardware transcoding' },
    { name: 'overseerr', url: 'http://localhost:5055', desc: 'Request Management', features: 'Media request management interface' },
    { name: 'yacreader', url: 'http://localhost:8083', desc: 'Comic Reader', features: 'Digital comic and manga library management' },
    { name: 'sonarr', url: 'http://localhost:8989', desc: 'TV Automation', features: 'Automatically manage series downloads' },
    { name: 'radarr', url: 'http://localhost:7878', desc: 'Movie Automation', features: 'Automatically manage movie downloads' },
    { name: 'prowlarr', url: 'http://localhost:9696', desc: 'Indexer Manager', features: 'Unified indexer management for usenet and torrent sources' },
    { name: 'readarr', url: 'http://localhost:8787', desc: 'Book Automation', features: 'Automated book and audiobook downloading and organization' },
    { name: 'bazarr', url: 'http://localhost:6767', desc: 'Subtitle Automation', features: 'Automatic subtitle downloading' },
    { name: 'whisparr', url: 'http://localhost:6969', desc: 'Adult Content Automation', features: 'Automated adult content management' },
    { name: 'mylar', url: 'http://localhost:8090', desc: 'Comic Automation', features: 'Automated comic downloading and organization' },
    { name: 'sabnzbd', url: 'http://localhost:8080', desc: 'Usenet Downloader', features: 'High-speed usenet downloading' },
    { name: 'transmission', url: 'http://localhost:9093', desc: 'Torrent Client', features: 'BitTorrent downloads with VPN' },
    { name: 'jackett', url: 'http://localhost:9117', desc: 'Indexer Proxy', features: 'Legacy torrent/usenet indexer aggregator' },
    { name: 'tdarr', url: 'http://localhost:8265', desc: 'Transcoding Engine', features: 'Automated video transcoding and optimization' },
    { name: 'recyclarr', url: 'http://localhost:3000', desc: 'Automation', features: 'TRaSH Guide quality automation', skip: true },
    { name: 'unpackerr', url: 'http://localhost:5657', desc: 'Extractor', features: 'Automated extraction of completed downloads', skip: true },
    { name: 'portainer', url: 'http://localhost:9000', desc: 'Container Management', features: 'Docker container management interface' },
    { name: 'netdata', url: 'http://localhost:19999', desc: 'System Monitoring', features: 'Real-time system metrics' },
    { name: 'samba', url: 'smb://localhost', desc: 'File Sharing', features: 'Windows file sharing', skip: true },
    { name: 'stash', url: 'http://localhost:9998', desc: 'Media Organizer', features: 'Video library management' },
    { name: 'tautulli', url: 'http://localhost:8181', desc: 'Usage Analytics', features: 'Monitor Jellyfin stream statistics' },
    { name: 'usenet-docs', url: 'http://localhost:4173', desc: 'Documentation Site', features: 'VitePress-based docs' }
];

async function captureService(service) {
    if (service.skip) {
        console.log(`⚠️ Skipping ${service.name} (no web interface)`);
        return { service: service.name, status: 'skipped' };
    }

    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    try {
        console.log(`📸 Capturing ${service.name} (${service.desc})...`);
        
        // Navigate and wait for content
        await page.goto(service.url, { waitUntil: 'networkidle', timeout: 15000 });
        
        // Get page info
        const title = await page.title();
        const url = page.url();
        
        await fs.promises.mkdir(IMAGE_DIR, { recursive: true });

        // Take full page screenshot
        await page.screenshot({
            path: path.join(IMAGE_DIR, `${service.name}.png`),
            fullPage: true,
            clip: { x: 0, y: 0, width: 1200, height: 800 } // Standard size for docs
        });
        
        // Take mobile screenshot
        await page.setViewportSize({ width: 375, height: 667 });
        await page.screenshot({
            path: path.join(IMAGE_DIR, `${service.name}-mobile.png`),
            fullPage: false
        });
        
        console.log(`  ✅ ${service.name}: ${title}`);
        console.log(`     📱 Mobile and desktop screenshots captured`);
        
        return { 
            service: service.name, 
            title, 
            url,
            desc: service.desc,
            features: service.features,
            status: 'documented' 
        };
        
    } catch (error) {
        console.log(`  ❌ ${service.name}: ${error.message}`);
        return { service: service.name, status: 'failed', error: error.message };
    } finally {
        await browser.close();
    }
}

async function main() {
    console.log('📚 DOCUMENTING WORKING SERVICES\n');
    console.log('Creating comprehensive service documentation...\n');
    
    // Create directories
    await fs.promises.mkdir(IMAGE_DIR, { recursive: true });
    
    const results = [];
    
    for (const service of workingServices) {
        const result = await captureService(service);
        results.push(result);
        
        // Small delay between captures
        await new Promise(resolve => setTimeout(resolve, 2000));
    }
    
    // Generate service documentation
    const workingCount = results.filter(r => r.status === 'documented').length;
    const totalCount = results.length;
    
    console.log('\n📊 DOCUMENTATION COMPLETE');
    console.log('='.repeat(50));
    console.log(`✅ Successfully documented: ${workingCount}/${totalCount} services`);
    console.log(`📸 Screenshots saved to: ${IMAGE_DIR}/`);
    
    // Create service registry
    const serviceRegistry = {
        metadata: {
            capturedAt: new Date().toISOString(),
            workingServices: workingCount,
            totalServices: totalCount,
            successRate: `${Math.round((workingCount/totalCount)*100)}%`
        },
        services: results.filter(r => r.status === 'documented')
    };
    
    await fs.promises.writeFile(
        REGISTRY_PATH,
        JSON.stringify(serviceRegistry, null, 2)
    );
    
    console.log(`💾 Service registry saved to: ${REGISTRY_PATH}`);
    console.log('\n🎯 Ready for documentation site integration!');main().catch(console.error);
