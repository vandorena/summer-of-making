import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["container"];
  static values = { row: Number };

  connect() {
    // me when there is a p2w minecraft server
    this.dupertrooper();
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

    const count = filtered.length;
    for (let i = 0; i < count; i++) {
      const clone = filtered[i].cloneNode(true);
      this.containerTarget.appendChild(clone);
    }
  }
}
