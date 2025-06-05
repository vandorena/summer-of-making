import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Register custom Turbo Stream action
    Turbo.StreamActions.show_modal = function() {
      const modal = document.getElementById(this.target)
      if (modal) {
        modal.showModal()
      }
    }
  }
}
