import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggle(event) {
    event.stopPropagation()
    const isOpen = this.panelTarget.classList.toggle("is-open")
    if (isOpen) {
      document.addEventListener("click", this.closeOnOutsideClick)
    } else {
      document.removeEventListener("click", this.closeOnOutsideClick)
    }
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.panelTarget.classList.remove("is-open")
      document.removeEventListener("click", this.closeOnOutsideClick)
    }
  }
}
