import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "step",
    "preview",
    "image",
    "imageContainer",
    "back",
    "next",
    "stepIndicator",
  ];

  connect() {
    this.step = 1;
    this.isActive = false;

    this.stepData = {
      1: {
        caption: "brainstorm something amazing!",
        imageSrc: "https://files.catbox.moe/3t37wi.png",
        bgGradient: "from-yellow-100 to-amber-100",
      },
      2: {
        caption: "1 hour = 1 shell earned!",
        imageSrc: "https://files.catbox.moe/z6gyg3.png",
        bgGradient: "from-orange-100 to-red-100",
      },
      3: {
        caption: "hype up your progress!",
        imageSrc: "https://files.catbox.moe/yo8c4k.png",
        bgGradient: "from-teal-100 to-cyan-100",
      },
      4: {
        caption: "ship it and earn shells!",
        imageSrc: "https://files.catbox.moe/uvg55r.png",
        bgGradient: "from-blue-100 to-indigo-100",
      },
      5: {
        caption: "get bonus shells from votes!",
        imageSrc: "https://files.catbox.moe/7o5p86.png",
        bgGradient: "from-green-100 to-emerald-100",
      },
    };

    this.setupKeyListener();
    this.updateDisplay(1);
    this.updateButtons();
  }

  setupKeyListener() {
    this.keyListener = (event) => {
      switch (event.key) {
        case "ArrowDown":
        case "ArrowRight":
          event.preventDefault();
          this.nextStep();
          break;
        case "ArrowUp":
        case "ArrowLeft":
          event.preventDefault();
          this.prevStep();
          break;
      }
    };

    this.touchStartX = 0;
    this.touchEndX = 0;

    this.touchStartListener = (event) => {
      this.touchStartX = event.touches[0].clientX;
    };

    this.touchEndListener = (event) => {
      this.touchEndX = event.changedTouches[0].clientX;
      this.touch();
    };

    document.addEventListener("keydown", this.keyListener);
    this.element.addEventListener("touchstart", this.touchStartListener, {
      passive: true,
    });
    this.element.addEventListener("touchend", this.touchEndListener, {
      passive: true,
    });
  }

  touch() {
    const swipeThreshold = 50;
    const diff = this.touchStartX - this.touchEndX;

    if (Math.abs(diff) > swipeThreshold) {
      if (diff > 0) {
        this.nextStep();
      } else {
        this.prevStep();
      }
    }
  }

  disconnect() {
    if (this.keyListener) {
      document.removeEventListener("keydown", this.keyListener);
    }
    if (this.touchStartListener) {
      this.element.removeEventListener("touchstart", this.touchStartListener);
    }
    if (this.touchEndListener) {
      this.element.removeEventListener("touchend", this.touchEndListener);
    }
  }

  goToStep(event) {
    const step = parseInt(event.target.dataset.step);
    if (step && step !== this.step) {
      this.activateStep(step);
    }
  }

  nextStep() {
    if (this.step < 5) {
      this.activateStep(this.step + 1);
    }
  }

  prevStep() {
    if (this.step > 1) {
      this.activateStep(this.step - 1);
    }
  }

  activateStep(step) {
    this.step = step;
    this.updateDisplay(step);
    this.updateButtons();
  }

  updateDisplay(step) {
    this.stepTargets.forEach((stepEl, index) => {
      const stepNum = index + 1;
      if (stepNum === step) {
        stepEl.classList.add("highlighted");
        stepEl.style.backgroundColor = "#FFF3CD";
        stepEl.style.borderLeftColor = "#E06540";
        stepEl.style.transform = "translateX(8px)";
        stepEl.style.fontWeight = "bold";
        stepEl.style.opacity = "1";
        stepEl.style.boxShadow = "0 4px 12px rgba(224, 101, 64, 0.2)";
      } else if (stepNum < step) {
        stepEl.classList.add("completed");
        stepEl.classList.remove("highlighted");
        stepEl.style.backgroundColor = "#D4EDDA";
        stepEl.style.borderLeftColor = "#28A745";
        stepEl.style.transform = "translateX(0px)";
        stepEl.style.fontWeight = "normal";
        stepEl.style.opacity = "0.8";
        stepEl.style.boxShadow = "0 2px 8px rgba(40, 167, 69, 0.1)";
      } else {
        stepEl.classList.remove("highlighted", "completed");
        stepEl.style.backgroundColor = "transparent";
        stepEl.style.borderLeftColor = "transparent";
        stepEl.style.transform = "translateX(0px)";
        stepEl.style.fontWeight = "normal";
        stepEl.style.opacity = "0.6";
        stepEl.style.boxShadow = "none";
      }
    });

    const data = this.stepData[step];
    if (data) {
      if (this.imageTarget) {
        this.imageTarget.style.opacity = "0";
        this.imageTarget.style.transform = "scale(0.9)";
        setTimeout(() => {
          this.imageTarget.src = data.imageSrc;
          this.imageTarget.alt = `Project step ${step}`;
          this.imageTarget.style.opacity = "1";
          this.imageTarget.style.transform = "scale(1)";
        }, 200);
      }

      if (this.previewTarget) {
        this.previewTarget.className = this.previewTarget.className.replace(
          /from-\w+-\d+\s+to-\w+-\d+/g,
          data.bgGradient
        );
      }
    }
  }

  updateButtons() {
    if (this.hasbackTarget) {
      this.backTarget.style.opacity = this.step > 1 ? "1" : "0.5";
      this.backTarget.disabled = this.step <= 1;
    }

    if (this.hasnextTarget) {
      this.nextTarget.style.opacity = this.step < 5 ? "1" : "0.5";
      this.nextTarget.disabled = this.step >= 5;
    }

    if (this.hasStepIndicatorTarget) {
      this.stepIndicatorTarget.textContent = this.step;
    }
  }
}
