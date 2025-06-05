// warning, jank code ahead!
// i got no clue whats going on here
// but fuck it we ball
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["step", "preview", "image", "imageContainer"];
  connect() {
    this.step = 1;
    this.slock = false;
    this.isShowcaseActive = false;
    this.lockTimeout = null;
    this.showcaseElement = this.element;
    this.exitCooldown = false;
    this.cooldownTimeout = null;

    this.hasScrolledPast = false;
    this.lastPos = window.pageYOffset;
    this.sBottomPassed = false;

    this.startC = 0;
    this.startL = 0;
    this.startT = Date.now();

    this.going = "down";
    this.hasBeenAboveSection = false;

    this.isPageHidden = false;
    this.ca = 0;
    this.userC = false;

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

    this.setupScrollListener();
    this.checkBrowserCompatibility();
    this.updateDisplay(1);
  }

  checkBrowserCompatibility() {
    try {
      this.supportsPassive = false;
      const opts = Object.defineProperty({}, "passive", {
        get: () => {
          this.supportsPassive = true;
        },
      });
      window.addEventListener("testPassive", null, opts);
      window.removeEventListener("testPassive", null, opts);

      this.supportsIntersectionObserver = "IntersectionObserver" in window;

      this.supportsRAF = "requestAnimationFrame" in window;

      if (!this.supportsRAF) {
        this.throttleDelay = 50;
      } else {
        this.throttleDelay = 16;
      }

      this.inIframe = window.self !== window.top;
      if (this.inIframe) {
      }
    } catch (error) {
      this.supportsPassive = false;
      this.supportsIntersectionObserver = false;
      this.supportsRAF = false;
      this.throttleDelay = 100;
    }
  }

  disconnect() {
    if (this.scrollListener) {
      window.removeEventListener("scroll", this.scrollListener);
    }
    if (this.wheelListener) {
      window.removeEventListener("wheel", this.wheelListener);
    }
    if (this.keyListener) {
      window.removeEventListener("keydown", this.keyListener);
    }
    if (this.keyJumpListener) {
      window.removeEventListener("keydown", this.keyJumpListener);
    }
    if (this.resizeListener) {
      window.removeEventListener("resize", this.resizeListener);
    }
    if (this.popstateListener) {
      window.removeEventListener("popstate", this.popstateListener);
    }
    if (this.orientationListener) {
      window.removeEventListener("orientationchange", this.orientationListener);
    }
    if (this.visibilityListener) {
      document.removeEventListener("visibilitychange", this.visibilityListener);
    }
    if (this.touchStartListener) {
      document.removeEventListener("touchstart", this.touchStartListener);
    }
    if (this.touchEndListener) {
      document.removeEventListener("touchend", this.touchEndListener);
    }
    if (this.selectionListener) {
      document.removeEventListener("selectionchange", this.selectionListener);
    }
    if (this.contextMenuListener) {
      document.removeEventListener("mousedown", this.contextMenuListener);
    }
    if (this.lockTimeout) {
      clearTimeout(this.lockTimeout);
    }
    if (this.cooldownTimeout) {
      clearTimeout(this.cooldownTimeout);
    }
    document.body.style.overflow = "";
  }

  setupScrollListener() {
    try {
      this.scrollListener = this.throttle(() => {
        try {
          if (this.slock) return;

          this.trackMov();
          this.check1();
          if (this.isShowcaseActive) {
            this.checkTriggers();
          }
        } catch (error) {
          console.warn("Scroll showcase error:", error);
          this.handleError();
        }
      }, this.throttleDelay || 16);

      this.keyJumpListener = (event) => {
        try {
          if (["Home", "End", "PageUp", "PageDown"].includes(event.key)) {
            setTimeout(() => this.rapid(), 100);
          }
        } catch (error) {
          this.handleError();
        }
      };
    } catch (error) {
      this.handleError();
    }

    this.visibilityListener = () => {
      if (document.hidden && this.isShowcaseActive) {
        this.isPageHidden = true;
        this.goodEnding();
      } else if (!document.hidden && this.isPageHidden) {
        this.isPageHidden = false;
        setTimeout(() => {
          this.checkPositionAfterReturn();
        }, 100);
      }
    };

    this.resizeListener = this.throttle(() => {
      if (this.isShowcaseActive) {
        setTimeout(() => {
          this.check1();
        }, 100);
      }
    }, 250);

    this.popstateListener = () => {
      if (this.isShowcaseActive) {
        this.goodEnding();
      }
    };

    this.touchStartY = 0;
    this.touchEndY = 0;

    this.touchStartListener = (event) => {
      if (!this.isShowcaseActive) return;
      this.touchStartY = event.touches[0].clientY;
    };

    this.touchEndListener = (event) => {
      if (!this.isShowcaseActive) return;
      this.touchEndY = event.changedTouches[0].clientY;
      this.handleTouchGesture();
    };

    this.orientationListener = () => {
      if (this.isShowcaseActive) {
        setTimeout(() => {
          this.check1();
        }, 300);
      }
    };

    window.addEventListener(
      "scroll",
      this.scrollListener,
      this.supportsPassive ? { passive: true } : false
    );
    window.addEventListener(
      "keydown",
      this.keyJumpListener,
      this.supportsPassive ? { passive: true } : false
    );
    window.addEventListener(
      "resize",
      this.resizeListener,
      this.supportsPassive ? { passive: true } : false
    );
    window.addEventListener("popstate", this.popstateListener);
    window.addEventListener("orientationchange", this.orientationListener);
    document.addEventListener("visibilitychange", this.visibilityListener);
    document.addEventListener(
      "touchstart",
      this.touchStartListener,
      this.supportsPassive ? { passive: true } : false
    );
    document.addEventListener(
      "touchend",
      this.touchEndListener,
      this.supportsPassive ? { passive: true } : false
    );
  }

  handleTouchGesture() {
    const swipeThreshold = 50;
    const diff = this.touchStartY - this.touchEndY;

    const currentTime = Date.now();
    if (this.lastTouchTime && currentTime - this.lastTouchTime < 200) {
      this.rapidTouchCount = (this.rapidTouchCount || 0) + 1;
      if (this.rapidTouchCount > 4) {
        this.goodEnding();
        return;
      }
    } else {
      this.rapidTouchCount = 0;
    }
    this.lastTouchTime = currentTime;

    if (Math.abs(diff) > swipeThreshold) {
      if (diff > 0) {
        this.nextStep();
      } else {
        this.prevStep();
      }
    }
  }

  rapid() {
    const c = window.pageYOffset;
    const rect = this.showcaseElement.getBoundingClientRect();
    const t = rect.top + c;
    const b = rect.bottom + c;

    if (c < t - window.innerHeight) {
      this.resetT();
    } else if (c > b + window.innerHeight) {
      this.hasScrolledPast = true;
      this.sBottomPassed = true;
    }
  }

  trackMov() {
    const c = window.pageYOffset;
    const rect = this.showcaseElement.getBoundingClientRect();
    const windowHeight = window.innerHeight;

    const goingDown = c > this.lastPos;

    if (goingDown) {
      this.going = "down";
    } else {
      this.going = "up";
    }

    const top = rect.top + c;
    const bot = rect.bottom + c - windowHeight;

    const isAboveSection = c < top - windowHeight * 0.5;

    if (isAboveSection) {
      this.hasBeenAboveSection = true;
    }

    const isPreviewOffScreen = rect.bottom < 0 || rect.top > windowHeight;

    if (!this.sBottomPassed && c > bot) {
      this.sBottomPassed = true;
      this.hasScrolledPast = true;
      this.hasBeenAboveSection = false;
      return;
    }

    if (c > bot && !this.sBottomPassed) {
      this.sBottomPassed = true;
      this.hasScrolledPast = true;
    }

    const z = top - windowHeight * 0.2;

    if (c < z && this.hasScrolledPast) {
      this.hasScrolledPast = false;
      this.sBottomPassed = false;
      this.hasBeenAboveSection = true;

      if (isPreviewOffScreen && this.step !== 1) {
        this.step = 1;
        this.updateDisplay(1);
      }
    }

    this.lastPos = c;
  }
  check1() {
    if (this.exitCooldown) return;
    if (this.hasScrolledPast) return;

    const currentTime = Date.now();
    if (this.startC >= 15) {
      console.log("[showcase] max activations reached");
      return;
    }

    if (currentTime - this.startL < 1000) {
      this.ca++;
      if (this.ca > 3) {
        console.log("[showcase] rapid - starting cooldown");
        this.setEc();
        return;
      }
    } else {
      this.ca = 0;
    }

    if (this.going !== "down" || !this.hasBeenAboveSection) return;

    const rect = this.showcaseElement.getBoundingClientRect();
    const windowHeight = window.innerHeight;

    const shouldActivate =
      rect.top <= windowHeight * 0.3 && rect.bottom >= windowHeight * 0.3;

    if (shouldActivate && !this.isShowcaseActive) {
      this.activateShowcase();
    } else if (!shouldActivate && this.isShowcaseActive) {
      this.deactivate();
    }
  }

  activateShowcase() {
    this.isShowcaseActive = true;
    this.userC = true;
    document.body.style.overflow = "hidden";

    this.startC++;
    this.startL = Date.now();

    console.log("[showcase] active");

    this.setupExitListeners();
  }

  deactivate() {
    this.isShowcaseActive = false;
    this.userC = false;
    document.body.style.overflow = "";

    console.log("[showcase] scroll to engage");
  }

  checkPositionAfterReturn() {
    const currPos = window.pageYOffset;
    const rect = this.showcaseElement.getBoundingClientRect();
    const showcaseTop = rect.top + currPos;
    const sBottom = rect.bottom + currPos;

    if (currPos > sBottom + window.innerHeight) {
      this.hasScrolledPast = true;
      this.sBottomPassed = true;
      console.log("[showcase] 📍 Returned past showcase");
    }
  }

  isPreviewVisible() {
    const rect = this.showcaseElement.getBoundingClientRect();
    const windowHeight = window.innerHeight;

    return rect.bottom > 0 && rect.top < windowHeight;
  }

  setupExitListeners() {
    if (!this.selectionListener) {
      this.selectionListener = () => {
        if (
          this.isShowcaseActive &&
          window.getSelection().toString().length > 0
        ) {
          this.goodEnding();
          console.log("[showcase] 📍 Text selection - auto exit");
        }
      };
      document.addEventListener("selectionchange", this.selectionListener);
    }

    if (!this.contextMenuListener) {
      this.contextMenuListener = (event) => {
        if (this.isShowcaseActive && event.button === 2) {
          this.goodEnding();
          console.log("[showcase] 📍 Context menu - auto exit");
        }
      };
      document.addEventListener("mousedown", this.contextMenuListener);
    }
  }

  goodEnding() {
    this.deactivate();
    this.setEc();
    this.hasScrolledPast = true;
    this.sBottomPassed = true;

    if (!this.isPreviewVisible()) {
      this.step = 1;
      this.updateDisplay(1);
      console.log("[showcase] 📍 Exit with reset - preview off-screen");
    } else {
      console.log("[showcase] 📍 Exit - preview still visible");
    }
  }

  setEc() {
    this.exitCooldown = true;

    if (this.cooldownTimeout) {
      clearTimeout(this.cooldownTimeout);
    }

    this.cooldownTimeout = setTimeout(() => {
      this.exitCooldown = false;
      console.log("[showcase] scroll to engage");
    }, 2000);

    console.log("[showcase] cooldown on");
  }

  checkTriggers() {
    if (!this.isShowcaseActive) return;

    if (!this.wheelListener) {
      this.wheelListener = this.throttle((event) => {
        if (!this.isShowcaseActive || this.slock) return;

        event.preventDefault();

        if (Math.abs(event.deltaY) > 1000) {
          this.goodEnding();
          console.log("[showcase] 📍 Programmatic scroll detected - auto exit");
          return;
        }

        if (event.deltaY > 0) {
          this.nextStep();
        } else {
          this.prevStep();
        }
      }, 300);

      window.addEventListener("wheel", this.wheelListener, { passive: false });
    }

    if (!this.keyListener) {
      this.keyListener = (event) => {
        if (!this.isShowcaseActive || this.slock) return;

        const currentTime = Date.now();
        if (this.lastKeyTime && currentTime - this.lastKeyTime < 100) {
          this.rapidKeyCount = (this.rapidKeyCount || 0) + 1;
          if (this.rapidKeyCount > 5) {
            this.goodEnding();
            console.log("[showcase] 📍 Rapid keys - auto exit");
            return;
          }
        } else {
          this.rapidKeyCount = 0;
        }
        this.lastKeyTime = currentTime;

        switch (event.key) {
          case "ArrowDown":
          case "ArrowRight":
          case " ":
            event.preventDefault();
            this.nextStep();
            break;
          case "ArrowUp":
          case "ArrowLeft":
            event.preventDefault();
            this.prevStep();
            break;
          case "Escape":
            this.goodEnding();
            break;
          case "F5":
          case "F11":
          case "F12":
            this.goodEnding();
            console.log("[showcase] 📍 Function key - auto exit");
            break;
          case "Tab":
            this.goodEnding();
            console.log("[showcase] 📍 Tab navigation - auto exit");
            break;
          case "+":
          case "-":
          case "0":
            if (event.ctrlKey || event.metaKey) {
              this.goodEnding();
              console.log("[showcase] 📍 Zoom control - auto exit");
            }
            break;
        }
      };

      window.addEventListener("keydown", this.keyListener);
    }
  }

  activateStep(step) {
    if (this.slock) return;

    this.step = step;
    this.updateDisplay(step);
    console.log(`[showcase] step ${step} on`);
    this.lockScroll();
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
        }, 250);
      }

      if (this.previewTarget) {
        this.previewTarget.className = this.previewTarget.className.replace(
          /from-\w+-\d+\s+to-\w+-\d+/g,
          data.bgGradient
        );
      }
    }
  }

  lockScroll() {
    this.slock = true;
    if (this.lockTimeout) {
      clearTimeout(this.lockTimeout);
    }

    this.lockTimeout = setTimeout(() => {
      this.slock = false;
    }, 600);
  }

  resetT() {
    this.hasScrolledPast = false;
    this.sBottomPassed = false;
    this.exitCooldown = false;
    this.hasBeenAboveSection = false;
    this.going = "down";
    this.ca = 0;
    this.startC = 0;
    this.rapidKeyCount = 0;
    this.userC = false;
    this.isPageHidden = false;
    if (this.cooldownTimeout) {
      clearTimeout(this.cooldownTimeout);
    }

    this.step = 1;
    this.updateDisplay(1);
  }

  handleError() {
    if (this.isShowcaseActive) {
      this.deactivate();
    }
    this.resetT();

    document.body.style.overflow = "";
  }

  throttle(func, limit) {
    let inThrottle;
    return function () {
      const args = arguments;
      const context = this;
      if (!inThrottle) {
        func.apply(context, args);
        inThrottle = true;
        setTimeout(() => (inThrottle = false), limit);
      }
    };
  }

  goToStep(event) {
    const step = parseInt(event.target.dataset.step);
    if (step && step !== this.step) {
      this.activateStep(step);
      console.log(`[showcase] Manual navigation to step ${step}`);
    }
  }

  nextStep() {
    if (this.slock || this.inprog) return;

    this.inprog = true;
    setTimeout(() => {
      this.inprog = false;
    }, 200);

    if (this.step < 5) {
      this.activateStep(this.step + 1);
    } else if (this.step === 5) {
      this.goodEnding();
    }
  }

  prevStep() {
    if (this.slock || this.inprog) return;

    this.inprog = true;
    setTimeout(() => {
      this.inprog = false;
    }, 200);

    if (this.step > 1) {
      this.activateStep(this.step - 1);
    } else if (this.step === 1) {
      this.goodEnding();
    }
  }
}
