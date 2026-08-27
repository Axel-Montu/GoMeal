import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"
// Connects to data-controller="swiper"

export default class extends Controller {
  connect() {
    new Swiper(this.element, {
      effect: "cards",
      grabCursor: true,
      on: {
        touchEnd: (swiper) => this.handleSwipe(swiper)
      }
    })
  }

  handleSwipe(swiper) {
    const direction = swiper.swipeDirection
    if (!direction) return

    const matchId = swiper.slides[swiper.activeIndex].dataset.matchId
    const action = direction === "prev" ? "like" : "reject"

    fetch(`/go_meal_matches/${matchId}/${action}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      }
    })
    .then((response) => {
      if (action == "reject") {
      window.location.href = "/"
      } else {
        window.location.href = "/go_meal_matches/:id"
      }
    })
  }
}
