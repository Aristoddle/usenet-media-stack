// Service validation with Playwright
const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const ROOT_DIR = __dirname;
const SCREENSHOT_DIR = path.join(ROOT_DIR, 'validation-screenshots');
const RESULTS_PATH = path.join(ROOT_DIR, 'validation-results.json');

const services = [
    { name: 'jellyfin', url: 'http://localhost:8096', desc: 'Media Server' },
    { name: 'overseerr', url: 'http://localhost:5055', desc: 'Request Management' },
    { name: 'prowlarr', url: 'http://localhost:9696', desc: 'Indexer Manager' },
    { name: 'sonarr', url: 'http://localhost:8989', desc: 'TV Automation' },
    { name: 'radarr', url: 'http://localhost:7878', desc: 'Movie Automation' },
    { name: 'sabnzbd', url: 'http://localhost:8080', desc: 'Downloader' },
    { name: 'portainer', url: 'http://localhost:9000', desc: 'Container Management' },
    { name: 'netdata', url: 'http://localhost:19999', desc: 'System Monitor' }
];

async function validateService(service) {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    
    try {
        console.log(`\n=== Validating ${service.name} (${service.desc}) ===`);
        
        // Navigate with timeout
        await page.goto(service.url, { waitUntil: 'networkidle', timeout: 10000 });
        
        // Take screenshot
        await fs.promises.mkdir(SCREENSHOT_DIR, { recursive: true });
        await page.screenshot({
            path: path.join(SCREENSHOT_DIR, `${service.name}.png`),
            fullPage: false
        });
        
        // Get page title and check for common error indicators
        const title = await page.title();
        const bodyText = await page.textContent('body');
        
        const hasError = bodyText.toLowerCase().includes('error') || 
                        bodyText.toLowerCase().includes('not found') ||
                        bodyText.toLowerCase().includes('500') ||
                        bodyText.toLowerCase().includes('502');
        
        console.log(`✅ ${service.name}: ${title}`);
        console.log(`   URL: ${service.url}`);
        console.log(`   Status: ${hasError ? '❌ Error detected' : '✅ Working'}`);
        
        return { service: service.name, status: hasError ? 'error' : 'working', title, url: service.url };
        
    } catch (error) {
        console.log(`❌ ${service.name}: Failed - ${error.message}`);
        return { service: service.name, status: 'failed', error: error.message, url: service.url };
    } finally {
        await browser.close();
    }
}

async function main() {
    console.log('🔍 Validating Usenet Media Stack Services...\n');
    
    const results = [];
    
    for (const service of services) {
        const result = await validateService(service);
        results.push(result);
        
        // Small delay between services
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    // Summary
    console.log('\n📊 VALIDATION SUMMARY');
    console.log('='.repeat(50));
    
    const working = results.filter(r => r.status === 'working').length;
    const errors = results.filter(r => r.status === 'error').length;
    const failed = results.filter(r => r.status === 'failed').length;
    
    console.log(`✅ Working: ${working}`);
    console.log(`⚠️  Errors: ${errors}`);
    console.log(`❌ Failed: ${failed}`);
    console.log(`📸 Screenshots saved to: ${SCREENSHOT_DIR}`);

    // Save results to JSON
    fs.writeFileSync(
        RESULTS_PATH,
        JSON.stringify(results, null, 2)
    );
    
    console.log(`💾 Results saved to: ${RESULTS_PATH}`);
}main().catch(console.error);