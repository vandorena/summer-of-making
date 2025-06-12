import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["emailInput", "msg"];

  connect() {
    this.emailInputTarget.addEventListener("input", () => {
      this.hideError();
    });
  }

  async startWizard() {
    const x = this.emailInputTarget.value.trim();

    this.hideError();

    if (!x) {
      this.error("pls enter your email");
      this.emailInputTarget.focus();
      return;
    }

    if (!this.isValidEmail(x)) {
      this.error("pls enter a valid email address");
      this.emailInputTarget.focus();
      return;
    }

    const button = document.querySelector(
      '[data-action="click->signup-form#startWizard"]'
    );
    const originalText = button ? button.textContent : "";

    if (button) {
      button.textContent = "Sending your invite...";
      button.disabled = true;
      button.classList.add("opacity-75");
    }

    try {
      await this.sendEmail(x);

      if (button) {
        button.textContent = originalText;
        button.disabled = false;
        button.classList.remove("opacity-75");
      }

      const y = document.getElementById("signup-wizard");
      if (y) {
        const z = this.application.getControllerForElementAndIdentifier(
          y,
          "signup-wizard"
        );
        if (z) {
          z.emailValue = x;
          z.emailSent = true;

          y.classList.remove("hidden");
          document.body.classList.add("overflow-hidden");

          z.initialize();
        } else {
          y.classList.remove("hidden");
          document.body.classList.add("overflow-hidden");
        }
      }
    } catch (error) {
      if (button) {
        button.textContent = originalText;
        button.disabled = false;
        button.classList.remove("opacity-75");
      }
      this.error("Failed to send email. Please try again.");
    }
  }

  async sendEmail(email) {
    let csrfToken = "";
    const metaTag = document.querySelector('meta[name="csrf-token"]');
    if (metaTag) {
      csrfToken = metaTag.content;
    }

    const response = await fetch("/sign-up", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({ email: email }),
    });

    if (!response.ok) {
      throw new Error("Failed to send email");
    }

    return await response.json();
  }

  isValidEmail(a) {
    const b = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return b.test(a);
  }

  error(message) {
    if (this.hasMsgTarget) {
      this.msgTarget.textContent = message;
      this.msgTarget.classList.remove("hidden");
    }
  }

  hideError() {
    if (this.hasMsgTarget) {
      this.msgTarget.classList.add("hidden");
    }
  }
}
