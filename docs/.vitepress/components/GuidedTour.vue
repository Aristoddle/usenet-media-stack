<template>
  <div class="guided-tour" v-if="isActive">
    <!-- Tour Overlay -->
    <div class="tour-overlay" @click="handleOverlayClick"></div>
    
    <!-- Spotlight Circle -->
    <div 
      class="spotlight"
      :style="spotlightStyle"
    ></div>
    
    <!-- Tour Step Card -->
    <div 
      class="tour-card"
      :style="cardStyle"
      :class="{ 'tour-card-enter': cardVisible }"
    >
      <div class="tour-header">
        <div class="tour-progress">
          <div class="progress-bar">
            <div 
              class="progress-fill"
              :style="{ width: `${(currentStep + 1) / totalSteps * 100}%` }"
            ></div>
          </div>
          <span class="step-counter">{{ currentStep + 1 }} / {{ totalSteps }}</span>
        </div>
        <button @click="closeTour" class="tour-close">×</button>
      </div>
      
      <div class="tour-content">
        <div class="tour-icon">{{ currentTourStep.icon }}</div>
        <h3>{{ currentTourStep.title }}</h3>
        <p>{{ currentTourStep.description }}</p>
        
        <!-- Interactive Elements -->
        <div v-if="currentTourStep.interactive" class="tour-interactive">
          <component 
            :is="currentTourStep.interactive.component"
            v-bind="currentTourStep.interactive.props"
            @action="handleInteractiveAction"
          />
        </div>
        
        <!-- Code Example -->
        <div v-if="currentTourStep.code" class="tour-code">
          <pre><code>{{ currentTourStep.code }}</code></pre>
        </div>
      </div>
      
      <div class="tour-actions">
        <button 
          v-if="currentStep > 0" 
          @click="previousStep"
          class="tour-btn secondary"
        >
          ← Previous
        </button>
        
        <div class="tour-navigation-dots">
          <div 
            v-for="(step, index) in tourSteps"
            :key="index"
            class="nav-dot"
            :class="{ active: index === currentStep, completed: index < currentStep }"
            @click="goToStep(index)"
          ></div>
        </div>
        
        <button 
          v-if="currentStep < totalSteps - 1"
          @click="nextStep"
          class="tour-btn primary"
        >
          {{ currentTourStep.nextLabel || 'Next' }} →
        </button>
        
        <button 
          v-else
          @click="completeTour"
          class="tour-btn success"
        >
          🚀 Start Exploring!
        </button>
      </div>
    </div>
    
    <!-- Floating Hints -->
    <div 
      v-for="hint in currentTourStep.hints || []"
      :key="hint.id"
      class="floating-hint"
      :style="hint.style"
    >
      <div class="hint-content">
        {{ hint.text }}
      </div>
      <div class="hint-arrow" :class="hint.direction"></div>
    </div>
  </div>
  
  <!-- Tour Trigger Button -->
  <button 
    v-if="!isActive && showTrigger"
    @click="startTour"
    class="tour-trigger"
    :class="{ pulse: shouldPulse }"
  >
    <span class="trigger-icon">🎯</span>
    <span class="trigger-text">Take the Tour</span>
  </button>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue'

// Props
const props = defineProps({
  autoStart: {
    type: Boolean,
    default: false
  },
  tourType: {
    type: String,
    default: 'architecture' // 'architecture', 'performance', 'cli', 'overview'
  }
})

// Reactive state
const isActive = ref(false)
const currentStep = ref(0)
const cardVisible = ref(false)
const showTrigger = ref(true)
const shouldPulse = ref(true)
const spotlightElement = ref(null)

// Tour definitions
const tourDefinitions = {
  architecture: [
    {
      id: 'welcome',
      icon: '🏗️',
      title: 'Welcome to the Interactive Architecture',
      description: 'This isn\'t just documentation - it\'s a live, interactive exploration of a production-grade media automation stack. Click and explore everything!',
      target: '.architecture-diagram',
      position: 'center',
      nextLabel: 'Show me the magic'
    },
    {
      id: 'system-overview',
      icon: '🎛️',
      title: 'Interactive System Diagram',
      description: 'Click on any layer or service to see detailed information. Toggle the controls to show data flow and connections between services.',
      target: '.architecture-svg',
      position: 'right',
      hints: [
        {
          id: 'controls',
          text: 'Try these controls!',
          style: { top: '20px', right: '20px' },
          direction: 'down'
        }
      ]
    },
    {
      id: 'performance-metrics',
      icon: '⚡',
      title: 'Real Performance Data',
      description: 'These aren\'t mock numbers - this shows actual hardware optimization results. 4K transcoding went from 2 FPS to 60+ FPS with GPU acceleration.',
      target: '.metrics-grid',
      position: 'left',
      code: 'usenet hardware optimize --auto\n# Result: 1200% performance improvement'
    },
    {
      id: 'service-topology',
      icon: '🌐',
      title: 'Service Network Explorer',
      description: 'Explore how all 19 services connect and communicate. Click any service to see its details and connections.',
      target: '.network-container',
      position: 'top'
    },
    {
      id: 'cli-simulator',
      icon: '💻',
      title: 'Live CLI Experience',
      description: 'This is a real terminal simulator. Type commands or use the quick actions. Try "usenet deploy --auto" to see the full deployment process.',
      target: '.terminal-window',
      position: 'bottom',
      interactive: {
        component: 'CLIPrompt',
        props: { suggestion: 'usenet deploy --auto' }
      }
    },
    {
      id: 'explore',
      icon: '🚀',
      title: 'Ready to Explore!',
      description: 'You\'ve seen the overview - now dive deep! Every component is interactive. Check out the Free Media hub, try the CLI commands, or deploy your own stack.',
      target: null,
      position: 'center'
    }
  ],
  
  performance: [
    {
      id: 'performance-intro',
      icon: '⚡',
      title: 'Hardware Optimization Showcase',
      description: 'See real-world performance gains from GPU acceleration and intelligent hardware detection.',
      target: '.performance-metrics',
      position: 'center'
    },
    {
      id: 'metric-cards',
      icon: '📊',
      title: 'Click Any Metric',
      description: 'Each card shows before/after comparisons. Click to see detailed charts and historical data.',
      target: '.metric-card',
      position: 'right'
    },
    {
      id: 'hardware-detection',
      icon: '🔍',
      title: 'Live Hardware Detection',
      description: 'This shows actual detected hardware from the system. AMD GPU with VAAPI acceleration enabled.',
      target: '.hardware-detection',
      position: 'left'
    },
    {
      id: 'recommendations',
      icon: '🎯',
      title: 'Smart Optimization',
      description: 'AI-powered recommendations based on your specific hardware configuration.',
      target: '.recommendations',
      position: 'top'
    }
  ]
}

// Computed properties
const tourSteps = computed(() => tourDefinitions[props.tourType] || tourDefinitions.architecture)
const totalSteps = computed(() => tourSteps.value.length)
const currentTourStep = computed(() => tourSteps.value[currentStep.value])

const spotlightStyle = computed(() => {
  if (!currentTourStep.value?.target) return { display: 'none' }
  
  const element = document.querySelector(currentTourStep.value.target)
  if (!element) return { display: 'none' }
  
  const rect = element.getBoundingClientRect()
  const radius = Math.max(rect.width, rect.height) * 0.6
  
  return {
    left: `${rect.left + rect.width / 2 - radius}px`,
    top: `${rect.top + rect.height / 2 - radius}px`,
    width: `${radius * 2}px`,
    height: `${radius * 2}px`,
    display: 'block'
  }
})

const cardStyle = computed(() => {
  if (!currentTourStep.value?.target) {
    return {
      left: '50%',
      top: '50%',
      transform: 'translate(-50%, -50%)'
    }
  }
  
  const element = document.querySelector(currentTourStep.value.target)
  if (!element) return {}
  
  const rect = element.getBoundingClientRect()
  const position = currentTourStep.value.position || 'right'
  
  const cardWidth = 400
  const cardHeight = 300
  const offset = 20
  
  let left, top, transform = ''
  
  switch (position) {
    case 'right':
      left = rect.right + offset
      top = rect.top + rect.height / 2
      transform = 'translateY(-50%)'
      break
    case 'left':
      left = rect.left - cardWidth - offset
      top = rect.top + rect.height / 2
      transform = 'translateY(-50%)'
      break
    case 'top':
      left = rect.left + rect.width / 2
      top = rect.top - cardHeight - offset
      transform = 'translateX(-50%)'
      break
    case 'bottom':
      left = rect.left + rect.width / 2
      top = rect.bottom + offset
      transform = 'translateX(-50%)'
      break
    default:
      left = window.innerWidth / 2
      top = window.innerHeight / 2
      transform = 'translate(-50%, -50%)'
  }
  
  // Ensure card stays within viewport
  left = Math.max(20, Math.min(left, window.innerWidth - cardWidth - 20))
  top = Math.max(20, Math.min(top, window.innerHeight - cardHeight - 20))
  
  return {
    left: `${left}px`,
    top: `${top}px`,
    transform
  }
})

// Tour control methods
const startTour = () => {
  isActive.value = true
  currentStep.value = 0
  showTrigger.value = false
  shouldPulse.value = false
  
  nextTick(() => {
    cardVisible.value = true
    scrollToTarget()
  })
}

const closeTour = () => {
  isActive.value = false
  cardVisible.value = false
  showTrigger.value = true
  
  // Store completion in localStorage
  localStorage.setItem(`tour-completed-${props.tourType}`, 'true')
}

const completeTour = () => {
  closeTour()
  // Emit completion event
  emit('tourCompleted', props.tourType)
}

const nextStep = () => {
  if (currentStep.value < totalSteps.value - 1) {
    currentStep.value++
    scrollToTarget()
  }
}

const previousStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--
    scrollToTarget()
  }
}

const goToStep = (stepIndex) => {
  if (stepIndex >= 0 && stepIndex < totalSteps.value) {
    currentStep.value = stepIndex
    scrollToTarget()
  }
}

const handleOverlayClick = (event) => {
  // Only close if clicking on the overlay itself, not tour elements
  if (event.target.classList.contains('tour-overlay')) {
    closeTour()
  }
}

const handleInteractiveAction = (action) => {
  console.log('Interactive action:', action)
  // Handle interactive elements within tour steps
}

const scrollToTarget = () => {
  if (!currentTourStep.value?.target) return
  
  const element = document.querySelector(currentTourStep.value.target)
  if (element) {
    element.scrollIntoView({
      behavior: 'smooth',
      block: 'center',
      inline: 'center'
    })
  }
}

// Lifecycle
onMounted(() => {
  // Check if tour was already completed
  const completed = localStorage.getItem(`tour-completed-${props.tourType}`)
  if (completed) {
    shouldPulse.value = false
  }
  
  // Auto-start if requested and not completed
  if (props.autoStart && !completed) {
    setTimeout(startTour, 1000)
  }
})

// Keyboard shortcuts
const handleKeydown = (event) => {
  if (!isActive.value) return
  
  switch (event.key) {
    case 'Escape':
      closeTour()
      break
    case 'ArrowRight':
    case ' ':
      event.preventDefault()
      nextStep()
      break
    case 'ArrowLeft':
      event.preventDefault()
      previousStep()
      break
  }
}

// Watch for step changes
watch(currentStep, () => {
  nextTick(() => {
    cardVisible.value = false
    setTimeout(() => {
      cardVisible.value = true
    }, 150)
  })
})

// Event handling
const emit = defineEmits(['tourCompleted'])

// Add global event listeners
onMounted(() => {
  document.addEventListener('keydown', handleKeydown)
})

onUnmounted(() => {
  document.removeEventListener('keydown', handleKeydown)
})
</script>

<style scoped>
.guided-tour {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 10000;
  pointer-events: none;
}

.tour-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.7);
  pointer-events: all;
  backdrop-filter: blur(2px);
}

.spotlight {
  position: absolute;
  background: radial-gradient(circle, transparent 0%, transparent 40%, rgba(0, 0, 0, 0.8) 70%);
  border-radius: 50%;
  transition: all 0.6s cubic-bezier(0.4, 0, 0.2, 1);
  pointer-events: none;
  box-shadow: 0 0 0 9999px rgba(0, 0, 0, 0.7);
}

.tour-card {
  position: absolute;
  width: 400px;
  max-width: 90vw;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
  color: white;
  pointer-events: all;
  transform-origin: center;
  transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  opacity: 0;
  scale: 0.8;
}

.tour-card-enter {
  opacity: 1;
  scale: 1;
}

.tour-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 1.5rem 0 1.5rem;
}

.tour-progress {
  display: flex;
  align-items: center;
  gap: 1rem;
  flex: 1;
}

.progress-bar {
  flex: 1;
  height: 4px;
  background: rgba(255, 255, 255, 0.2);
  border-radius: 2px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: #50fa7b;
  transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

.step-counter {
  font-size: 0.9rem;
  opacity: 0.8;
  font-weight: 500;
}

.tour-close {
  background: rgba(255, 255, 255, 0.1);
  border: none;
  color: white;
  font-size: 1.5rem;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.3s ease;
}

.tour-close:hover {
  background: rgba(255, 255, 255, 0.2);
  transform: scale(1.1);
}

.tour-content {
  padding: 1.5rem;
  text-align: center;
}

.tour-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
  display: block;
}

.tour-content h3 {
  margin: 0 0 1rem 0;
  font-size: 1.5rem;
  font-weight: bold;
}

.tour-content p {
  margin: 0 0 1.5rem 0;
  line-height: 1.6;
  opacity: 0.9;
}

.tour-interactive {
  background: rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  padding: 1rem;
  margin: 1rem 0;
}

.tour-code {
  background: rgba(0, 0, 0, 0.3);
  border-radius: 8px;
  padding: 1rem;
  margin: 1rem 0;
  font-family: 'Fira Code', monospace;
  text-align: left;
}

.tour-code pre {
  margin: 0;
  color: #50fa7b;
}

.tour-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 1.5rem 1.5rem 1.5rem;
  gap: 1rem;
}

.tour-btn {
  background: rgba(255, 255, 255, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.3);
  color: white;
  padding: 0.75rem 1.5rem;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.tour-btn.primary {
  background: #50fa7b;
  color: #1e1e1e;
  border-color: #50fa7b;
}

.tour-btn.secondary {
  background: rgba(255, 255, 255, 0.1);
}

.tour-btn.success {
  background: #ff79c6;
  color: #1e1e1e;
  border-color: #ff79c6;
  animation: pulse-success 2s infinite;
}

@keyframes pulse-success {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}

.tour-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
}

.tour-navigation-dots {
  display: flex;
  gap: 0.5rem;
}

.nav-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.3);
  cursor: pointer;
  transition: all 0.3s ease;
}

.nav-dot.active {
  background: #50fa7b;
  transform: scale(1.3);
}

.nav-dot.completed {
  background: #50fa7b;
}

.floating-hint {
  position: absolute;
  background: #ff79c6;
  color: #1e1e1e;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  font-size: 0.85rem;
  font-weight: 600;
  pointer-events: all;
  animation: float 2s ease-in-out infinite;
  box-shadow: 0 4px 15px rgba(255, 121, 198, 0.3);
}

@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-10px); }
}

.hint-arrow {
  position: absolute;
  width: 0;
  height: 0;
  border: 6px solid transparent;
}

.hint-arrow.down {
  top: 100%;
  left: 50%;
  transform: translateX(-50%);
  border-top-color: #ff79c6;
}

.tour-trigger {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  color: white;
  padding: 1rem 1.5rem;
  border-radius: 50px;
  cursor: pointer;
  font-weight: 600;
  box-shadow: 0 8px 32px rgba(102, 126, 234, 0.3);
  display: flex;
  align-items: center;
  gap: 0.75rem;
  transition: all 0.3s ease;
  z-index: 1000;
}

.tour-trigger:hover {
  transform: translateY(-3px);
  box-shadow: 0 12px 40px rgba(102, 126, 234, 0.4);
}

.tour-trigger.pulse {
  animation: pulse-trigger 3s infinite;
}

@keyframes pulse-trigger {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.1); }
}

.trigger-icon {
  font-size: 1.2rem;
}

.trigger-text {
  font-size: 0.95rem;
}

/* Responsive design */
@media (max-width: 768px) {
  .tour-card {
    width: 350px;
    bottom: 2rem;
    left: 50% !important;
    top: auto !important;
    transform: translateX(-50%) !important;
  }
  
  .tour-actions {
    flex-direction: column;
    gap: 0.75rem;
  }
  
  .tour-btn {
    width: 100%;
    justify-content: center;
  }
  
  .tour-trigger {
    bottom: 1rem;
    right: 1rem;
    padding: 0.75rem 1rem;
  }
  
  .trigger-text {
    display: none;
  }
}
</style>