import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["todoButton"]

  toggle() {
    const todoButton = this.todoButtonTarget
    console.log("Todo button clicked")

  }
} 