import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["helpButton"]

  toggle() {
    const overlay = document.querySelector('.tutorial-overlay')
    const helpButton = this.helpButtonTarget
    
    if (overlay) {
      const isVisible = overlay.style.display !== 'none'
      
      if (isVisible) {
        overlay.style.display = 'none'
        helpButton.style.display = 'flex'
      } else {
        overlay.style.display = 'block'
        helpButton.style.display = 'none'
      }
    }
  }
} 