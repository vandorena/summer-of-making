import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["star"]

  connect() {
    const f = this.element.querySelector('form')
    if (f) {
      f.addEventListener('submit', this.spinStar.bind(this))
    }
  }

  spinStar(event) {
    const s = this.starTarget
    if (s) {
      s.classList.add('star-spin')
      
      setTimeout(() => {
        s.classList.remove('star-spin')
      }, 500)
    }
  }
}
