import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["todoButton", "callout", "modal"]

  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
  }

  toggle() {
    if (this.modalTarget.style.display === "none" || this.modalTarget.style.display === "") {
      this.show()
    } else {
      this.close()
    }
  }

  show() {
    this.modalTarget.style.display = "block"
    // this.todoButtonTarget.style.display = "none"
    // this.calloutTarget.style.display = "none"
    // before animation
    setTimeout(() => {
      this.modalTarget.classList.remove("translate-x-full")
      this.modalTarget.classList.add("translate-x-0")
    }, 10)
    
    // Add click outside listener when modal is shown
    setTimeout(() => {
      document.addEventListener("click", this.handleOutsideClick)
    }, 100)
  }

  close() {
    this.modalTarget.classList.remove("translate-x-0")
    this.modalTarget.classList.add("translate-x-full")
    // Remove click outside listener when modal is closed
    document.removeEventListener("click", this.handleOutsideClick)
    // after animation
    setTimeout(() => {
      this.modalTarget.style.display = "none"
      // this.todoButtonTarget.style.display = "flex"
      // this.calloutTarget.style.display = "block"
    }, 300)
  }

  handleOutsideClick(event) {
    // Check if the modal is currently visible
    if (this.modalTarget.style.display === "none" || this.modalTarget.style.display === "") {
      return
    }
    
    // Check if the click was outside the modal
    if (!this.modalTarget.contains(event.target) && !this.todoButtonTarget.contains(event.target)) {
      this.close()
    }
  }
} 