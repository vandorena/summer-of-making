import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["text", "form", "error"]

  connect() {
    
    if (this.hasTextTarget) {
      this.originalText = this.textTarget.dataset.originalText
      
      if (this.hasFormTarget) {
        this.formTarget.addEventListener('submit', this.validateBeforeSubmit.bind(this))
      } else {
        const form = this.element.querySelector('form')
        if (form) {
          form.addEventListener('submit', this.validateBeforeSubmit.bind(this))
        }
      }
    }
  }
  
  open() {
    this.element.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    
    if (this.hasTextTarget) {
      setTimeout(() => this.textTarget.focus(), 100)
    }
  }
  
  close() {
    this.element.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  validateBeforeSubmit(event) {
    if (!this.hasTextTarget && !this.element.querySelector('textarea')) {
      return true
    }
    
    const textarea = this.hasTextTarget ? this.textTarget : this.element.querySelector('textarea')
    const currentText = textarea.value
    const originalText = this.originalText || textarea.dataset.originalText
    
    if (!this.isFormattingChangeOnly(originalText, currentText)) {
      event.preventDefault()
      
      this.showError("You can only change formatting (markdown, spaces, line breaks). You cannot add or remove text content.")
      
      textarea.classList.add('border-vintage-red')
      
      setTimeout(() => {
        textarea.value = originalText;
      }, 500);
      
      return false
    }
    
    return true
  }

  isFormattingChangeOnly(original, updated) {
    if (!original || !updated) {
      return false
    }
    
    const stripFormatting = (text) => {
      return text
        .replace(/[\s\n\r\t\*\_\#\~\`\>\<\-\+\.\,\;\:\!\?\(\)\[\]\{\}]/g, '')
        .toLowerCase()
    }
    
    const originalStripped = stripFormatting(original)
    const updatedStripped = stripFormatting(updated)
    
    return originalStripped === updatedStripped
  }
  
  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    } else {

      const errorElement = document.createElement('p')
      errorElement.className = 'edit-error-message text-sm text-vintage-red mt-2'
      errorElement.textContent = message
      
      const textarea = this.hasTextTarget ? this.textTarget : this.element.querySelector('textarea')
      if (textarea) {
        const textareaContainer = textarea.closest('.space-y-2')
        if (textareaContainer) {
          textareaContainer.appendChild(errorElement)
        }
      }
    }
  }
} 