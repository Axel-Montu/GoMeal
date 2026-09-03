import { Controller } from "@hotwired/stimulus"
import gsap from "gsap"

export default class extends Controller {
  static targets = ["value"]
  static values = { score: Number, duration: { type: Number, default: 1.4 } }

  connect() {
    const target = Math.max(0, Math.min(100, this.scoreValue))
    const state = { score: 0 }

    this.element.style.setProperty("--score", 0)
    if (this.hasValueTarget) this.valueTarget.firstChild.nodeValue = "0"

    this.tween = gsap.to(state, {
      score: target,
      duration: this.durationValue,
      ease: "expo.out",
      onUpdate: () => {
        this.element.style.setProperty("--score", state.score)
        if (this.hasValueTarget) {
          this.valueTarget.firstChild.nodeValue = Math.round(state.score)
        }
      }
    })
  }

  disconnect() {
    this.tween?.kill()
  }
}
