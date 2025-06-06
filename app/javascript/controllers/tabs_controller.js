import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabButton", "content"]
  static values = { currentTab: String }

  connect() {
    this.updateTabButtons()
  }

  switchTab(event) {
    const newTab = event.currentTarget.dataset.tab
    this.currentTabValue = newTab
    this.updateTabButtons()
    this.loadTabContent(newTab)
  }

  updateTabButtons() {
    this.tabButtonTargets.forEach(button => {
      const isActive = button.dataset.tab === this.currentTabValue
      
      if (isActive) {
        button.className = "px-6 tab-element py-2 text-lg text-black"
      } else {
        button.className = "px-6 py-2 text-lg text-black"
      }
    })
  }

  loadTabContent(tab) {
    const updatesListContainer = document.getElementById('updates-list-container')
    
    if (updatesListContainer) {
      updatesListContainer.innerHTML = `
        <div class="space-y-4 sm:space-y-6" id="updates-list">
        </div>
        <div id="load-more-updates">
        </div>
      `
    }

    const updatesList = document.getElementById('updates-list')
    const newInitialFrame = document.createElement('turbo-frame')
    newInitialFrame.id = 'initial-updates'
    newInitialFrame.src = `/explore?tab=${tab}&format=turbo_stream`
    newInitialFrame.loading = 'eager'
    
    if (updatesList) {
      updatesList.appendChild(newInitialFrame)
    }
  }
} 