<template>
  <div class="animated-hero">
    <!-- Animated Background -->
    <div class="hero-background">
      <div class="floating-particles">
        <div 
          v-for="particle in particles"
          :key="particle.id"
          class="particle"
          :style="particle.style"
        ></div>
      </div>
      
      <div class="gradient-orbs">
        <div class="orb orb-1"></div>
        <div class="orb orb-2"></div>
        <div class="orb orb-3"></div>
      </div>
    </div>
    
    <!-- Hero Content -->
    <div class="hero-content">
      <div class="hero-text">
        <h1 class="hero-title">
          <span class="title-line" :class="{ animate: titleVisible }">
            <span class="text-gradient">Usenet</span> Media Stack
          </span>
          <span class="title-line" :class="{ animate: titleVisible }">
            Professional-Grade 
            <span class="text-highlight">Hot-Swappable</span>
          </span>
          <span class="title-line" :class="{ animate: titleVisible }">
            JBOD Media Automation
          </span>
        </h1>
        
        <p class="hero-subtitle" :class="{ animate: subtitleVisible }">
          From camping trips to data centers - the only media stack that 
          <strong>just fucking works</strong> everywhere.
        </p>
        
        <div class="hero-stats" :class="{ animate: statsVisible }">
          <div class="stat-item">
            <div class="stat-number" ref="servicesCounter">0</div>
            <div class="stat-label">Integrated Services</div>
          </div>
          <div class="stat-item">
            <div class="stat-number" ref="performanceCounter">0</div>
            <div class="stat-label">% Performance Gain</div>
          </div>
          <div class="stat-item">
            <div class="stat-number" ref="drivesCounter">0</div>
            <div class="stat-label">Drives Detected</div>
          </div>
        </div>
        
        <div class="hero-actions" :class="{ animate: actionsVisible }">
          <button @click="startQuickDeploy" class="hero-btn primary">
            <span class="btn-icon">🚀</span>
            <span class="btn-text">Quick Deploy</span>
            <span class="btn-subtitle">5-minute setup</span>
          </button>
          
          <button @click="exploreArchitecture" class="hero-btn secondary">
            <span class="btn-icon">🏗️</span>
            <span class="btn-text">Explore Architecture</span>
            <span class="btn-subtitle">Interactive tour</span>
          </button>
          
          <button @click="accessResources" class="hero-btn tertiary">
            <span class="btn-icon">📚</span>
            <span class="btn-text">Free Media Hub</span>
            <span class="btn-subtitle">Millions of resources</span>
          </button>
        </div>
        
        <!-- Architecture Preview -->
        <div class="architecture-preview" :class="{ animate: architectureVisible }">
          <div class="preview-container">
            <img 
              src="/images/generated/hero-architecture.svg" 
              alt="Usenet Media Stack Architecture" 
              class="architecture-diagram"
              @click="exploreArchitecture"
            />
            <div class="preview-overlay">
              <span class="overlay-text">Click to explore interactive architecture</span>
            </div>
          </div>
        </div>
        
        <div class="hero-features" :class="{ animate: featuresVisible }">
          <div class="feature-item">
            <div class="feature-icon">⚡</div>
            <div class="feature-text">
              <strong>4K Transcoding</strong><br>
              2 FPS → 60+ FPS
            </div>
          </div>
          <div class="feature-item">
            <div class="feature-icon">🗄️</div>
            <div class="feature-text">
              <strong>Hot-Swap Storage</strong><br>
              Any drive, anywhere
            </div>
          </div>
          <div class="feature-item">
            <div class="feature-icon">🌐</div>
            <div class="feature-text">
              <strong>Zero Config SSL</strong><br>
              Cloudflare Tunnel
            </div>
          </div>
          <div class="feature-item">
            <div class="feature-icon">🎯</div>
            <div class="feature-text">
              <strong>Auto Optimization</strong><br>
              Any GPU, any platform
            </div>
          </div>
        </div>
      </div>
      
      <!-- Live Demo Preview -->
      <div class="hero-demo" :class="{ animate: demoVisible }">
        <div class="demo-container">
          <div class="demo-header">
            <div class="demo-title">
              <span class="status-dot running"></span>
              Live System Status
            </div>
            <div class="demo-timestamp">{{ currentTime }}</div>
          </div>
          
          <div class="demo-content">
            <div class="service-grid">
              <div 
                v-for="service in demoServices"
                :key="service.id"
                class="service-item"
                :class="service.status"
                @click="highlightService(service)"
              >
                <div class="service-icon">{{ service.icon }}</div>
                <div class="service-name">{{ service.name }}</div>
                <div class="service-metrics">
                  <div class="metric">{{ service.metric }}</div>
                </div>
              </div>
            </div>
            
            <div class="demo-terminal">
              <div class="terminal-header">
                <span>joe@usenet-stack:~/usenet$</span>
              </div>
              <div class="terminal-content">
                <div class="terminal-line" v-for="line in terminalLines" :key="line.id">
                  <span class="prompt">❯</span>
                  <span class="command" v-html="line.content"></span>
                </div>
                <div class="terminal-cursor"></div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Scroll Indicator -->
    <div class="scroll-indicator" :class="{ animate: scrollVisible }">
      <div class="scroll-text">Scroll to explore</div>
      <div class="scroll-arrow">↓</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'

// Reactive state
const titleVisible = ref(false)
const subtitleVisible = ref(false)
const statsVisible = ref(false)
const actionsVisible = ref(false)
const architectureVisible = ref(false)
const featuresVisible = ref(false)
const demoVisible = ref(false)
const scrollVisible = ref(false)
const currentTime = ref('')

// Counter refs
const servicesCounter = ref(null)
const performanceCounter = ref(null)
const drivesCounter = ref(null)

// Animation sequences
const animationSequence = [
  { target: titleVisible, delay: 200 },
  { target: subtitleVisible, delay: 400 },
  { target: statsVisible, delay: 600 },
  { target: actionsVisible, delay: 800 },
  { target: architectureVisible, delay: 1000 },
  { target: featuresVisible, delay: 1200 },
  { target: demoVisible, delay: 1400 },
  { target: scrollVisible, delay: 1600 }
]

// Particles for background animation
const particles = ref([])

// Demo data
const demoServices = ref([
  { id: 'plex', name: 'Plex', icon: '🎬', status: 'running', metric: '4K/60fps' },
  { id: 'sonarr', name: 'Sonarr', icon: '📺', status: 'running', metric: '1.2K shows' },
  { id: 'radarr', name: 'Radarr', icon: '🎭', status: 'running', metric: '3.4K movies' },
  { id: 'tdarr', name: 'Tdarr', icon: '⚡', status: 'processing', metric: 'GPU active' },
  { id: 'prowlarr', name: 'Prowlarr', icon: '🔍', status: 'running', metric: '45 indexers' },
  { id: 'overseerr', name: 'Overseerr', icon: '📋', status: 'running', metric: '12 requests' }
])

const terminalLines = ref([
  { id: 1, content: '<span class="cmd">usenet deploy --auto</span>' },
  { id: 2, content: '✅ <span class="success">Hardware detected: AMD Ryzen 7 + Radeon 780M</span>' },
  { id: 3, content: '✅ <span class="success">GPU acceleration: VAAPI enabled</span>' },
  { id: 4, content: '✅ <span class="success">Storage discovery: 29 drives found</span>' },
  { id: 5, content: '🚀 <span class="info">Deploying 19 services with optimization...</span>' }
])

// Methods
const generateParticles = () => {
  particles.value = Array.from({ length: 50 }, (_, i) => ({
    id: i,
    style: {
      left: `${Math.random() * 100}%`,
      top: `${Math.random() * 100}%`,
      animationDelay: `${Math.random() * 20}s`,
      animationDuration: `${15 + Math.random() * 10}s`
    }
  }))
}

const startAnimationSequence = () => {
  animationSequence.forEach(({ target, delay }) => {
    setTimeout(() => {
      target.value = true
    }, delay)
  })
  
  // Start counters when stats become visible
  setTimeout(() => {
    animateCounter(servicesCounter.value, 19, 2000)
    animateCounter(performanceCounter.value, 1200, 2500)
    animateCounter(drivesCounter.value, 29, 1500)
  }, 600)
}

const animateCounter = (element, target, duration) => {
  if (!element) return
  
  const start = 0
  const increment = target / (duration / 16)
  let current = start
  
  const timer = setInterval(() => {
    current += increment
    if (current >= target) {
      current = target
      clearInterval(timer)
    }
    element.textContent = Math.floor(current)
  }, 16)
}

const updateTime = () => {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('en-US', {
    hour12: false,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  })
}

const highlightService = (service) => {
  // Add visual feedback for service interaction
  console.log('Service highlighted:', service.name)
}

// Navigation methods
const startQuickDeploy = () => {
  // Scroll to CLI simulator or open deployment guide
  const cliSection = document.querySelector('.cli-simulator')
  if (cliSection) {
    cliSection.scrollIntoView({ behavior: 'smooth' })
  } else {
    window.location.href = '/getting-started/'
  }
}

const exploreArchitecture = () => {
  window.location.href = '/architecture/'
}

const accessResources = () => {
  window.location.href = '/free-media'
}

// Lifecycle
onMounted(() => {
  generateParticles()
  updateTime()
  
  // Start animation sequence after a brief delay
  setTimeout(startAnimationSequence, 300)
  
  // Update time every second
  const timeInterval = setInterval(updateTime, 1000)
  
  // Cleanup
  onUnmounted(() => {
    clearInterval(timeInterval)
  })
})
</script>

<style scoped>
.animated-hero {
  position: relative;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: linear-gradient(135deg, #1e1e2e 0%, #2d2d4a 50%, #3d3d5a 100%);
}

.hero-background {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 1;
}

.floating-particles {
  position: absolute;
  width: 100%;
  height: 100%;
}

.particle {
  position: absolute;
  width: 4px;
  height: 4px;
  background: radial-gradient(circle, rgba(124, 58, 237, 0.8) 0%, transparent 70%);
  border-radius: 50%;
  animation: float linear infinite;
}

@keyframes float {
  0% {
    transform: translateY(100vh) scale(0);
    opacity: 0;
  }
  10% {
    opacity: 1;
  }
  90% {
    opacity: 1;
  }
  100% {
    transform: translateY(-100vh) scale(1);
    opacity: 0;
  }
}

.gradient-orbs {
  position: absolute;
  width: 100%;
  height: 100%;
}

.orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  animation: orb-float 20s ease-in-out infinite;
}

.orb-1 {
  width: 400px;
  height: 400px;
  background: radial-gradient(circle, rgba(139, 69, 19, 0.3) 0%, transparent 70%);
  top: 20%;
  left: 10%;
  animation-delay: 0s;
}

.orb-2 {
  width: 300px;
  height: 300px;
  background: radial-gradient(circle, rgba(75, 0, 130, 0.3) 0%, transparent 70%);
  top: 60%;
  right: 20%;
  animation-delay: 7s;
}

.orb-3 {
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, rgba(25, 25, 112, 0.2) 0%, transparent 70%);
  bottom: 10%;
  left: 50%;
  animation-delay: 14s;
}

@keyframes orb-float {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33% { transform: translate(30px, -30px) scale(1.1); }
  66% { transform: translate(-20px, 20px) scale(0.9); }
}

.hero-content {
  position: relative;
  z-index: 2;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 4rem;
  max-width: 1400px;
  width: 100%;
  padding: 0 2rem;
  align-items: center;
}

.hero-text {
  color: white;
}

.hero-title {
  font-size: clamp(2.5rem, 5vw, 4rem);
  font-weight: 800;
  margin: 0 0 1.5rem 0;
  line-height: 1.1;
}

.title-line {
  display: block;
  opacity: 0;
  transform: translateY(50px);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.title-line.animate {
  opacity: 1;
  transform: translateY(0);
}

.title-line:nth-child(2) { transition-delay: 0.1s; }
.title-line:nth-child(3) { transition-delay: 0.2s; }

.text-gradient {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.text-highlight {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-subtitle {
  font-size: 1.3rem;
  line-height: 1.6;
  margin: 0 0 2.5rem 0;
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  color: rgba(255, 255, 255, 0.9);
}

.hero-subtitle.animate {
  opacity: 1;
  transform: translateY(0);
}

.hero-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2rem;
  margin: 0 0 3rem 0;
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.hero-stats.animate {
  opacity: 1;
  transform: translateY(0);
}

.stat-item {
  text-align: center;
  padding: 1.5rem;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
}

.stat-number {
  font-size: 2.5rem;
  font-weight: 800;
  background: linear-gradient(135deg, #50fa7b 0%, #8be9fd 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: 0.5rem;
}

.stat-label {
  font-size: 0.9rem;
  opacity: 0.8;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.hero-actions {
  display: flex;
  gap: 1rem;
  margin: 0 0 3rem 0;
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
  flex-wrap: wrap;
}

.hero-actions.animate {
  opacity: 1;
  transform: translateY(0);
}

.hero-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
  padding: 1rem 1.5rem;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  min-width: 140px;
  backdrop-filter: blur(10px);
}

.hero-btn.primary {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-color: transparent;
  box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
}

.hero-btn.secondary {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
  border-color: transparent;
  box-shadow: 0 8px 32px rgba(240, 147, 251, 0.3);
}

.hero-btn.tertiary {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
  border-color: transparent;
  box-shadow: 0 8px 32px rgba(79, 172, 254, 0.3);
}

.hero-btn:hover {
  transform: translateY(-4px);
  box-shadow: 0 12px 40px rgba(102, 126, 234, 0.4);
}

.btn-icon {
  font-size: 1.5rem;
}

.btn-text {
  font-weight: 600;
  font-size: 0.95rem;
}

.btn-subtitle {
  font-size: 0.75rem;
  opacity: 0.8;
}

/* Architecture Preview Styles */
.architecture-preview {
  margin-top: 2rem;
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.8s ease;
}

.architecture-preview.animate {
  opacity: 1;
  transform: translateY(0);
}

.preview-container {
  position: relative;
  border-radius: 16px;
  overflow: hidden;
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  cursor: pointer;
  transition: all 0.3s ease;
}

.preview-container:hover {
  transform: translateY(-8px);
  box-shadow: 0 20px 60px rgba(102, 126, 234, 0.3);
  border-color: rgba(102, 126, 234, 0.4);
}

.architecture-diagram {
  width: 100%;
  height: auto;
  max-height: 400px;
  object-fit: contain;
  transition: transform 0.3s ease;
}

.preview-container:hover .architecture-diagram {
  transform: scale(1.02);
}

.preview-overlay {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  background: linear-gradient(transparent, rgba(0, 0, 0, 0.8));
  padding: 1.5rem;
  transform: translateY(100%);
  transition: transform 0.3s ease;
}

.preview-container:hover .preview-overlay {
  transform: translateY(0);
}

.overlay-text {
  color: white;
  font-size: 0.9rem;
  font-weight: 500;
  text-align: center;
  display: block;
}

.hero-features {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 1.5rem;
  opacity: 0;
  transform: translateY(30px);
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.hero-features.animate {
  opacity: 1;
  transform: translateY(0);
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.feature-icon {
  font-size: 1.5rem;
}

.feature-text {
  font-size: 0.9rem;
  line-height: 1.4;
}

.hero-demo {
  opacity: 0;
  transform: translateX(50px);
  transition: all 1s cubic-bezier(0.4, 0, 0.2, 1);
}

.hero-demo.animate {
  opacity: 1;
  transform: translateX(0);
}

.demo-container {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  overflow: hidden;
  backdrop-filter: blur(20px);
}

.demo-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1rem 1.5rem;
  background: rgba(255, 255, 255, 0.05);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  color: white;
}

.demo-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-weight: 600;
}

.status-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.status-dot.running {
  background: #50fa7b;
  animation: pulse-green 2s infinite;
}

@keyframes pulse-green {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}

.demo-timestamp {
  font-family: 'Fira Code', monospace;
  font-size: 0.9rem;
  opacity: 0.8;
}

.demo-content {
  padding: 1.5rem;
}

.service-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.service-item {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 1rem;
  text-align: center;
  cursor: pointer;
  transition: all 0.3s ease;
  color: white;
}

.service-item:hover {
  background: rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

.service-item.running {
  border-color: #50fa7b;
}

.service-item.processing {
  border-color: #f1fa8c;
  animation: pulse-processing 2s infinite;
}

@keyframes pulse-processing {
  0%, 100% { border-color: #f1fa8c; }
  50% { border-color: #ffb86c; }
}

.service-icon {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
}

.service-name {
  font-size: 0.85rem;
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.service-metrics .metric {
  font-size: 0.75rem;
  opacity: 0.8;
}

.demo-terminal {
  background: #1e1e1e;
  border-radius: 8px;
  overflow: hidden;
  font-family: 'Fira Code', monospace;
}

.terminal-header {
  background: #2d2d2d;
  padding: 0.75rem 1rem;
  color: #50fa7b;
  font-size: 0.85rem;
}

.terminal-content {
  padding: 1rem;
  min-height: 120px;
}

.terminal-line {
  display: flex;
  gap: 0.5rem;
  margin-bottom: 0.5rem;
  font-size: 0.8rem;
  color: #e0e0e0;
}

.prompt {
  color: #50fa7b;
}

.command .cmd {
  color: #8be9fd;
}

.command .success {
  color: #50fa7b;
}

.command .info {
  color: #f1fa8c;
}

.terminal-cursor {
  width: 8px;
  height: 16px;
  background: #50fa7b;
  animation: blink 1s infinite;
}

@keyframes blink {
  0%, 50% { opacity: 1; }
  51%, 100% { opacity: 0; }
}

.scroll-indicator {
  position: absolute;
  bottom: 2rem;
  left: 50%;
  transform: translateX(-50%);
  text-align: center;
  color: rgba(255, 255, 255, 0.6);
  opacity: 0;
  transition: all 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.scroll-indicator.animate {
  opacity: 1;
}

.scroll-text {
  font-size: 0.9rem;
  margin-bottom: 0.5rem;
}

.scroll-arrow {
  font-size: 1.5rem;
  animation: bounce 2s infinite;
}

@keyframes bounce {
  0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
  40% { transform: translateY(-10px); }
  60% { transform: translateY(-5px); }
}

/* Responsive design */
@media (max-width: 1024px) {
  .hero-content {
    grid-template-columns: 1fr;
    gap: 3rem;
    text-align: center;
  }
  
  .hero-stats {
    grid-template-columns: repeat(3, 1fr);
  }
  
  .service-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .hero-title {
    font-size: 2.5rem;
  }
  
  .hero-subtitle {
    font-size: 1.1rem;
  }
  
  .hero-stats {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
  
  .hero-actions {
    flex-direction: column;
    align-items: center;
  }
  
  .hero-btn {
    width: 100%;
    max-width: 250px;
  }
  
  .hero-features {
    grid-template-columns: 1fr;
  }
  
  .service-grid {
    grid-template-columns: 1fr;
  }
}
</style>
