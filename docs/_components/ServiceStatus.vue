<template>
  <div class="service-status">
    <h2>🎯 Usenet Media Stack Status</h2>
    <div class="status-summary">
      <div class="metric">
        <span class="number">{{ workingServices.length }}</span>
        <span class="label">Working Services</span>
      </div>
      <div class="metric">
        <span class="number">{{ totalServices }}</span>
        <span class="label">Total Services</span>
      </div>
      <div class="metric">
        <span class="number">{{ successRate }}%</span>
        <span class="label">Success Rate</span>
      </div>
    </div>
    
    <div class="services-grid">
      <div 
        v-for="service in services" 
        :key="service.name"
        :class="['service-card', service.status]"
      >
        <div class="service-header">
          <span class="status-icon">{{ getStatusIcon(service.status) }}</span>
          <h3>{{ service.name }}</h3>
        </div>
        <p class="service-description">{{ service.description }}</p>
        <div class="service-details">
          <span class="port">Port: {{ service.port }}</span>
          <a v-if="service.status === 'working'" :href="service.url" target="_blank" class="service-link">
            Open Service →
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ServiceStatus',
  data() {
    return {
      services: [
        {
          name: 'Plex',
          description: 'Media Server - Stream movies, TV shows, music',
          port: 32400,
          url: 'http://localhost:32400',
          status: 'working'
        },
        {
          name: 'Prowlarr', 
          description: 'Indexer Manager - Unified search sources',
          port: 9696,
          url: 'http://localhost:9696',
          status: 'working'
        },
        {
          name: 'Portainer',
          description: 'Container Management - Docker interface',
          port: 9000,
          url: 'http://localhost:9000', 
          status: 'working'
        },
        {
          name: 'Bazarr',
          description: 'Subtitle Automation - Multi-language subtitles',
          port: 6767,
          url: 'http://localhost:6767',
          status: 'working'
        },
        {
          name: 'Tdarr',
          description: 'Transcoding Engine - Video optimization',
          port: 8265,
          url: 'http://localhost:8265',
          status: 'working'
        },
        {
          name: 'YACReader',
          description: 'Comic Reader - Digital comic library',
          port: 8083,
          url: 'http://localhost:8083',
          status: 'working'
        },
        {
          name: 'Sonarr',
          description: 'TV Automation - Series management',
          port: 8989,
          url: 'http://localhost:8989',
          status: 'failed'
        },
        {
          name: 'Radarr',
          description: 'Movie Automation - Film management', 
          port: 7878,
          url: 'http://localhost:7878',
          status: 'failed'
        },
        {
          name: 'SABnzbd',
          description: 'Downloader - Usenet client',
          port: 8080,
          url: 'http://localhost:8080',
          status: 'error'
        },
        {
          name: 'Overseerr',
          description: 'Request Management - Media requests',
          port: 5055,
          url: 'http://localhost:5055',
          status: 'error'
        }
      ]
    }
  },
  computed: {
    workingServices() {
      return this.services.filter(s => s.status === 'working')
    },
    totalServices() {
      return this.services.length
    },
    successRate() {
      return Math.round((this.workingServices.length / this.totalServices) * 100)
    }
  },
  methods: {
    getStatusIcon(status) {
      switch(status) {
        case 'working': return '✅'
        case 'error': return '⚠️'
        case 'failed': return '❌'
        default: return '❓'
      }
    }
  }
}
</script>

<style scoped>
.service-status {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem;
}

.status-summary {
  display: flex;
  gap: 2rem;
  margin-bottom: 2rem;
  justify-content: center;
}

.metric {
  text-align: center;
  padding: 1rem;
  background: var(--vp-c-bg-soft);
  border-radius: 8px;
  min-width: 120px;
}

.metric .number {
  display: block;
  font-size: 2rem;
  font-weight: bold;
  color: var(--vp-c-brand-1);
}

.metric .label {
  font-size: 0.9rem;
  color: var(--vp-c-text-2);
}

.services-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1rem;
}

.service-card {
  padding: 1.5rem;
  border-radius: 8px;
  border: 2px solid;
  transition: transform 0.2s;
}

.service-card:hover {
  transform: translateY(-2px);
}

.service-card.working {
  border-color: #10b981;
  background: linear-gradient(135deg, #ecfdf5 0%, #f0fdf4 100%);
}

.service-card.error {
  border-color: #f59e0b;
  background: linear-gradient(135deg, #fffbeb 0%, #fef3c7 100%);
}

.service-card.failed {
  border-color: #ef4444;
  background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
}

.service-header {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
}

.status-icon {
  font-size: 1.2rem;
}

.service-header h3 {
  margin: 0;
  font-size: 1.1rem;
}

.service-description {
  color: var(--vp-c-text-2);
  margin-bottom: 1rem;
  font-size: 0.9rem;
}

.service-details {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.port {
  font-family: monospace;
  background: var(--vp-c-bg-mute);
  padding: 0.2rem 0.5rem;
  border-radius: 4px;
  font-size: 0.8rem;
}

.service-link {
  color: var(--vp-c-brand-1);
  text-decoration: none;
  font-weight: 500;
}

.service-link:hover {
  text-decoration: underline;
}
</style>
