<template>
  <div class="interactive-cli-demo">
    <div class="demo-header">
      <div class="demo-title">
        <span class="demo-icon">💻</span>
        <span>Interactive CLI Demo</span>
      </div>
      <div class="demo-controls">
        <button @click="resetDemo" class="control-btn">🔄 Reset</button>
        <button @click="toggleAutoPlay" class="control-btn" :class="{ active: autoPlay }">
          {{ autoPlay ? '⏸️ Pause' : '▶️ Auto' }}
        </button>
      </div>
    </div>
    
    <div class="terminal-container">
      <div class="terminal-header">
        <div class="terminal-controls">
          <span class="control-dot close"></span>
          <span class="control-dot minimize"></span>
          <span class="control-dot maximize"></span>
        </div>
        <div class="terminal-title">joe@usenet-stack:~/usenet$</div>
      </div>
      
      <div class="terminal-body">
        <div class="terminal-content" ref="terminalContent">
          <!-- Command history -->
          <div 
            v-for="(line, index) in terminalHistory" 
            :key="index"
            class="terminal-line"
            :class="line.type"
          >
            <span v-if="line.type === 'command'" class="prompt">❯</span>
            <span class="line-content" v-html="line.content"></span>
          </div>
          
          <!-- Current command being typed -->
          <div v-if="currentCommand" class="terminal-line command">
            <span class="prompt">❯</span>
            <span class="line-content">
              <span class="typed-text">{{ typedText }}</span>
              <span class="cursor" :class="{ blink: showCursor }">_</span>
            </span>
          </div>
        </div>
        
        <!-- Interactive command buttons -->
        <div class="command-suggestions" v-if="showSuggestions">
          <div class="suggestions-header">💡 Try these commands:</div>
          <div class="suggestions-grid">
            <button 
              v-for="cmd in availableCommands" 
              :key="cmd.command"
              @click="executeCommand(cmd)"
              class="suggestion-btn"
              :class="{ disabled: cmd.disabled }"
            >
              <span class="cmd-icon">{{ cmd.icon }}</span>
              <span class="cmd-text">{{ cmd.command }}</span>
              <span class="cmd-desc">{{ cmd.description }}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Progress indicator -->
    <div class="demo-progress" v-if="demoProgress.total > 0">
      <div class="progress-bar">
        <div 
          class="progress-fill" 
          :style="{ width: `${(demoProgress.current / demoProgress.total) * 100}%` }"
        ></div>
      </div>
      <div class="progress-text">
        Step {{ demoProgress.current }} of {{ demoProgress.total }}: {{ demoProgress.step }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'

// Reactive state
const terminalHistory = ref([])
const currentCommand = ref('')
const typedText = ref('')
const showCursor = ref(true)
const showSuggestions = ref(true)
const autoPlay = ref(false)
const terminalContent = ref(null)

const demoProgress = ref({
  current: 0,
  total: 0,
  step: ''
})

// Available commands
const availableCommands = ref([
  {
    command: 'usenet deploy --auto',
    icon: '🚀',
    description: 'Full stack deployment',
    disabled: false
  },
  {
    command: 'usenet storage list',
    icon: '💾',
    description: 'Show available drives',
    disabled: false
  },
  {
    command: 'usenet hardware optimize',
    icon: '⚡',
    description: 'GPU acceleration setup',
    disabled: false
  },
  {
    command: 'usenet services list',
    icon: '📊',
    description: 'Service health check',
    disabled: false
  }
])

// Demo scenarios
const demoScenarios = {
  'usenet deploy --auto': [
    { type: 'output', content: '🔍 <span class="highlight">Scanning system...</span>' },
    { type: 'output', content: '✅ <span class="success">Hardware detected: AMD Ryzen 7 7840HS + Radeon 780M</span>' },
    { type: 'output', content: '✅ <span class="success">GPU acceleration: VAAPI enabled</span>' },
    { type: 'output', content: '✅ <span class="success">Storage discovery: 29 drives found</span>' },
    { type: 'output', content: '🐳 <span class="info">Docker containers starting...</span>' },
    { type: 'output', content: '📺 <span class="success">Sonarr (8989): Running</span>' },
    { type: 'output', content: '🎬 <span class="success">Radarr (7878): Running</span>' },
    { type: 'output', content: '🎭 <span class="success">Jellyfin (8096): Running with GPU acceleration</span>' },
    { type: 'output', content: '🎉 <span class="success">Stack ready at:</span> <span class="link">https://beppesarrstack.net</span>' }
  ],
  
  'usenet storage list': [
    { type: 'output', content: '🗄️  <span class="highlight">DISCOVERED STORAGE DEVICES:</span>' },
    { type: 'output', content: '○ [ 1] /                    <span class="info">ZFS (798G total, 594G available)</span>' },
    { type: 'output', content: '○ [ 2] /home/joe/Dropbox    <span class="info">Cloud Storage (3.1TB available)</span>' },
    { type: 'output', content: '○ [ 3] /media/Movies_4TB    <span class="info">HDD (4TB available, exFAT - portable)</span>' },
    { type: 'output', content: '💡 <span class="success">Hot-swap ready for portable deployment</span>' }
  ],
  
  'usenet hardware optimize': [
    { type: 'output', content: '⚡ <span class="success">AMD GPU Detected! Hardware acceleration unlocks:</span>' },
    { type: 'output', content: '   • Hardware HEVC encoding (10x faster than CPU)' },
    { type: 'output', content: '📊 <span class="info">Performance: 4K HEVC 2 FPS → 67 FPS</span>' },
    { type: 'output', content: '🎯 <span class="success">Optimization complete!</span>' }
  ],
  
  'usenet services list': [
    { type: 'output', content: '📊 <span class="highlight">SERVICE HEALTH CHECK:</span>' },
    { type: 'output', content: '🎬 Jellyfin       <span class="success">●</span> Running  (8096) GPU: Active' },
    { type: 'output', content: '📺 Sonarr         <span class="success">●</span> Running  (8989)' },
    { type: 'output', content: '🎭 Radarr         <span class="success">●</span> Running  (7878)' },
    { type: 'output', content: '✅ <span class="success">All services operational</span>' }
  ]
}

// Methods
const typeCommand = async (command, speed = 50) => {
  currentCommand.value = command
  typedText.value = ''
  
  return new Promise((resolve) => {
    let i = 0
    const timer = setInterval(() => {
      if (i < command.length) {
        typedText.value += command[i]
        i++
      } else {
        clearInterval(timer)
        resolve()
      }
    }, speed)
  })
}

const addToHistory = (content, type = 'command') => {
  terminalHistory.value.push({ content, type })
  nextTick(() => {
    if (terminalContent.value) {
      terminalContent.value.scrollTop = terminalContent.value.scrollHeight
    }
  })
}

const executeCommand = async (cmd) => {
  if (cmd.disabled) return
  
  showSuggestions.value = false
  
  // Type the command
  await typeCommand(cmd.command, 30)
  
  // Add command to history
  addToHistory(`<span class="cmd">${cmd.command}</span>`, 'command')
  currentCommand.value = ''
  typedText.value = ''
  
  // Show output
  const scenario = demoScenarios[cmd.command] || [
    { type: 'output', content: '✅ <span class="success">Command executed successfully!</span>' }
  ]
  
  demoProgress.value = {
    current: 0,
    total: scenario.length,
    step: cmd.description
  }
  
  for (let i = 0; i < scenario.length; i++) {
    await new Promise(resolve => setTimeout(resolve, 400))
    addToHistory(scenario[i].content, scenario[i].type)
    demoProgress.value.current = i + 1
  }
  
  demoProgress.value = { current: 0, total: 0, step: '' }
  
  // Re-enable suggestions
  setTimeout(() => {
    showSuggestions.value = true
  }, 1000)
}

const resetDemo = () => {
  terminalHistory.value = [
    { 
      type: 'output', 
      content: '🚀 <span class="highlight">Usenet Media Stack v2.0</span> - Interactive CLI Demo' 
    },
    { 
      type: 'output', 
      content: '💡 Click any command below to see it in action!' 
    },
    { type: 'output', content: '' }
  ]
  currentCommand.value = ''
  typedText.value = ''
  showSuggestions.value = true
  demoProgress.value = { current: 0, total: 0, step: '' }
}

const toggleAutoPlay = () => {
  autoPlay.value = !autoPlay.value
}

// Lifecycle
onMounted(() => {
  resetDemo()
  setInterval(() => {
    showCursor.value = !showCursor.value
  }, 500)
})
</script>

<style scoped>
.interactive-cli-demo {
  max-width: 900px;
  margin: 2rem auto;
  border-radius: 16px;
  overflow: hidden;
  box-shadow: 0 24px 64px rgba(0, 0, 0, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(16px);
}

.demo-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1rem 1.5rem;
}

.demo-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-weight: 600;
  font-size: 1.1rem;
}

.demo-controls {
  display: flex;
  gap: 0.5rem;
}

.control-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-size: 0.9rem;
}

.control-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: translateY(-2px);
}

.control-btn.active {
  background: rgba(80, 250, 123, 0.2);
  border-color: rgba(80, 250, 123, 0.5);
}

.terminal-container {
  background: #1e1e1e;
  font-family: 'Fira Code', 'Monaco', 'Cascadia Code', monospace;
}

.terminal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  background: #2d2d2d;
  padding: 0.75rem 1rem;
  border-bottom: 1px solid #404040;
}

.terminal-controls {
  display: flex;
  gap: 0.5rem;
}

.control-dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
}

.control-dot.close { background: #ff5f57; }
.control-dot.minimize { background: #ffbd2e; }
.control-dot.maximize { background: #28ca42; }

.terminal-title {
  color: #50fa7b;
  font-size: 0.9rem;
  font-weight: 500;
}

.terminal-body {
  min-height: 400px;
  max-height: 600px;
  display: flex;
  flex-direction: column;
}

.terminal-content {
  flex: 1;
  padding: 1rem;
  overflow-y: auto;
  max-height: 400px;
}

.terminal-line {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  line-height: 1.4;
}

.terminal-line.command .line-content {
  color: #8be9fd;
}

.terminal-line.output .line-content {
  color: #f8f8f2;
}

.prompt {
  color: #50fa7b;
  font-weight: bold;
}

.cursor {
  background: #50fa7b;
  color: #1e1e1e;
  padding: 0 2px;
}

.cursor.blink {
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

/* Terminal styling */
.line-content .cmd { color: #8be9fd; font-weight: 600; }
.line-content .success { color: #50fa7b; }
.line-content .warning { color: #f1fa8c; }
.line-content .info { color: #8be9fd; }
.line-content .highlight { color: #ffb86c; font-weight: 600; }
.line-content .link { color: #bd93f9; text-decoration: underline; }

.command-suggestions {
  background: #282828;
  border-top: 1px solid #404040;
  padding: 1.5rem;
}

.suggestions-header {
  color: #f1fa8c;
  font-size: 0.9rem;
  margin-bottom: 1rem;
  font-weight: 600;
}

.suggestions-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 0.75rem;
}

.suggestion-btn {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
  padding: 1rem;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  text-align: left;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}

.suggestion-btn:hover {
  background: rgba(102, 126, 234, 0.2);
  border-color: rgba(102, 126, 234, 0.5);
  transform: translateY(-2px);
}

.cmd-icon {
  font-size: 1.25rem;
  margin-bottom: 0.25rem;
}

.cmd-text {
  font-family: 'Fira Code', monospace;
  font-size: 0.85rem;
  color: #8be9fd;
  font-weight: 600;
}

.cmd-desc {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.7);
  line-height: 1.3;
}

.demo-progress {
  background: #2d2d2d;
  padding: 1rem 1.5rem;
  border-top: 1px solid #404040;
}

.progress-bar {
  width: 100%;
  height: 6px;
  background: #404040;
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(135deg, #50fa7b 0%, #8be9fd 100%);
  transition: width 0.3s ease;
  border-radius: 3px;
}

.progress-text {
  color: #f8f8f2;
  font-size: 0.85rem;
  font-weight: 500;
}

/* Responsive */
@media (max-width: 768px) {
  .interactive-cli-demo {
    margin: 1rem;
    border-radius: 12px;
  }
  
  .suggestions-grid {
    grid-template-columns: 1fr;
  }
  
  .demo-header {
    flex-direction: column;
    gap: 1rem;
    text-align: center;
  }
}
</style>