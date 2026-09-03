import { Controller } from "@hotwired/stimulus"

const DISPLAY_DURATION = 1000
const FADE_DURATION = 500

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => this.dismiss(), DISPLAY_DURATION)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  dismiss() {
    this.element.style.transition = `opacity ${FADE_DURATION}ms ease-out`
    this.element.style.opacity = 0
    setTimeout(() => this.element.remove(), FADE_DURATION)
  }
}
