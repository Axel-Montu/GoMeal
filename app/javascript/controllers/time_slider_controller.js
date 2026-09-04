import { Controller } from "@hotwired/stimulus"
import noUiSlider from "nouislider"
import gsap from "gsap"
import { SplitText } from "gsap/SplitText"

gsap.registerPlugin(SplitText)

const formatTime = (m) =>
  m < 60 ? `${m} min` : `${Math.floor(m / 60)} h${m % 60 ? ` ${m % 60}` : ""}`

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
    pips:     Array,   // [30, 60, 90]
    maxPlus:  Boolean  // if true, the max value is displayed as "…+" (means "≥ max")
  }

  connect() {
    this.caption = new AnimatedCaption(this.labelTarget)

    const format = (v) => {
      const val = Math.round(v)
      if (this.maxPlusValue && val >= this.maxValue) {
        return `${formatTime(val).replace(/\s+/g, "")}+`
      }
      return formatTime(val)
    }

    const slider = noUiSlider.create(this.sliderTarget, {
      start: this.initialValue,
      step: this.stepValue,
      range: { min: this.minValue, max: this.maxValue },
      connect: [true, false],
      tooltips: { to: format },
      pips: {
        mode: "values",
        values: this.pipsValue,
        density: 50,
        format: { to: format }
      }
    })

    slider.on("update", ([v]) => {
      const val = Math.round(v)
      // Le hidden input est optionnel (ex : walking pas encore migré côté back)
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
