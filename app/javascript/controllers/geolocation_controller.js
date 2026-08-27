import { Controller } from "@hotwired/stimulus"

const options = {
  enableHighAccuracy: true,
  maximumAge: 0
}
// Connects to data-controller="geolocation"
export default class extends Controller {
  static values = { url: String }

  search() {
    navigator.geolocation.getCurrentPosition(
      this.success.bind(this),
      this.error.bind(this),
      options
    )
  }

  success(pos) {
    console.log("lat:", pos.coords.latitude, "long:", pos.coords.longitude)
    const { latitude: lat, longitude: long } = pos.coords;




  //   fetch(this.urlValue, {
  //       method: "POST",
  //       headers: {
  //         "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
  //         "Content-Type": "application/json"
  //   },
  //   body: JSON.stringify({ lat, long })
  // })
  // .then((response) => {
  //   if (!response.ok) throw new Error(
  //     "Request rejected"
  //   )
  //   return response.json()
  // })
  // .then((data) => {

  // })
  // .catch((e) => {
  //   console.error(e)
  // })
}

    error(e) {
    console.error(
      "Geolocation is not permitted or unavailable:\n",
      e
    )
    }
}
