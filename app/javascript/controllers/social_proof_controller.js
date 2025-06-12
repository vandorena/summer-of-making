import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["counter"];

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.animated) {
            this.animateCounters();
            this.animated = true;
          }
        });
      },
      {
        threshold: 0.3,
        rootMargin: "0px 0px -50px 0px",
      }
    );

    this.observer.observe(this.element);
    this.animated = false;
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect();
    }
  }

  animateCounters() {
    this.counterTargets.forEach((counter, index) => {
      const finalValue = counter.textContent.trim();
      const isMonetary = finalValue.includes("$");
      const numericValue = parseInt(finalValue.replace(/[$,]/g, ""));

      counter.textContent = isMonetary ? "$0" : "0";

      setTimeout(() => {
        this.countTo(counter, numericValue, isMonetary);
      }, index * 150);
    });
  }

  countTo(element, target, isMonetary = false) {
    const duration = 2000;
    const steps = 60; // steps
    const increment = target / steps;
    const stepDuration = duration / steps;
    let current = 0;

    const timer = setInterval(() => {
      current += increment;

      if (current >= target) {
        current = target;
        clearInterval(timer);

        element.classList.add("animate-pulse");
        setTimeout(() => {
          element.classList.remove("animate-pulse");
        }, 500);
      }

      const displayValue = Math.floor(current).toLocaleString();
      element.textContent = isMonetary ? `$${displayValue}` : displayValue;
    }, stepDuration);
  }
}
