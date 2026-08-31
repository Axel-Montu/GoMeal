import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"
// Connects to data-controller="swiper"

export default class extends Controller {
  connect() {
    this.locked = false

    this.swiper = new Swiper(this.element, {
      effect: "cards",
      grabCursor: true,
      on: {
        touchEnd: (swiper) => this.handleSwipe(swiper)
      }
    })
  }

  disconnect() {
    this.swiper?.destroy(true, true)
  }

  // Drag : Swiper a deja fait glisser la carte, on n'anime rien nous-memes.
  handleSwipe(swiper) {
    const direction = swiper.swipeDirection
    if (!direction) return

    const card = swiper.slides[swiper.activeIndex]
    const action = direction === "prev" ? "like" : "reject"

    this.decide(card, action, { animate: false })
  }

  like(event) {
    this.decide(this.cardFor(event), "like")
  }

  reject(event) {
    this.decide(this.cardFor(event), "reject")
  }

  // Les boutons vivent dans la carte qu'ils concernent : on remonte depuis le
  // clic plutot que de se fier a activeIndex, qui peut avoir bouge.
  cardFor(event) {
    return event.currentTarget.closest(".swipe-card")
  }

  decide(card, action, { animate = true } = {}) {
    if (!card || this.locked) return
    this.locked = true

    const matchId = card.dataset.matchId
    // .is-liking / .is-rejecting sont definies dans _swiper_card.scss ; on ne
    // les pose que pour un clic, sinon elles ecrasent la transform de Swiper.
    if (animate) card.classList.add(action === "like" ? "is-liking" : "is-rejecting")

    fetch(`/go_meal_matches/${matchId}/${action}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
    })
    .then((response) => {
      if (!response.ok) throw new Error(
        `Request rejected (${response.status})`
      )

      if (action === "like") {
        window.location.href = `/go_meal_matches/${matchId}`
        return
      }

      // Sur un rejet au clic, c'est a nous d'avancer le deck.
      if (animate) this.swiper.slideNext(280)
      this.locked = false
    })
    .catch((e) => {
      console.error(e)
      card.classList.remove("is-liking", "is-rejecting")
      this.locked = false
    })
  }

}
