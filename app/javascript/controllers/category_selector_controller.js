import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "hiddenField"];
  static values = { selected: String };

  connect() {
    this.updateButtons();
  }

  selectCategory(event) {
    const category = event.currentTarget.dataset.category;
    this.selectedValue = category;
    this.hiddenFieldTarget.value = category;
    this.updateButtons();
  }

  updateButtons() {
    this.buttonTargets.forEach((button) => {
      const isSelected = button.dataset.category === this.selectedValue;
      const underline = button.querySelector('[data-kind="underline"]');

      if (isSelected) {
        underline.classList.remove("opacity-0");
      } else {
        underline.classList.add("opacity-0");
      }
    });
  }
}
