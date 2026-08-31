import { Controller } from "@hotwired/stimulus"
import noUiSlider from "nouislider"
import gsap from "gsap"
import { SplitText } from "gsap/SplitText"

gsap.registerPlugin(SplitText)

const CAPTIONS = [
  [45, "Express"],
  [75, "Normal"],
  [90, "J'ai le temps"]
]

const formatTime = (m) =>
  m < 60 ? `${m} min` : `${Math.floor(m / 60)} h${m % 60 ? ` ${m % 60}` : ""}`

// Trouve le premier tuple dont max >= mins, extrait le texte (index [1]).
const captionFor = (m) => CAPTIONS.find(([max]) => m <= max)[1]

export default class extends Controller {
  static targets = ["slider", "input", "label"]
  static values = { initial: Number }

  connect() {
    const slider = noUiSlider.create(this.sliderTarget, {
      start: this.initialValue || 60,
      step: 5,
      range: { min: 30, max: 90 },
      tooltips: { to: (v) => formatTime(Math.round(v)) },
      pips: {
        mode: "values",
        values: [30, 60, 90],
        density: 50,
        format: { to: (v) => formatTime(Math.round(v)) }
      }
    })

    // Écouteur : appelé à chaque mouvement du handle (drag, click, keyboard)
    slider.on("update", ([v]) => {
      const mins = Math.round(v)
      // Écrit la valeur dans le hidden input → form submit enverra `average_lunch_time_minutes=45`
      this.inputTarget.value = mins
      this.setCaption(captionFor(mins))
    })
  }


  setCaption(text) {
    if (text === this.caption) return
    // Détecte le tout premier appel (this.caption est undefined au boot)
    const isFirst = !this.caption
    // Mémorise pour la comparaison suivante
    this.caption = text


    this.tl?.kill()
    // Restaure le DOM d'avant le précédent SplitText (sinon les wrappers <div> s'accumulent)
    this.split?.revert()
    this.labelTarget.textContent = text
    this.split = new SplitText(this.labelTarget, { type: "chars" })


    this.tl = gsap.from(this.split.chars, {
      opacity: 0,
      duration: 0.4,
      stagger: { each: 0.008 },
      rotation: "random(-25, 25)",
      // Pivot depuis le bas, plus naturel pour du texte
      transformOrigin: "center bottom",
      ease: "power2.out"
    })

    // Premier rendu : on termine instantanément la timeline (pas d'anim au boot)
    if (isFirst) this.tl.progress(1)
  }

  disconnect() {
    this.tl?.kill()
    this.split?.revert()
    this.sliderTarget.noUiSlider?.destroy()
  }
}
