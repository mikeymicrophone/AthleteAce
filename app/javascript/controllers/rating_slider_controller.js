import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = []
  static values = {
    targetId: Number,
    targetType: String
  }

  connect() {
    this.initializeAllSliders()
    this.element.stimulusController = this
  }

  initializeAllSliders() {
    const sliders = this.element.querySelectorAll('input[type="range"].rating-slider-input')

    sliders.forEach(slider => {
      const spectrumId = slider.dataset.ratingSliderSpectrumIdParam
      const valueLabel = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`)

      if (valueLabel) {
        this.updateValueLabel(slider.value, valueLabel)
      }
    })
  }

  updateValue(event) {
    const slider = event.target
    const spectrumId = slider.dataset.ratingSliderSpectrumIdParam
    const valueLabel = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`)

    if (valueLabel) {
      this.updateValueLabel(slider.value, valueLabel)
    }
  }

  updateValueLabel(value, labelElement) {
    if (labelElement) {
      labelElement.textContent = value
    }
  }

  async submitRating(event) {
    const slider = event.target
    const ratingValue = slider.value
    const spectrumId = slider.dataset.ratingSliderSpectrumIdParam

    const statusLabel = this.element.querySelector(`[data-rating-slider-target="status_${spectrumId}"]`)

    if (!spectrumId) {
      console.error("[RatingSlider] Spectrum ID not found")
      if (statusLabel) statusLabel.textContent = "Error: Spectrum ID missing"
      return
    }

    let targetType, targetId

    if (this.hasTargetTypeValue && this.hasTargetIdValue) {
      targetType = this.targetTypeValue
      targetId = this.targetIdValue
    } else {
      targetType = this.element.dataset.ratingSliderTargetType
      targetId = this.element.dataset.ratingSliderTargetId
    }

    if (!targetType || !targetId) {
      console.error("[RatingSlider] Target ID or Type not found")
      if (statusLabel) statusLabel.textContent = "Error: Target missing"
      return
    }

    targetType = targetType.charAt(0).toUpperCase() + targetType.slice(1)
    const path = targetType.toLowerCase() + 's'
    const url = `/${path}/${targetId}/ratings`

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']").content
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken,
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          rating: {
            value: ratingValue,
            spectrum_id: spectrumId,
            target_id: targetId,
            target_type: targetType
          },
          spectrum_id: spectrumId
        })
      })

      const data = await response.json()

      if (response.ok) {
        slider.value = data.rating.value
        const valueLabel = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`)
        if (valueLabel) this.updateValueLabel(data.rating.value, valueLabel)
      } else {
        console.error("Error saving rating:", data)
      }
    } catch (error) {
      console.error("Network error:", error)
    }
  }
}
