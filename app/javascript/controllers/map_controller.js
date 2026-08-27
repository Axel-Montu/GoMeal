import { Controller } from "@hotwired/stimulus"
import * as maplibregl from "maplibre-gl"

// Connects to data-controller="map"
export default class extends Controller {
  static values = { center: Array, zoom: Number }

  connect() {
    // 1. Build the map inside this element. OpenFreeMap tiles need no token.
    this.map = new maplibregl.Map({
      container: this.element,
      style: "https://tiles.openfreemap.org/styles/liberty",
      center: this.centerValue,
      zoom: this.zoomValue
    })
  }

  disconnect() {
    // 2. Destroy the map, so Turbo does not leave one running in the background
    this.map.remove()
  }
}
