import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]
  static values = { 
    maxLength: { type: Number, default: 200 },
    truncateAt: { type: String, default: "word" }
  }

  connect() {
    this.originalText = this.contentTarget.innerHTML
    this.truncateText()
  }

  truncateText() {
    const text = this.contentTarget.textContent || this.contentTarget.innerText
    
    if (text.length <= this.maxLengthValue) {
      return
    }

    let truncatedText
    if (this.truncateAtValue === "word") {
      const words = text.split(' ')
      let currentLength = 0
      let wordIndex = 0
      
      while (wordIndex < words.length && currentLength + words[wordIndex].length <= this.maxLengthValue) {
        currentLength += words[wordIndex].length + 1
        wordIndex++
      }
      
      truncatedText = words.slice(0, wordIndex).join(' ')
    } else {
      truncatedText = text.substring(0, this.maxLengthValue)
    }

    this.truncatedHTML = this.contentTarget.innerHTML.substring(0, truncatedText.length) + 
      '... <button class="text-nice-blue hover:text-dark-blue font-medium transition-colors duration-200 cursor-pointer hover:underline" data-action="click->read-more#expand">Read more</button>'
    
    this.contentTarget.innerHTML = this.truncatedHTML
    this.isExpanded = false
  }

  expand() {
    this.contentTarget.innerHTML = this.originalText
    this.isExpanded = true
  }
} 