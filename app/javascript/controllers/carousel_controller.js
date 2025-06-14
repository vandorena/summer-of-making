import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];
  static values = { row: Number };

  connect() {
    this.dupertrooper();
    this.startSeamlessScroll();
  }

  dupertrooper() {
    const all = Array.from(this.containerTarget.children);
    const row = this.rowValue || 1;

    const filtered = all.filter((s, i) => {
      if (row === 1) {
        return i % 2 === 0;
      } else {
        return i % 2 === 1;
      }
    });

    this.containerTarget.innerHTML = "";
    filtered.forEach((s) => {
      this.containerTarget.appendChild(s);
    });

    // Double the items for seamless looping
    const count = filtered.length;
    for (let i = 0; i < count; i++) {
      const clone = filtered[i].cloneNode(true);
      this.containerTarget.appendChild(clone);
    }
  }

  startSeamlessScroll() {
    const track = this.containerTarget;
    if (!track) return;
    // Reset any previous state
    track.style.transition = "none";
    track.style.transform = "translateX(0)";

    // Wait for next frame to allow transition to be set
    requestAnimationFrame(() => {
      const firstSetWidth = track.scrollWidth / 2;
      track.style.transition = "transform 30s linear";
      track.style.transform = `translateX(-${firstSetWidth}px)`;

      // Listen for transition end to reset
      track.addEventListener(
        "transitionend",
        () => {
          track.style.transition = "none";
          track.style.transform = "translateX(0)";
          // Force reflow
          void track.offsetWidth;
          // Restart animation
          track.style.transition = "transform 30s linear";
          track.style.transform = `translateX(-${firstSetWidth}px)`;
        },
        { once: true }
      );
    });
  }
}
