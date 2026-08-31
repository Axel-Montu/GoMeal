import { Controller } from "@hotwired/stimulus"

const options = {
  enableHighAccuracy: true,
  maximumAge: 0
}
// Connects to data-controller="geolocation"
export default class extends Controller {
  static values = { url: String }
  static targets = ["travelTime", "mealTime", "totalTime"]

  // 1. Ask on load, not on click: the tiles must be filled while the user
  //    is still deciding whether to go
  connect() {
    this.search()
  }

  search() {
    navigator.geolocation.getCurrentPosition(
      this.success.bind(this),
      this.error.bind(this),
      options
    )
  }

  success(pos) {
    // 1. The browser gives latitude first — the server expects both by name,
    //    so no order to get wrong here
    const { latitude: lat, longitude: long } = pos.coords

    // 2. Send the position in the body, never in the URL
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ start_latitude: lat, start_longitude: long })
    })
      .then((response) => {
        if (!response.ok) throw new Error("Request rejected")
        return response.json()
      })
            .then((data) => {
        // 3. Fill the tiles the server just computed. A missing value stays
        //    a dash rather than becoming a wrong number.
        if (this.hasTravelTimeTarget && data.travel_time) {
          this.travelTimeTarget.textContent = data.travel_time
        }
        if (this.hasMealTimeTarget && data.meal_time) {
          this.mealTimeTarget.textContent = data.meal_time
        }
        if (this.hasTotalTimeTarget && data.total_time) {
          this.totalTimeTarget.textContent = data.total_time
        }
      })
      .catch((e) => {
        console.error(e)
      })
  }

  error(e) {
    // 4. A refused permission must be visible on screen, not only in the console
    console.error("Geolocation is not permitted or unavailable:\n", e)
    window.alert("Nous avons besoin de ta position pour t'indiquer le chemin.")
  }
}
