import { Controller } from "@hotwired/stimulus"
import Swiper from "swiper"
// Connects to data-controller="swiper"
export default class extends Controller {

  connect() {
    new Swiper(this.element, {
      effect: "cards",
      grabCursor: true
    })
  }
}
