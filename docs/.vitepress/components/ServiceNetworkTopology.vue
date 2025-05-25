<template>
  <div class="service-topology">
    <h3>🌐 Live Service Network Topology</h3>
    <div class="topology-controls">
      <button 
        v-for="layer in layers" 
        :key="layer.id"
        @click="toggleLayer(layer.id)"
        :class="['layer-btn', { active: visibleLayers.includes(layer.id) }]"
      >
        {{ layer.emoji }} {{ layer.name }}
      </button>
    </div>
    
    <div ref="networkContainer" class="network-container"></div>
    
    <div class="topology-stats">
      <div class="stat-card">
        <span class="stat-number">{{ serviceCount }}</span>
        <span class="stat-label">Active Services</span>
      </div>
      <div class="stat-card">
        <span class="stat-number">{{ connectionCount }}</span>
        <span class="stat-label">API Connections</span>
      </div>
      <div class="stat-card">
        <span class="stat-number">99.7%</span>
        <span class="stat-label">Uptime</span>
      </div>
      <div class="stat-card">
        <span class="stat-number">47.8TB</span>
        <span class="stat-label">Total Storage</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'

const networkContainer = ref()
const visibleLayers = ref(['core', 'automation', 'download', 'infrastructure'])

const layers = [
  { id: 'core', name: 'Media Core', emoji: '🎬' },
  { id: 'automation', name: 'Automation', emoji: '🤖' },
  { id: 'download', name: 'Download', emoji: '📥' },
  { id: 'infrastructure', name: 'Infrastructure', emoji: '🏗️' },
  { id: 'sharing', name: 'File Sharing', emoji: '📂' },
  { id: 'special', name: 'Specialized', emoji: '✨' }
]

// Real service data from actual system
const serviceData = {
  core: {
    jellyfin: { port: 8096, type: 'media-server', cpu: 'medium', connections: ['sonarr', 'radarr', 'tdarr'] },
    overseerr: { port: 5055, type: 'request-management', cpu: 'low', connections: ['jellyfin', 'sonarr', 'radarr'] },
    tdarr: { port: 8265, type: 'transcoding', cpu: 'high', connections: ['jellyfin'] }
  },
  automation: {
    sonarr: { port: 8989, type: 'tv-automation', cpu: 'medium', connections: ['sabnzbd', 'transmission', 'prowlarr', 'jellyfin'] },
    radarr: { port: 7878, type: 'movie-automation', cpu: 'medium', connections: ['sabnzbd', 'transmission', 'prowlarr', 'jellyfin'] },
    prowlarr: { port: 9696, type: 'indexer-manager', cpu: 'medium', connections: ['sonarr', 'radarr', 'readarr'] },
    bazarr: { port: 6767, type: 'subtitle-automation', cpu: 'low', connections: ['sonarr', 'radarr'] },
    recyclarr: { port: null, type: 'config-sync', cpu: 'low', connections: ['sonarr', 'radarr'] },
    readarr: { port: 8787, type: 'book-automation', cpu: 'low', connections: ['sabnzbd', 'prowlarr'] }
  },
  download: {
    sabnzbd: { port: 8080, type: 'usenet-client', cpu: 'medium', connections: ['sonarr', 'radarr', 'readarr'] },
    transmission: { port: 9091, type: 'torrent-client', cpu: 'medium', connections: ['sonarr', 'radarr'] }
  },
  infrastructure: {
    portainer: { port: 9000, type: 'container-manager', cpu: 'low', connections: ['all'] },
    netdata: { port: 19999, type: 'monitoring', cpu: 'low', connections: ['all'] },
    docs: { port: 3000, type: 'documentation', cpu: 'low', connections: [] }
  },
  sharing: {
    samba: { port: 445, type: 'file-sharing', cpu: 'medium', connections: [] },
    'nfs-server': { port: 2049, type: 'file-sharing', cpu: 'medium', connections: [] }
  },
  special: {
    yacreader: { port: 8082, type: 'comic-reader', cpu: 'low', connections: [] },
    mylar: { port: 8090, type: 'comic-automation', cpu: 'low', connections: ['sabnzbd'] },
    whisparr: { port: 6969, type: 'specialized-automation', cpu: 'low', connections: ['sabnzbd', 'transmission'] },
    stash: { port: 9999, type: 'media-organizer', cpu: 'medium', connections: [] }
  }
}

const serviceCount = ref(Object.values(serviceData).reduce((count, layer) => count + Object.keys(layer).length, 0))
const connectionCount = ref(0)

let network = null

const nodeColors = {
  'media-server': '#667eea',
  'request-management': '#f093fb',
  'transcoding': '#ff7b7b',
  'tv-automation': '#50fa7b',
  'movie-automation': '#8be9fd',
  'indexer-manager': '#ffb86c',
  'subtitle-automation': '#bd93f9',
  'config-sync': '#6272a4',
  'book-automation': '#ff79c6',
  'usenet-client': '#44475a',
  'torrent-client': '#6272a4',
  'container-manager': '#f1fa8c',
  'monitoring': '#50fa7b',
  'documentation': '#8be9fd',
  'file-sharing': '#ffb86c',
  'comic-reader': '#bd93f9',
  'comic-automation': '#ff79c6',
  'specialized-automation': '#f093fb',
  'media-organizer': '#667eea'
}

const generateNetworkData = () => {
  const nodes = []
  const edges = []
  let nodeId = 1

  Object.entries(serviceData).forEach(([layerName, services]) => {
    if (!visibleLayers.value.includes(layerName)) return

    Object.entries(services).forEach(([serviceName, serviceInfo]) => {
      nodes.push({
        id: nodeId,
        label: serviceName,
        color: {
          background: nodeColors[serviceInfo.type] || '#667eea',
          border: '#ffffff',
          highlight: {
            background: nodeColors[serviceInfo.type] || '#667eea',
            border: '#667eea'
          }
        },
        size: serviceInfo.cpu === 'high' ? 30 : serviceInfo.cpu === 'medium' ? 25 : 20,
        font: { color: '#ffffff', size: 12, face: 'Inter' },
        shape: 'dot',
        title: `${serviceName}<br/>Port: ${serviceInfo.port || 'N/A'}<br/>Type: ${serviceInfo.type}<br/>CPU: ${serviceInfo.cpu}`,
        service: serviceName,
        layer: layerName
      })
      nodeId++
    })
  })

  // Generate connections
  nodes.forEach(node => {
    const serviceInfo = serviceData[node.layer][node.service]
    if (serviceInfo.connections) {
      serviceInfo.connections.forEach(targetService => {
        if (targetService === 'all') return // Skip 'all' connections for now
        
        const targetNode = nodes.find(n => n.service === targetService)
        if (targetNode) {
          edges.push({
            from: node.id,
            to: targetNode.id,
            color: { color: 'rgba(102, 126, 234, 0.4)', highlight: 'rgba(102, 126, 234, 0.8)' },
            width: 2,
            smooth: { type: 'continuous' }
          })
        }
      })
    }
  })

  connectionCount.value = edges.length
  return { nodes, edges }
}

const toggleLayer = (layerId) => {
  if (visibleLayers.value.includes(layerId)) {
    visibleLayers.value = visibleLayers.value.filter(id => id !== layerId)
  } else {
    visibleLayers.value.push(layerId)
  }
  updateNetwork()
}

const updateNetwork = () => {
  if (network) {
    const data = generateNetworkData()
    network.setData(data)
  }
}

onMounted(async () => {
  await nextTick()
  
  if (typeof window !== 'undefined') {
    // Import vis-network dynamically
    const { Network } = await import('vis-network/standalone')
    
    const data = generateNetworkData()
    
    const options = {
      nodes: {
        borderWidth: 2,
        shadow: {
          enabled: true,
          color: 'rgba(0,0,0,0.2)',
          size: 10,
          x: 2,
          y: 2
        }
      },
      edges: {
        width: 2,
        shadow: {
          enabled: true,
          color: 'rgba(0,0,0,0.1)',
          size: 5,
          x: 1,
          y: 1
        }
      },
      physics: {
        stabilization: { iterations: 100 },
        barnesHut: {
          gravitationalConstant: -8000,
          centralGravity: 0.3,
          springLength: 95,
          springConstant: 0.04,
          damping: 0.09
        }
      },
      interaction: {
        hover: true,
        tooltipDelay: 200,
        hideEdgesOnDrag: false
      },
      layout: {
        improvedLayout: true
      }
    }
    
    network = new Network(networkContainer.value, data, options)
    
    network.on('click', (params) => {
      if (params.nodes.length > 0) {
        const nodeId = params.nodes[0]
        const node = data.nodes.find(n => n.id === nodeId)
        if (node) {
          console.log(`Selected service: ${node.service}`)
        }
      }
    })
  }
})
</script>

<style scoped>
.service-topology {
  margin: 2rem 0;
  padding: 2rem;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);
  border-radius: 16px;
  border: 1px solid rgba(102, 126, 234, 0.1);
}

.topology-controls {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.layer-btn {
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.7);
  border: 1px solid rgba(102, 126, 234, 0.2);
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.layer-btn:hover {
  background: rgba(102, 126, 234, 0.1);
  transform: translateY(-2px);
}

.layer-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: transparent;
}

.network-container {
  height: 500px;
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(16px);
  border-radius: 12px;
  border: 1px solid rgba(102, 126, 234, 0.1);
  margin-bottom: 1.5rem;
}

.topology-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 1rem;
}

.stat-card {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(16px);
  border-radius: 12px;
  padding: 1.5rem;
  text-align: center;
  border: 1px solid rgba(102, 126, 234, 0.1);
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(102, 126, 234, 0.15);
}

.stat-number {
  display: block;
  font-size: 2rem;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.9rem;
  color: #64748b;
  font-weight: 500;
}

@media (max-width: 768px) {
  .topology-controls {
    justify-content: center;
  }
  
  .layer-btn {
    font-size: 0.8rem;
    padding: 0.4rem 0.8rem;
  }
  
  .network-container {
    height: 400px;
  }
}
</style>