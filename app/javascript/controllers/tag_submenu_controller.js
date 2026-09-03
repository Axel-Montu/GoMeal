import { Controller } from "@hotwired/stimulus"

// Keeps an already-checked tag visible below its <details> fold even once
// the fold is closed: checking a tag moves its pill out of the fold's list
// and into a sibling "selected" area; unchecking sends it back.
export default class extends Controller {
  static targets = ["list", "selected"]

  toggle(event) {
    const checkbox = event.target
    if (!checkbox.classList.contains("tag-selector")) return

    const tagItem = checkbox.closest(".tag-item")
    if (!tagItem) return

    if (checkbox.checked) {
      this.selectedContainer().appendChild(tagItem)
    } else if (this.hasListTarget) {
      this.listTarget.appendChild(tagItem)
      this.removeSelectedContainerIfEmpty()
    }
  }

  selectedContainer() {
    if (this.hasSelectedTarget) return this.selectedTarget

    const container = document.createElement("div")
    container.classList.add("cuisine-card__tags", "cuisine-card__submenu__selected")
    container.setAttribute("data-tag-submenu-target", "selected")
    this.element.appendChild(container)
    return container
  }

  removeSelectedContainerIfEmpty() {
    if (this.hasSelectedTarget && this.selectedTarget.children.length === 0) {
      this.selectedTarget.remove()
    }
  }
}
