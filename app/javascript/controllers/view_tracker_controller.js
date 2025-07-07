import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trackable"]
  static values = { 
    viewableType: String,
    viewableId: String,
    threshold: { type: Number, default: 0.5 },
    delay: { type: Number, default: 1000 }
  }

  connect() {
    console.log('views? yes')
    this.trackedItems = new Set()
    this.timeouts = new Map()
    
    this.observer = new IntersectionObserver(
      this.handleIntersection.bind(this),
      {
        threshold: this.thresholdValue,
        rootMargin: "0px"
      }
    )

    const elementsToObserve = this.trackableTargets.length > 0 
      ? this.trackableTargets 
      : [this.element]
    
    console.log(`found ${elementsToObserve.length} trackable elements`)
    elementsToObserve.forEach(target => {
      console.log(`obs id ${target.dataset.viewableId}, type: ${target.dataset.viewableType}`)
      this.observer.observe(target)
    })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    
    this.timeouts.forEach(timeout => clearTimeout(timeout))
    this.timeouts.clear()
  }

  trackableTargetConnected(target) {
    if (this.observer) {
      this.observer.observe(target)
    }
  }

  trackableTargetDisconnected(target) {
    if (this.observer) {
      this.observer.unobserve(target)
    }
    
    const viewableId = target.dataset.viewableId
    if (this.timeouts.has(viewableId)) {
      clearTimeout(this.timeouts.get(viewableId))
      this.timeouts.delete(viewableId)
    }
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
    console.log(`tv on ${viewableType} ${viewableId}`)
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
        console.log(`tv on ${viewableType} ${viewableId}`)
      } else {
        console.warn(`tv failed on ${viewableType} ${viewableId}`, response.status)
      }
    } catch (error) {
      console.error('tv error:', error)
    }
  }
}
