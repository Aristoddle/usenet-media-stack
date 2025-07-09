// Comprehensive documentation capture for 7 confirmed working services
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const ROOT_DIR = __dirname;
const IMAGE_DIR = path.join(ROOT_DIR, 'docs', 'public', 'images', 'services');
const REGISTRY_PATH = path.join(ROOT_DIR, 'docs', 'service-registry.json');

const workingServices = [
    { 
        name: 'jellyfin', 
        url: 'http://localhost:8096', 
        desc: 'Media Server',
        features: 'Stream movies, TV shows, music with hardware transcoding'
    },
    { 
        name: 'prowlarr', 
        url: 'http://localhost:9696', 
        desc: 'Indexer Manager',
        features: 'Unified indexer management for usenet and torrent sources'
    },
    { 
        name: 'portainer', 
        url: 'http://localhost:9000', 
        desc: 'Container Management',
        features: 'Docker container management and monitoring interface'
    },
    { 
        name: 'readarr', 
        url: 'http://localhost:8787', 
        desc: 'Book Automation',
        features: 'Automated book and audiobook downloading and organization'
    },
    { 
        name: 'bazarr', 
        url: 'http://localhost:6767', 
        desc: 'Subtitle Automation',
        features: 'Automatic subtitle downloading for movies and TV shows'
    },
    { 
        name: 'tdarr', 
        url: 'http://localhost:8265', 
        desc: 'Transcoding Engine',
        features: 'Automated video transcoding and optimization'
    },
    { 
        name: 'yacreader', 
        url: 'http://localhost:8083', 
        desc: 'Comic Reader',
        features: 'Digital comic and manga library management'
    }
];

async function captureService(service) {
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
    console.log('\n🎯 Ready for documentation site integration!');
}main().catch(console.error);