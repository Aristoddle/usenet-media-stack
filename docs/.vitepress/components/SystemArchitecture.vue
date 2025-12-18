<template>
  <div class="architecture-diagram">
    <h3>🏗️ Interactive System Architecture</h3>
    <div class="diagram-container">
      <svg viewBox="0 0 1200 800" class="architecture-svg">
        <!-- Background gradients -->
        <defs>
          <linearGradient id="containerGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#3eaf7c;stop-opacity:0.1" />
            <stop offset="100%" style="stop-color:#3eaf7c;stop-opacity:0.3" />
          </linearGradient>
          <linearGradient id="storageGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#e74c3c;stop-opacity:0.1" />
            <stop offset="100%" style="stop-color:#e74c3c;stop-opacity:0.3" />
          </linearGradient>
          <linearGradient id="networkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#f39c12;stop-opacity:0.1" />
            <stop offset="100%" style="stop-color:#f39c12;stop-opacity:0.3" />
          </linearGradient>
          <linearGradient id="gpuGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:#9b59b6;stop-opacity:0.1" />
            <stop offset="100%" style="stop-color:#9b59b6;stop-opacity:0.3" />
          </linearGradient>
        </defs>

        <!-- Network Layer -->
        <g class="layer network-layer" @click="selectLayer('network')">
          <rect x="50" y="50" width="1100" height="120" rx="10" 
                fill="url(#networkGrad)" stroke="#f39c12" stroke-width="2" 
                :class="{ active: selectedLayer === 'network' }"/>
          <text x="600" y="85" text-anchor="middle" class="layer-title">🌐 Network & Security Layer</text>
          
          <!-- Cloudflare Tunnel -->
          <g class="service-node" @click.stop="selectService('cloudflare')">
            <rect x="150" y="100" width="120" height="50" rx="5" 
                  fill="#f39c12" :class="{ active: selectedService === 'cloudflare' }"/>
            <text x="210" y="130" text-anchor="middle" class="service-text">Cloudflare</text>
          </g>
          
          <!-- Domain -->
          <g class="service-node" @click.stop="selectService('domain')">
            <rect x="300" y="100" width="120" height="50" rx="5" 
                  fill="#f39c12" :class="{ active: selectedService === 'domain' }"/>
            <text x="360" y="130" text-anchor="middle" class="service-text">beppesarrstack.net</text>
          </g>
          
          <!-- SSL/TLS -->
          <g class="service-node" @click.stop="selectService('ssl')">
            <rect x="450" y="100" width="120" height="50" rx="5" 
                  fill="#f39c12" :class="{ active: selectedService === 'ssl' }"/>
            <text x="510" y="130" text-anchor="middle" class="service-text">SSL/TLS</text>
          </g>
        </g>

        <!-- Container Layer -->
        <g class="layer container-layer" @click="selectLayer('containers')">
          <rect x="50" y="200" width="1100" height="350" rx="10" 
                fill="url(#containerGrad)" stroke="#3eaf7c" stroke-width="2"
                :class="{ active: selectedLayer === 'containers' }"/>
          <text x="600" y="235" text-anchor="middle" class="layer-title">🐳 Container Orchestration (19 Services)</text>
          
          <!-- Media Automation -->
          <g class="service-group">
            <text x="200" y="270" text-anchor="middle" class="group-title">📺 Media Automation</text>
            <g class="service-node" @click.stop="selectService('sonarr')">
              <rect x="120" y="280" width="80" height="40" rx="5" fill="#3eaf7c" :class="{ active: selectedService === 'sonarr' }"/>
              <text x="160" y="305" text-anchor="middle" class="service-text">Sonarr</text>
            </g>
            <g class="service-node" @click.stop="selectService('radarr')">
              <rect x="220" y="280" width="80" height="40" rx="5" fill="#3eaf7c" :class="{ active: selectedService === 'radarr' }"/>
              <text x="260" y="305" text-anchor="middle" class="service-text">Radarr</text>
            </g>
            <g class="service-node operational" @click.stop="selectService('prowlarr')">
              <rect x="120" y="330" width="80" height="40" rx="5" fill="#10B981" :class="{ active: selectedService === 'prowlarr' }"/>
              <text x="160" y="355" text-anchor="middle" class="service-text">Prowlarr ✅</text>
            </g>
            <g class="service-node" @click.stop="selectService('bazarr')">
              <rect x="220" y="330" width="80" height="40" rx="5" fill="#3eaf7c" :class="{ active: selectedService === 'bazarr' }"/>
              <text x="260" y="355" text-anchor="middle" class="service-text">Bazarr</text>
            </g>
          </g>

          <!-- Media Servers -->
          <g class="service-group">
            <text x="500" y="270" text-anchor="middle" class="group-title">🎬 Media Servers</text>
            <g class="service-node" @click.stop="selectService('plex')">
              <rect x="420" y="280" width="80" height="40" rx="5" fill="#2980b9" :class="{ active: selectedService === 'plex' }"/>
              <text x="460" y="305" text-anchor="middle" class="service-text">Plex</text>
            </g>
            <g class="service-node" @click.stop="selectService('overseerr')">
              <rect x="520" y="280" width="80" height="40" rx="5" fill="#2980b9" :class="{ active: selectedService === 'overseerr' }"/>
              <text x="560" y="305" text-anchor="middle" class="service-text">Overseerr</text>
            </g>
            <g class="service-node" @click.stop="selectService('tdarr')">
              <rect x="420" y="330" width="80" height="40" rx="5" fill="#9b59b6" :class="{ active: selectedService === 'tdarr' }"/>
              <text x="460" y="355" text-anchor="middle" class="service-text">Tdarr</text>
            </g>
          </g>

          <!-- Downloads & Processing -->
          <g class="service-group">
            <text x="800" y="270" text-anchor="middle" class="group-title">⬇️ Downloads</text>
            <g class="service-node" @click.stop="selectService('sabnzbd')">
              <rect x="720" y="280" width="80" height="40" rx="5" fill="#e74c3c" :class="{ active: selectedService === 'sabnzbd' }"/>
              <text x="760" y="305" text-anchor="middle" class="service-text">SABnzbd</text>
            </g>
            <g class="service-node operational" @click.stop="selectService('transmission')">
              <rect x="820" y="280" width="80" height="40" rx="5" fill="#10B981" :class="{ active: selectedService === 'transmission' }"/>
              <text x="860" y="305" text-anchor="middle" class="service-text">Transmission ✅</text>
            </g>
          </g>

          <!-- Management -->
          <g class="service-group">
            <text x="1000" y="270" text-anchor="middle" class="group-title">📊 Management</text>
            <g class="service-node" @click.stop="selectService('portainer')">
              <rect x="920" y="280" width="80" height="40" rx="5" fill="#34495e" :class="{ active: selectedService === 'portainer' }"/>
              <text x="960" y="305" text-anchor="middle" class="service-text">Portainer</text>
            </g>
            <g class="service-node" @click.stop="selectService('netdata')">
              <rect x="1020" y="280" width="80" height="40" rx="5" fill="#34495e" :class="{ active: selectedService === 'netdata' }"/>
              <text x="1060" y="305" text-anchor="middle" class="service-text">Netdata</text>
            </g>
          </g>

          <!-- Data Flow Arrows -->
          <g class="data-flows" v-if="showDataFlow">
            <defs>
              <marker id="arrowhead" markerWidth="10" markerHeight="7" 
                      refX="10" refY="3.5" orient="auto">
                <polygon points="0 0, 10 3.5, 0 7" fill="#3eaf7c" />
              </marker>
            </defs>
            <!-- Prowlarr to *arr apps -->
            <path d="M 200 350 Q 300 320 420 300" stroke="#3eaf7c" stroke-width="2" 
                  fill="none" marker-end="url(#arrowhead)" class="flow-arrow"/>
            <!-- Downloads to Tdarr -->
            <path d="M 800 300 Q 650 315 500 350" stroke="#9b59b6" stroke-width="2" 
                  fill="none" marker-end="url(#arrowhead)" class="flow-arrow"/>
          </g>
        </g>

        <!-- GPU Hardware Layer -->
        <g class="layer gpu-layer" @click="selectLayer('gpu')" v-if="showGPU">
          <rect x="50" y="580" width="550" height="120" rx="10" 
                fill="url(#gpuGrad)" stroke="#9b59b6" stroke-width="2"
                :class="{ active: selectedLayer === 'gpu' }"/>
          <text x="325" y="615" text-anchor="middle" class="layer-title">🎮 GPU Acceleration</text>
          
          <g class="service-node" @click.stop="selectService('amd-gpu')">
            <rect x="150" y="630" width="120" height="50" rx="5" 
                  fill="#9b59b6" :class="{ active: selectedService === 'amd-gpu' }"/>
            <text x="210" y="660" text-anchor="middle" class="service-text">AMD VAAPI</text>
          </g>
          
          <g class="service-node" @click.stop="selectService('transcoding')">
            <rect x="300" y="630" width="120" height="50" rx="5" 
                  fill="#9b59b6" :class="{ active: selectedService === 'transcoding' }"/>
            <text x="360" y="660" text-anchor="middle" class="service-text">4K Transcoding</text>
          </g>
        </g>

        <!-- Storage Layer -->
        <g class="layer storage-layer" @click="selectLayer('storage')">
          <rect x="650" y="580" width="500" height="120" rx="10" 
                fill="url(#storageGrad)" stroke="#e74c3c" stroke-width="2"
                :class="{ active: selectedLayer === 'storage' }"/>
          <text x="900" y="615" text-anchor="middle" class="layer-title">🗄️ Hot-Swappable Storage</text>
          
          <g class="service-node" @click.stop="selectService('zfs')">
            <rect x="680" y="630" width="80" height="50" rx="5" 
                  fill="#e74c3c" :class="{ active: selectedService === 'zfs' }"/>
            <text x="720" y="660" text-anchor="middle" class="service-text">ZFS Pool</text>
          </g>
          
          <g class="service-node" @click.stop="selectService('cloud')">
            <rect x="780" y="630" width="80" height="50" rx="5" 
                  fill="#e74c3c" :class="{ active: selectedService === 'cloud' }"/>
            <text x="820" y="660" text-anchor="middle" class="service-text">Cloud Mounts</text>
          </g>
          
          <g class="service-node" @click.stop="selectService('jbod')">
            <rect x="880" y="630" width="80" height="50" rx="5" 
                  fill="#e74c3c" :class="{ active: selectedService === 'jbod' }"/>
            <text x="920" y="660" text-anchor="middle" class="service-text">JBOD Array</text>
          </g>
          
          <g class="service-node" @click.stop="selectService('exfat')">
            <rect x="980" y="630" width="80" height="50" rx="5" 
                  fill="#e74c3c" :class="{ active: selectedService === 'exfat' }"/>
            <text x="1020" y="660" text-anchor="middle" class="service-text">exFAT Drives</text>
          </g>
        </g>

        <!-- Connection lines between layers -->
        <g class="layer-connections" v-if="showConnections">
          <line x1="600" y1="170" x2="600" y2="200" stroke="#34495e" stroke-width="3"/>
          <line x1="325" y1="550" x2="325" y2="580" stroke="#9b59b6" stroke-width="3"/>
          <line x1="900" y1="550" x2="900" y2="580" stroke="#e74c3c" stroke-width="3"/>
        </g>
      </svg>
    </div>

    <!-- Interactive Controls -->
    <div class="controls">
      <div class="control-group">
        <h4>🎛️ Visualization Controls</h4>
        <label class="control-item">
          <input type="checkbox" v-model="showDataFlow" />
          Show Data Flow
        </label>
        <label class="control-item">
          <input type="checkbox" v-model="showGPU" />
          Show GPU Layer
        </label>
        <label class="control-item">
          <input type="checkbox" v-model="showConnections" />
          Show Layer Connections
        </label>
      </div>
    </div>

    <!-- Service Details Panel -->
    <div class="service-details" v-if="selectedService">
      <h4>{{ getServiceDetails(selectedService).name }}</h4>
      <p>{{ getServiceDetails(selectedService).description }}</p>
      <div class="service-stats">
        <span class="stat">Port: {{ getServiceDetails(selectedService).port }}</span>
        <span class="stat">Type: {{ getServiceDetails(selectedService).type }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'

const selectedLayer = ref(null)
const selectedService = ref(null)
const showDataFlow = ref(false)
const showGPU = ref(true)
const showConnections = ref(true)

const selectLayer = (layer) => {
  selectedLayer.value = selectedLayer.value === layer ? null : layer
  selectedService.value = null
}

const selectService = (service) => {
  selectedService.value = selectedService.value === service ? null : service
}

const serviceDetails = {
  sonarr: { name: 'Sonarr', description: 'TV show automation with TRaSH Guide optimization - Currently not running due to port conflicts', port: '8989', type: 'Media Automation', status: 'stopped' },
  radarr: { name: 'Radarr', description: 'Movie automation with custom quality profiles - Currently not running due to port conflicts', port: '7878', type: 'Media Automation', status: 'stopped' },
  prowlarr: { name: 'Prowlarr', description: 'Universal indexer management for breaking paywall barriers - OPERATIONAL ✅', port: '9696', type: 'Media Automation', status: 'running' },
  bazarr: { name: 'Bazarr', description: 'Subtitle automation for 40+ languages - Currently not running due to port conflicts', port: '6767', type: 'Media Automation', status: 'stopped' },
  plex: { name: 'Plex', description: 'Media server with hardware transcoding', port: '32400', type: 'Media Server', status: 'running' },
  overseerr: { name: 'Overseerr', description: 'Beautiful request management interface - Currently not running due to port conflicts', port: '5055', type: 'Media Server', status: 'stopped' },
  tdarr: { name: 'Tdarr', description: 'Automated transcoding with GPU acceleration - Currently not running due to port conflicts', port: '8265', type: 'Processing', status: 'stopped' },
  sabnzbd: { name: 'SABnzbd', description: 'High-speed Usenet downloader - Currently not running due to port conflicts', port: '8080', type: 'Download Client', status: 'stopped' },
  transmission: { name: 'Transmission', description: 'P2P liberation network - OPERATIONAL ✅', port: '9091', type: 'Download Client', status: 'running' },
  portainer: { name: 'Portainer', description: 'Docker container management', port: '9000', type: 'Management' },
  netdata: { name: 'Netdata', description: 'Real-time system monitoring', port: '19999', type: 'Monitoring' },
  cloudflare: { name: 'Cloudflare Tunnel', description: 'Secure remote access with zero exposed ports', port: '443', type: 'Network' },
  domain: { name: 'Domain', description: 'beppesarrstack.net with automatic SSL', port: '443', type: 'Network' },
  ssl: { name: 'SSL/TLS', description: 'Automatic encryption via Cloudflare', port: '443', type: 'Security' },
  'amd-gpu': { name: 'AMD GPU', description: 'VAAPI hardware acceleration for transcoding', port: 'N/A', type: 'Hardware' },
  transcoding: { name: '4K Transcoding', description: '60+ FPS with 75% power reduction', port: 'N/A', type: 'Processing' },
  zfs: { name: 'ZFS Pool', description: 'High-performance filesystem with snapshots', port: 'N/A', type: 'Storage' },
  cloud: { name: 'Cloud Mounts', description: 'Dropbox, OneDrive, Google Drive integration', port: 'N/A', type: 'Storage' },
  jbod: { name: 'JBOD Array', description: 'Hot-swappable drive arrays', port: 'N/A', type: 'Storage' },
  exfat: { name: 'exFAT Drives', description: 'Portable drives for camping trips', port: 'N/A', type: 'Storage' }
}

const getServiceDetails = (service) => {
  return serviceDetails[service] || { name: service, description: 'Service details', port: 'N/A', type: 'Unknown' }
}
</script>

<style scoped>
.architecture-diagram {
  background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
  border-radius: 12px;
  padding: 2rem;
  margin: 2rem 0;
}

.diagram-container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
}

.architecture-svg {
  width: 100%;
  height: auto;
  border-radius: 8px;
  background: white;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.layer {
  cursor: pointer;
  transition: all 0.3s ease;
}

.layer:hover rect {
  filter: brightness(1.1);
}

.layer.active rect {
  stroke-width: 4;
  filter: drop-shadow(0 0 10px rgba(62, 175, 124, 0.5));
}

.service-node {
  cursor: pointer;
  transition: all 0.3s ease;
}

.service-node:hover rect {
  transform: scale(1.05);
  filter: brightness(1.1);
}

.service-node.active rect {
  stroke: #2c3e50;
  stroke-width: 2;
  filter: drop-shadow(0 0 8px rgba(44, 62, 80, 0.4));
}

.layer-title {
  font-size: 16px;
  font-weight: bold;
  fill: #2c3e50;
}

.group-title {
  font-size: 12px;
  font-weight: bold;
  fill: #34495e;
}

.service-text {
  font-size: 10px;
  font-weight: 500;
  fill: white;
}

.flow-arrow {
  opacity: 0;
  animation: flowPulse 2s ease-in-out infinite;
}

@keyframes flowPulse {
  0%, 100% { opacity: 0; }
  50% { opacity: 1; }
}

.controls {
  display: flex;
  gap: 2rem;
  margin-top: 2rem;
  padding: 1rem;
  background: white;
  border-radius: 8px;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.05);
}

.control-group h4 {
  margin: 0 0 1rem 0;
  color: #2c3e50;
}

.control-item {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  font-size: 14px;
  color: #34495e;
  cursor: pointer;
}

.control-item input[type="checkbox"] {
  accent-color: #3eaf7c;
}

.service-details {
  margin-top: 2rem;
  padding: 1.5rem;
  background: linear-gradient(135deg, #3eaf7c, #2ecc71);
  color: white;
  border-radius: 8px;
  box-shadow: 0 4px 15px rgba(62, 175, 124, 0.3);
}

.service-details h4 {
  margin: 0 0 0.5rem 0;
  font-size: 1.5rem;
}

.service-details p {
  margin: 0 0 1rem 0;
  opacity: 0.9;
}

.service-stats {
  display: flex;
  gap: 1rem;
}

.stat {
  padding: 0.25rem 0.75rem;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 500;
}

/* Responsive design */
@media (max-width: 768px) {
  .controls {
    flex-direction: column;
    gap: 1rem;
  }
  
  .service-stats {
    flex-direction: column;
    gap: 0.5rem;
  }
}
</style>
