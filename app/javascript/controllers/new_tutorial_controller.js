import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "background", "dialogue", "focus"]
  static values = {
    displayName: String
  }

  connect() {
    this.dialogue = [
      // intro
      `Psst! Hey there! <span class="new-tutorial-shake">${this.displayNameValue || "Hey"}!</span>`,
      `Welcome to the... <span class="new-tutorial-shake">SUMMER OF MAKING!!!</span>`,
      `Oh... I don't believe I've introduced myself.<br>I'm Explorpheus!`,
      `I'm here to guide you through everything you need to know to start shipping and earning <span class="new-tutorial-bling">prizes</span>`,
      
      // campfire
      `You're currently at the Campfire! This is where the latest news is shared!`,
      `You should check back here every once in a while! There's always so much happening on the island!`,

      // currency
      `Shells are our currency here. You can get so much cool stuff with them, but to get 'em, you gotta...`,
      `<span class="new-tutorial-shake">Build cool projects and ship them!</span>`,
      `Awesome! Let's dive a bit deeper!`,

      // step by step flow - video skips this part
      `Come up with a cool project idea. Make it something you've always wanted to build.`,
      `Start building! Track how much time you spent with Hackatime.`,
      `As you build, post <span class="new-tutorial-shake">devlogs</span>! They're mini updates on your progress.`,
      `Once it's ready, <span class="new-tutorial-shake">ship</span> it to the world! It doesn't have to be perfect. A MVP is okay!`,
      `Our shipwrights will make sure your project is working. They'll give you feedback!`,
      `Your project will then be voted on by the community. You'll vote on others' projects as well.`,
      `You'll earn shells depending on the number of votes and how long you've worked on your project.`,
      `You can spend these shells in our shop for awesome prizes!`,
      `Alright, that was quite the ramble...`,

      // hackatime
      `Don't worry if this is confusing, I'll walk you through each step`
    ];
    this.focusedIds = [
      // intro
      '',
      '',
      '',
      '',

      //campfire
      'new-tutorial-campfire-title',
      'new-tutorial-campfire-title',

      // currency
      '',
      '',
      '',

      // step by step flow
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',

      // hackatime
      ''
    ]
    // x, y, width, height are offsets
    this.focusAttributes = [
      // intro
      {},
      {},
      {},
      {},

      // campfire
      {x: 0, y: 10, width: 50, height: -50, radius: 20},
      {x: 0, y: 10, width: 50, height: -50, radius: 20},

      // currency
      {},
      {},
      {},

      // step by step flow
      {},
      {},
      {},
      {},
      {},
      {},
      {},
      {},
      {},

      // hackatime
      {}
    ]
    this.progress = 0;
    this.initialDelay = 750;
    this.nextDelay = 500;
    this.lastClickedNext = Date.now();
    this.textTarget.innerHTML = this.dialogue[this.progress];
    this.focusedElement = this.focusedIds[this.progress] ? document.getElementById(this.focusedIds[this.progress]) : null;

    this.updateFocus();

    // click to advance elements
    this.backgroundTarget.addEventListener("click", () => this.advance());
    this.dialogueTarget.addEventListener("click", () => this.advance());

    // update focus when window size changes, the user scrolls, or resizes
    window.addEventListener("resize", () => this.updateFocus());
    document.addEventListener("scroll", () => this.updateFocus());
  }

  disconnect() {
    this.backgroundTarget.removeEventListener("click", () => this.advance());
    this.dialogueTarget.removeEventListener("click", () => this.advance());
    window.removeEventListener("resize", () => this.updateFocus());
    document.removeEventListener("scroll", () => this.updateFocus());
  }

  updateFocus() {
    this.focusedElement = this.focusedIds[this.progress] ? document.getElementById(this.focusedIds[this.progress]) : null;
    if (this.focusedElement) {
      const rect = this.focusedElement.getBoundingClientRect();
      this.dialogueFocus = {
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
        radius: 0,
        z: true
      };
      const attributes = this.focusAttributes[this.progress];
      this.dialogueFocus.x += (attributes.x ?? 0) - (attributes.width ?? 0) / 2;
      this.dialogueFocus.y += (attributes.y ?? 0) - (attributes.height ?? 0) / 2;
      this.dialogueFocus.width += (attributes.width ?? 0);
      this.dialogueFocus.height += (attributes.height ?? 0);
      this.dialogueFocus.radius += (attributes.radius ?? 0);
      this.dialogueFocus.z = attributes.z ?? true;
    } else {
      this.dialogueFocus = {
        x: 0,
        y: 0,
        width: 0,
        height: 0,
        radius: 0,
        z: true
      };
    }

    this.focusTarget.setAttribute("x", this.dialogueFocus.x);
    this.focusTarget.setAttribute("y", this.dialogueFocus.y);
    this.focusTarget.setAttribute("width", this.dialogueFocus.width);
    this.focusTarget.setAttribute("height", this.dialogueFocus.height);
    this.focusTarget.setAttribute("rx", this.dialogueFocus.radius);
    this.focusTarget.setAttribute("ry", this.dialogueFocus.radius);

    if (this.focusedElement) {
      if (this.dialogueFocus.z) {
        this.focusedElement.style.zIndex = 100;
      } else {
        this.focusedElement.style.zIndex = "";
      }
    }

  }

  advance() {
    if (Date.now() - this.lastClickedNext < (this.progress == 0 ? this.initialDelay : this.nextDelay)) {
      console.log("Clicked too soon");
      return;
    }
    this.lastClickedNext = Date.now();
    this.progress++;
    if (this.progress < this.dialogue.length) {
      this.textTarget.innerHTML = this.dialogue[this.progress];
      if (this.focusedElement) {
        this.focusedElement.style.zIndex = "";
      }
      this.focusedElement = this.focusedIds[this.progress] ? document.getElementById(this.focusedIds[this.progress]) : null;
      this.updateFocus();
    }
  }
}
