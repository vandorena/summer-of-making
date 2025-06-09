import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["emailInput"];

  startWizard() {
    const x = this.emailInputTarget.value.trim();

    if (!x) {
      alert("pls enter your email");
      this.emailInputTarget.focus();
      return;
    }

    if (!this.isValidEmail(x)) {
      alert("pls enter a real email");
      this.emailInputTarget.focus();
      return;
    }

    const y = document.getElementById("signup-wizard");
    if (y) {
      const z = this.application.getControllerForElementAndIdentifier(
        y,
        "signup-wizard"
      );
      if (z) {
        z.emailValue = x;
        z.initialize();
      }

      y.classList.remove("hidden");
      document.body.classList.add("overflow-hidden");
    }
  }

  isValidEmail(a) {
    const b = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return b.test(a);
  }
}
