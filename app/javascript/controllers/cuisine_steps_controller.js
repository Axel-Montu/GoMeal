import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.activate(this.cardTargets[0])
  }

  selectBranch(event) {
    event.preventDefault()
    const card = this.cardTargets.find((card) => card.dataset.category === event.params.category)
    if (card && card !== this.activeCard) this.transitionTo(card)
  }

  transitionTo(nextCard) {
    const previous = this.activeCard
    if (previous) {
      previous.classList.remove("cuisine-card--active")
      previous.classList.add("cuisine-card--leaving")
      const clear = (event) => {
        if (event.propertyName !== "opacity") return
        previous.classList.remove("cuisine-card--leaving")
        previous.removeEventListener("transitionend", clear)
      }
      previous.addEventListener("transitionend", clear)
    }
    this.activate(nextCard)
  }

  activate(card) {
    card.classList.add("cuisine-card--active")
    this.activeCard = card
  }
}
