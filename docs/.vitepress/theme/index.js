import DefaultTheme from 'vitepress/theme'
import SystemArchitecture from '../components/SystemArchitecture.vue'
import PerformanceMetrics from '../components/PerformanceMetrics.vue'
import ServiceTopology from '../components/ServiceTopology.vue'
import CLISimulator from '../components/CLISimulator.vue'
import GuidedTour from '../components/GuidedTour.vue'
import AnimatedHero from '../components/AnimatedHero.vue'
import InteractiveCLIDemo from '../components/InteractiveCLIDemo.vue'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    // Register global components
    app.component('SystemArchitecture', SystemArchitecture)
    app.component('PerformanceMetrics', PerformanceMetrics)
    app.component('ServiceTopology', ServiceTopology)
    app.component('CLISimulator', CLISimulator)
    app.component('GuidedTour', GuidedTour)
    app.component('AnimatedHero', AnimatedHero)
    app.component('InteractiveCLIDemo', InteractiveCLIDemo)
    
    // Enhanced responsive animations for mobile-first UX
    if (typeof window !== 'undefined') {
      const style = document.createElement('style')
      style.textContent = `
        /* Responsive card animations with wiggle and expand */
        .feature-card, .service-card, .metric-card, [class*="card"], .vp-feature {
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          cursor: pointer;
          position: relative;
          overflow: hidden;
        }
        
        .feature-card:hover, .service-card:hover, .metric-card:hover, [class*="card"]:hover, .vp-feature:hover {
          transform: translateY(-8px) scale(1.02);
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
          border-color: var(--vp-c-brand-1);
          z-index: 10;
        }
        
        /* Wiggle animation for interactive elements */
        @keyframes wiggle {
          0% { transform: translateY(-8px) scale(1.02) rotate(0deg); }
          25% { transform: translateY(-8px) scale(1.02) rotate(1deg); }
          75% { transform: translateY(-8px) scale(1.02) rotate(-1deg); }
          100% { transform: translateY(-8px) scale(1.02) rotate(0deg); }
        }
        
        .feature-card:hover, .service-card:hover, .metric-card:hover, .vp-feature:hover {
          animation: wiggle 0.5s ease-in-out;
        }
        
        /* Click shimmer effect */
        .feature-card::before, .service-card::before, .metric-card::before, .vp-feature::before {
          content: '';
          position: absolute;
          top: 0;
          left: -100%;
          width: 100%;
          height: 100%;
          background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
          transition: left 0.5s;
          pointer-events: none;
        }
        
        .feature-card:hover::before, .service-card:hover::before, .metric-card:hover::before, .vp-feature:hover::before {
          left: 100%;
        }
        
        /* Mobile responsive adjustments */
        @media (max-width: 768px) {
          .feature-card:hover, .service-card:hover, .metric-card:hover, .vp-feature:hover {
            transform: translateY(-4px) scale(1.01);
          }
        }
        
        /* Make everything clickable look clickable */
        .clickable-element {
          cursor: pointer;
          transition: all 0.2s ease;
        }
        
        .clickable-element:hover {
          opacity: 0.8;
          transform: scale(1.05);
        }
      `
      document.head.appendChild(style)
      
      // Add click handlers to make cards functional
      document.addEventListener('DOMContentLoaded', () => {
        // Make feature cards clickable
        document.querySelectorAll('.vp-feature, .feature-card, .service-card, .metric-card').forEach(card => {
          card.addEventListener('click', (e) => {
            const link = card.querySelector('a')
            if (link) {
              window.open(link.href, link.target || '_self')
            }
          })
        })
      })
    }
  }
}