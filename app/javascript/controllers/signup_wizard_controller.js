import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "videoContainer",
    "introVideo",
    "sendInviteButton",
    "modal",
    "container",
  ];
  static values = {
    email: String,
  };

  connect() {
    this.handleKeydown = this.handleKeydown.bind(this);
    document.addEventListener("keydown", this.handleKeydown);
  }

  initialize() {
    if (this.hasIntroVideoTarget) {
      this.introVideoTarget.currentTime = 0;
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

        // autoplay failed, manual add button
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

  disconnect() {
    document.removeEventListener("keydown", this.handleKeydown);
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.element.classList.contains("hidden")) {
      this.close();
      event.stopPropagation();
    }
  }

  videoEnded() {
    if (this.hasSendInviteButtonTarget) {
      this.sendInviteButtonTarget.disabled = false;
      this.sendInviteButtonTarget.classList.remove("opacity-50");

      this.sendInviteButtonTarget.classList.add("animate-pulse");

      const buttonText = document.createElement("span");
      buttonText.innerHTML =
        "Send Slack Invite <span class='ml-2 text-yellow-100'>→</span>";
      this.sendInviteButtonTarget.innerHTML = "";
      this.sendInviteButtonTarget.appendChild(buttonText);

      this.sendInviteButtonTarget.scrollIntoView({
        behavior: "smooth",
        block: "center",
      });
    }
  }

  async sendInviteEmail() {
    const button = this.sendInviteButtonTarget;
    const originalText = button.innerHTML;

    button.innerHTML = "Sending...";
    button.disabled = true;
    button.classList.add("opacity-75");
    button.classList.remove("animate-pulse");

    try {
      // Get CSRF token with proper error handling
      let csrfToken = "";
      const metaTag = document.querySelector('meta[name="csrf-token"]');
      if (metaTag) {
        csrfToken = metaTag.content;
      } else {
        console.warn("CSRF token meta tag not found. Request may fail.");
      }

      const response = await fetch("/sign-up", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify({ email: this.emailValue }),
      });

      if (response.ok) {
        const data = await response.json();
        this.showSuccessScreen(data);
      } else {
        const errorData = await response.json();
        throw new Error(errorData.error || "Failed to send signup email");
      }
    } catch (error) {
      console.error("Error sending signup email:", error);

      // Show a more user-friendly error message
      let errorMessage = "There was a problem sending your signup email.";
      if (error.message && error.message !== "Failed to send signup email") {
        errorMessage += ` Details: ${error.message}`;
      }

      alert(errorMessage);

      button.innerHTML = "Try Again";
      button.disabled = false;
      button.classList.remove("opacity-75");

      setTimeout(() => {
        button.innerHTML = originalText;
      }, 2000);
    }
  }

  showSuccessScreen(responseData) {
    // Hide the video container with a fade-out effect
    if (this.hasVideoContainerTarget) {
      this.videoContainerTarget.style.transition = "opacity 250ms ease-out";
      this.videoContainerTarget.style.opacity = "0";

      setTimeout(() => {
        this.videoContainerTarget.classList.add("hidden");

        // Create and show success message with fade-in effect
        const successElement = this.createSuccessElement(responseData);
        successElement.style.opacity = "0";

        const contentContainer = this.element.querySelector(".flex-1.p-8");
        if (contentContainer) {
          contentContainer.innerHTML = "";
          contentContainer.appendChild(successElement);

          // Force reflow before starting animation
          successElement.offsetHeight;

          // Fade in the success message
          setTimeout(() => {
            successElement.style.transition = "opacity 250ms ease-in";
            successElement.style.opacity = "1";
          }, 10);
        }

        // Hide the footer with the send button
        const footer = this.element.querySelector(".border-t");
        if (footer) {
          footer.classList.add("hidden");
        }
      }, 250);
    } else {
      // Fallback if video container target isn't available
      const successElement = this.createSuccessElement(responseData);

      const contentContainer = this.element.querySelector(".flex-1.p-8");
      if (contentContainer) {
        contentContainer.innerHTML = "";
        contentContainer.appendChild(successElement);
      }

      // Hide the footer with the send button
      const footer = this.element.querySelector(".border-t");
      if (footer) {
        footer.classList.add("hidden");
      }
    }
  }

  createSuccessElement(responseData) {
    const successHtml = `
      <div class="flex flex-col items-center justify-center h-full text-center space-y-8 max-w-3xl mx-auto">
        <h2 class="text-4xl font-bold text-forest mb-6">Welcome aboard! ✨</h2>
        <p class="text-xl">Check your inbox (<strong>${
          responseData.email
        }</strong>) for an email from Slack</p>
        
        ${
          responseData.ok
            ? '<div class="text-6xl mb-4 animate-bounce">🎉</div><p class="text-green-600 font-semibold text-lg">✅ Email sent successfully!</p>'
            : `<div class="text-6xl mb-4">😢</div><p class="text-red-500 text-lg font-semibold">❌ Error: ${
                responseData.error || "Unknown error"
              }</p>`
        }

        <button class="marble-button mt-8 px-8 py-4 text-lg" data-action="click->signup-wizard#close">
          Close
        </button>
      </div>
    `;

    const successElement = document.createElement("div");
    successElement.innerHTML = successHtml;
    successElement.classList.add(
      "flex-1",
      "flex",
      "items-center",
      "justify-center"
    );

    return successElement;
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

      // Reset the send invite button
      if (this.hasSendInviteButtonTarget) {
        this.sendInviteButtonTarget.disabled = true;
        this.sendInviteButtonTarget.classList.add("opacity-50");
        this.sendInviteButtonTarget.classList.remove("animate-pulse");
        this.sendInviteButtonTarget.textContent = "Send Slack Invite";
      }
    }

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
