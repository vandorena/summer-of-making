import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    activeProjectId: String
  }

  openTimer() {
    if (this.hasActiveProjectIdValue) {
      const modal = document.getElementById(`timer-modal-${this.activeProjectIdValue}`)
      if (modal) {
        modal.classList.remove('hidden')
        document.body.classList.add('overflow-hidden')
      } else {
        window.location.href = `/projects/${this.activeProjectIdValue}?open_timer=true`
      }
    }
  }
} 