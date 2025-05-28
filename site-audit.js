const { chromium } = require('@playwright/test');

async function auditSite() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  const page = await context.newPage();

  console.log('🔍 COMPREHENSIVE SITE AUDIT: https://beppesarrstack.net\n');
  console.log('=' + '='.repeat(60) + '\n');

  try {
    // Navigate to the homepage
    console.log('📍 HOMEPAGE ANALYSIS');
    console.log('-'.repeat(30));
    
    await page.goto('https://beppesarrstack.net', { waitUntil: 'networkidle' });
    
    // Get page title and meta description
    const title = await page.title();
    const metaDescription = await page.getAttribute('meta[name="description"]', 'content');
    
    console.log('✅ Title:', title);
    console.log('✅ Meta Description:', metaDescription);
    
    // Check Open Graph tags
    console.log('\n🏷️  OPEN GRAPH TAGS');
    console.log('-'.repeat(30));
    
    const ogTags = await page.evaluate(() => {
      const tags = {};
      const ogElements = document.querySelectorAll('meta[property^="og:"]');
      ogElements.forEach(el => {
        tags[el.getAttribute('property')] = el.getAttribute('content');
      });
      return tags;
    });
    
    Object.entries(ogTags).forEach(([property, content]) => {
      console.log(`✅ ${property}: ${content}`);
    });
    
    // Check Twitter tags
    console.log('\n🐦 TWITTER TAGS');
    console.log('-'.repeat(30));
    
    const twitterTags = await page.evaluate(() => {
      const tags = {};
      const twitterElements = document.querySelectorAll('meta[name^="twitter:"]');
      twitterElements.forEach(el => {
        tags[el.getAttribute('name')] = el.getAttribute('content');
      });
      return tags;
    });
    
    Object.entries(twitterTags).forEach(([name, content]) => {
      console.log(`✅ ${name}: ${content}`);
    });

    // Check navigation menu
    console.log('\n🧭 NAVIGATION MENU');
    console.log('-'.repeat(30));
    
    const navLinks = await page.evaluate(() => {
      const links = [];
      const navElements = document.querySelectorAll('nav a, .VPNavBarMenuLink');
      navElements.forEach(el => {
        if (el.textContent.trim() && el.href) {
          links.push({
            text: el.textContent.trim(),
            href: el.href,
            isActive: el.classList.contains('active')
          });
        }
      });
      return links;
    });
    
    navLinks.forEach(link => {
      const status = link.isActive ? '🔶 ACTIVE' : '⚪';
      console.log(`${status} ${link.text} → ${link.href}`);
    });

    // Check console errors
    console.log('\n🚨 CONSOLE ERRORS & WARNINGS');
    console.log('-'.repeat(30));
    
    const logs = [];
    page.on('console', msg => {
      if (msg.type() === 'error' || msg.type() === 'warning') {
        logs.push(`${msg.type().toUpperCase()}: ${msg.text()}`);
      }
    });
    
    // Wait a bit for any console messages
    await page.waitForTimeout(2000);
    
    if (logs.length > 0) {
      logs.forEach(log => console.log(`❌ ${log}`));
    } else {
      console.log('✅ No console errors or warnings detected');
    }

    // Test the Visualizations page specifically
    console.log('\n📊 VISUALIZATIONS PAGE ANALYSIS');
    console.log('-'.repeat(30));
    
    await page.goto('https://beppesarrstack.net/visualizations', { waitUntil: 'networkidle' });
    
    const vizTitle = await page.title();
    console.log('✅ Visualizations Page Title:', vizTitle);
    
    // Check if visualization components are present
    const content = await page.textContent('body');
    
    const expectedSections = [
      '📊 Advanced System Visualizations',
      '🚀 Performance Benchmarking', 
      '🌐 Service Network Topology',
      '🗄️ Storage System Visualization',
      '🏗️ System Architecture'
    ];
    
    expectedSections.forEach(section => {
      if (content.includes(section)) {
        console.log(`✅ Found section: ${section}`);
      } else {
        console.log(`❌ Missing section: ${section}`);
      }
    });
    
    // Check for component placeholders (indicating disabled components)
    const hasPlaceholders = content.includes('<!---->');
    if (hasPlaceholders) {
      console.log('⚠️  Empty component placeholders detected (components commented out)');
    }

    // Check page load performance
    console.log('\n⚡ PERFORMANCE METRICS');
    console.log('-'.repeat(30));
    
    const navigationTiming = await page.evaluate(() => {
      const timing = performance.getEntriesByType('navigation')[0];
      return {
        domContentLoaded: Math.round(timing.domContentLoadedEventEnd - timing.fetchStart),
        loadComplete: Math.round(timing.loadEventEnd - timing.fetchStart),
        firstPaint: Math.round(timing.responseEnd - timing.fetchStart)
      };
    });
    
    console.log(`✅ DOM Content Loaded: ${navigationTiming.domContentLoaded}ms`);
    console.log(`✅ Load Complete: ${navigationTiming.loadComplete}ms`);
    console.log(`✅ First Paint: ${navigationTiming.firstPaint}ms`);

    // Test a few more key pages
    console.log('\n🔗 KEY PAGES ACCESSIBILITY');
    console.log('-'.repeat(30));
    
    const testPages = [
      '/getting-started/',
      '/cli/',
      '/architecture/',
      '/free-media'
    ];
    
    for (const testPage of testPages) {
      try {
        const response = await page.goto(`https://beppesarrstack.net${testPage}`, { 
          waitUntil: 'networkidle',
          timeout: 10000 
        });
        const status = response.status();
        if (status === 200) {
          console.log(`✅ ${testPage} → Status ${status}`);
        } else {
          console.log(`⚠️  ${testPage} → Status ${status}`);
        }
      } catch (error) {
        console.log(`❌ ${testPage} → Error: ${error.message}`);
      }
    }

    // Check for any broken links or 404s
    console.log('\n🔍 LINK VALIDATION');
    console.log('-'.repeat(30));
    
    await page.goto('https://beppesarrstack.net', { waitUntil: 'networkidle' });
    
    const internalLinks = await page.evaluate(() => {
      const links = [];
      const anchors = document.querySelectorAll('a[href^="/"], a[href^="https://beppesarrstack.net"]');
      anchors.forEach(a => {
        if (a.href && !links.includes(a.href)) {
          links.push(a.href);
        }
      });
      return links.slice(0, 10); // Test first 10 internal links
    });
    
    for (const link of internalLinks) {
      try {
        const response = await page.goto(link, { timeout: 5000 });
        const status = response.status();
        const shortLink = link.replace('https://beppesarrstack.net', '');
        if (status === 200) {
          console.log(`✅ ${shortLink || '/'} → ${status}`);
        } else {
          console.log(`⚠️  ${shortLink || '/'} → ${status}`);
        }
      } catch (error) {
        console.log(`❌ ${link} → Timeout or error`);
      }
    }

  } catch (error) {
    console.error('❌ AUDIT FAILED:', error.message);
  } finally {
    await browser.close();
  }

  console.log('\n' + '=' + '='.repeat(60));
  console.log('🏁 AUDIT COMPLETE');
  console.log('=' + '='.repeat(60));
}

auditSite().catch(console.error);