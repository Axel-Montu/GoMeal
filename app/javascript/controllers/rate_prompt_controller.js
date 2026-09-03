import { Controller } from "@hotwired/stimulus"

// Bottom sheet controller for the "Tu y es allé ?" prompt.
// Opens on connect, and closes on backdrop / × click by posting a dismiss
// to the server (session-scoped, per match) then sliding out.
const CLOSE_ANIMATION_MS = 220

export default class extends Controller {
  static targets = ["sheet", "backdrop"]
  static values = { dismissUrl: String }

  connect() {
    // Two frames so the initial transform:translateY(100%) is committed
    // before we flip .is-open on and let the transition run.
    requestAnimationFrame(() => {
      requestAnimationFrame(() => this.element.classList.add("is-open"))
    })
  }

  async dismiss(event) {
    event?.preventDefault()

    try {
      await fetch(this.dismissUrlValue, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": this.csrfToken,
          "Accept": "application/json"
        },
        credentials: "same-origin"
      })
    } catch (_error) {
      // The server-side dismiss is best-effort. If it fails, the sheet
      // still closes visually so the user is not stuck with it.
    }

    this.element.classList.remove("is-open")
    setTimeout(() => this.element.remove(), CLOSE_ANIMATION_MS)
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content || ""
  }
}
