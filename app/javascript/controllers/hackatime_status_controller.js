import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "status", "step"]
  static values = { 
    shouldPoll: Boolean,
    checkFillIcon: String,
    todoFillIcon: String
  }

  connect() {
    if (this.shouldPollValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollInterval = setInterval(() => {
      this.updateStatus()
    }, 5000)

    // Set up mutation observer to stop polling when status changes to "Setup done"
    this.observer = new MutationObserver(() => {
      if (this.statusTarget.textContent.includes('Setup done')) {
        this.stopPolling()
      }
    })

    this.observer.observe(document.body, { childList: true, subtree: true })
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
    
    if (this.observer) {
      this.observer.disconnect()
      this.observer = null
    }
  }

  updateStatus() {
    fetch('/campfire/hackatime_status')
      .then(response => response.json())
      .then(data => {
        if (data.hackatime_setup) {
          // green
          this.iconTarget.className = 'w-8 h-8 bg-green-100 rounded-full flex items-center justify-center'
          this.iconTarget.innerHTML = this.checkFillIconValue
          this.statusTarget.className = 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-green-100 text-green-800'
          this.statusTarget.textContent = 'Connected & Setup done!'
        } else if (data.hackatime_linked) {
          // yellow
          this.iconTarget.className = 'w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center'
          this.iconTarget.innerHTML = this.todoFillIconValue
          this.statusTarget.className = 'inline-flex items-center px-3 py-1 rounded-full text-sm bg-yellow-100 text-yellow-800'
          this.statusTarget.textContent = 'Waiting for data...'
        }
      })
      .catch(error => console.log('Status check failed:', error))
  }
} 