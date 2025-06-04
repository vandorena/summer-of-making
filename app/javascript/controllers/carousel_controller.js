import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];

  connect() {
    // me when there is a p2w minecraft server
    this.dupertrooper();
  }

  dupertrooper() {
    const slides = this.containerTarget.children;
    const count = slides.length;
    for (let i = 0; i < count; i++) {
      const clone = slides[i].cloneNode(true);
      this.containerTarget.appendChild(clone);
    }
  }
}
