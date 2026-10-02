import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "fallback"]

  connect() {
    // Cached images may have finished before Stimulus connected.
    if (this.hasImageTarget && this.imageTarget.complete) {
      this.imageTarget.naturalWidth > 0 ? this.loaded() : this.failed()
    }
  }

  loaded() {
    this.element.dataset.imageState = "loaded"
    this.imageTarget.classList.remove("hidden")
    this.fallbackTarget.classList.add("hidden")
  }

  failed() {
    this.element.dataset.imageState = "fallback"
    this.imageTarget.classList.add("hidden")
    this.fallbackTarget.classList.remove("hidden")
  }
}
