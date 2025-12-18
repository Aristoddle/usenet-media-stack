<template>
  <div class="cli-simulator">
    <h3>💻 Interactive CLI Demonstration</h3>
    
    <!-- Terminal Window -->
    <div class="terminal-window">
      <div class="terminal-header">
        <div class="window-controls">
          <div class="control close"></div>
          <div class="control minimize"></div>
          <div class="control maximize"></div>
        </div>
        <div class="terminal-title">
          usenet-media-stack: ~/usenet
        </div>
      </div>
      
      <div class="terminal-body" ref="terminalBody">
        <div class="terminal-content">
          <!-- Command History -->
          <div 
            v-for="(entry, index) in commandHistory" 
            :key="index"
            class="command-entry"
            :class="{ 'executing': entry.executing }"
          >
            <!-- Prompt -->
            <div class="prompt-line">
              <span class="prompt">{{ prompt }}</span>
              <span class="command">{{ entry.command }}</span>
              <span v-if="entry.executing" class="cursor blinking">|</span>
            </div>
            
            <!-- Output -->
            <div v-if="entry.output && !entry.executing" class="command-output">
              <div 
                v-for="line in entry.output" 
                :key="line.id"
                class="output-line"
                :class="line.type"
                v-html="line.content"
              ></div>
            </div>
            
            <!-- Loading Animation -->
            <div v-if="entry.executing" class="loading-animation">
              <div class="spinner"></div>
              <span>{{ entry.loadingText || 'Executing...' }}</span>
            </div>
          </div>
          
          <!-- Current Input -->
          <div v-if="!isExecuting" class="current-input">
            <span class="prompt">{{ prompt }}</span>
            <input 
              ref="commandInput"
              v-model="currentCommand"
              @keydown="handleKeydown"
              @input="handleInput"
              class="command-input"
              placeholder="Type a usenet command or press Tab for suggestions..."
              :disabled="isExecuting"
            />
            <span class="cursor blinking">|</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Command Suggestions -->
    <div v-if="showSuggestions && filteredSuggestions.length > 0" class="suggestions-panel">
      <div class="suggestions-header">
        <span>💡 Available Commands</span>
        <span class="hint">Press Tab to autocomplete</span>
      </div>
      <div class="suggestions-list">
        <div 
          v-for="(suggestion, index) in filteredSuggestions" 
          :key="suggestion.command"
          class="suggestion-item"
          :class="{ active: selectedSuggestion === index }"
          @click="applySuggestion(suggestion)"
        >
          <div class="suggestion-command">{{ suggestion.command }}</div>
          <div class="suggestion-description">{{ suggestion.description }}</div>
        </div>
      </div>
    </div>

    <!-- Quick Actions -->
    <div class="quick-actions">
      <div class="action-group">
        <h5>🚀 Quick Start</h5>
        <button 
          v-for="action in quickStartActions"
          :key="action.command"
          @click="executeCommand(action.command)"
          class="action-btn"
          :disabled="isExecuting"
        >
          {{ action.label }}
        </button>
      </div>
      
      <div class="action-group">
        <h5>🔧 Management</h5>
        <button 
          v-for="action in managementActions"
          :key="action.command"
          @click="executeCommand(action.command)"
          class="action-btn"
          :disabled="isExecuting"
        >
          {{ action.label }}
        </button>
      </div>
      
      <div class="action-group">
        <h5>📊 Monitoring</h5>
        <button 
          v-for="action in monitoringActions"
          :key="action.command"
          @click="executeCommand(action.command)"
          class="action-btn"
          :disabled="isExecuting"
        >
          {{ action.label }}
        </button>
      </div>
    </div>

    <!-- Help Panel -->
    <div v-if="showHelp" class="help-panel">
      <div class="help-header">
        <h4>🔍 Command Help</h4>
        <button @click="showHelp = false" class="close-btn">×</button>
      </div>
      <div class="help-content">
        <div class="help-section">
          <h5>Storage Commands</h5>
          <div class="help-commands">
            <code>usenet storage list</code> - List all detected drives<br>
            <code>usenet storage add &lt;path&gt;</code> - Add drive to pool<br>
            <code>usenet storage sync</code> - Update service APIs
          </div>
        </div>
        <div class="help-section">
          <h5>Hardware Commands</h5>
          <div class="help-commands">
            <code>usenet hardware list</code> - Show GPU capabilities<br>
            <code>usenet hardware optimize</code> - Generate optimized configs<br>
            <code>usenet hardware install-drivers</code> - Install GPU drivers
          </div>
        </div>
        <div class="help-section">
          <h5>Service Commands</h5>
          <div class="help-commands">
            <code>usenet services list</code> - Health check all services<br>
            <code>usenet services logs &lt;name&gt;</code> - View service logs<br>
            <code>usenet services restart</code> - Restart all services
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'

// Reactive state
const commandHistory = ref([])
const currentCommand = ref('')
const isExecuting = ref(false)
const showSuggestions = ref(false)
const selectedSuggestion = ref(0)
const showHelp = ref(false)
const commandInput = ref(null)
const terminalBody = ref(null)

const prompt = 'joe@usenet-stack:~/usenet$'

// Command suggestions database
const commands = [
  { command: 'usenet deploy', description: 'Deploy complete media stack with auto-optimization' },
  { command: 'usenet deploy --auto', description: 'Auto-detect hardware and deploy optimized stack' },
  { command: 'usenet storage list', description: 'List all detected storage drives' },
  { command: 'usenet storage add /mnt/drive1', description: 'Add specific drive to storage pool' },
  { command: 'usenet storage sync', description: 'Update all service APIs with new storage' },
  { command: 'usenet hardware list', description: 'Show detected GPU and optimization opportunities' },
  { command: 'usenet hardware optimize --auto', description: 'Generate hardware-optimized configurations' },
  { command: 'usenet hardware install-drivers', description: 'Install optimal GPU drivers automatically' },
  { command: 'usenet services list', description: 'Health check all 19 services' },
  { command: 'usenet services logs sonarr', description: 'View Sonarr service logs' },
  { command: 'usenet services restart', description: 'Restart all services gracefully' },
  { command: 'usenet backup create', description: 'Create timestamped configuration backup' },
  { command: 'usenet backup list', description: 'List all available backups' },
  { command: 'usenet validate', description: 'Run pre-deployment validation checks' },
  { command: 'usenet --help', description: 'Show comprehensive help system' }
]

// Quick action buttons
const quickStartActions = [
  { command: 'usenet deploy --auto', label: 'Auto Deploy' },
  { command: 'usenet validate', label: 'Validate Setup' },
  { command: 'usenet --help', label: 'Show Help' }
]

const managementActions = [
  { command: 'usenet services list', label: 'Service Status' },
  { command: 'usenet storage list', label: 'Storage Drives' },
  { command: 'usenet backup create', label: 'Create Backup' }
]

const monitoringActions = [
  { command: 'usenet services logs plex', label: 'Plex Logs' },
  { command: 'usenet hardware list', label: 'Hardware Info' },
  { command: 'docker compose ps', label: 'Container Status' }
]

// Computed properties
const filteredSuggestions = computed(() => {
  if (!currentCommand.value.trim()) return []
  
  const query = currentCommand.value.toLowerCase()
  return commands.filter(cmd => 
    cmd.command.toLowerCase().includes(query) ||
    cmd.description.toLowerCase().includes(query)
  ).slice(0, 6)
})

// Mock command outputs
const getCommandOutput = (command) => {
  const outputs = {
    'usenet deploy --auto': [
      { type: 'info', content: '🚀 <span class="highlight">Usenet Media Stack Auto-Deployment</span>' },
      { type: 'step', content: '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' },
      { type: 'success', content: '✅ Hardware detection: <span class="value">AMD Ryzen 7 7840HS + Radeon 780M</span>' },
      { type: 'success', content: '✅ GPU acceleration: <span class="value">VAAPI/AMF enabled</span>' },
      { type: 'success', content: '✅ Storage discovery: <span class="value">29 drives detected</span>' },
      { type: 'info', content: '⚙️  Generating optimized Docker Compose configurations...' },
      { type: 'success', content: '✅ Hardware profile: <span class="value">High Performance (75% allocation)</span>' },
      { type: 'info', content: '🐳 Starting 19 services with GPU optimization...' },
      { type: 'success', content: '✅ Plex: <span class="value">Started with hardware transcoding</span>' },
      { type: 'success', content: '✅ Sonarr: <span class="value">Started with TRaSH Guide profiles</span>' },
      { type: 'success', content: '✅ Radarr: <span class="value">Started with quality optimization</span>' },
      { type: 'success', content: '✅ Tdarr: <span class="value">GPU transcoding queue ready</span>' },
      { type: 'info', content: '🌐 Configuring Cloudflare tunnel...' },
      { type: 'success', content: '✅ Tunnel: <span class="value">beppesarrstack.net secured</span>' },
      { type: 'complete', content: '🎉 <span class="highlight">Deployment Complete!</span> Stack ready at https://beppesarrstack.net' }
    ],
    
    'usenet storage list': [
      { type: 'info', content: '🗄️ <span class="highlight">Discovered Storage Devices</span>' },
      { type: 'step', content: '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' },
      { type: 'device', content: '○ [ 1] <span class="path">/</span>                    <span class="fs">ZFS</span> <span class="size">(798G available)</span>' },
      { type: 'device', content: '○ [ 2] <span class="path">/media/joe/Fast_8TB_31</span> <span class="fs">exFAT</span> <span class="size">(7.3T available)</span>' },
      { type: 'device', content: '○ [ 3] <span class="path">/home/joe/Dropbox</span>     <span class="fs">Cloud</span> <span class="size">(2.5T available)</span>' },
      { type: 'device', content: '○ [ 4] <span class="path">/home/joe/OneDrive</span>    <span class="fs">Cloud</span> <span class="size">(903G available)</span>' },
      { type: 'pool', content: '📁 <span class="highlight">Current Storage Pool:</span>' },
      { type: 'active', content: '● <span class="path">/tmp/test_drive1</span> - <span class="status">Active in pool</span>' },
      { type: 'info', content: '💡 Run <span class="cmd">usenet storage add &lt;path&gt;</span> to add drives to pool' }
    ],
    
    'usenet hardware list': [
      { type: 'info', content: '🎮 <span class="highlight">Hardware Detection Results</span>' },
      { type: 'step', content: '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' },
      { type: 'cpu', content: 'ℹ CPU: <span class="value">AMD Ryzen 7 7840HS w/ Radeon 780M Graphics (16 threads, high_performance class)</span>' },
      { type: 'memory', content: 'ℹ RAM: <span class="value">30GB total, 24GB available (standard class)</span>' },
      { type: 'gpu', content: 'ℹ GPU: <span class="value">AMD: Advanced Micro Devices, Inc. [AMD/ATI] Rembrandt (VAAPI/AMF acceleration)</span>' },
      { type: 'step', content: '' },
      { type: 'success', content: '🚀 <span class="highlight">PERFORMANCE OPTIMIZATION OPPORTUNITIES DETECTED</span>' },
      { type: 'optimization', content: '⚡ AMD GPU Detected! Hardware acceleration unlocks:' },
      { type: 'benefit', content: '   • Hardware HEVC encoding (10x faster than CPU)' },
      { type: 'benefit', content: '   • VAAPI-accelerated transcoding for energy-efficient processing' },
      { type: 'benefit', content: '   • Dual-stream processing (encode while serving media)' },
      { type: 'benefit', content: '   • HDR10 passthrough with tone mapping capabilities' },
      { type: 'step', content: '' },
      { type: 'recommendation', content: '🔧 Run <span class="cmd">usenet hardware optimize --auto</span> to apply optimizations' }
    ],
    
    'usenet services list': [
      { type: 'info', content: '📊 <span class="highlight">Service Health Status</span>' },
      { type: 'step', content: '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' },
      { type: 'running', content: '🟢 <span class="service">plex</span>         <span class="port">:32400</span> <span class="status">Running</span> <span class="info">(4K hardware transcoding active)</span>' },
      { type: 'running', content: '🟢 <span class="service">sonarr</span>        <span class="port">:8989</span>  <span class="status">Running</span> <span class="info">(TRaSH profiles loaded)</span>' },
      { type: 'running', content: '🟢 <span class="service">radarr</span>        <span class="port">:7878</span>  <span class="status">Running</span> <span class="info">(Quality profiles optimized)</span>' },
      { type: 'running', content: '🟢 <span class="service">prowlarr</span>      <span class="port">:9696</span>  <span class="status">Running</span> <span class="info">(Indexers synchronized)</span>' },
      { type: 'running', content: '🟢 <span class="service">bazarr</span>        <span class="port">:6767</span>  <span class="status">Running</span> <span class="info">(40+ languages active)</span>' },
      { type: 'running', content: '🟢 <span class="service">tdarr</span>         <span class="port">:8265</span>  <span class="status">Running</span> <span class="info">(GPU queue: 3 items)</span>' },
      { type: 'running', content: '🟢 <span class="service">overseerr</span>     <span class="port">:5055</span>  <span class="status">Running</span> <span class="info">(Request management)</span>' },
      { type: 'running', content: '🟢 <span class="service">sabnzbd</span>       <span class="port">:8080</span>  <span class="status">Running</span> <span class="info">(Download queue: 12)</span>' },
      { type: 'running', content: '🟢 <span class="service">transmission</span>  <span class="port">:9092</span>  <span class="status">Running</span> <span class="info">(Seeding: 45 torrents)</span>' },
      { type: 'step', content: '' },
      { type: 'success', content: '✅ All 19 services healthy and optimized!' },
      { type: 'info', content: '🌐 Access via: <span class="url">https://beppesarrstack.net</span>' }
    ],
    
    'usenet --help': [
      { type: 'info', content: '📖 <span class="highlight">Usenet Media Stack - Professional CLI</span>' },
      { type: 'step', content: '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' },
      { type: 'section', content: '🚀 <span class="section-title">DEPLOYMENT</span>' },
      { type: 'command', content: '  <span class="cmd">usenet deploy</span>                    Interactive full deployment' },
      { type: 'command', content: '  <span class="cmd">usenet deploy --auto</span>             Auto-detect everything' },
      { type: 'step', content: '' },
      { type: 'section', content: '🗄️ <span class="section-title">STORAGE MANAGEMENT</span>' },
      { type: 'command', content: '  <span class="cmd">usenet storage list</span>             List available drives' },
      { type: 'command', content: '  <span class="cmd">usenet storage add &lt;path&gt;</span>       Add drive to pool' },
      { type: 'command', content: '  <span class="cmd">usenet storage sync</span>             Update service APIs' },
      { type: 'step', content: '' },
      { type: 'section', content: '🎮 <span class="section-title">HARDWARE OPTIMIZATION</span>' },
      { type: 'command', content: '  <span class="cmd">usenet hardware list</span>            Show capabilities' },
      { type: 'command', content: '  <span class="cmd">usenet hardware optimize</span>        Generate configs' },
      { type: 'command', content: '  <span class="cmd">usenet hardware install-drivers</span> Auto-install drivers' },
      { type: 'step', content: '' },
      { type: 'info', content: '💡 For more help: <span class="cmd">usenet help &lt;command&gt;</span>' }
    ]
  }
  
  return outputs[command] || [
    { type: 'error', content: `Command not found: ${command}` },
    { type: 'info', content: 'Type <span class="cmd">usenet --help</span> for available commands' }
  ]
}

// Input handling
const handleKeydown = (event) => {
  switch (event.key) {
    case 'Enter':
      if (currentCommand.value.trim()) {
        executeCommand(currentCommand.value.trim())
      }
      break
    case 'Tab':
      event.preventDefault()
      if (filteredSuggestions.value.length > 0) {
        applySuggestion(filteredSuggestions.value[selectedSuggestion.value])
      }
      break
    case 'ArrowUp':
      event.preventDefault()
      if (showSuggestions.value && selectedSuggestion.value > 0) {
        selectedSuggestion.value--
      }
      break
    case 'ArrowDown':
      event.preventDefault()
      if (showSuggestions.value && selectedSuggestion.value < filteredSuggestions.value.length - 1) {
        selectedSuggestion.value++
      }
      break
    case 'Escape':
      showSuggestions.value = false
      selectedSuggestion.value = 0
      break
  }
}

const handleInput = () => {
  showSuggestions.value = currentCommand.value.length > 0
  selectedSuggestion.value = 0
}

const applySuggestion = (suggestion) => {
  currentCommand.value = suggestion.command
  showSuggestions.value = false
  selectedSuggestion.value = 0
  nextTick(() => {
    commandInput.value?.focus()
  })
}

// Command execution
const executeCommand = async (command) => {
  if (isExecuting.value) return
  
  isExecuting.value = true
  showSuggestions.value = false
  
  // Add command to history with executing state
  const entry = {
    command,
    executing: true,
    loadingText: getLoadingText(command)
  }
  
  commandHistory.value.push(entry)
  currentCommand.value = ''
  
  // Scroll to bottom
  await nextTick()
  scrollToBottom()
  
  // Simulate command execution delay
  const delay = getExecutionDelay(command)
  await new Promise(resolve => setTimeout(resolve, delay))
  
  // Update with results
  entry.executing = false
  entry.output = getCommandOutput(command)
  
  isExecuting.value = false
  
  // Focus input and scroll
  await nextTick()
  scrollToBottom()
  commandInput.value?.focus()
}

const getLoadingText = (command) => {
  const loadingTexts = {
    'usenet deploy --auto': 'Detecting hardware and deploying stack...',
    'usenet storage list': 'Scanning for storage devices...',
    'usenet hardware list': 'Detecting GPU and system capabilities...',
    'usenet services list': 'Checking service health status...',
    'usenet --help': 'Loading help documentation...'
  }
  return loadingTexts[command] || 'Executing command...'
}

const getExecutionDelay = (command) => {
  const delays = {
    'usenet deploy --auto': 3000,
    'usenet storage list': 1500,
    'usenet hardware list': 2000,
    'usenet services list': 1800,
    'usenet --help': 800
  }
  return delays[command] || 1000
}

const scrollToBottom = () => {
  if (terminalBody.value) {
    terminalBody.value.scrollTop = terminalBody.value.scrollHeight
  }
}

// Lifecycle
onMounted(() => {
  nextTick(() => {
    commandInput.value?.focus()
  })
  
  // Add welcome message
  commandHistory.value.push({
    command: '',
    output: [
      { type: 'welcome', content: '🚀 <span class="highlight">Welcome to Usenet Media Stack CLI Simulator</span>' },
      { type: 'info', content: 'Type commands or click Quick Actions below. Press Tab for autocompletion.' },
      { type: 'info', content: 'Try: <span class="cmd">usenet deploy --auto</span> or <span class="cmd">usenet --help</span>' },
      { type: 'step', content: '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━' }
    ]
  })
})
</script>

<style scoped>
.cli-simulator {
  background: linear-gradient(135deg, #1e1e1e 0%, #2d2d2d 100%);
  border-radius: 16px;
  padding: 2rem;
  margin: 2rem 0;
  color: #e0e0e0;
  font-family: 'Fira Code', 'Consolas', 'Monaco', monospace;
}

.cli-simulator h3 {
  text-align: center;
  margin-bottom: 2rem;
  font-size: 2rem;
  color: #61dafb;
  text-shadow: 0 2px 4px rgba(97, 218, 251, 0.3);
}

.terminal-window {
  background: #1e1e1e;
  border-radius: 12px;
  border: 1px solid #404040;
  margin-bottom: 2rem;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
}

.terminal-header {
  background: #2d2d2d;
  padding: 0.75rem 1rem;
  border-radius: 12px 12px 0 0;
  border-bottom: 1px solid #404040;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.window-controls {
  display: flex;
  gap: 0.5rem;
}

.control {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  cursor: pointer;
}

.control.close { background: #ff5f56; }
.control.minimize { background: #ffbd2e; }
.control.maximize { background: #27ca3f; }

.terminal-title {
  color: #888;
  font-size: 0.9rem;
}

.terminal-body {
  padding: 1rem;
  height: 500px;
  overflow-y: auto;
  background: #1e1e1e;
  border-radius: 0 0 12px 12px;
}

.terminal-content {
  font-size: 14px;
  line-height: 1.5;
}

.command-entry {
  margin-bottom: 1rem;
}

.prompt-line {
  display: flex;
  align-items: center;
  margin-bottom: 0.5rem;
}

.prompt {
  color: #27ca3f;
  font-weight: bold;
  margin-right: 0.5rem;
}

.command {
  color: #e0e0e0;
  font-weight: 500;
}

.cursor {
  color: #61dafb;
  margin-left: 0.25rem;
}

.blinking {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

.command-output {
  margin-left: 1rem;
  border-left: 2px solid #404040;
  padding-left: 1rem;
}

.output-line {
  margin-bottom: 0.25rem;
  font-family: 'Fira Code', monospace;
}

.output-line.info { color: #61dafb; }
.output-line.success { color: #27ca3f; }
.output-line.error { color: #ff5f56; }
.output-line.warning { color: #ffbd2e; }
.output-line.step { color: #666; }
.output-line.welcome { color: #ff79c6; }
.output-line.complete { color: #50fa7b; }
.output-line.device { color: #8be9fd; }
.output-line.running { color: #50fa7b; }
.output-line.cpu { color: #f1fa8c; }
.output-line.memory { color: #bd93f9; }
.output-line.gpu { color: #ff79c6; }
.output-line.optimization { color: #ff5555; }
.output-line.benefit { color: #8be9fd; }
.output-line.recommendation { color: #f1fa8c; }
.output-line.section { color: #ff79c6; }
.output-line.command { color: #8be9fd; }
.output-line.pool { color: #50fa7b; }
.output-line.active { color: #50fa7b; }

/* Output styling */
.highlight { color: #ff79c6; font-weight: bold; }
.value { color: #50fa7b; }
.path { color: #8be9fd; }
.fs { color: #f1fa8c; }
.size { color: #bd93f9; }
.cmd { color: #ff5555; background: rgba(255, 85, 85, 0.1); padding: 0.1rem 0.3rem; border-radius: 3px; }
.service { color: #8be9fd; font-weight: bold; }
.port { color: #f1fa8c; }
.status { color: #50fa7b; }
.info { color: #6272a4; }
.url { color: #ff79c6; text-decoration: underline; }
.section-title { color: #ff79c6; font-weight: bold; }

.loading-animation {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #61dafb;
  margin-left: 1rem;
}

.spinner {
  width: 16px;
  height: 16px;
  border: 2px solid #404040;
  border-top: 2px solid #61dafb;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.current-input {
  display: flex;
  align-items: center;
}

.command-input {
  background: transparent;
  border: none;
  outline: none;
  color: #e0e0e0;
  font-family: inherit;
  font-size: inherit;
  flex: 1;
  margin-left: 0.5rem;
}

.command-input::placeholder {
  color: #666;
}

.suggestions-panel {
  background: rgba(45, 45, 45, 0.95);
  border: 1px solid #404040;
  border-radius: 8px;
  margin-bottom: 1rem;
  backdrop-filter: blur(10px);
}

.suggestions-header {
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #404040;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 0.9rem;
}

.hint {
  color: #666;
  font-size: 0.8rem;
}

.suggestions-list {
  max-height: 200px;
  overflow-y: auto;
}

.suggestion-item {
  padding: 0.75rem 1rem;
  cursor: pointer;
  border-bottom: 1px solid #333;
  transition: background 0.2s ease;
}

.suggestion-item:hover,
.suggestion-item.active {
  background: #404040;
}

.suggestion-command {
  color: #61dafb;
  font-weight: bold;
  margin-bottom: 0.25rem;
}

.suggestion-description {
  color: #888;
  font-size: 0.85rem;
}

.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.action-group h5 {
  color: #61dafb;
  margin: 0 0 1rem 0;
  font-size: 1rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.action-btn {
  display: block;
  width: 100%;
  background: rgba(97, 218, 251, 0.1);
  border: 1px solid rgba(97, 218, 251, 0.3);
  color: #61dafb;
  padding: 0.75rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  margin-bottom: 0.5rem;
  transition: all 0.3s ease;
  font-family: inherit;
  font-size: 0.9rem;
}

.action-btn:hover:not(:disabled) {
  background: rgba(97, 218, 251, 0.2);
  transform: translateY(-1px);
}

.action-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.help-panel {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 90%;
  max-width: 600px;
  max-height: 80vh;
  background: rgba(30, 30, 30, 0.95);
  border: 1px solid #404040;
  border-radius: 12px;
  overflow: hidden;
  z-index: 1000;
  backdrop-filter: blur(10px);
}

.help-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem;
  border-bottom: 1px solid #404040;
  background: #2d2d2d;
}

.help-header h4 {
  margin: 0;
  color: #61dafb;
}

.close-btn {
  background: none;
  border: none;
  color: #888;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.close-btn:hover {
  background: #404040;
  color: #e0e0e0;
}

.help-content {
  padding: 1rem;
  max-height: calc(80vh - 80px);
  overflow-y: auto;
}

.help-section {
  margin-bottom: 1.5rem;
}

.help-section h5 {
  color: #ff79c6;
  margin: 0 0 0.75rem 0;
  font-size: 1.1rem;
}

.help-commands {
  font-family: 'Fira Code', monospace;
  font-size: 0.9rem;
  line-height: 1.6;
  color: #e0e0e0;
}

.help-commands code {
  color: #61dafb;
  background: rgba(97, 218, 251, 0.1);
  padding: 0.1rem 0.3rem;
  border-radius: 3px;
}

/* Responsive design */
@media (max-width: 768px) {
  .quick-actions {
    grid-template-columns: 1fr;
  }
  
  .terminal-body {
    height: 300px;
  }
  
  .suggestions-panel {
    position: relative;
  }
  
  .help-panel {
    width: 95%;
  }
}

/* Custom scrollbar */
.terminal-body::-webkit-scrollbar,
.suggestions-list::-webkit-scrollbar,
.help-content::-webkit-scrollbar {
  width: 8px;
}

.terminal-body::-webkit-scrollbar-track,
.suggestions-list::-webkit-scrollbar-track,
.help-content::-webkit-scrollbar-track {
  background: #1e1e1e;
}

.terminal-body::-webkit-scrollbar-thumb,
.suggestions-list::-webkit-scrollbar-thumb,
.help-content::-webkit-scrollbar-thumb {
  background: #404040;
  border-radius: 4px;
}

.terminal-body::-webkit-scrollbar-thumb:hover,
.suggestions-list::-webkit-scrollbar-thumb:hover,
.help-content::-webkit-scrollbar-thumb:hover {
  background: #555;
}
</style>
