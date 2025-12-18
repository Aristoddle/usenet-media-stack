<template>
  <div class="service-topology">
    <h3>🌐 Interactive Service Network Topology</h3>
    
    <!-- Controls -->
    <div class="topology-controls">
      <div class="control-group">
        <label>
          <input type="checkbox" v-model="showDataFlow" @change="updateNetwork" />
          Show Data Flow
        </label>
        <label>
          <input type="checkbox" v-model="showPorts" @change="updateNetwork" />
          Show Port Numbers
        </label>
        <label>
          <input type="checkbox" v-model="groupByType" @change="updateLayout" />
          Group by Service Type
        </label>
      </div>
      
      <div class="layout-controls">
        <button 
          v-for="layout in layouts" 
          :key="layout.key"
          @click="changeLayout(layout.key)"
          :class="{ active: currentLayout === layout.key }"
          class="layout-btn"
        >
          {{ layout.name }}
        </button>
      </div>
    </div>

    <!-- Network Visualization -->
    <div class="network-container">
      <div ref="networkEl" class="network-canvas"></div>
    </div>

    <!-- Service Details Panel -->
    <div class="service-panel" v-if="selectedService">
      <div class="panel-header">
        <h4>{{ selectedService.label }}</h4>
        <button @click="selectedService = null" class="close-btn">×</button>
      </div>
      
      <div class="panel-content">
        <div class="service-info">
          <div class="info-item">
            <span class="label">Type:</span>
            <span class="value">{{ selectedService.group }}</span>
          </div>
          <div class="info-item">
            <span class="label">Port:</span>
            <span class="value">{{ selectedService.port }}</span>
          </div>
          <div class="info-item">
            <span class="label">Status:</span>
            <span class="value status" :class="selectedService.status">{{ selectedService.status }}</span>
          </div>
          <div class="info-item">
            <span class="label">Description:</span>
            <span class="value">{{ selectedService.description }}</span>
          </div>
        </div>

        <div class="service-connections">
          <h5>Connected Services</h5>
          <div class="connections-list">
            <div 
              v-for="connection in getServiceConnections(selectedService.id)" 
              :key="connection.id"
              class="connection-item"
              @click="selectService(connection)"
            >
              <span class="connection-name">{{ connection.label }}</span>
              <span class="connection-type">{{ getConnectionType(selectedService.id, connection.id) }}</span>
            </div>
          </div>
        </div>

        <div class="service-actions">
          <button class="action-btn primary" @click="openService(selectedService)">
            🌐 Open Web UI
          </button>
          <button class="action-btn secondary" @click="showLogs(selectedService)">
            📋 View Logs
          </button>
          <button class="action-btn secondary" @click="restartService(selectedService)">
            🔄 Restart
          </button>
        </div>
      </div>
    </div>

    <!-- Network Statistics -->
    <div class="network-stats">
      <div class="stat-card">
        <div class="stat-value">{{ services.length }}</div>
        <div class="stat-label">Total Services</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ activeServices }}</div>
        <div class="stat-label">Active</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ connections.length }}</div>
        <div class="stat-label">Connections</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">{{ serviceGroups.length }}</div>
        <div class="stat-label">Service Types</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, computed, nextTick } from 'vue'
import { DataSet, Network } from 'vis-network/standalone/esm/vis-network'

// Reactive state
const networkEl = ref(null)
const network = ref(null)
const selectedService = ref(null)
const showDataFlow = ref(true)
const showPorts = ref(true)
const groupByType = ref(true)
const currentLayout = ref('hierarchical')

// Layout options
const layouts = [
  { key: 'hierarchical', name: 'Hierarchical' },
  { key: 'force', name: 'Force-Directed' },
  { key: 'circular', name: 'Circular' },
  { key: 'random', name: 'Random' }
]

// Service data
const services = [
  // Media Automation
  { id: 'sonarr', label: 'Sonarr', group: 'Media Automation', port: '8989', status: 'running', description: 'TV show automation with TRaSH Guide optimization' },
  { id: 'radarr', label: 'Radarr', group: 'Media Automation', port: '7878', status: 'running', description: 'Movie automation with custom quality profiles' },
  { id: 'prowlarr', label: 'Prowlarr', group: 'Media Automation', port: '9696', status: 'running', description: 'Universal indexer management' },
  { id: 'bazarr', label: 'Bazarr', group: 'Media Automation', port: '6767', status: 'running', description: 'Subtitle automation for 40+ languages' },
  { id: 'recyclarr', label: 'Recyclarr', group: 'Media Automation', port: 'N/A', status: 'running', description: 'Automatic TRaSH Guide optimization' },
  
  // Media Servers
  { id: 'plex', label: 'Plex', group: 'Media Server', port: '32400', status: 'running', description: 'Media server with hardware transcoding' },
  { id: 'overseerr', label: 'Overseerr', group: 'Media Server', port: '5055', status: 'running', description: 'Beautiful request management interface' },
  
  // Processing
  { id: 'tdarr', label: 'Tdarr', group: 'Processing', port: '8265', status: 'running', description: 'Automated transcoding with GPU acceleration' },
  
  // Download Clients
  { id: 'sabnzbd', label: 'SABnzbd', group: 'Download Client', port: '8080', status: 'running', description: 'High-speed Usenet downloader' },
  { id: 'transmission', label: 'Transmission', group: 'Download Client', port: '9092', status: 'running', description: 'BitTorrent client' },
  
  // Management
  { id: 'portainer', label: 'Portainer', group: 'Management', port: '9000', status: 'running', description: 'Docker container management' },
  { id: 'netdata', label: 'Netdata', group: 'Management', port: '19999', status: 'running', description: 'Real-time system monitoring' },
  
  // Indexers
  { id: 'jackett', label: 'Jackett', group: 'Indexer', port: '9117', status: 'running', description: 'Torrent tracker proxy' },
  
  // File Sharing
  { id: 'samba', label: 'Samba', group: 'File Sharing', port: '445', status: 'running', description: 'Windows file sharing' },
  { id: 'nfs', label: 'NFS Server', group: 'File Sharing', port: '2049', status: 'running', description: 'Unix/Linux file sharing' },
  
  // Adult Content
  { id: 'whisparr', label: 'Whisparr', group: 'Adult Content', port: '6969', status: 'running', description: 'Adult content automation' },
  
  // Comics
  { id: 'mylar', label: 'Mylar3', group: 'Comics', port: '8090', status: 'running', description: 'Comic book automation' }
]

// Connection definitions
const connections = [
  // Prowlarr feeds indexers to *arr apps
  { from: 'prowlarr', to: 'sonarr', type: 'indexer-feed', label: 'Indexer Config' },
  { from: 'prowlarr', to: 'radarr', type: 'indexer-feed', label: 'Indexer Config' },
  { from: 'prowlarr', to: 'whisparr', type: 'indexer-feed', label: 'Indexer Config' },
  { from: 'prowlarr', to: 'mylar', type: 'indexer-feed', label: 'Indexer Config' },
  
  // *arr apps send downloads to clients
  { from: 'sonarr', to: 'sabnzbd', type: 'download', label: 'Download Request' },
  { from: 'sonarr', to: 'transmission', type: 'download', label: 'Download Request' },
  { from: 'radarr', to: 'sabnzbd', type: 'download', label: 'Download Request' },
  { from: 'radarr', to: 'transmission', type: 'download', label: 'Download Request' },
  
  // Download clients notify completion
  { from: 'sabnzbd', to: 'sonarr', type: 'completion', label: 'Download Complete' },
  { from: 'sabnzbd', to: 'radarr', type: 'completion', label: 'Download Complete' },
  { from: 'transmission', to: 'sonarr', type: 'completion', label: 'Download Complete' },
  { from: 'transmission', to: 'radarr', type: 'completion', label: 'Download Complete' },
  
  // Bazarr gets subtitle requests
  { from: 'sonarr', to: 'bazarr', type: 'subtitle-request', label: 'Subtitle Request' },
  { from: 'radarr', to: 'bazarr', type: 'subtitle-request', label: 'Subtitle Request' },
  
  // Media servers access content
  { from: 'plex', to: 'sonarr', type: 'library-scan', label: 'Library Scan' },
  { from: 'plex', to: 'radarr', type: 'library-scan', label: 'Library Scan' },
  
  // Tdarr processes media
  { from: 'tdarr', to: 'plex', type: 'transcoding', label: 'Transcoding' },
  
  // Overseerr manages requests
  { from: 'overseerr', to: 'sonarr', type: 'media-request', label: 'Media Request' },
  { from: 'overseerr', to: 'radarr', type: 'media-request', label: 'Media Request' },
  
  // TRaSH Guide optimization
  { from: 'recyclarr', to: 'sonarr', type: 'config-sync', label: 'TRaSH Config' },
  { from: 'recyclarr', to: 'radarr', type: 'config-sync', label: 'TRaSH Config' },
  
  // File sharing access
  { from: 'samba', to: 'plex', type: 'file-access', label: 'File Access' },
  { from: 'nfs', to: 'plex', type: 'file-access', label: 'File Access' },
  
  // Jackett legacy indexer support
  { from: 'jackett', to: 'sonarr', type: 'legacy-indexer', label: 'Legacy Indexer' },
  { from: 'jackett', to: 'radarr', type: 'legacy-indexer', label: 'Legacy Indexer' }
]

// Computed properties
const activeServices = computed(() => 
  services.filter(s => s.status === 'running').length
)

const serviceGroups = computed(() => 
  [...new Set(services.map(s => s.group))]
)

// Network configuration
const getNetworkData = () => {
  const nodes = new DataSet(services.map(service => ({
    id: service.id,
    label: showPorts.value ? `${service.label}\n:${service.port}` : service.label,
    group: service.group,
    title: `${service.label} (${service.port})\n${service.description}`,
    color: getServiceColor(service.group, service.status),
    font: { 
      color: '#2c3e50',
      size: 12,
      face: 'Inter, sans-serif'
    },
    shape: 'box',
    margin: 10,
    widthConstraint: { minimum: 80, maximum: 150 }
  })))

  const edges = new DataSet(connections.filter(conn => 
    !showDataFlow.value || conn.type !== 'legacy-indexer'
  ).map(conn => ({
    from: conn.from,
    to: conn.to,
    label: showDataFlow.value ? conn.label : '',
    color: getConnectionColor(conn.type),
    arrows: 'to',
    width: 2,
    smooth: { type: 'dynamic' },
    font: { size: 10, color: '#7f8c8d' }
  })))

  return { nodes, edges }
}

const getServiceColor = (group, status) => {
  const groupColors = {
    'Media Automation': { background: '#3498db', border: '#2980b9' },
    'Media Server': { background: '#9b59b6', border: '#8e44ad' },
    'Download Client': { background: '#e74c3c', border: '#c0392b' },
    'Processing': { background: '#f39c12', border: '#e67e22' },
    'Management': { background: '#34495e', border: '#2c3e50' },
    'Indexer': { background: '#16a085', border: '#138d75' },
    'File Sharing': { background: '#27ae60', border: '#229954' },
    'Adult Content': { background: '#e91e63', border: '#c2185b' },
    'Comics': { background: '#ff9800', border: '#f57c00' }
  }
  
  const baseColor = groupColors[group] || { background: '#95a5a6', border: '#7f8c8d' }
  
  if (status !== 'running') {
    return { background: '#bdc3c7', border: '#95a5a6' }
  }
  
  return baseColor
}

const getConnectionColor = (type) => {
  const typeColors = {
    'indexer-feed': '#3498db',
    'download': '#e74c3c',
    'completion': '#27ae60',
    'subtitle-request': '#f39c12',
    'library-scan': '#9b59b6',
    'transcoding': '#e67e22',
    'media-request': '#16a085',
    'config-sync': '#34495e',
    'file-access': '#27ae60',
    'legacy-indexer': '#95a5a6'
  }
  return typeColors[type] || '#7f8c8d'
}

const getNetworkOptions = () => ({
  layout: getLayoutOptions(),
  physics: {
    enabled: currentLayout.value !== 'hierarchical',
    stabilization: { iterations: 100 }
  },
  groups: groupByType.value ? {
    'Media Automation': { color: { background: '#3498db', border: '#2980b9' } },
    'Media Server': { color: { background: '#9b59b6', border: '#8e44ad' } },
    'Download Client': { color: { background: '#e74c3c', border: '#c0392b' } },
    'Processing': { color: { background: '#f39c12', border: '#e67e22' } },
    'Management': { color: { background: '#34495e', border: '#2c3e50' } },
    'Indexer': { color: { background: '#16a085', border: '#138d75' } },
    'File Sharing': { color: { background: '#27ae60', border: '#229954' } },
    'Adult Content': { color: { background: '#e91e63', border: '#c2185b' } },
    'Comics': { color: { background: '#ff9800', border: '#f57c00' } }
  } : {},
  interaction: {
    hover: true,
    selectConnectedEdges: false
  },
  nodes: {
    shape: 'box',
    margin: 10,
    font: { 
      color: '#2c3e50',
      size: 12,
      face: 'Inter, sans-serif'
    }
  },
  edges: {
    smooth: {
      type: 'dynamic',
      roundness: 0.5
    },
    arrows: {
      to: { enabled: true, scaleFactor: 1 }
    }
  }
})

const getLayoutOptions = () => {
  switch (currentLayout.value) {
    case 'hierarchical':
      return {
        hierarchical: {
          enabled: true,
          direction: 'UD',
          sortMethod: 'directed',
          nodeSpacing: 200,
          levelSeparation: 150
        }
      }
    case 'force':
      return {
        randomSeed: 42
      }
    case 'circular':
      return {
        randomSeed: 42
      }
    default:
      return {}
  }
}

// Network management methods
const createNetwork = () => {
  if (!networkEl.value) return
  
  const data = getNetworkData()
  const options = getNetworkOptions()
  
  network.value = new Network(networkEl.value, data, options)
  
  // Event listeners
  network.value.on('click', (event) => {
    if (event.nodes.length > 0) {
      const nodeId = event.nodes[0]
      const service = services.find(s => s.id === nodeId)
      if (service) {
        selectedService.value = service
      }
    } else {
      selectedService.value = null
    }
  })
  
  network.value.on('hoverNode', (event) => {
    networkEl.value.style.cursor = 'pointer'
  })
  
  network.value.on('blurNode', (event) => {
    networkEl.value.style.cursor = 'default'
  })
}

const updateNetwork = () => {
  if (!network.value) return
  
  const data = getNetworkData()
  network.value.setData(data)
}

const updateLayout = () => {
  if (!network.value) return
  
  const options = getNetworkOptions()
  network.value.setOptions(options)
}

const changeLayout = (layoutKey) => {
  currentLayout.value = layoutKey
  updateLayout()
}

// Service interaction methods
const getServiceConnections = (serviceId) => {
  const connectedIds = new Set()
  
  connections.forEach(conn => {
    if (conn.from === serviceId) {
      connectedIds.add(conn.to)
    }
    if (conn.to === serviceId) {
      connectedIds.add(conn.from)
    }
  })
  
  return services.filter(s => connectedIds.has(s.id))
}

const getConnectionType = (fromId, toId) => {
  const connection = connections.find(c => 
    (c.from === fromId && c.to === toId) || 
    (c.from === toId && c.to === fromId)
  )
  return connection ? connection.type : 'unknown'
}

const selectService = (service) => {
  selectedService.value = service
  if (network.value) {
    network.value.selectNodes([service.id])
    network.value.focus(service.id, { animation: true })
  }
}

const openService = (service) => {
  if (service.port && service.port !== 'N/A') {
    window.open(`http://localhost:${service.port}`, '_blank')
  }
}

const showLogs = (service) => {
  alert(`Would show logs for ${service.label}`)
}

const restartService = (service) => {
  alert(`Would restart ${service.label}`)
}

// Lifecycle
onMounted(() => {
  nextTick(createNetwork)
})

onUnmounted(() => {
  if (network.value) {
    network.value.destroy()
  }
})
</script>

<style scoped>
.service-topology {
  background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
  border-radius: 16px;
  padding: 2rem;
  margin: 2rem 0;
  color: white;
}

.service-topology h3 {
  text-align: center;
  margin-bottom: 2rem;
  font-size: 2rem;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.topology-controls {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.control-group {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.control-group label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  cursor: pointer;
  font-size: 0.9rem;
}

.control-group input[type="checkbox"] {
  accent-color: #3eaf7c;
}

.layout-controls {
  display: flex;
  gap: 0.5rem;
}

.layout-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.85rem;
}

.layout-btn:hover,
.layout-btn.active {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-1px);
}

.network-container {
  position: relative;
  margin-bottom: 2rem;
}

.network-canvas {
  width: 100%;
  height: 600px;
  background: rgba(255, 255, 255, 0.95);
  border-radius: 8px;
  border: 2px solid rgba(255, 255, 255, 0.3);
}

.service-panel {
  position: fixed;
  top: 50%;
  right: 2rem;
  transform: translateY(-50%);
  width: 350px;
  max-height: 80vh;
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 12px;
  overflow: hidden;
  z-index: 1000;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.1);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.panel-header h4 {
  margin: 0;
  font-size: 1.2rem;
}

.close-btn {
  background: none;
  border: none;
  color: white;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.3s ease;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

.panel-content {
  padding: 1rem;
  max-height: calc(80vh - 80px);
  overflow-y: auto;
}

.service-info {
  margin-bottom: 1.5rem;
}

.info-item {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  padding: 0.5rem 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.info-item .label {
  font-weight: bold;
  opacity: 0.8;
}

.info-item .value {
  flex: 1;
  text-align: right;
}

.status.running {
  color: #27ae60;
  font-weight: bold;
}

.service-connections {
  margin-bottom: 1.5rem;
}

.service-connections h5 {
  margin: 0 0 1rem 0;
  font-size: 1rem;
}

.connections-list {
  max-height: 200px;
  overflow-y: auto;
}

.connection-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem;
  margin-bottom: 0.5rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 6px;
  cursor: pointer;
  transition: background 0.3s ease;
}

.connection-item:hover {
  background: rgba(255, 255, 255, 0.2);
}

.connection-name {
  font-weight: bold;
}

.connection-type {
  font-size: 0.8rem;
  opacity: 0.7;
}

.service-actions {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.action-btn {
  padding: 0.75rem 1rem;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
}

.action-btn.primary {
  background: #3eaf7c;
  color: white;
}

.action-btn.secondary {
  background: rgba(255, 255, 255, 0.2);
  color: white;
}

.action-btn:hover {
  transform: translateY(-1px);
  filter: brightness(1.1);
}

.network-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1rem;
  margin-top: 2rem;
}

.stat-card {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 1rem;
  text-align: center;
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.stat-value {
  font-size: 2rem;
  font-weight: bold;
  color: #3eaf7c;
  margin-bottom: 0.25rem;
}

.stat-label {
  font-size: 0.85rem;
  opacity: 0.8;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

/* Responsive design */
@media (max-width: 1024px) {
  .service-panel {
    position: relative;
    right: auto;
    top: auto;
    transform: none;
    width: 100%;
    max-height: none;
  }
}

@media (max-width: 768px) {
  .topology-controls {
    flex-direction: column;
    align-items: stretch;
  }
  
  .layout-controls {
    justify-content: center;
  }
  
  .network-canvas {
    height: 400px;
  }
}
</style>
