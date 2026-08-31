import { Controller } from "@hotwired/stimulus"
import gsap from "gsap"
import { DrawSVGPlugin } from "gsap/DrawSVGPlugin"
import { SplitText } from "gsap/SplitText"

gsap.registerPlugin(DrawSVGPlugin, SplitText)

export default class extends Controller {
  static targets = ["logo", "description"]

  connect() {
    const paths = this.logoTarget.querySelectorAll("path")

    this.split = new SplitText(this.descriptionTarget, { type: "lines" })

    gsap.set(paths, { drawSVG: "0%", fillOpacity: 0 })
    gsap.set(this.split.lines, { opacity: 0, x: -100 })

    this.timeline = gsap.timeline({ defaults: { ease: "expo.out" } })
      .to(paths, {
        drawSVG: "100%",
        duration: 1.5,
        stagger: 0.01
      })
      .to(paths, {
        fillOpacity: 1,
        duration: 1.3,
        stagger: 0.01
      }, "-=1.5")
      .to(this.split.lines, {
        opacity: 1,
        y: 0,
        x: 0,
        duration: 0.5,
        stagger: 0.5
      }, "-= 1.3")
  }

  disconnect() {
    this.timeline?.kill()
    this.split?.revert()
  }
}
