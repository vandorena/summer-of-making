import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    threshold: { type: Number, default: 0.5 },
    delay: { type: Number, default: 1000 }
  }

  connect() {
    console.log('ViewTracker connected')
    this.trackedItems = new Set()
    this.timeouts = new Map()
    
    this.observer = new IntersectionObserver(
      this.handleIntersection.bind(this),
      {
        threshold: this.thresholdValue,
        rootMargin: "0px"
      }
    )

    this.observeTrackableElements()
  }

  observeTrackableElements() {
    const trackableElements = this.element.querySelectorAll('[data-viewable-id][data-viewable-type]')
    
    console.log(`Found ${trackableElements.length} trackable elements`)
    trackableElements.forEach(element => {
      const id = element.dataset.viewableId
      const type = element.dataset.viewableType
      console.log(`Observing ${type} #${id}`)
      this.observer.observe(element)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    
    this.timeouts.forEach(timeout => clearTimeout(timeout))
    this.timeouts.clear()
  }

  handleIntersection(entries) {
    entries.forEach(entry => {
      const viewableId = entry.target.dataset.viewableId
      const viewableType = entry.target.dataset.viewableType
      
      if (entry.isIntersecting) {
        if (!this.trackedItems.has(viewableId)) {
          const timeout = setTimeout(() => {
            this.trackView(viewableType, viewableId)
            this.trackedItems.add(viewableId)
            this.timeouts.delete(viewableId)
          }, this.delayValue)
          
          this.timeouts.set(viewableId, timeout)
        }
      } else {
        if (this.timeouts.has(viewableId)) {
          clearTimeout(this.timeouts.get(viewableId))
          this.timeouts.delete(viewableId)
        }
      }
    })
  }

  async trackView(viewableType, viewableId) {
    console.log(`Tracking view: ${viewableType} #${viewableId}`)
    try {
      const response = await fetch('/track_view', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          viewable_type: viewableType,
          viewable_id: viewableId
        })
      })

      if (response.ok) {
        console.log(`✓ View tracked: ${viewableType} #${viewableId}`)
      } else {
        console.warn(`✗ View tracking failed: ${viewableType} #${viewableId}`, response.status)
      }
    } catch (error) {
      console.error('View tracking error:', error)
    }
  }
}
