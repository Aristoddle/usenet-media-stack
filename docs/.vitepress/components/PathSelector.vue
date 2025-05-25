<template>
  <div class="path-selector-container">
    <!-- Initial Path Selection -->
    <div v-if="!selectedPath" class="path-selection">
      <div class="selector-header">
        <h2>👋 Choose Your Journey</h2>
        <p>Let's find the best path for your experience level and goals</p>
      </div>
      
      <div class="path-cards">
        <div 
          class="path-card beginner"
          @click="selectPath('beginner')"
        >
          <div class="card-icon">🚀</div>
          <h3>New to Media Automation</h3>
          <p>Visual guide with explanations</p>
          <ul class="path-features">
            <li>Step-by-step walkthrough</li>
            <li>What each service does</li>
            <li>Safe default settings</li>
          </ul>
          <div class="path-cta">Get Started Simply</div>
        </div>
        
        <div 
          class="path-card intermediate"
          @click="selectPath('intermediate')"
        >
          <div class="card-icon">⚡</div>
          <h3>Some Docker Experience</h3>
          <p>Balanced technical details</p>
          <ul class="path-features">
            <li>Quick setup commands</li>
            <li>Configuration options</li>
            <li>Performance tips</li>
          </ul>
          <div class="path-cta">Deploy Efficiently</div>
        </div>
        
        <div 
          class="path-card advanced"
          @click="selectPath('advanced')"
        >
          <div class="card-icon">🔧</div>
          <h3>Infrastructure Expert</h3>
          <p>Full technical depth</p>
          <ul class="path-features">
            <li>Architecture details</li>
            <li>CLI reference</li>
            <li>Advanced configuration</li>
          </ul>
          <div class="path-cta">Dive Deep</div>
        </div>
      </div>
      
      <div class="skip-selector">
        <button @click="selectPath('all')" class="skip-btn">
          Show me everything 📋
        </button>
      </div>
    </div>
    
    <!-- Selected Path Content -->
    <div v-else class="selected-path-content">
      <div class="path-header">
        <button @click="resetPath" class="back-btn">← Choose Different Path</button>
        <h3>{{ getPathTitle() }}</h3>
      </div>
      
      <!-- Beginner Path -->
      <div v-if="selectedPath === 'beginner'" class="beginner-content">
        <div class="simple-explainer">
          <h4>🎬 What This Actually Does</h4>
          <p>Think of this as your personal Netflix that automatically finds and downloads the shows/movies you want. Plus it works on any device, anywhere.</p>
          
          <div class="visual-flow">
            <div class="flow-step">
              <div class="step-icon">📱</div>
              <div class="step-text">
                <strong>1. Request</strong><br>
                "I want Season 3 of The Office"
              </div>
            </div>
            <div class="flow-arrow">→</div>
            <div class="flow-step">
              <div class="step-icon">🤖</div>
              <div class="step-text">
                <strong>2. Automation</strong><br>
                Finds and downloads automatically
              </div>
            </div>
            <div class="flow-arrow">→</div>
            <div class="flow-step">
              <div class="step-icon">📺</div>
              <div class="step-text">
                <strong>3. Watch</strong><br>
                Stream on any device
              </div>
            </div>
          </div>
          
          <div class="beginner-cta">
            <a href="/getting-started/" class="primary-btn">Start Setup Guide</a>
            <a href="mailto:j3lanzone@gmail.com?subject=Help%20Getting%20Started" class="secondary-btn">Get Personal Help</a>
          </div>
        </div>
      </div>
      
      <!-- Intermediate Path -->
      <div v-if="selectedPath === 'intermediate'" class="intermediate-content">
        <div class="quick-deploy">
          <h4>⚡ Quick Deployment</h4>
          <div class="code-block">
            <pre><code># One command setup
git clone https://github.com/Aristoddle/usenet-media-stack.git
cd usenet-media-stack
./usenet deploy --auto</code></pre>
          </div>
          
          <div class="key-features">
            <div class="feature-grid">
              <div class="feature-item">
                <span class="feature-icon">🗄️</span>
                <strong>Smart Storage</strong>
                <p>Add/remove drives without breaking anything</p>
              </div>
              <div class="feature-item">
                <span class="feature-icon">⚡</span>
                <strong>GPU Acceleration</strong>
                <p>60+ FPS 4K transcoding vs 2 FPS CPU-only</p>
              </div>
              <div class="feature-item">
                <span class="feature-icon">🌐</span>
                <strong>Remote Access</strong>
                <p>Secure tunnels, no port forwarding needed</p>
              </div>
            </div>
          </div>
          
          <div class="intermediate-cta">
            <a href="/getting-started/installation" class="primary-btn">Installation Guide</a>
            <a href="/architecture/" class="secondary-btn">See Architecture</a>
          </div>
        </div>
      </div>
      
      <!-- Advanced Path -->
      <div v-if="selectedPath === 'advanced'" class="advanced-content">
        <div class="technical-overview">
          <h4>🔧 Technical Architecture</h4>
          
          <div class="tech-grid">
            <div class="tech-section">
              <h5>Service Stack</h5>
              <ul class="service-list">
                <li>19 integrated services</li>
                <li>Docker Swarm ready</li>
                <li>Hot-swappable JBOD</li>
                <li>GPU acceleration</li>
              </ul>
            </div>
            <div class="tech-section">
              <h5>Performance</h5>
              <ul class="perf-list">
                <li>4K HEVC: 2 FPS → 67 FPS</li>
                <li>Power: 185W → 48W</li>
                <li>29 drives detected</li>
                <li>Cloud integration</li>
              </ul>
            </div>
          </div>
          
          <InteractiveCLIDemo />
          
          <div class="advanced-cta">
            <a href="/cli/" class="primary-btn">CLI Reference</a>
            <a href="/architecture/" class="secondary-btn">Full Architecture</a>
            <a href="https://github.com/Aristoddle/usenet-media-stack" class="tertiary-btn">View Source</a>
          </div>
        </div>
      </div>
      
      <!-- All Content Path -->
      <div v-if="selectedPath === 'all'" class="all-content">
        <p class="all-notice">Showing full content below. Use the navigation to jump to specific sections.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import InteractiveCLIDemo from './InteractiveCLIDemo.vue'

const selectedPath = ref(null)

const selectPath = (path) => {
  selectedPath.value = path
  
  // Track analytics if available
  if (typeof gtag !== 'undefined') {
    gtag('event', 'path_selected', {
      path_type: path
    })
  }
  
  // Scroll to content
  setTimeout(() => {
    document.querySelector('.selected-path-content')?.scrollIntoView({ 
      behavior: 'smooth' 
    })
  }, 100)
}

const resetPath = () => {
  selectedPath.value = null
  setTimeout(() => {
    document.querySelector('.path-selection')?.scrollIntoView({ 
      behavior: 'smooth' 
    })
  }, 100)
}

const getPathTitle = () => {
  const titles = {
    beginner: '🚀 Simple Setup Path',
    intermediate: '⚡ Efficient Deployment',
    advanced: '🔧 Technical Deep Dive',
    all: '📋 Complete Documentation'
  }
  return titles[selectedPath.value] || ''
}
</script>

<style scoped>
.path-selector-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1rem;
}

/* Path Selection */
.path-selection {
  text-align: center;
}

.selector-header h2 {
  font-size: 2.5rem;
  margin-bottom: 1rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.selector-header p {
  font-size: 1.25rem;
  color: var(--vp-c-text-2);
  margin-bottom: 3rem;
}

.path-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 2rem;
  margin-bottom: 3rem;
}

.path-card {
  background: rgba(255, 255, 255, 0.05);
  border: 2px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  padding: 2rem;
  cursor: pointer;
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
  backdrop-filter: blur(10px);
}

.path-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
  transition: left 0.5s;
}

.path-card:hover::before {
  left: 100%;
}

.path-card:hover {
  transform: translateY(-8px) scale(1.02);
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.2);
}

.path-card.beginner:hover {
  border-color: rgba(80, 250, 123, 0.5);
  background: rgba(80, 250, 123, 0.05);
}

.path-card.intermediate:hover {
  border-color: rgba(139, 233, 253, 0.5);
  background: rgba(139, 233, 253, 0.05);
}

.path-card.advanced:hover {
  border-color: rgba(255, 184, 108, 0.5);
  background: rgba(255, 184, 108, 0.05);
}

.card-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.path-card h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: var(--vp-c-text-1);
}

.path-card p {
  color: var(--vp-c-text-2);
  margin-bottom: 1.5rem;
}

.path-features {
  list-style: none;
  padding: 0;
  margin-bottom: 2rem;
}

.path-features li {
  padding: 0.5rem 0;
  color: var(--vp-c-text-2);
  position: relative;
  padding-left: 1.5rem;
}

.path-features li::before {
  content: '✓';
  position: absolute;
  left: 0;
  color: #50fa7b;
  font-weight: bold;
}

.path-cta {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  padding: 1rem 2rem;
  border-radius: 10px;
  font-weight: 600;
  transition: all 0.3s ease;
}

.path-card:hover .path-cta {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(102, 126, 234, 0.3);
}

.skip-selector {
  margin-top: 2rem;
}

.skip-btn {
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: var(--vp-c-text-2);
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.skip-btn:hover {
  background: rgba(255, 255, 255, 0.15);
  transform: translateY(-2px);
}

/* Selected Path Content */
.selected-path-content {
  animation: fadeInUp 0.6s ease-out;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.path-header {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.back-btn {
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: var(--vp-c-text-2);
  padding: 0.5rem 1rem;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.back-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

/* Beginner Content */
.simple-explainer h4 {
  font-size: 1.8rem;
  margin-bottom: 1rem;
  color: var(--vp-c-text-1);
}

.simple-explainer p {
  font-size: 1.2rem;
  line-height: 1.6;
  color: var(--vp-c-text-2);
  margin-bottom: 2rem;
}

.visual-flow {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
  margin: 2rem 0;
  flex-wrap: wrap;
}

.flow-step {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  padding: 1.5rem;
  text-align: center;
  min-width: 150px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.step-icon {
  font-size: 2rem;
  margin-bottom: 0.5rem;
}

.step-text {
  font-size: 0.9rem;
  line-height: 1.4;
}

.flow-arrow {
  font-size: 1.5rem;
  color: var(--vp-c-text-2);
}

/* Intermediate Content */
.code-block {
  background: #1e1e1e;
  border-radius: 8px;
  padding: 1.5rem;
  margin: 1rem 0;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.code-block pre {
  color: #f8f8f2;
  font-family: 'Fira Code', monospace;
  margin: 0;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.5rem;
  margin: 2rem 0;
}

.feature-item {
  background: rgba(255, 255, 255, 0.05);
  padding: 1.5rem;
  border-radius: 10px;
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.feature-icon {
  font-size: 1.5rem;
  margin-right: 0.5rem;
}

/* Advanced Content */
.tech-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  margin: 2rem 0;
}

.tech-section h5 {
  color: var(--vp-c-text-1);
  margin-bottom: 1rem;
}

.service-list, .perf-list {
  list-style: none;
  padding: 0;
}

.service-list li, .perf-list li {
  padding: 0.25rem 0;
  color: var(--vp-c-text-2);
}

/* CTA Buttons */
.beginner-cta, .intermediate-cta, .advanced-cta {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 2rem;
  flex-wrap: wrap;
}

.primary-btn, .secondary-btn, .tertiary-btn {
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  text-decoration: none;
  font-weight: 600;
  transition: all 0.3s ease;
  display: inline-block;
}

.primary-btn {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
}

.secondary-btn {
  background: rgba(255, 255, 255, 0.1);
  color: var(--vp-c-text-1);
  border: 1px solid rgba(255, 255, 255, 0.2);
}

.tertiary-btn {
  background: transparent;
  color: var(--vp-c-text-2);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.primary-btn:hover, .secondary-btn:hover, .tertiary-btn:hover {
  transform: translateY(-2px);
}

.all-notice {
  background: rgba(255, 184, 108, 0.1);
  border: 1px solid rgba(255, 184, 108, 0.3);
  padding: 1rem;
  border-radius: 8px;
  color: var(--vp-c-text-2);
  text-align: center;
}

/* Responsive */
@media (max-width: 768px) {
  .path-cards {
    grid-template-columns: 1fr;
  }
  
  .visual-flow {
    flex-direction: column;
  }
  
  .flow-arrow {
    transform: rotate(90deg);
  }
  
  .feature-grid {
    grid-template-columns: 1fr;
  }
  
  .beginner-cta, .intermediate-cta, .advanced-cta {
    flex-direction: column;
    align-items: center;
  }
  
  .path-header {
    flex-direction: column;
    align-items: flex-start;
  }
}
</style>