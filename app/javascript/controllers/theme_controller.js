import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "gomeal-theme"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this.closeOnOutsideClick = this.closeOnOutsideClick.bind(this)
    const saved = localStorage.getItem(STORAGE_KEY) || "default"
    this.apply(saved)
  }

  disconnect() {
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  toggleMenu(event) {
    event.stopPropagation()
    const isOpen = this.menuTarget.classList.toggle("is-open")
    if (isOpen) {
      document.addEventListener("click", this.closeOnOutsideClick)
    } else {
      document.removeEventListener("click", this.closeOnOutsideClick)
    }
  }

  select(event) {
    const theme = event.currentTarget.dataset.themeName
    this.apply(theme)
    localStorage.setItem(STORAGE_KEY, theme)
    this.menuTarget.classList.remove("is-open")
    document.removeEventListener("click", this.closeOnOutsideClick)
  }

  apply(theme) {
    document.documentElement.dataset.theme = theme === "default" ? "" : theme
  }

  closeOnOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.remove("is-open")
      document.removeEventListener("click", this.closeOnOutsideClick)
    }
  }
}
