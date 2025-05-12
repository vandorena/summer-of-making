import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    originalText: String,
    countdownTime: { type: Number, default: 3 }
  }

  connect() {
    this.originalTextValue = this.element.textContent.trim()
    this.isCountingDown = false
    
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
    this.clearCountdown()
  }

  reset() {
    this.element.textContent = this.originalTextValue
    this.isCountingDown = false
    this.clearCountdown()
  }

  clearCountdown() {
    if (this.countdownTimer) {
      clearInterval(this.countdownTimer)
      this.countdownTimer = null
    }
  }

  confirm(event) {
    const currentText = this.element.textContent.trim();
    
    if (currentText === "Delete" || currentText === "Discard") {
      event.preventDefault();
      this.element.textContent = "Sure?";
      return;
    } 
    
    if (currentText === "Sure?" && !this.isCountingDown) {
      if (this.originalTextValue === "Discard") {
        event.preventDefault();
        this.startCountdown();
      } else {
        return this.proceedWithAction(event);
      }
    } else if (!this.isCountingDown) {
      return this.proceedWithAction(event);
    }
  }
  
  startCountdown() {
    this.isCountingDown = true
    let timeLeft = this.countdownTimeValue
    this.element.textContent = `Wait (${timeLeft})`
    this.element.disabled = true
    
    this.countdownTimer = setInterval(() => {
      timeLeft -= 1
      if (timeLeft <= 0) {
        this.clearCountdown()
        this.element.textContent = "Really, sure?"
        this.element.disabled = false
        this.isCountingDown = false
      } else {
        this.element.textContent = `Wait (${timeLeft})`
      }
    }, 1000)
  }
  
  proceedWithAction(event) {
    const timerController = this.application.getControllerForElementAndIdentifier(
      this.element.closest('[data-controller~="timer"]'),
      'timer'
    );
    
    if (timerController) {
      event.preventDefault();
      timerController.discardSession(event);
      return false;
    }
    
    return true;
  }
} 