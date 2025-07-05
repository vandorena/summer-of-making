import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.apply()
  }

  apply() {
    const cx = Math.random() * 40 + 30;
    const cy = Math.random() * 40 + 30;
    this.element.style.background = `radial-gradient(circle at ${cx}% ${cy}%, #F6DBBA, #E6D4BE)`;
  }
}
