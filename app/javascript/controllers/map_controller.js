import { Controller } from "@hotwired/stimulus"
import * as maplibregl from "maplibre-gl"

// Connects to data-controller="map"
export default class extends Controller {
  static values = { center: Array, zoom: Number, route: Object }

  connect() {
    // 1. Build the map inside this element. OpenFreeMap tiles need no token.
    this.map = new maplibregl.Map({
      container: this.element,
      style: "https://tiles.openfreemap.org/styles/liberty",
      center: this.centerValue,
      zoom: this.zoomValue
    })
    // 3. Draw the route once the map is ready — layers cannot be added before
    this.map.on("load", () => this.#drawRoute())
  }
  #drawRoute() {
    // 4. No geometry means no route: the map stays, the line does not
    if (!this.hasRouteValue || !this.routeValue.type) return

    // 5. The geometry is already GeoJSON — it goes in as a source unchanged
    this.map.addSource("route", {
      type: "geojson",
      data: { type: "Feature", geometry: this.routeValue }
    })

    // 6. Paint that source as a line
    this.map.addLayer({
      id: "route",
      type: "line",
      source: "route",
      paint: { "line-width": 5, "line-color": "#ef7308" }
    })

    // 7. Frame both ends of the line, with room so neither touches an edge
    const coordinates = this.routeValue.coordinates
    const bounds = new maplibregl.LngLatBounds(coordinates[0], coordinates[0])
    coordinates.forEach((point) => bounds.extend(point))
    this.map.fitBounds(bounds, { padding: 60 })
  }
  
  disconnect() {
    // 2. Destroy the map, so Turbo does not leave one running in the background
    this.map.remove()
  }
}
