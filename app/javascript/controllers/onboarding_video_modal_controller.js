import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "video", "closeButton"]

  connect() {
    // Start the video when modal appears
    if (this.videoTarget) {
      this.videoTarget.play()
    }
    
    // Set up event listeners
    this.setupEventListeners()
  }

  disconnect() {
    // Stop video when controller is disconnected (e.g., navigating away)
    if (this.videoTarget) {
      this.videoTarget.pause()
    }
    
    // Clean up event listeners
    this.removeEventListeners()
  }

  setupEventListeners() {
    // Bind methods to maintain context
    this.boundHandleKeydown = this.handleKeydown.bind(this)

    // Add event listeners
    document.addEventListener("keydown", this.boundHandleKeydown)
  }

  removeEventListeners() {
    if (this.boundHandleKeydown) {
      document.removeEventListener("keydown", this.boundHandleKeydown)
    }
  }

  close() {
    this.stopVideo()
    this.hideModal()
    this.markVideoAsSeen()
  }

  closeOnVideoEnd() {
    this.close()
  }

  closeOnBackgroundClick(event) {
    if (event.target === this.modalTarget) {
      this.close()
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.modalTarget.style.display !== "none") {
      this.close()
    }
  }

  stopVideo() {
    if (this.videoTarget) {
      this.videoTarget.pause()
      this.videoTarget.currentTime = 0
    }
  }

  hideModal() {
    this.modalTarget.style.display = "none"
  }

  markVideoAsSeen() {
    fetch(window.location.pathname + "?mark_video_seen=true", {
      method: "GET",
      headers: {
        "X-Requested-With": "XMLHttpRequest"
      }
    }).then(() => {
      // Video marked as seen, modal will not show again
    }).catch(error => {
      console.error("Error marking video as seen:", error)
    })
  }
}
