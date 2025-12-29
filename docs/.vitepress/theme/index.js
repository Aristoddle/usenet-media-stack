import DefaultTheme from 'vitepress/theme'

// All custom components disabled for deployment stability
// They can be re-enabled after fixing ESM compatibility issues

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
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

        /* Mobile responsive adjustments */
        @media (max-width: 768px) {
          .feature-card:hover, .service-card:hover, .metric-card:hover, .vp-feature:hover {
            transform: translateY(-4px) scale(1.01);
          }
        }
      `
      document.head.appendChild(style)
    }
  }
}
