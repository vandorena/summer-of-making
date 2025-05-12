import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]
  
  connect() {
    const hasSkippedHackatimeModal = localStorage.getItem('hasSkippedHackatimeModal');
    
    if (!hasSkippedHackatimeModal) {
      setTimeout(() => {
        if (this.element.classList.contains('hidden')) {
          this.element.classList.remove('hidden');
          document.body.classList.add('overflow-hidden');
        }
      }, 250);
    }
  }
  
  skip() {
    localStorage.setItem('hasSkippedHackatimeModal', 'true');
    this.close();
  }
  
  close() {
    this.element.classList.add('hidden');
    document.body.classList.remove('overflow-hidden');
  }
} 