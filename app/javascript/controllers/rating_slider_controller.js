import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["slider", "precisionButton"]
  static values = { precision: { type: String, default: "coarse" } }

  precisionValueChanged() {
    this.precisionButtonTargets.forEach(button => {
      button.setAttribute("aria-pressed", String(button.dataset.precision === this.precisionValue))
    })
  }

  changePrecision(event) {
    this.precisionValue = event.currentTarget.dataset.precision
  }

  sliderTargetConnected(slider) {
    slider.setAttribute("aria-valuetext", this.rowFor(slider).dataset.rated === "true" ? this.formatValue(slider.value) : "Not rated")
  }

  get increment() { return this.precisionValue === "fine" ? 100 : 1000 }

  formatValue(value) {
    const number = Number(value)
    return `${number > 0 ? "+" : ""}${number.toLocaleString()}`
  }

  rowFor(slider) { return slider.closest(".rating-slider-instance") }

  promptSignIn(event) {
    const row = this.rowFor(event.currentTarget)
    row.querySelector(".status-indicator").textContent = "You need to sign in to rate."
    row.querySelector(".rating-sign-in-link").classList.remove("hidden")
    row.querySelector(".slider-status").scrollIntoView({ block: "nearest" })
  }

  showDraft(slider) {
    const row = this.rowFor(slider)
    row.querySelector(".slider-value").textContent = this.formatValue(slider.value)
    slider.setAttribute("aria-valuetext", this.formatValue(slider.value))
    row.querySelector(".status-indicator").textContent = "Not saved yet"
  }

  updateValue(event) {
    const slider = event.target
    slider.value = Math.round(Number(slider.value) / this.increment) * this.increment
    this.showDraft(slider)
  }

  adjustWithKeyboard(event) {
    const slider = event.target
    if (slider.disabled) return
    const increments = { ArrowRight: 1, ArrowUp: 1, ArrowLeft: -1, ArrowDown: -1, PageUp: 10, PageDown: -10 }
    let value
    if (event.key === "Home") value = -10000
    else if (event.key === "End") value = 10000
    else if (event.key in increments) value = Number(slider.value) + increments[event.key] * this.increment
    else return
    event.preventDefault()
    slider.value = Math.max(-10000, Math.min(10000, value))
    this.showDraft(slider)
    this.save(slider)
  }

  submitRating(event) { this.save(event.target) }

  retry(event) { this.save(event.currentTarget.closest(".rating-slider-instance").querySelector("input")) }

  async save(slider) {
    if (slider.disabled) return
    const row = this.rowFor(slider)
    const status = row.querySelector(".status-indicator")
    const retry = row.querySelector(".rating-retry")
    const focusedAtStart = document.activeElement === slider
    slider.disabled = true
    row.setAttribute("aria-busy", "true")
    status.textContent = "Saving…"
    retry.classList.add("hidden")
    try {
      const response = await fetch(slider.dataset.ratingSliderUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json", "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content || ""
        },
        body: JSON.stringify({ rating: { value: Number(slider.value), spectrum_id: slider.dataset.ratingSliderSpectrumIdParam } })
      })
      if (!response.ok || !response.headers.get("content-type")?.includes("turbo-stream")) throw new Error("Rating was not saved")
      const keepFocus = focusedAtStart && (document.activeElement === slider || document.activeElement === document.body)
      const stream = await response.text()
      await Turbo.renderStreamMessage(stream)
      // Turbo removes the old row. Wait for the replacement before returning keyboard focus.
      requestAnimationFrame(() => requestAnimationFrame(() => {
        const replacement = document.getElementById(row.id)?.querySelector("input")
        if (keepFocus && replacement) replacement.focus({ preventScroll: true })
      }))
    } catch (error) {
      slider.disabled = false
      row.removeAttribute("aria-busy")
      status.textContent = "Couldn’t save your rating."
      retry.classList.remove("hidden")
      if (focusedAtStart && document.activeElement === document.body) slider.focus({ preventScroll: true })
    }
  }
}
