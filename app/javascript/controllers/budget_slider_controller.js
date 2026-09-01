import { Controller } from "@hotwired/stimulus"
import noUiSlider from "nouislider"
import gsap from "gsap"
import { SplitText } from "gsap/SplitText"

gsap.registerPlugin(SplitText)

const formatBudget = (v) => `${v} €`

// Helper animée : split le texte en chars, cascade random + rotation.
class AnimatedCaption {
  constructor(el) {
    this.el = el
    this.text = null
  }

  set(newText) {
    if (newText === this.text) return
    const isFirst = !this.text
    this.text = newText

    this.tl?.kill()
    this.split?.revert()
    this.el.textContent = newText
    this.split = new SplitText(this.el, { type: "chars" })

    this.tl = gsap.from(this.split.chars, {
      opacity: 0,
      duration: 0.4,
      stagger: { each: 0.008, from: "random" },
      rotation: "random(-25, 25)",
      transformOrigin: "center bottom",
      ease: "power2.out"
    })

    if (isFirst) this.tl.progress(1)
  }

  destroy() {
    this.tl?.kill()
    this.split?.revert()
  }
}

export default class extends Controller {
  static targets = ["slider", "input", "label"]
  static values = {
    initial: Number,
    min:     Number,
    max:     Number,
    step:    { type: Number, default: 5 },
    captions: Array,   // [[seuilMax, texte], ...]
    pips:     Array    // [0, 10, 20, ...]
  }

  connect() {
    this.caption = new AnimatedCaption(this.labelTarget)

    const slider = noUiSlider.create(this.sliderTarget, {
      start: this.initialValue,
      step: this.stepValue,
      range: { min: this.minValue, max: this.maxValue },
      tooltips: { to: (v) => formatBudget(Math.round(v)) },
      pips: {
        mode: "values",
        values: this.pipsValue,
        density: 50,
        format: { to: (v) => formatBudget(Math.round(v)) }
      }
    })

    slider.on("update", ([v]) => {
      const val = Math.round(v)
      if (this.hasInputTarget) this.inputTarget.value = val
      this.caption.set(this.captionFor(val))
    })
  }

  captionFor(val) {
    return this.captionsValue.find(([max]) => val <= max)[1]
  }

  disconnect() {
    this.caption?.destroy()
    this.sliderTarget.noUiSlider?.destroy()
  }
}
