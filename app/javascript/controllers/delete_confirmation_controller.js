import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    originalText: String
  }

  connect() {
    this.originalTextValue = this.element.textContent.trim()
    
    this.modal = this.element.closest('[data-controller~="timer"]')
    
    // if modal is hidden, then reset the button text
    if (this.modal) {
      this.modalObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          if (mutation.attributeName === 'class') {
            if (this.modal.classList.contains('hidden')) {
              this.reset()
            }
          }
        })
      })
      
      this.modalObserver.observe(this.modal, { attributes: true })
    }
    
  }
  
  disconnect() {
    if (this.modalObserver) {
      this.modalObserver.disconnect()
    }
  }

  reset() {
    this.element.textContent = this.originalTextValue
  }

  confirm(event) {
    if (this.element.textContent.trim() === "Delete" || this.element.textContent.trim() === "Discard") {
      event.preventDefault()
      this.element.textContent = "Sure?"
    } else {
      const timerController = this.application.getControllerForElementAndIdentifier(
        this.element.closest('[data-controller~="timer"]'),
        'timer'
      )
      
      if (timerController) {
        timerController.discardSession(event)
      }
      
      return true
    }
  }
} 