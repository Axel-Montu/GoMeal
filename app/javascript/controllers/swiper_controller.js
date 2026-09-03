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
    // Reference vers la carte que le user est en train de manipuler.
    // On la capture au touchStart parce qu'au touchEnd, swiper.activeIndex
    // a deja bascule sur la carte suivante et on flasherait la mauvaise.
    this.dragCard = null
    this.dragStartIndex = null

    // Swiper doit s'initialiser sur .swiper.swipe-deck (le vrai container),
    // pas sur .swipe-deck-wrapper qui porte maintenant le controller pour que
    // l'overlay (position: fixed) puisse echapper au perspective pose par
    // l'effet "cards".
    this.swiper = new Swiper(this.deckTarget, {
      effect: "cards",
      grabCursor: true,
      on: {
        touchStart: (swiper) => {
          this.dragCard = swiper.slides[swiper.activeIndex]
          this.dragStartIndex = swiper.activeIndex
        },
        touchMove: (swiper) => this.updateFlash(swiper),
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
    const card = this.dragCard
    const startIndex = this.dragStartIndex
    this.dragCard = null
    this.dragStartIndex = null
    if (!card) return

    // swiper.swipeDirection est pose des le premier pixel de drag et n'est
    // jamais efface quand la carte snap back sous le seuil : s'y fier ferait
    // partir un reject fantome (et laisserait l'overlay rouge en place). On
    // regarde donc si activeIndex a vraiment bouge. Notre callback est emit
    // AVANT le slideTo interne de Swiper, d'ou le rAF pour lire l'index final.
    requestAnimationFrame(() => {
      if (swiper.activeIndex === startIndex) {
        this.resetFlash(card)
        return
      }

      const action = swiper.activeIndex > startIndex ? "reject" : "like"
      // Sur un reject au drag, l'overlay rouge est deja a son maximum
      // (le user a franchi le seuil) et va s'en aller avec la carte ; pas
      // besoin de rejouer la keyframe flashReject.
      this.decide(card, action, { animate: false })
    })
  }

  // Fait monter le rouge sur la carte manipulee pendant le drag gauche.
  // Cap 0.35 atteint des ~20% de la largeur de carte pour que le signal
  // arrive tres tot ("des qu'on commence a tourner la page").
  updateFlash(swiper) {
    if (!this.dragCard) return
    const flash = this.dragCard.querySelector(".swipe-card__flash")
    if (!flash) return

    const dx = swiper.touches.currentX - swiper.touches.startX
    if (dx >= 0) {
      flash.style.opacity = 0
      return
    }

    const threshold = this.dragCard.offsetWidth * 0.2
    const ratio = Math.min(1, Math.abs(dx) / threshold)
    flash.style.opacity = (ratio * 0.35).toFixed(3)
  }

  // Fade court pour ne pas snap brutalement quand la carte revient a sa
  // place au drag annule.
  resetFlash(card) {
    const flash = card?.querySelector(".swipe-card__flash")
    if (!flash) return
    flash.style.transition = "opacity 220ms ease-out"
    flash.style.opacity = 0
    setTimeout(() => {
      flash.style.transition = ""
      flash.style.opacity = ""
    }, 240)
  }

  like(event) {
    this.decide(this.cardFor(event), "like")
  }

  reject(event) {
    const card = this.cardFor(event)
    this.flashReject(card)
    this.decide(card, "reject")
  }

  // Overlay rouge qui pulse (300ms keyframe) via .is-flashing-reject.
  // On la retire sur animationend pour pouvoir rejouer sur la carte
  // suivante si le user enchaine les rejets vite.
  flashReject(card) {
    if (!card) return
    card.classList.remove("is-flashing-reject")
    // reflow pour redemarrer la keyframe si la classe etait encore la
    void card.offsetWidth
    card.classList.add("is-flashing-reject")
    card.addEventListener(
      "animationend",
      () => card.classList.remove("is-flashing-reject"),
      { once: true }
    )
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
    .catch(() => {
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
