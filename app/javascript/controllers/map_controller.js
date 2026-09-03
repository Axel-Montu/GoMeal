import { Controller } from "@hotwired/stimulus"
import * as maplibregl from "maplibre-gl"
import consumer from "channels/consumer"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    center: Array,
    zoom: Number,
    route: Object,
    matchId: Number
  }

  connect() {
    // 1. Build the map inside this element. OpenFreeMap tiles need no token.
    this.map = new maplibregl.Map({
      container: this.element,
      style: "https://tiles.openfreemap.org/styles/liberty",
      center: this.centerValue,
      zoom: this.zoomValue,
      attributionControl: false
    })

    // 2. Route, live wiring and geolocation watching all need the map ready:
    //    layers cannot be added before load, and the marker to move must exist
    //    before broadcasts start arriving.
    this.map.on("load", () => {
      this.#drawRoute()
      this.#subscribeToLocationChannel()
      this.#startWatchingPosition()
    })
  }

  disconnect() {
    // 3. Stop pushing positions on Turbo navigation
    if (this.watchId !== undefined) navigator.geolocation.clearWatch(this.watchId)
    // 4. Drop the subscription so Turbo does not leave it dangling on nav
    if (this.subscription) this.subscription.unsubscribe()
    // 5. Destroy the map, so Turbo does not leave one running in the background
    this.map.remove()
  }

  #drawRoute() {
    // 6. No geometry means no route: the map stays, the line does not
    if (!this.hasRouteValue || !this.routeValue.type) return

    // 7. The geometry is already GeoJSON — it goes in as a source unchanged
    this.map.addSource("route", {
      type: "geojson",
      data: { type: "Feature", geometry: this.routeValue }
    })

    // 8. Paint that source as a line
    this.map.addLayer({
      id: "route",
      type: "line",
      source: "route",
      paint: { "line-width": 5, "line-color": "#ef7308" }
    })

    const coordinates = this.routeValue.coordinates
    const theme = getComputedStyle(document.documentElement)

    // 9. The user marker is kept as an instance field so live broadcasts
    //    can move it later — the destination one stays anonymous.
    this.userMarker = new maplibregl.Marker({
      color: theme.getPropertyValue("--color-secondary").trim(),
      scale: 0.75
    }).setLngLat(coordinates[0]).addTo(this.map)

    new maplibregl.Marker({
      color: theme.getPropertyValue("--color-primary").trim()
    }).setLngLat(coordinates.at(-1)).addTo(this.map)

    // 10. Frame both ends of the line, with room so neither touches an edge
    const bounds = new maplibregl.LngLatBounds(coordinates[0], coordinates[0])
    coordinates.forEach((point) => bounds.extend(point))
    this.map.fitBounds(bounds, { padding: 60 })
  }

  #subscribeToLocationChannel() {
    // 11. stream_for current_user on the server side — no channel params needed
    this.subscription = consumer.subscriptions.create("LocationChannel", {
      received: (data) => this.#onPositionBroadcast(data)
    })
  }

  #onPositionBroadcast(data) {
    // 12. Move the user marker to the new position
    if (this.userMarker && data.user_position) {
      this.userMarker.setLngLat(data.user_position)
    }
    // 13. Replace the route line if a fresh geometry came with the broadcast.
    //     A null geometry (ORS failed) leaves the previous line in place —
    //     stale is better than blank.
    if (data.geometry && this.map.getSource("route")) {
      this.map.getSource("route").setData({
        type: "Feature",
        geometry: data.geometry
      })
    }
  }

  #startWatchingPosition() {
    // 14. Silent fallback when geolocation is unavailable or refused: the
    //     route stays static, the map still works.
    if (!("geolocation" in navigator)) return

    this.lastSentAt = 0
    this.lastSentCoords = null

    this.watchId = navigator.geolocation.watchPosition(
      (position) => this.#onPositionChange(position),
      () => {},
      { enableHighAccuracy: true, maximumAge: 5000 }
    )
  }

  #onPositionChange(position) {
    const now = Date.now()
    const coords = [position.coords.longitude, position.coords.latitude]

    // 15. Throttle: send only if 10s elapsed OR the user moved more than 20m.
    //     Protects the ORS quota and avoids spamming broadcasts.
    const enoughTime = now - this.lastSentAt > 10_000
    const enoughDistance =
      !this.lastSentCoords ||
      this.#haversineMeters(this.lastSentCoords, coords) > 20

    if (!enoughTime && !enoughDistance) return

    this.lastSentAt = now
    this.lastSentCoords = coords
    this.#pushPosition(coords)
  }

  #pushPosition([longitude, latitude]) {
    // 16. CSRF token lives in the `content` attribute of the meta tag, not
    //     its text content — meta elements have none.
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/locations", {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrf
      },
      body: JSON.stringify({
        latitude,
        longitude,
        go_meal_match_id: this.matchIdValue
      })
    })
  }

  #haversineMeters(a, b) {
    // 17. Great-circle distance between two [lng, lat] points, in meters.
    //     Duplicates the Ruby haversine_meters in GoMealScorer — kept in JS
    //     because the throttle must run before any request goes out.
    const [lng1, lat1] = a
    const [lng2, lat2] = b
    const R = 6_371_000
    const toRad = (deg) => (deg * Math.PI) / 180
    const dLat = toRad(lat2 - lat1)
    const dLng = toRad(lng2 - lng1)
    const h =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2
    return 2 * R * Math.asin(Math.sqrt(h))
  }
}
