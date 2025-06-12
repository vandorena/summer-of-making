import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["introVideo", "modal", "container"];
  static values = { email: String };

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.handleKeydown);
    this.enableClose(false);
    this.videoLooped = false;
    this.uem();
    this.play();
    this.fuckery();
  }

  fuckery() {
    if (this.hasIntroVideoTarget) {
      this.handleVideoLoop = this.handleVideoLoop.bind(this);
      this.introVideoTarget.addEventListener("ended", this.handleVideoLoop);
    }
  }

  handleVideoLoop() {
    if (!this.videoLooped) {
      this.videoLooped = true;
      this.enableClose(true);
    }
  }

  uem() {
    const msg = this.element.querySelector(".signup-wizard-message");
    if (msg) {
      const email = this.emailValue || "your email";
      msg.innerHTML = `Check your email <span class='font-bold'>${email}</span> for your invite!`;
      msg.classList.remove("text-saddle-taupe");
      msg.classList.add("text-green-700", "font-semibold");
    }
  }

  play() {
    if (
      this.hasIntroVideoTarget &&
      !this.element.classList.contains("hidden")
    ) {
      this.introVideoTarget.loop = true;
      this.introVideoTarget.play().catch((error) => {
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

  enableClose(enabled) {
    const closeBtn = this.element.querySelector(
      '[data-action="click->signup-wizard#close"]'
    );
    if (closeBtn) {
      closeBtn.disabled = !enabled;
      if (!enabled) {
        closeBtn.classList.add("text-gray-600", "cursor-not-allowed");
        closeBtn.classList.remove(
          "text-vintage-red",
          "hover:text-vintage-red",
          "cursor-pointer"
        );
      } else {
        closeBtn.classList.remove("text-gray-600", "cursor-not-allowed");
        closeBtn.classList.add(
          "text-vintage-red",
          "hover:text-vintage-red",
          "cursor-pointer"
        );
      }
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
    if (this.hasIntroVideoTarget && this.handleVideoLoop) {
      this.introVideoTarget.removeEventListener("ended", this.handleVideoLoop);
    }
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close();
      event.stopPropagation();
    }
  }

  close() {
    if (!this.videoLooped) return; // Prevent close until video has looped once
    if (this.hasIntroVideoTarget) {
      this.introVideoTarget.pause();
      this.introVideoTarget.currentTime = 0;
      const playButton = document.getElementById("manual-play-button");
      if (playButton) playButton.remove();
    }
    if (this.hasModalTarget && this.hasContainerTarget) {
      this.modalTarget.style.transition = "opacity 250ms ease-in";
      this.containerTarget.style.transition = "all 250ms ease-in";
      this.modalTarget.style.opacity = "0";
      this.containerTarget.style.transform = "scale(0.9)";
      this.containerTarget.style.opacity = "0";
      setTimeout(() => {
        this.modalTarget.classList.add("hidden");
        this.modalTarget.style.transition = "";
        this.containerTarget.style.transition = "";
        this.containerTarget.style.transform = "";
        document.body.classList.remove("overflow-hidden");
      }, 250);
    } else {
      this.element.classList.add("hidden");
      document.body.classList.remove("overflow-hidden");
    }
  }

  closeOnOutsideClick(event) {
    if (event.target === this.element) {
      this.close();
    }
  }
}
