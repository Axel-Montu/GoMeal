import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"
// swiper-bundle (voir config/importmap.rb) enregistre déjà tous les modules ;
// le CSS est chargé via <link> dans application.html.erb.

// Connects to data-controller="swiper"
// Tinder-style restaurant deck: drag or tap the buttons to like / skip a match.
export default class extends Controller {
  static targets = ["swiper", "counter", "actions", "empty"]

  connect() {
    try {
      this.remaining = this.swiperTarget.querySelectorAll(".swiper-slide").length
      this.locked = false

      this.swiper = new Swiper(this.swiperTarget, {
        effect: "cards",
        grabCursor: true,
        watchSlidesProgress: true,
        cardsEffect: { perSlideOffset: 4, perSlideRotate: 0, slideShadows: false },
        on: {
          setTranslate: () => this.paintStamps(),
          touchEnd: (swiper) => this.onTouchEnd(swiper),
          transitionEnd: () => this.clearStamps()
        }
      })

      if (this.remaining === 0) this.showEmpty()
    } catch (e) {
      console.error("[swiper] init failed:", e)
    }
  }

  disconnect() {
    this.swiper?.destroy(true, true)
  }

  // --- pointer feedback -----------------------------------------------------

  paintStamps() {
    const card = this.currentCard
    if (!card || this.swiper.animating) return

    const width = this.swiperTarget.offsetWidth || 1
    const t = this.swiper.touches
    const shift = t ? t.currentX - t.startX : 0
    const ratio = Math.max(-1, Math.min(1, shift / (width * 0.4)))

    this.setStamp(card, ".swipe-card__stamp--like", ratio > 0 ? ratio : 0)
    this.setStamp(card, ".swipe-card__stamp--nope", ratio < 0 ? -ratio : 0)
  }

  setStamp(card, selector, opacity) {
    const el = card.querySelector(selector)
    if (el) el.style.opacity = opacity.toFixed(2)
  }

  clearStamps() {
    this.element.querySelectorAll(".swipe-card__stamp").forEach((el) => (el.style.opacity = 0))
  }

  onTouchEnd(swiper) {
    const direction = swiper.swipeDirection
    if (!direction || this.locked) return this.clearStamps()
    // "prev" = dragged right = like, "next" = dragged left = skip
    direction === "prev" ? this.like() : this.reject()
  }

  // --- decisions ----------------------------------------------------------

  like(event) {
    event?.preventDefault()
    const card = this.currentCard
    if (!card || this.locked) return
    this.flash(card, "is-liking")
    this.decide(card.dataset.matchId, "like")
  }

  reject(event) {
    event?.preventDefault()
    const card = this.currentCard
    if (!card || this.locked) return
    this.flash(card, "is-rejecting")
    this.decide(card.dataset.matchId, "reject")
  }

  details(event) {
    event?.preventDefault()
    const card = this.currentCard
    if (card) window.location.href = `/go_meal_matches/${card.dataset.matchId}`
  }

  decide(matchId, action) {
    this.locked = true

    fetch(`/go_meal_matches/${matchId}/${action}`, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
        "Content-Type": "application/json",
        "Accept": "application/json"
      }
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Request rejected (${response.status})`)
        if (action === "like") {
          window.location.href = `/go_meal_matches/${matchId}`
          return
        }
        this.advance()
      })
      .catch((error) => {
        console.error(error)
        this.locked = false
      })
  }

  advance() {
    this.clearStamps()
    this.remaining = Math.max(0, this.remaining - 1)
    if (this.hasCounterTarget) this.counterTarget.textContent = this.remaining

    if (this.remaining === 0) {
      this.showEmpty()
    } else {
      this.swiper.slideNext(260)
    }
    this.locked = false
  }

  showEmpty() {
    this.swiperTarget.setAttribute("hidden", "")
    if (this.hasActionsTarget) this.actionsTarget.setAttribute("hidden", "")
    if (this.hasEmptyTarget) this.emptyTarget.removeAttribute("hidden")
  }

  flash(card, klass) {
    card.classList.add(klass)
  }

  get currentCard() {
    return this.swiper?.slides?.[this.swiper.activeIndex] || null
  }
}
