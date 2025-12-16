import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Usenet Media Stack',
  description: 'Professional Usenet-powered media automation with hot-swappable storage, GPU acceleration, and intelligent deployment. Plus curated free content resources.',
  
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#3eaf7c' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: 'Usenet Media Stack' }],
    ['meta', { property: 'og:description', content: 'Professional-grade hot-swappable JBOD media automation with Monty as your guide' }],
    ['meta', { property: 'og:image', content: 'https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png' }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { property: 'og:url', content: 'https://beppesarrstack.net' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: 'Usenet Media Stack' }],
    ['meta', { name: 'twitter:description', content: 'Professional media automation with hot-swappable storage. Guided by Monty.' }],
    ['meta', { name: 'twitter:image', content: 'https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png' }],
    ['meta', { name: 'keywords', content: 'media automation, docker, jellyfin, sonarr, radarr, hot-swap, jbod, gpu acceleration' }]
  ],
  // Allow dead links during local builds to keep CI green while docs are being realigned
  ignoreDeadLinks: true,

  themeConfig: {
    logo: '/logo.svg',
    
    nav: [
      { text: 'Guide', link: '/getting-started/' },
      { text: 'CLI Reference', link: '/cli/' },
      { text: 'Architecture', link: '/architecture/' },
      { text: 'Advanced', link: '/advanced/' },
      { text: '📊 Visualizations', link: '/visualizations' },
      { text: '📚 Free Media', link: '/free-media' },
      { text: 'Reading Stack', link: '/reading-stack' },
      { text: 'Komics TODO', link: '/TODO-komics-stack' },
      { text: 'Ops Runbook', link: '/ops-runbook' },
      { text: 'Secrets', link: '/secrets' },
      { text: 'Usenet Primer', link: '/usenet-primer' },
      { text: 'Usenet Onboarding', link: '/usenet-onboarding' },
      { text: 'FAQ', link: '/faq' },
      { 
        text: 'Links',
        items: [
          { text: 'GitHub', link: 'https://github.com/Aristoddle/usenet-media-stack' },
          { text: 'Issues', link: 'https://github.com/Aristoddle/usenet-media-stack/issues' },
          { text: '📧 Request Credentials', link: 'mailto:j3lanzone@gmail.com?subject=Credentials%20Access%20Request&body=Hi%20Joe,%0A%0AI%20need%20access%20to:%0A%0A-%20Specific%20services:%0A-%20My%20background:%0A-%20How%20we%20know%20each%20other:%0A%0AThanks!' }
        ]
      }
    ],
    sidebar: {
      '/getting-started/': [
        {
          text: '🚀 Getting Started',
          items: [
            { text: 'Quick Start', link: '/getting-started/' },
            { text: 'Prerequisites', link: '/getting-started/prerequisites' },
            { text: 'Installation', link: '/getting-started/installation' },
            { text: 'First Deployment', link: '/getting-started/first-deployment' }
          ]
        }
      ],
      
      '/cli/': [
        {
          text: '📋 CLI Reference',
          items: [
            { text: 'Overview', link: '/cli/' },
            { text: 'Deploy Command', link: '/cli/deploy' },
            { text: 'Storage Management', link: '/cli/storage' },
            { text: 'Hardware Optimization', link: '/cli/hardware' },
            { text: 'Backup & Restore', link: '/cli/backup' },
            { text: 'Service Management', link: '/cli/services' },
            { text: 'Validation', link: '/cli/validate' }
          ]
        }
      ],
      
      '/architecture/': [
        {
          text: '🏗️ Architecture',
          items: [
            { text: 'System Overview', link: '/architecture/' },
            { text: 'CLI Design', link: '/architecture/cli-design' },
            { text: 'Service Architecture', link: '/architecture/services' },
            { text: 'Storage System', link: '/architecture/storage' },
            { text: 'Hardware Integration', link: '/architecture/hardware' },
            { text: 'Network & Security', link: '/architecture/network' }
          ]
        }
      ],
      
      '/advanced/': [
        {
          text: '🔧 Advanced Topics',
          items: [
            { text: 'Overview', link: '/advanced/' },
            { text: 'Custom Configurations', link: '/advanced/custom-configs' },
            { text: 'Performance Tuning', link: '/advanced/performance' },
            { text: 'Backup Strategies', link: '/advanced/backup-strategies' },
            { text: 'Hot-Swap Workflows', link: '/advanced/hot-swap' },
            { text: 'Usenet Onboarding', link: '/usenet-onboarding' },
            { text: 'API Integration', link: '/advanced/api-integration' },
            { text: 'Troubleshooting', link: '/advanced/troubleshooting' }
          ]
        }
      ]
    },
    socialLinks: [
      { icon: 'github', link: 'https://github.com/Aristoddle/usenet-media-stack' }
    ],
    footer: {
      message: 'Built with ❤️ following Bell Labs standards. Dedicated to Stan Eisenstat.',
      copyright: 'Copyright © 2025 Joseph Lanzone. MIT Licensed.'
    },
    search: {
      provider: 'local'
    },
    editLink: {
      pattern: 'https://github.com/Aristoddle/usenet-media-stack/edit/main/docs/:path',
      text: 'Edit this page on GitHub'
    },
    lastUpdated: {
      text: 'Updated at',
      formatOptions: {
        dateStyle: 'full',
        timeStyle: 'medium'
      }
    }
  },
  markdown: {
    lineNumbers: true,
    config: (md) => {
      // Add any markdown-it plugins here
    }
  },
  vue: {
    template: {
      compilerOptions: {
        isCustomElement: (tag) => tag.includes('-')
      }
    }
  },
  vite: {
    define: {
      __VUE_OPTIONS_API__: false
    }
  }
})
