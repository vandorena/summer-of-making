import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon", "status", "link"]
  static values = { tutorialActive: Boolean }

  connect() {
    if (this.tutorialActiveValue) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    this.pollInterval = setInterval(() => {
      this.updateStatus()
    }, 1000)

    this.observer = new MutationObserver(() => {
      if (this.hasStatusTarget && this.statusTarget.textContent.includes('Setup done')) {
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
        if (data.hackatime_projects) {
          // green
          this.iconTarget.className = 'w-8 h-8 bg-green-100 rounded-full flex items-center justify-center'
          this.iconTarget.innerHTML = `
            <svg class="w-5 h-5" xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'>
              <g fill='none' fill-rule='evenodd'>
                <path fill='currentColor' d='M21.546 5.111a1.5 1.5 0 0 1 0 2.121L10.303 18.475a1.6 1.6 0 0 1-2.263 0L2.454 12.89a1.5 1.5 0 1 1 2.121-2.121l4.596 4.596L19.424 5.111a1.5 1.5 0 0 1 2.122 0'/>
              </g>
            </svg>
          `
          
          // replace w/ status span
          const contentDiv = this.iconTarget.parentElement.nextElementSibling
          contentDiv.innerHTML = `
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Connect your Hackatime account</h3>
            <p class="text-gray-600 mb-4">Hackatime tracks how much you code, and we use that time to give you shells as a reward for all your hard work!</p>
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-green-100 text-green-800" data-hackatime-status-target="status">
              Linked and projects tracked!
            </span>
          `
        } else if (data.hackatime_setup) {
          // yellow
          this.iconTarget.className = 'w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center'
          this.iconTarget.innerHTML = `
            <svg class="w-5 h-5" xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'>
              <g fill='none' fill-rule='evenodd'>
                <path fill='currentColor' d='M18 2a2 2 0 0 1 2 2v8.803A6 6 0 0 0 12.528 22H6a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2zm-1 12a4 4 0 1 1 0 8 4 4 0 0 1 0-8m0 1.5a1 1 0 0 0-.993.883L16 16.5V18a1 1 0 0 0 .883.993L17 19h1a1 1 0 0 0 .117-1.993L18 17v-.5a1 1 0 0 0-1-1M9 11H8a1 1 0 1 0 0 2h1a1 1 0 1 0 0-2m5-4H8a1 1 0 0 0-.117 1.993L8 9h6a1 1 0 0 0 .117-1.993z'/>
              </g>
            </svg>
          `
          
          // replace w/ status span
          const contentDiv = this.iconTarget.parentElement.nextElementSibling
          contentDiv.innerHTML = `
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Connect your Hackatime account</h3>
            <p class="text-gray-600 mb-4">Hackatime tracks how much you code, and we use that time to give you shells as a reward for all your hard work!</p>
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-yellow-100 text-yellow-800" data-hackatime-status-target="status">
              Linked, now waiting for real data...
            </span>
          `
        } else if (data.hackatime_linked) {
          // yellow
          this.iconTarget.className = 'w-8 h-8 bg-yellow-100 rounded-full flex items-center justify-center'
          this.iconTarget.innerHTML = `
            <svg class="w-5 h-5" xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'>
              <g fill='none' fill-rule='evenodd'>
                <path fill='currentColor' d='M12 2a10 10 0 1 1 0 20 10 10 0 0 1 0-20m0 2a8 8 0 1 0 0 16 8 8 0 0 0 0-16m0 1.5a1 1 0 0 0-.993.883L12 14.5V16a1 1 0 0 0 .883.993L13 17h1a1 1 0 0 0 .117-1.993L14 15v-.5a1 1 0 0 0-1-1M9 11H8a1 1 0 1 0 0 2h1a1 1 0 1 0 0-2m5-4H8a1 1 0 0 0-.117 1.993L8 9h6a1 1 0 0 0 .117-1.993z'/>
              </g>
            </svg>
          `

          // replace w/ status span
          const contentDiv = this.iconTarget.parentElement.nextElementSibling
          contentDiv.innerHTML = `
            <h3 class="text-lg font-semibold text-gray-900 mb-2">Connect your Hackatime account</h3>
            <p class="text-gray-600 mb-4">Hackatime tracks how much you code, and we use that time to give you shells as a reward for all your hard work!</p>
            <span class="inline-flex items-center px-3 py-1 rounded-full text-sm bg-yellow-100 text-yellow-800" data-hackatime-status-target="status">
              Waiting for test data...
            </span>
          `
        }
      })
      .catch(error => console.log('Status check failed:', error))
  }
} 