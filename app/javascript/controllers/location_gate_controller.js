import { Controller } from "@hotwired/stimulus"

const options = {
  enableHighAccuracy: true,
  maximumAge: 0
}

// Connects to data-controller="location-gate"
export default class extends Controller {
  static values = { url: String }
  static targets = ["blocked"]

  // 1. Check first: a browser that already remembers "denied" must not
  //    show a pointless prompt-less ask before the blocked message
  connect() {
    this.check()
  }

  async check() {
    if (navigator.permissions?.query) {
      try {
        const status = await navigator.permissions.query({ name: "geolocation" })

        if (status.state === "denied") {
          this.blocked()
          return
        }
      } catch (e) {
        // Permissions API unsupported for this query — fall through to asking directly
      }
    }

    this.ask()
  }

  ask() {
    navigator.geolocation.getCurrentPosition(
      this.success.bind(this),
      this.error.bind(this),
      options
    )
  }

  // 2. Already shared or just granted: either way, save it and move on
  success(pos) {
    const { latitude, longitude } = pos.coords

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ latitude, longitude })
    })
      .then((response) => {
        if (!response.ok) throw new Error("Request rejected")
        return response.json()
      })
      .then((data) => {
        window.location.href = data.redirect_to
      })
      .catch(() => {})
  }

  error() {
    this.blocked()
  }

  blocked() {
    if (this.hasBlockedTarget) this.blockedTarget.hidden = false
  }

  retry() {
    if (this.hasBlockedTarget) this.blockedTarget.hidden = true
    this.ask()
  }
}
