import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.currentIndex = 0
    this.showCurrent()
  }

  next(event) {
    event.preventDefault()
    if (this.currentIndex >= this.cardTargets.length - 1) return
    this.currentIndex += 1
    this.showCurrent()
  }

  showCurrent() {
    this.cardTargets.forEach((card, index) => {
      card.hidden = index !== this.currentIndex
    })
  }
}
