import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["videoContainer", "introVideo", "modal", "container"];
  static values = {
    email: String,
  };

  emailSent = false;
  videoLoopCount = 0;

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.handleKeydown);
    this.setCloseButtonEnabled(false);
    this.videoLoopCount = 0;
  }

  initialize() {
    if (this.hasIntroVideoTarget) {
      this.introVideoTarget.currentTime = 0;
      this.introVideoTarget.loop = false;
      this.introVideoTarget.removeEventListener(
        "ended",
        this.handleVideoEndedBound
      );
      this.handleVideoEndedBound = this.handleVideoEnded.bind(this);
      this.introVideoTarget.addEventListener(
        "ended",
        this.handleVideoEndedBound
      );
      const genericMsg = this.element.querySelector(
        "#signup-wizard-generic-message"
      );
      if (genericMsg) {
        genericMsg.style.display = "";
      }
      const specificMsg = this.element.querySelector(
        "#signup-wizard-specific-message"
      );
      if (specificMsg) {
        specificMsg.remove();
      }
      const emailSpan = this.element.querySelector(
        "#signup-wizard-email-placeholder"
      );
      if (emailSpan) {
        emailSpan.remove();
      }
      if (this.hasModalTarget && this.hasContainerTarget) {
        this.modalTarget.style.opacity = "0";
        this.containerTarget.style.transform = "scale(0.9)";
        this.containerTarget.style.opacity = "0";

        this.modalTarget.offsetHeight;

        setTimeout(() => {
          this.modalTarget.style.transition = "opacity 250ms ease-out";
          this.containerTarget.style.transition = "all 250ms ease-out";
          this.modalTarget.style.opacity = "1";
          this.containerTarget.style.transform = "scale(1)";
          this.containerTarget.style.opacity = "1";

          setTimeout(() => {
            this.playVideo();
          }, 250);
        }, 10);
      } else {
        setTimeout(() => {
          this.playVideo();
        }, 200);
      }
    }
  }

  playVideo() {
    if (
      this.hasIntroVideoTarget &&
      !this.element.classList.contains("hidden")
    ) {
      this.introVideoTarget.play().catch((error) => {
        console.warn("Video playback was prevented:", error);

        if (!document.getElementById("manual-play-button")) {
          const playButton = document.createElement("button");
          playButton.id = "manual-play-button";
          playButton.className =
            "absolute inset-0 flex items-center justify-center bg-black/50 rounded-lg";
          playButton.innerHTML = `
            <div class="bg-white/80 rounded-full p-3 hover:bg-white transition-all">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-12 w-12 text-vintage-red" viewBox="0 0 24 24">
                <path fill="currentColor" d="M8 5.14v14l11-7l-11-7Z"/>
              </svg>
            </div>
          `;
          playButton.addEventListener("click", () => {
            this.introVideoTarget.play();
            playButton.remove();
          });

          const videoContainer = this.introVideoTarget.parentElement;
          videoContainer.style.position = "relative";
          videoContainer.appendChild(playButton);
        }
      });
    }
  }

  handleVideoEnded() {
    this.videoLoopCount = (this.videoLoopCount || 0) + 1;
    if (this.videoLoopCount === 1) {
      this.setCloseButtonEnabled(true);
      const genericMsg = this.element.querySelector(
        "#signup-wizard-generic-message"
      );
      if (genericMsg) {
        const email = this.emailValue || "your email";
        genericMsg.textContent = `Check for an email from Slack!`;
        genericMsg.classList.remove("text-saddle-taupe");
        genericMsg.classList.add("text-green-700", "font-semibold");
      }
    }
    this.introVideoTarget.currentTime = 0;
    this.introVideoTarget.play();
  }

  setCloseButtonEnabled(enabled) {
    const closeBtn = this.element.querySelector(
      '[data-action="click->signup-wizard#close"]'
    );
    if (closeBtn) {
      closeBtn.disabled = !enabled;
      if (!enabled) {
        closeBtn.classList.remove("cursor-pointer");
        closeBtn.classList.add("cursor-not-allowed");
        closeBtn.classList.remove("hover:text-vintage-red");
        closeBtn.classList.add("text-gray-600");
        closeBtn.classList.remove("text-vintage-red");
      } else {
        closeBtn.classList.remove("cursor-not-allowed");
        closeBtn.classList.add("cursor-pointer");
        closeBtn.classList.remove("text-gray-600");
        closeBtn.classList.add("text-vintage-red");
        closeBtn.classList.add("hover:text-vintage-red");
      }
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
    if (this.hasIntroVideoTarget && this.handleVideoEndedBound) {
      this.introVideoTarget.removeEventListener(
        "ended",
        this.handleVideoEndedBound
      );
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close();
      event.stopPropagation();
    }
  }

  close() {
    // Stop the video if it's playing
    if (this.hasIntroVideoTarget) {
      this.introVideoTarget.pause();
      this.introVideoTarget.currentTime = 0;

      // Remove the play button if it exists
      const playButton = document.getElementById("manual-play-button");
      if (playButton) {
        playButton.remove();
      }
    }

    this.emailSent = false;

    // Apply closing animations
    if (this.hasModalTarget && this.hasContainerTarget) {
      this.modalTarget.style.transition = "opacity 250ms ease-in";
      this.containerTarget.style.transition = "all 250ms ease-in";
      this.modalTarget.style.opacity = "0";
      this.containerTarget.style.transform = "scale(0.9)";
      this.containerTarget.style.opacity = "0";

      // Wait for the animation to complete before hiding the modal
      setTimeout(() => {
        this.modalTarget.classList.add("hidden");
        this.modalTarget.style.transition = "";
        this.containerTarget.style.transition = "";
        this.containerTarget.style.transform = "";
        document.body.classList.remove("overflow-hidden");
      }, 250);
    } else {
      // Fallback if targets aren't available
      this.element.classList.add("hidden");
      document.body.classList.remove("overflow-hidden");
    }
  }

  closeOnOutsideClick(event) {
    // Only close if clicking directly on the background overlay
    if (event.target === this.element) {
      this.close();
    }
  }
}
