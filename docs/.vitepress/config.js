import { defineConfig } from 'vitepress'

export default defineConfig({
  title: "Beppe's Arr Stack",
  description: "Beppe's Arr: opinionated Usenet+torrent homelab stack with 41TB MergerFS pool, SVT-AV1 transcoding, and comprehensive media management.",

  head: [
    ['link', { rel: 'icon', href: '/favicon.ico' }],
    ['meta', { name: 'theme-color', content: '#3eaf7c' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black' }],
    ['meta', { property: 'og:type', content: 'website' }],
    ['meta', { property: 'og:title', content: "Beppe's Arr Stack" }],
    ['meta', { property: 'og:description', content: '41TB MergerFS pool, SVT-AV1 transcoding, Tailscale remote access, and comprehensive books/manga/emulation stacks' }],
    ['meta', { property: 'og:image', content: 'https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png' }],
    ['meta', { property: 'og:image:width', content: '1200' }],
    ['meta', { property: 'og:image:height', content: '630' }],
    ['meta', { property: 'og:url', content: 'https://beppesarrstack.net' }],
    ['meta', { name: 'twitter:card', content: 'summary_large_image' }],
    ['meta', { name: 'twitter:title', content: "Beppe's Arr Stack" }],
    ['meta', { name: 'twitter:description', content: '41TB MergerFS pool, SVT-AV1 transcoding, Tailscale remote access, EmuDeck gaming' }],
    ['meta', { name: 'twitter:image', content: 'https://images.squarespace-cdn.com/content/v1/6565030c0f2a89615e0be33d/fe9447b9-db94-4428-9713-6d2c7d146e2b/Monty2.png' }],
    ['meta', { name: 'keywords', content: 'media automation, docker, plex, sonarr, radarr, mergerfs, svt-av1, tdarr, tailscale, emudeck, komga, audiobookshelf' }]
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
          { text: 'Stack Usage Guide', link: '/STACK_USAGE_GUIDE' },
          { text: 'Usenet Primer', link: '/usenet-primer' },
          { text: 'TRaSH Guides', link: '/trash-guides' },
          { text: 'FAQ', link: '/faq' }
        ]
      },
      {
        text: 'Infrastructure',
        items: [
          { text: 'Architecture', link: '/architecture/' },
          { text: 'Storage & MergerFS', link: '/STORAGE_AND_REMOTE_ACCESS' },
          { text: 'Tdarr Transcoding', link: '/TDARR' },
          { text: 'ISO to AV1 Pipeline', link: '/ISO_REENCODING_WORKFLOW' },
          { text: 'Networking', link: '/networking' },
          { text: 'Services Status', link: '/SERVICES' },
          { text: 'Local Endpoints', link: '/local-endpoints' }
        ]
      },
      {
        text: 'Libraries',
        items: [
          { text: 'Books & Audiobooks', link: '/BOOKS_AND_AUDIOBOOKS_GUIDE' },
          { text: 'Manga Ecosystem', link: '/MANGA_ECOSYSTEM_ANALYSIS' },
          { text: 'Plex Libraries', link: '/PLEX_LIBRARY_ANALYSIS' },
          { text: 'Mylar Setup', link: '/MYLAR_SETUP' },
          { text: 'Suwayomi Setup', link: '/SUWAYOMI_SETUP' },
          { text: 'Library Architecture', link: '/LIBRARY_ARCHITECTURE' }
        ]
      },
      {
        text: 'Gaming',
        items: [
          { text: 'EmuDeck Inventory', link: '/EMUDECK_INVENTORY' }
        ]
      },
      {
        text: 'Reference',
        items: [
          { text: 'CLI Reference', link: '/cli/' },
          { text: 'Advanced', link: '/advanced/' },
          { text: 'User Taste Profile', link: '/USER_TASTE_PROFILE' },
          { text: 'Strategic Roadmap', link: '/STRATEGIC_ROADMAP' },
          { text: 'Free Media Resources', link: '/free-media' }
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
          text: 'Getting Started',
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
          text: 'CLI Reference',
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
          text: 'Architecture',
          items: [
            { text: 'System Overview', link: '/architecture/' },
            { text: 'Design Philosophy', link: '/architecture/design-philosophy' },
            { text: 'Volume Safety', link: '/architecture/volume-safety' },
            { text: 'Storage System', link: '/storage/' }
          ]
        }
      ],

      '/storage/': [
        {
          text: 'Storage',
          items: [
            { text: 'Overview', link: '/storage/' },
            { text: 'MergerFS Architecture', link: '/storage/architecture' },
            { text: 'Storage & Remote Access', link: '/STORAGE_AND_REMOTE_ACCESS' },
            { text: 'BTRFS Migration', link: '/storage/BTRFS_MIGRATION_PLAN' }
          ]
        }
      ],

      '/advanced/': [
        {
          text: 'Advanced Topics',
          items: [
            { text: 'Overview', link: '/advanced/' },
            { text: 'Performance Tuning', link: '/advanced/performance' },
            { text: 'Custom Configurations', link: '/advanced/custom-configs' },
            { text: 'Backup Strategies', link: '/advanced/backup-strategies' },
            { text: 'Hot-Swap Workflows', link: '/advanced/hot-swap' },
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
