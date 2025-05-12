import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "modalContent", "countdownContent", "instructionsContent", "countdown"]
  
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
  
  connectHackatime() {
    this.modalContentTarget.classList.add('hidden');
    this.countdownContentTarget.classList.remove('hidden');
    
    let count = 3;
    this.countdownTarget.textContent = count;
    
    const countdownInterval = setInterval(() => {
      count--;
      this.countdownTarget.textContent = count;
      
      if (count <= 0) {
        clearInterval(countdownInterval);
        
        window.open('https://hackatime.hackclub.com/', '_blank');
        
        this.countdownContentTarget.classList.add('hidden');
        this.instructionsContentTarget.classList.remove('hidden');
      }
    }, 1000);
  }
} 