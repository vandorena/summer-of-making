import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { 
    maxLength: { type: Number, default: 200 },
    projectPath: { type: String, default: "" },
    showProjectNavigation: { type: Boolean, default: false }
  }

  connect() {
    this.originalText = this.contentTarget.innerHTML
    this.truncateText()
    this.isExpanded = false
  }

  navigateToProject(event) {
    if (this.showProjectNavigationValue && this.projectPathValue) {
      // only navigate if we're not clicking on interactive elements (before that we had inline JS with preventPropagation which was kinda jank)
      if (!this.isInteractiveElement(event.target)) {
        window.location.href = this.projectPathValue
      }
    }
  }

  isInteractiveElement(element) {
    const interactiveSelectors = [
      'button', 'a', 'input', 'textarea', 'select',
      '[data-action]', '[onclick]', '.cursor-pointer'
    ]
    
    let current = element
    while (current && current !== this.element) {
      if (interactiveSelectors.some(selector => current.matches && current.matches(selector))) {
        return true
      }
      current = current.parentElement
    }
    return false
  }

  truncateText() {
    // walk the dom to get specifically the text
    let text = [];

    let walk = (el) => {
      for (let child of el.childNodes) {
        if (child instanceof Text) {
          let content = child.textContent.trim();
          if (content.length)
            text.push({ text: content, node: child });
        } else if (child instanceof HTMLElement) {
          walk(child);
        }
      }
    }

    walk(this.contentTarget);

    // split based on aggregated text nodes
    let length = 0;
    let splitAt;
    outer: for (let [nodeIdx, node] of text.map((x, i) => [i, x])) {
      for (let [idx, word] of node.text.split(" ").map((x, i) => [i, x])) {
        length += word.length;
        if (nodeIdx != text.length - 1)
          length += 1;
  
        if (length > this.maxLengthValue) {
          splitAt = { node: node.node, idx, };
          break outer;
        }
      }
    }

    // apply split to dom
    if (splitAt) {
      splitAt.node.textContent = splitAt.node.textContent.split(" ").filter((_, i) => i < splitAt.idx).join(" ");
      
      let node = splitAt.node.parentNode;
      let anchor = splitAt.node;
      while (node != this.contentTarget.parentNode) {
        let reachedAnchor = false;
        for (let child of [...node.childNodes]) {
          if (reachedAnchor) {
            child.remove();
          } else {
            reachedAnchor = child === anchor;
          }
        }
        node = node.parentNode;
        anchor = anchor.parentNode;
      }

      // append read more button
      let splitParent = splitAt.node;
      while (!(splitParent instanceof HTMLElement && ["DIV", "P"].includes(splitParent.tagName))) {
        splitParent = splitParent.parentNode;
      }
      
      splitParent.appendChild(new Text("..."));
      let temp = document.createElement("temp");
      temp.innerHTML = `<button class="text-nice-blue hover:text-dark-blue font-medium transition-colors duration-200 cursor-pointer hover:underline" data-action="click->update-card#expand">Read more</button>`;
      splitParent.appendChild(temp.firstChild);
    }
  }

  expand() {
    this.contentTarget.innerHTML = this.originalText
    this.isExpanded = true
  }
} 