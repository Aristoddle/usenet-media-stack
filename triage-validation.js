// Quick triage validation of remaining services
const { chromium } = require('playwright');

const remainingServices = [
    { name: 'bazarr', url: 'http://localhost:6767', desc: 'Subtitle Automation' },
    { name: 'readarr', url: 'http://localhost:8787', desc: 'Book Automation' },
    { name: 'yacreader', url: 'http://localhost:8082', desc: 'Comic Reader' },
    { name: 'tdarr', url: 'http://localhost:8265', desc: 'Transcoding' },
    { name: 'mylar', url: 'http://localhost:8090', desc: 'Comic Automation' }
];

async function quickCheck(service) {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage();
    
    try {
        await page.goto(service.url, { waitUntil: 'domcontentloaded', timeout: 5000 });
        const title = await page.title();
        
        // Quick error detection
        const bodyText = await page.textContent('body');
        const hasError = bodyText.toLowerCase().includes('error') || 
                        bodyText.toLowerCase().includes('not found') ||
                        bodyText.toLowerCase().includes('500') ||
                        bodyText.toLowerCase().includes('502') ||
                        title.toLowerCase().includes('error');
        
        console.log(`${hasError ? '❌' : '✅'} ${service.name}: ${title}`);
        return { service: service.name, status: hasError ? 'error' : 'working', title };
        
    } catch (error) {
        console.log(`❌ ${service.name}: FAILED - ${error.message.split('\n')[0]}`);
        return { service: service.name, status: 'failed', error: error.message };
    } finally {
        await browser.close();
    }
}

async function main() {
    console.log('🔍 TRIAGE: Quick validation of remaining services...\n');
    
    const results = [];
    for (const service of remainingServices) {
        const result = await quickCheck(service);
        results.push(result);
    }
    
    // Quick summary
    const working = results.filter(r => r.status === 'working').length;
    const total = results.length;
    
    console.log(`\n📊 TRIAGE RESULTS: ${working}/${total} additional services working`);
    
    // Save for analysis
    require('fs').writeFileSync('/home/joe/usenet/triage-results.json', JSON.stringify(results, null, 2));
}

main().catch(console.error);