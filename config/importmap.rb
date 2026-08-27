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
