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
    Array.from(
      this.containerTarget.querySelectorAll("[data-carousel-clone]")
    ).forEach((el) => el.remove());

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
      clone.setAttribute("data-carousel-clone", "true");
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
      const children = Array.from(track.children);
      const count = children.length / 2; // since we doubled
      let stopIndex = count - 2;
      if (stopIndex < 1) stopIndex = 1;
      let stopOffset = 0;
      for (let i = 0; i < stopIndex; i++) {
        stopOffset += children[i].offsetWidth;
      }
      track.style.transition = "transform 30s linear";
      track.style.transform = `translateX(-${stopOffset}px)`;

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
          track.style.transform = `translateX(-${stopOffset}px)`;
        },
        { once: true }
      );
    });
  }
}
