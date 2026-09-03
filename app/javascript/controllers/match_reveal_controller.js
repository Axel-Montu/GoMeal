import { Controller } from "@hotwired/stimulus"
import gsap from "gsap"

export default class extends Controller {
  static targets = ["cover", "title", "info", "stats"]

  connect() {
    this.buildTimeline()
    this.timeline.play(0)
  }

  disconnect() {
    this.timeline?.kill()
  }

  play() {
    this.timeline?.play(0)
  }

  buildTimeline() {
    const tl = gsap.timeline({ paused: true, defaults: { ease: "power3.out" } })

    if (this.hasCoverTarget) {
      tl.from(this.coverTarget, {
        autoAlpha: 0,
        scale: 1.06,
        y: -100,
        ease: "elastic.out",
        duration: 0.7
      })
    }

    if (this.hasTitleTarget) {
      tl.from(this.titleTarget, {
        autoAlpha: 0,
        x: -100,
        duration: 0.5
      }, "-=0.35")
    }

    if (this.hasInfoTarget) {
      tl.from(this.infoTargets, {
        autoAlpha: 0,
        x: -100,
        duration: 0.4,
        stagger: 0.08
      }, "-=0.25")
    }

    if (this.hasStatsTarget) {
      const statChildren = this.statsTarget.children.length
        ? this.statsTarget.children
        : this.statsTarget
      tl.from(statChildren, {
        autoAlpha: 0,
        y: 10,
        duration: 0.4,
        stagger: 0.08
      }, "-=0.2")
    }

    this.timeline = tl
  }
}
