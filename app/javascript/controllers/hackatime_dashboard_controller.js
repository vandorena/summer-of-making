import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["todayTime", "totalTime", "noDataAlert"]
  static values = { 
    updateInterval: { type: Number, default: 30000 } // 30 seconds
  }

  connect() {
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  startPolling() {
    // Update immediately
    this.updateDashboard()
    
    // Then update every interval
    this.pollInterval = setInterval(() => {
      this.updateDashboard()
    }, this.updateIntervalValue)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  updateDashboard() {
    fetch('/campfire/hackatime_status')
      .then(response => response.json())
      .then(data => {
        if (data.dashboard) {
          if (this.hasTodayTimeTarget) {
            this.todayTimeTarget.textContent = data.dashboard.today_time_formatted
          }
          
          if (this.hasTotalTimeTarget) {
            this.totalTimeTarget.textContent = data.dashboard.total_time_formatted
          }
          
          if (this.hasNoDataAlertTarget) {
            if (data.dashboard.has_time_recorded) {
              this.noDataAlertTarget.style.display = 'none'
            } else {
              this.noDataAlertTarget.style.display = 'block'
            }
          }
        }
      })
      .catch(error => {
        console.log('Dashboard update failed:', error)
      })
  }

  refresh() {
    this.updateDashboard()
  }
} 