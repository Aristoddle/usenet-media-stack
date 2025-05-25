import DefaultTheme from 'vitepress/theme'
import SystemArchitecture from '../components/SystemArchitecture.vue'
import PerformanceMetrics from '../components/PerformanceMetrics.vue'
import ServiceTopology from '../components/ServiceTopology.vue'
import CLISimulator from '../components/CLISimulator.vue'
import GuidedTour from '../components/GuidedTour.vue'
import AnimatedHero from '../components/AnimatedHero.vue'

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
  }
}