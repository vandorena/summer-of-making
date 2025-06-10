import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["collapseIcon"];
  static values = {
    collapsed: { type: Boolean, default: false },
  };

  connect() {
    const s = localStorage.getItem("sidebarCollapsed");
    if (s === "true") {
      this.collapsedValue = true;
      if (this.hasCollapseIconTarget) {
        this.collapseIconTarget.classList.add("rotate-180");
      }
    }
    this.u();
  }

  toggle(e) {
    if (e) {
      e.stopPropagation();
    }
    this.collapsedValue = !this.collapsedValue;
    localStorage.setItem("sidebarCollapsed", this.collapsedValue);
    if (this.hasCollapseIconTarget) {
      this.collapseIconTarget.classList.toggle(
        "rotate-180",
        this.collapsedValue
      );
    }
  }

  collapsedValueChanged() {
    this.u();
  }

  u() {
    document.querySelectorAll("[data-sidebar-collapsed]").forEach((e) => {
      e.setAttribute("data-sidebar-collapsed", this.collapsedValue);
    });
  }
}
