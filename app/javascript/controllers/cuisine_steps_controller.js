import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]

  connect() {
    this.showOnly(this.cardTargets[0])
  }

  selectBranch(event) {
    event.preventDefault()
    const card = this.cardTargets.find((card) => card.dataset.category === event.params.category)
    if (card) this.showOnly(card)
  }

  showOnly(cardToShow) {
    this.cardTargets.forEach((card) => {
      card.hidden = card !== cardToShow
    })
  }
}
