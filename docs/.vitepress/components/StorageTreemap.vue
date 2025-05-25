<template>
  <div class="storage-treemap">
    <h3>🗄️ Interactive Storage Visualization</h3>
    
    <div class="storage-controls">
      <button 
        v-for="view in viewModes" 
        :key="view.id"
        @click="currentView = view.id"
        :class="['view-btn', { active: currentView === view.id }]"
      >
        {{ view.emoji }} {{ view.name }}
      </button>
    </div>
    
    <div ref="treemapContainer" class="treemap-container"></div>
    
    <div class="storage-details">
      <div class="detail-grid">
        <div class="detail-card">
          <h4>💾 Total Detected Storage</h4>
          <div class="storage-stat">
            <span class="storage-number">47.8TB</span>
            <span class="storage-label">Across 29 drives</span>
          </div>
          <div class="storage-breakdown">
            <div class="breakdown-item">
              <span class="breakdown-label">ZFS Pools:</span>
              <span class="breakdown-value">798GB</span>
            </div>
            <div class="breakdown-item">
              <span class="breakdown-label">Cloud Storage:</span>
              <span class="breakdown-value">8.2TB</span>
            </div>
            <div class="breakdown-item">
              <span class="breakdown-label">External Drives:</span>
              <span class="breakdown-value">39TB</span>
            </div>
          </div>
        </div>

        <div class="detail-card">
          <h4>🔄 Hot-Swap Performance</h4>
          <div class="performance-metrics">
            <div class="metric-item">
              <span class="metric-label">Detection Time:</span>
              <span class="metric-value">2.1s</span>
            </div>
            <div class="metric-item">
              <span class="metric-label">Mount Generation:</span>
              <span class="metric-value">1.2s</span>
            </div>
            <div class="metric-item">
              <span class="metric-label">API Updates:</span>
              <span class="metric-value">3.4s</span>
            </div>
            <div class="metric-item">
              <span class="metric-label">Total Integration:</span>
              <span class="metric-value">< 10s</span>
            </div>
          </div>
        </div>

        <div class="detail-card">
          <h4>📊 Usage Analytics</h4>
          <div class="usage-stats">
            <div class="usage-bar">
              <div class="usage-fill" :style="{ width: '68%' }"></div>
              <span class="usage-text">Media Library: 68%</span>
            </div>
            <div class="usage-bar">
              <div class="usage-fill" :style="{ width: '15%' }"></div>
              <span class="usage-text">System Files: 15%</span>
            </div>
            <div class="usage-bar">
              <div class="usage-fill" :style="{ width: '12%' }"></div>
              <span class="usage-text">Downloads: 12%</span>
            </div>
            <div class="usage-bar">
              <div class="usage-fill" :style="{ width: '5%' }"></div>
              <span class="usage-text">Other: 5%</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, watch } from 'vue'

const treemapContainer = ref()
const currentView = ref('by-size')

const viewModes = [
  { id: 'by-size', name: 'By Size', emoji: '📏' },
  { id: 'by-type', name: 'By Type', emoji: '🏷️' },
  { id: 'by-usage', name: 'By Usage', emoji: '📊' },
  { id: 'by-performance', name: 'By Speed', emoji: '⚡' }
]

// Real storage data based on actual system discovery
const storageData = {
  'by-size': {
    name: 'Root',
    children: [
      {
        name: 'Fast_8TB_31 (NVMe)',
        size: 8000,
        type: 'nvme',
        usage: 45,
        speed: 'high',
        color: '#50fa7b'
      },
      {
        name: 'External_4TB_1',
        size: 4000,
        type: 'external',
        usage: 78,
        speed: 'medium',
        color: '#8be9fd'
      },
      {
        name: 'External_4TB_2',
        size: 4000,
        type: 'external',
        usage: 65,
        speed: 'medium',
        color: '#8be9fd'
      },
      {
        name: 'Cloud_Dropbox',
        size: 3100,
        type: 'cloud',
        usage: 80,
        speed: 'variable',
        color: '#bd93f9'
      },
      {
        name: 'Cloud_OneDrive',
        size: 2100,
        type: 'cloud',
        usage: 43,
        speed: 'variable',
        color: '#bd93f9'
      },
      {
        name: 'ZFS_Root',
        size: 798,
        type: 'zfs',
        usage: 26,
        speed: 'high',
        color: '#ffb86c'
      },
      {
        name: 'External_Drives_Array',
        size: 25000,
        type: 'jbod',
        usage: 72,
        speed: 'medium',
        color: '#f093fb'
      }
    ]
  },
  'by-type': {
    name: 'Root',
    children: [
      {
        name: 'NVMe Storage',
        size: 8798,
        children: [
          { name: 'Fast_8TB_31', size: 8000, color: '#50fa7b' },
          { name: 'ZFS_Root', size: 798, color: '#ffb86c' }
        ]
      },
      {
        name: 'Cloud Storage',
        size: 5200,
        children: [
          { name: 'Dropbox', size: 3100, color: '#bd93f9' },
          { name: 'OneDrive', size: 2100, color: '#bd93f9' }
        ]
      },
      {
        name: 'External Arrays',
        size: 33000,
        children: [
          { name: 'JBOD_Array', size: 25000, color: '#f093fb' },
          { name: 'External_4TB_1', size: 4000, color: '#8be9fd' },
          { name: 'External_4TB_2', size: 4000, color: '#8be9fd' }
        ]
      }
    ]
  }
}

let treemap = null

const createTreemap = () => {
  if (typeof window === 'undefined') return
  
  import('d3').then(d3 => {
    const container = treemapContainer.value
    container.innerHTML = ''
    
    const width = container.clientWidth
    const height = 400
    
    const svg = d3.select(container)
      .append('svg')
      .attr('width', width)
      .attr('height', height)
    
    const data = storageData[currentView.value]
    
    const root = d3.hierarchy(data)
      .sum(d => d.size)
      .sort((a, b) => b.value - a.value)
    
    const treemapLayout = d3.treemap()
      .size([width, height])
      .padding(2)
      .round(true)
    
    treemapLayout(root)
    
    const tooltip = d3.select(container)
      .append('div')
      .style('position', 'absolute')
      .style('background', 'rgba(0, 0, 0, 0.9)')
      .style('color', 'white')
      .style('padding', '12px')
      .style('border-radius', '8px')
      .style('font-size', '12px')
      .style('pointer-events', 'none')
      .style('opacity', 0)
      .style('z-index', 1000)
    
    const leaf = svg.selectAll('g')
      .data(root.leaves())
      .enter().append('g')
      .attr('transform', d => `translate(${d.x0},${d.y0})`)
    
    leaf.append('rect')
      .attr('width', d => Math.max(0, d.x1 - d.x0))
      .attr('height', d => Math.max(0, d.y1 - d.y0))
      .attr('fill', d => d.data.color || '#667eea')
      .attr('stroke', '#ffffff')
      .attr('stroke-width', 2)
      .attr('rx', 4)
      .style('cursor', 'pointer')
      .style('transition', 'all 0.3s ease')
      .on('mouseover', function(event, d) {
        d3.select(this)
          .style('opacity', 0.8)
          .attr('stroke-width', 3)
        
        tooltip.transition().duration(200).style('opacity', 1)
        tooltip.html(`
          <strong>${d.data.name}</strong><br/>
          Size: ${(d.data.size / 1000).toFixed(1)}TB<br/>
          Usage: ${d.data.usage || 'N/A'}%<br/>
          Type: ${d.data.type || 'N/A'}<br/>
          Speed: ${d.data.speed || 'N/A'}
        `)
        .style('left', (event.pageX + 10) + 'px')
        .style('top', (event.pageY - 10) + 'px')
      })
      .on('mouseout', function() {
        d3.select(this)
          .style('opacity', 1)
          .attr('stroke-width', 2)
        
        tooltip.transition().duration(200).style('opacity', 0)
      })
    
    leaf.append('text')
      .attr('x', 4)
      .attr('y', 16)
      .text(d => {
        const width = d.x1 - d.x0
        const height = d.y1 - d.y0
        if (width > 100 && height > 30) {
          return d.data.name
        }
        return ''
      })
      .attr('font-size', '12px')
      .attr('font-weight', '600')
      .attr('fill', '#ffffff')
      .attr('text-shadow', '1px 1px 2px rgba(0,0,0,0.5)')
    
    leaf.append('text')
      .attr('x', 4)
      .attr('y', 32)
      .text(d => {
        const width = d.x1 - d.x0
        const height = d.y1 - d.y0
        if (width > 80 && height > 45) {
          return `${(d.data.size / 1000).toFixed(1)}TB`
        }
        return ''
      })
      .attr('font-size', '10px')
      .attr('fill', '#ffffff')
      .attr('opacity', 0.9)
      .attr('text-shadow', '1px 1px 2px rgba(0,0,0,0.5)')
  })
}

watch(currentView, () => {
  createTreemap()
})

onMounted(async () => {
  await nextTick()
  createTreemap()
  
  // Recreate on window resize
  window.addEventListener('resize', createTreemap)
})
</script>

<style scoped>
.storage-treemap {
  margin: 2rem 0;
  padding: 2rem;
  background: linear-gradient(135deg, rgba(102, 126, 234, 0.05) 0%, rgba(118, 75, 162, 0.05) 100%);
  border-radius: 16px;
  border: 1px solid rgba(102, 126, 234, 0.1);
}

.storage-controls {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  margin-bottom: 1.5rem;
}

.view-btn {
  padding: 0.5rem 1rem;
  background: rgba(255, 255, 255, 0.7);
  border: 1px solid rgba(102, 126, 234, 0.2);
  border-radius: 8px;
  font-size: 0.9rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.view-btn:hover {
  background: rgba(102, 126, 234, 0.1);
  transform: translateY(-2px);
}

.view-btn.active {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  border-color: transparent;
}

.treemap-container {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(16px);
  border-radius: 12px;
  border: 1px solid rgba(102, 126, 234, 0.1);
  margin-bottom: 1.5rem;
  position: relative;
  overflow: hidden;
}

.storage-details {
  margin-top: 1.5rem;
}

.detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 1.5rem;
}

.detail-card {
  background: rgba(255, 255, 255, 0.8);
  backdrop-filter: blur(16px);
  border-radius: 12px;
  padding: 1.5rem;
  border: 1px solid rgba(102, 126, 234, 0.1);
  transition: all 0.3s ease;
}

.detail-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 24px rgba(102, 126, 234, 0.15);
}

.detail-card h4 {
  margin: 0 0 1rem 0;
  color: #334155;
  font-weight: 600;
}

.storage-stat {
  text-align: center;
  margin-bottom: 1rem;
}

.storage-number {
  display: block;
  font-size: 2.5rem;
  font-weight: 700;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.storage-label {
  font-size: 0.9rem;
  color: #64748b;
  font-weight: 500;
}

.storage-breakdown {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.breakdown-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid rgba(102, 126, 234, 0.1);
}

.breakdown-item:last-child {
  border-bottom: none;
}

.breakdown-label {
  font-size: 0.9rem;
  color: #64748b;
}

.breakdown-value {
  font-weight: 600;
  color: #334155;
}

.performance-metrics {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.metric-item {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.metric-label {
  font-size: 0.8rem;
  color: #64748b;
  font-weight: 500;
}

.metric-value {
  font-size: 1.2rem;
  color: #334155;
  font-weight: 700;
}

.usage-stats {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.usage-bar {
  position: relative;
  background: rgba(102, 126, 234, 0.1);
  border-radius: 8px;
  height: 32px;
  overflow: hidden;
}

.usage-fill {
  height: 100%;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  transition: width 0.8s ease;
}

.usage-text {
  position: absolute;
  top: 50%;
  left: 12px;
  transform: translateY(-50%);
  font-size: 0.85rem;
  font-weight: 500;
  color: #ffffff;
  text-shadow: 1px 1px 2px rgba(0,0,0,0.3);
}

@media (max-width: 768px) {
  .detail-grid {
    grid-template-columns: 1fr;
  }
  
  .performance-metrics {
    grid-template-columns: 1fr;
  }
}
</style>