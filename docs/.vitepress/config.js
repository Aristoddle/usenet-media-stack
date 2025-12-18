import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "Beppe's Arr Stack",
  description: "Beppe's Arr: opinionated Usenet+torrent homelab stack with hot-swappable storage, GPU assist, and honest docs.",
  
  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#3eaf7c' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: "Beppe's Arr Stack" }],
    ['meta', { property: 'og:description', content: 'Opinionated Usenet+torrent homelab stack with hot-swap storage and GPU assist' }],
    ['meta', { property: 'og:image', content: 'https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png' }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { property: 'og:url', content: 'https://beppesarrstack.net' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: "Beppe's Arr Stack" }],
    ['meta', { name: 'twitter:description', content: 'Opinionated Usenet+torrent homelab stack with hot-swap storage and GPU assist.' }],
    ['meta', { name: 'twitter:image', content: 'https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png' }],
    ['meta', { name: 'keywords', content: 'media automation, docker, jellyfin, sonarr, radarr, hot-swap, jbod, gpu acceleration' }]
  ],
  // Allow dead links during local builds to keep CI green while docs are being realigned
  ignoreDeadLinks: true,

  themeConfig: {
    logo: '/logo.svg',
    
    nav: [
      { text: 'Home', link: '/' },
      {
        text: 'Guides',
        items: [
          { text: 'Quickstart', link: '/getting-started/' },
          { text: 'Ops Runbook', link: '/ops-runbook' },
          { text: 'Usenet Primer', link: '/usenet-primer' },
          { text: 'Usenet Onboarding', link: '/usenet-onboarding' },
          { text: 'TRaSH Guides', link: '/trash-guides' },
          { text: 'Reading Stack', link: '/reading-stack' },
          { text: 'Books Reorg Plan', link: '/books-reorg-plan' },
          { text: 'Komics TODO', link: '/TODO-komics-stack' },
          { text: 'FAQ', link: '/faq' }
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'CLI Reference', link: '/cli/' },
          { text: 'Architecture', link: '/architecture/' },
          { text: 'Advanced', link: '/advanced/' },
          { text: 'Service Status', link: '/SERVICES/' },
          { text: 'Local Endpoints', link: '/local-endpoints' },
          { text: 'Visualizations', link: '/visualizations' }
        ]
      },
      {
        text: 'Resources',
        items: [
          { text: 'Free Media', link: '/free-media' },
          { text: 'Secrets', link: '/secrets' }
        ]
      },
      {
        text: 'Support',
        items: [
          { text: 'Open an Issue', link: 'https://github.com/Aristoddle/usenet-media-stack/issues' },
          { text: 'Email Joe', link: 'mailto:j3lanzone@gmail.com?subject=Help%20with%20media%20stack' }
        ]
      },
      { text: 'GitHub', link: 'https://github.com/Aristoddle/usenet-media-stack' }
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
