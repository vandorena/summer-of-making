import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "modal"]

  connect() {
    this.escapeHandler = this.escapeHandler.bind(this)
    document.addEventListener("keydown", this.escapeHandler)
    
    this.clickOutsideHandler = this.clickOutsideHandler.bind(this)
    this.modalTargets.forEach(modal => {
      modal.addEventListener("click", this.clickOutsideHandler)
    })
  }

  disconnect() {
    document.removeEventListener("keydown", this.escapeHandler)
    this.modalTargets.forEach(modal => {
      modal.removeEventListener("click", this.clickOutsideHandler)
    })
  }

  open(event) {
    let modal;
    if (event.currentTarget.dataset.modalId) {
      const modalId = event.currentTarget.dataset.modalId;
      modal = document.getElementById(`comment-modal-${modalId}`);
    } else {
      modal = document.getElementById("create-project-modal") || this.modalTarget;
    }
    
    modal.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    setTimeout(() => {
      const firstInput = modal.querySelector("input, textarea")
      if (firstInput) firstInput.focus()
    }, 100)
  }

  close(event) {
    let modal;
    
    if (event && event.currentTarget && event.currentTarget.dataset.modalId) {
      const modalId = event.currentTarget.dataset.modalId;
      modal = document.getElementById(`comment-modal-${modalId}`);
    } 
    else if (this.element.closest("[id^='comment-modal-']")) {
      modal = this.element.closest("[id^='comment-modal-']");
    }
    else {
      modal = document.getElementById("create-project-modal") || this.modalTarget;
    }
    
    if (modal) {
      modal.classList.add("hidden");
      document.body.classList.remove("overflow-hidden");
    }
  }

  escapeHandler(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  clickOutsideHandler(event) {
    const container = event.currentTarget.querySelector("[data-modal-target='container']")
    if (container && !container.contains(event.target) && event.target === event.currentTarget) {
      this.close()
    }
  }
} 