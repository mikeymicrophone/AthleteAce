import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["form", "selectedSummary", "toggleIcon", "pickerPanel", "multiSelectToggle", "spectrumButton", "toggleButton", "status"]

  connect() { this.updateSummaryDisplay() }

  toggleExpand() {
    const expanded = this.toggleButtonTarget.getAttribute("aria-expanded") !== "true"
    this.toggleButtonTarget.setAttribute("aria-expanded", String(expanded))
    this.pickerPanelTarget.classList.toggle("hidden", !expanded)
    this.toggleIconTarget.classList.toggle("rotate-180", expanded)
  }

  selectedButtons() { return this.spectrumButtonTargets.filter(button => button.getAttribute("aria-pressed") === "true") }

  updateSummaryDisplay() {
    const names = this.selectedButtons().map(button => button.textContent.trim())
    this.selectedSummaryTarget.textContent = names.length === 0 ? "None" : names.join(", ").length > 25 ? `${names.length} selected` : names.join(", ")
  }

  handleMultiSelectToggle() {
    if (!this.multiSelectToggleTarget.checked) {
      this.selectedButtons().slice(1).forEach(button => button.setAttribute("aria-pressed", "false"))
    }
    this.applySpectrumChange()
  }

  toggleSpectrum(event) {
    const button = event.currentTarget
    const selected = button.getAttribute("aria-pressed") === "true"
    if (!this.multiSelectToggleTarget.checked && !selected) {
      this.spectrumButtonTargets.forEach(other => other.setAttribute("aria-pressed", "false"))
    }
    button.setAttribute("aria-pressed", String(!selected))
    this.applySpectrumChange()
  }

  async applySpectrumChange() {
    this.updateSummaryDisplay()
    const ids = this.selectedButtons().map(button => button.dataset.spectrumId)
    this.formTarget.querySelectorAll('input[name="spectrum_ids[]"]').forEach(input => input.remove())
    // Keep the ordinary GET form fields in sync with the visible selection.
    for (const id of ids.length ? ids : [""]) {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "spectrum_ids[]"
      input.value = id
      this.formTarget.appendChild(input)
    }
    const revision = (this.revision || 0) + 1
    this.revision = revision
    this.statusTarget.textContent = "Loading…"
    try {
      await Promise.all(Array.from(document.querySelectorAll("[data-rating-spectrum-url]")).map(async container => {
        const url = new URL(container.dataset.ratingSpectrumUrl, window.location.origin)
        url.searchParams.set("spectrum_ids", ids.join(","))
        const response = await fetch(url, { headers: { Accept: "text/vnd.turbo-stream.html" } })
        if (!response.ok || !response.headers.get("content-type")?.includes("turbo-stream")) throw new Error("Could not load ratings")
        const stream = await response.text()
        if (this.revision === revision) Turbo.renderStreamMessage(stream)
      }))
      if (this.revision === revision) this.statusTarget.textContent = ""
    } catch (error) {
      if (this.revision === revision) this.statusTarget.textContent = "Couldn’t load ratings. Choose a trait to try again."
    }
  }
}
