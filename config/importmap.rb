# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "@popperjs/core", to: "popper.js", preload: true
pin "swiper", to: "https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.mjs"

pin "maplibre-gl", to: "https://cdn.jsdelivr.net/npm/maplibre-gl@6.6.0/+esm"

pin "gsap",               to: "https://cdn.jsdelivr.net/npm/gsap@3.13.0/index.js"
pin "gsap/DrawSVGPlugin", to: "https://cdn.jsdelivr.net/npm/gsap@3.13.0/DrawSVGPlugin.js"
pin "gsap/SplitText",     to: "https://cdn.jsdelivr.net/npm/gsap@3.13.0/SplitText.js"
pin "nouislider",         to: "https://cdn.jsdelivr.net/npm/nouislider@15/dist/nouislider.mjs"
pin "@rails/actioncable", to: "@rails--actioncable.js" # @7.2.302
pin_all_from "app/javascript/channels", under: "channels"
