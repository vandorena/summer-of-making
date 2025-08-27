import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "background", "dialogue"]
  static values = {
    displayName: String
  }

  connect() {
    this.dialogue = [
      `Psst! Hey there! <span class="new-tutorial-shake">${this.displayNameValue || "Hey"}!</span>`,
      `Welcome to the... <span class="new-tutorial-shake">SUMMER OF MAKING!!!</span>`,
      `Oh... I don't believe I've introduced myself.`,
      `I'm Explorpheus! I'll guide you through everything you need to know to start shipping and earning <span class="new-tutorial-bling">shells</span>.`
    ];
    this.dialogueProgress = 3;
    this.initialDelay = 500;
    this.nextDelay = 100;
    this.nextLastClickedTime = Date.now();
    this.textTarget.innerHTML = this.dialogue[this.dialogueProgress];

    // click to advance elements
    this.backgroundTarget.addEventListener("click", () => this.advance());
    this.dialogueTarget.addEventListener("click", () => this.advance());
  }

  disconnect() {
    this.backgroundTarget.removeEventListener("click", () => this.advance());
    this.dialogueTarget.removeEventListener("click", () => this.advance());
  }

  advance() {
    if (Date.now() - this.nextLastClickedTime < (this.dialogueProgress == 0 ? this.initialDelay : this.nextDelay)) {
      console.log("Clicked too soon");
      return;
    }
    this.nextLastClickedTime = Date.now();
    this.dialogueProgress++;
    if (this.dialogueProgress < this.dialogue.length) {
      this.textTarget.innerHTML = this.dialogue[this.dialogueProgress];
    }
  }
}
