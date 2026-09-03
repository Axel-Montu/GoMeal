import { Controller } from "@hotwired/stimulus"

// Five stars over a hidden field. The field is what the form submits, so the
// server validates a plain integer whatever happens here.
const CAPTIONS = [
  "Touche une étoile pour noter",
  "À éviter",
  "Bof",
  "Correct",
  "Très bien",
  "À refaire demain"
]

export default class extends Controller {
  static targets = ["star", "input", "caption", "submit"]

  connect() {
    // 1. A form re-rendered after an error comes back with its rating
    this.render(Number(this.inputTarget.value) || 0)
  }

  pick(event) {
    // 1. The star that was tapped carries its own rank
    const rating = Number(event.currentTarget.dataset.index)

    // 2. The hidden field is the only thing the server will read
    this.inputTarget.value = rating

    this.render(rating)
  }

  render(rating) {
    // 1. Fill every star up to the rating, leave the others outlined
    this.starTargets.forEach((star, index) => {
      const icon = star.querySelector("i")
      const filled = index < rating
      icon.classList.toggle("fa-solid", filled)
      icon.classList.toggle("fa-regular", !filled)
    })

    // 2. Say the rating in words, so the number is never the only clue
    this.captionTarget.textContent = CAPTIONS[rating]

    // 3. Nothing to submit without a rating
    this.submitTarget.disabled = rating === 0
  }
}
