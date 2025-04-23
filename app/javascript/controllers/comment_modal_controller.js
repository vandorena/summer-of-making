import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["warning", "commentForm"]

  connect() {
    const updateId = this.element.closest("[id^='comment-modal-']")?.id.replace('comment-modal-', '');
    
    if (updateId) {
      this.updateId = updateId;
    }
  }

  next() {
    this.warningTarget.remove();
    this.commentFormTarget.classList.remove("hidden");
    const firstInput = this.commentFormTarget.querySelector("textarea");
    if (firstInput) firstInput.focus();
  }
}