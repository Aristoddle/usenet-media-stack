#!/usr/bin/env node
/**
 * Web UI Automation Testing for Usenet Media Stack
 * 
 * Tests:
 * - Web interface loading and functionality
 * - Service-specific UI elements
 * - Cross-service navigation
 * - API endpoint validation
 * - Performance metrics
 */

const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

// Service definitions with expected UI elements
const SERVICES = {
    sonarr: {
        port: 8989,
        name: 'Sonarr',
        selectors: {
            title: 'title',
            logo: '[alt*="Sonarr"], .navbar-brand, h1',
            navigation: 'nav, .navbar, .sidebar',
            content: '.main-content, .page-content, #content'
        },
        expectedElements: ['Series', 'Calendar', 'Activity', 'System']
    },
    radarr: {
        port: 7878,
        name: 'Radarr',
        selectors: {
            title: 'title',
            logo: '[alt*="Radarr"], .navbar-brand, h1',
            navigation: 'nav, .navbar, .sidebar',
            content: '.main-content, .page-content, #content'
        },
        expectedElements: ['Movies', 'Calendar', 'Activity', 'System']
    },
    plex: {
        port: 32400,
        name: 'Plex',
        selectors: {
            title: 'title',
            logo: '.headerLogo, [alt*="Plex"], h1',
            loginForm: '.login-form, #loginForm, [data-role="page"]',
            content: '.mainContent, .page, #mainContent'
        },
        expectedElements: ['Movies', 'TV Shows', 'Music', 'Collections']
    },
    overseerr: {
        port: 5055,
        name: 'Overseerr',
        selectors: {
            title: 'title',
            logo: '[alt*="Overseerr"], .logo, h1',
            navigation: 'nav, .navbar',
            content: '.main-content, .page-content'
        },
        expectedElements: ['Discover', 'Requests', 'Users', 'Settings']
    },
    portainer: {
        port: 9000,
        name: 'Portainer',
        selectors: {
            title: 'title',
            logo: '[alt*="Portainer"], .navbar-brand',
            loginForm: '.login-form, #loginForm',
            dashboard: '.dashboard, .home'
        },
        expectedElements: ['Containers', 'Images', 'Networks', 'Volumes']
    },
    sabnzbd: {
        port: 8080,
        name: 'SABnzbd',
        selectors: {
            title: 'title',
            logo: '[alt*="SABnzbd"], .logo, h1',
            queue: '.queue, #queue',
            navigation: '.nav, .navbar, .menu'
        },
        expectedElements: ['Queue', 'History', 'Config', 'Status']
    },
    prowlarr: {
        port: 9696,
        name: 'Prowlarr',
        selectors: {
            title: 'title',
            logo: '[alt*="Prowlarr"], .navbar-brand, h1',
            navigation: 'nav, .navbar, .sidebar',
            content: '.main-content, .page-content'
        },
        expectedElements: ['Indexers', 'History', 'System']
    },
    netdata: {
        port: 19999,
        name: 'Netdata',
        selectors: {
            title: 'title',
            logo: '.netdata-logo, [alt*="netdata"], h1',
            dashboard: '.dashboard, .chart-container',
            navigation: '.sidebar, .menu'
        },
        expectedElements: ['CPU', 'Memory', 'Disk', 'Network']
    }
};

// Test results storage
const results = {
    passed: 0,
    failed: 0,
    tests: [],
    startTime: new Date(),
    endTime: null
};

// Utility functions
function log(level, message, ...args) {
    const timestamp = new Date().toISOString();
    const prefix = {
        'INFO': '💡',
        'SUCCESS': '✅',
        'ERROR': '❌',
        'WARNING': '⚠️'
    }[level] || 'ℹ️';
    
    console.log(`${prefix} [${timestamp}] ${message}`, ...args);
}

function recordTest(name, passed, details = {}) {
    results.tests.push({
        name,
        passed,
        details,
        timestamp: new Date()
    });
    
    if (passed) {
        results.passed++;
        log('SUCCESS', `${name} - PASSED`);
    } else {
        results.failed++;
        log('ERROR', `${name} - FAILED`, details);
    }
}

// Core testing functions
async function testServiceUI(browser, serviceName, config) {
    const url = `http://localhost:${config.port}`;
    log('INFO', `Testing ${config.name} UI at ${url}`);
    
    const context = await browser.newContext({
        viewport: { width: 1920, height: 1080 },
        userAgent: 'Mozilla/5.0 (compatible; UsenetMediaStackTester/1.0)'
    });
    
    const page = await context.newPage();
    
    try {
        // Test basic loading
        const startTime = Date.now();
        const response = await page.goto(url, { 
            waitUntil: 'domcontentloaded',
            timeout: 15000 
        });
        const loadTime = Date.now() - startTime;
        
        if (!response || response.status() !== 200) {
            recordTest(`${serviceName}_loading`, false, { 
                status: response?.status(),
                error: 'Non-200 response'
            });
            return false;
        }
        
        recordTest(`${serviceName}_loading`, true, { loadTime });
        
        // Test title
        const title = await page.title();
        const titleContainsService = title.toLowerCase().includes(config.name.toLowerCase());
        recordTest(`${serviceName}_title`, titleContainsService, { title });
        
        // Test for service-specific elements
        let elementsFound = 0;
        for (const expectedElement of config.expectedElements) {
            try {
                const elementExists = await page.locator(`text=${expectedElement}`).count() > 0 ||
                                   await page.locator(`[aria-label*="${expectedElement}"]`).count() > 0 ||
                                   await page.locator(`[title*="${expectedElement}"]`).count() > 0;
                
                if (elementExists) {
                    elementsFound++;
                }
            } catch (e) {
                // Element not found, continue
            }
        }
        
        const elementsTest = elementsFound >= config.expectedElements.length / 2; // At least half found
        recordTest(`${serviceName}_elements`, elementsTest, { 
            found: elementsFound, 
            expected: config.expectedElements.length 
        });
        
        // Test navigation elements
        let navigationFound = false;
        for (const selector of Object.values(config.selectors)) {
            try {
                if (await page.locator(selector).count() > 0) {
                    navigationFound = true;
                    break;
                }
            } catch (e) {
                // Selector failed, continue
            }
        }
        
        recordTest(`${serviceName}_navigation`, navigationFound);
        
        // Performance test
        const performanceTest = loadTime < 5000; // Should load within 5 seconds
        recordTest(`${serviceName}_performance`, performanceTest, { loadTime });
        
        return true;
        
    } catch (error) {
        recordTest(`${serviceName}_error`, false, { error: error.message });
        return false;
    } finally {
        await context.close();
    }
}

async function testAPIEndpoints(serviceName, config) {
    // Test API endpoints without Playwright (lighter weight)
    const apiUrl = `http://localhost:${config.port}/api/v3/system/status`;
    
    try {
        const response = await fetch(apiUrl, {
            method: 'GET',
            headers: {
                'User-Agent': 'UsenetMediaStackTester/1.0'
            }
        });
        
        // API responses: 200 (public), 401 (auth required), 404 (different version)
        const validResponses = [200, 401, 404];
        const isValid = validResponses.includes(response.status);
        
        recordTest(`${serviceName}_api`, isValid, { 
            status: response.status,
            url: apiUrl 
        });
        
        return isValid;
        
    } catch (error) {
        recordTest(`${serviceName}_api`, false, { 
            error: error.message,
            url: apiUrl 
        });
        return false;
    }
}

async function runWebTests() {
    log('INFO', '🌐 Starting comprehensive web UI testing...');
    
    const browser = await chromium.launch({ 
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    for (const [serviceName, config] of Object.entries(SERVICES)) {
        await testServiceUI(browser, serviceName, config);
        
        // Small delay between tests
        await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    await browser.close();
}

async function runAPITests() {
    log('INFO', '🔌 Starting API endpoint testing...');
    
    const apiServices = ['sonarr', 'radarr', 'prowlarr', 'whisparr', 'bazarr'];
    
    for (const serviceName of apiServices) {
        if (SERVICES[serviceName]) {
            await testAPIEndpoints(serviceName, SERVICES[serviceName]);
        }
    }
}

async function generateReport() {
    results.endTime = new Date();
    const duration = results.endTime - results.startTime;
    
    log('INFO', '📊 Generating test report...');
    
    const report = {
        summary: {
            total: results.passed + results.failed,
            passed: results.passed,
            failed: results.failed,
            duration: `${Math.round(duration / 1000)}s`,
            timestamp: results.startTime.toISOString()
        },
        tests: results.tests,
        services: Object.keys(SERVICES).map(service => ({
            name: service,
            port: SERVICES[service].port,
            tests: results.tests.filter(test => test.name.startsWith(service))
        }))
    };
    
    // Write detailed JSON report
    const reportPath = path.join(__dirname, 'test-report.json');
    fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
    
    // Console summary
    console.log('\n' + '='.repeat(80));
    log('INFO', '🧪 TEST SUMMARY');
    console.log('='.repeat(80));
    console.log(`📊 Total Tests: ${report.summary.total}`);
    console.log(`✅ Passed: ${report.summary.passed}`);
    console.log(`❌ Failed: ${report.summary.failed}`);
    console.log(`⏱️  Duration: ${report.summary.duration}`);
    console.log(`📄 Report saved: ${reportPath}`);
    
    if (results.failed > 0) {
        console.log('\n❌ FAILED TESTS:');
        results.tests
            .filter(test => !test.passed)
            .forEach(test => {
                console.log(`   • ${test.name}: ${test.details.error || 'Unknown error'}`);
            });
    }
    
    console.log('='.repeat(80));
    
    return report;
}

// Main execution
async function main() {
    const args = process.argv.slice(2);
    const suite = args.find(arg => arg.startsWith('--suite='))?.split('=')[1] || 'all';
    
    try {
        log('INFO', '🚀 Starting Usenet Media Stack Web Testing');
        log('INFO', `Test suite: ${suite}`);
        
        switch (suite) {
            case 'web':
                await runWebTests();
                break;
            case 'api':
                await runAPITests();
                break;
            case 'all':
            default:
                await runWebTests();
                await runAPITests();
                break;
        }
        
        const report = await generateReport();
        
        // Exit with error code if tests failed
        process.exit(results.failed > 0 ? 1 : 0);
        
    } catch (error) {
        log('ERROR', 'Test execution failed:', error.message);
        process.exit(1);
    }
}

// For Node.js fetch (if not available)
if (typeof fetch === 'undefined') {
    global.fetch = require('node-fetch');
}

if (require.main === module) {
    main();
}

module.exports = { main, SERVICES, testServiceUI, testAPIEndpoints };
