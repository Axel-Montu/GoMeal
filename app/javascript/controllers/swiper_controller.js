import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"
import gsap from "gsap"
import { DrawSVGPlugin } from "gsap/DrawSVGPlugin"
import { SplitText } from "gsap/SplitText"

gsap.registerPlugin(DrawSVGPlugin, SplitText)

// Connects to data-controller="swiper"

export default class extends Controller {
  static targets = ["deck", "overlay", "overlayLogo", "overlayText"]

  connect() {
    this.locked = false

    // Swiper doit s'initialiser sur .swiper.swipe-deck (le vrai container),
    // pas sur .swipe-deck-wrapper qui porte maintenant le controller pour que
    // l'overlay (position: fixed) puisse echapper au perspective pose par
    // l'effet "cards".
    this.swiper = new Swiper(this.deckTarget, {
      effect: "cards",
      grabCursor: true,
      on: {
        touchEnd: (swiper) => this.handleSwipe(swiper)
      }
    })
  }

  disconnect() {
    this.swiper?.destroy(true, true)
    this.overlayTimeline?.kill()
    this.overlaySplit?.revert()
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
        this.showMatchOverlay(matchId)
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

  // Meme timeline que home_intro_controller : on trace les paths, on remplit,
  // puis on fait entrer les chars du texte. Le redirect est cale sur onComplete
  // pour ne pas couper l'anim si on tune les durees plus tard.
  showMatchOverlay(matchId) {
    if (!this.hasOverlayTarget) {
      window.location.href = `/go_meal_matches/${matchId}`
      return
    }

    const paths = this.overlayLogoTarget.querySelectorAll("path")
    this.overlaySplit = new SplitText(this.overlayTextTarget, {
      type: "chars",
      charsClass: "char"
    })

    gsap.set(paths, { drawSVG: "0%", fillOpacity: 0 })
    gsap.set(this.overlaySplit.chars, { opacity: 0, x: -60 })

    this.overlayTarget.classList.add("is-visible")
    this.overlayTarget.setAttribute("aria-hidden", "false")

    this.overlayTimeline = gsap.timeline({
      defaults: { ease: "expo.out" },
      onComplete: () => {
        window.location.href = `/go_meal_matches/${matchId}`
      }
    })
      .to(paths, {
        drawSVG: "100%",
        duration: 1.5,
        stagger: 0.01
      })
      .to(paths, {
        fillOpacity: 1,
        duration: 1.3,
        stagger: 0.01
      }, "-=1.5")
      .to(this.overlaySplit.chars, {
        opacity: 1,
        x: 0,
        duration: 0.5,
        stagger: 0.06
      }, "-=1.1")
  }
}
