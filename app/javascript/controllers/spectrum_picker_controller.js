import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="spectrum-picker"
export default class extends Controller {
  static targets = [
    "form",
    "selectedSummary",
    "toggleIcon",
    "pickerPanel",
    "multiSelectToggle",
    "spectrumButton"
  ]

  static values = {
    highlightColor: String
  }

  connect() {
    this.isExpanded = false
    this.updateSummaryDisplay()
    this.updateMultiSelectToggleState()
  }

  toggleExpand() {
    this.isExpanded = !this.isExpanded
    this.pickerPanelTarget.classList.toggle("hidden", !this.isExpanded)
    this.toggleIconTarget.classList.toggle("rotate-180", this.isExpanded)
  }

  updateSummaryDisplay() {
    const selectedButtons = this.spectrumButtonTargets.filter(btn => !btn.classList.contains('bg-gray-200'))
    const selectedNames = selectedButtons.map(btn => btn.textContent.trim())

    if (selectedNames.length === 0) {
      this.selectedSummaryTarget.textContent = 'None'
    } else if (selectedNames.join(', ').length > 25) {
      this.selectedSummaryTarget.textContent = `${selectedNames.length} selected`
    } else {
      this.selectedSummaryTarget.textContent = selectedNames.join(', ')
    }
  }
  
  updateMultiSelectToggleState() {
    if (!this.hasMultiSelectToggleTarget) return
  }

  handleMultiSelectToggle(event) {
    const isMulti = event.target.checked
    const form = this.formTarget

    if (!isMulti) {
      const selected = this.spectrumButtonTargets.filter(btn => !btn.classList.contains('bg-gray-200'))
      if (selected.length > 1) {
        selected.slice(1).forEach(btn => {
          this.toggleButtonSelection(btn, false)
          const input = form.querySelector(`input[type=hidden][name='spectrum_ids[]'][value='${btn.dataset.spectrumId}']`)
          if (input) input.remove()
        })
      }
    }

    this.updateSummaryDisplay()
    this.applySpectrumChange()
  }

  toggleSpectrum(event) {
    const btn = event.currentTarget
    const id = btn.dataset.spectrumId
    const form = this.formTarget
    const isSelected = !btn.classList.contains('bg-gray-200')
    const isMultiSelectEnabled = this.hasMultiSelectToggleTarget && this.multiSelectToggleTarget.checked

    if (!isMultiSelectEnabled && !isSelected) {
      this.spectrumButtonTargets.forEach(otherBtn => {
        if (otherBtn !== btn && !otherBtn.classList.contains('bg-gray-200')) {
          this.toggleButtonSelection(otherBtn, false)
          const otherInput = form.querySelector(`input[type=hidden][name='spectrum_ids[]'][value='${otherBtn.dataset.spectrumId}']`)
          if (otherInput) otherInput.remove()
        }
      })
    }

    this.toggleButtonSelection(btn, !isSelected)

    if (!isSelected) {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'spectrum_ids[]'
      input.value = id
      input.dataset.spectrum = id
      form.appendChild(input)
    } else {
      const input = form.querySelector(`input[type=hidden][name='spectrum_ids[]'][value='${id}']`)
      if (input) input.remove()
    }

    this.updateSummaryDisplay()
    this.applySpectrumChange()
  }

  toggleButtonSelection(btn, select) {
    const highlightClasses = this.highlightColorValue.split(' ')
    if (select) {
      btn.classList.remove('bg-gray-200', 'text-gray-700')
      btn.classList.add(...highlightClasses)
    } else {
      btn.classList.remove(...highlightClasses)
      btn.classList.add('bg-gray-200', 'text-gray-700')
    }
  }

  applySpectrumChange() {
    const selectedIds = Array.from(this.formTarget.querySelectorAll('input[name="spectrum_ids[]"]'))
      .map(input => input.value)
      .filter(id => id !== '')

    this.updateRatingSliders(selectedIds)
  }

  updateRatingSliders(selectedIds) {
    const containers = document.querySelectorAll('[data-controller*="rating-slider"]')
    containers.forEach(container => this.updateSingleRatingSlider(container, selectedIds))
  }
  
  // Update a single rating slider container using batch fetching for better performance
  async updateSingleRatingSlider(container, selectedIds) {
    const targetType = container.dataset.ratingSliderTargetTypeValue || container.dataset.ratingSliderTargetType
    const targetId = container.dataset.ratingSliderTargetIdValue || container.dataset.ratingSliderTargetId

    if (!targetType || !targetId) {
      console.warn('Rating slider container missing target type or ID:', container)
      return
    }

    const existingSliders = container.querySelectorAll('.rating-slider-instance')
    existingSliders.forEach(slider => slider.remove())

    if (selectedIds.length === 0) {
      container.innerHTML = '<p class="empty-state-message">Select a spectrum to see rating sliders.</p>'
      return
    }

    try {
      selectedIds.forEach(spectrumId => {
        const loadingHtml = this.createLoadingPlaceholder(spectrumId)
        container.insertAdjacentHTML('beforeend', loadingHtml)
      })

      const ratingsData = await this.fetchBatchRatingValues(targetType, targetId, selectedIds)

      selectedIds.forEach(spectrumId => {
        const loadingElement = container.querySelector(`[data-spectrum-id="${spectrumId}"]`)
        if (loadingElement) {
          const ratingValue = ratingsData[spectrumId] || 0
          const sliderHtml = this.createSliderHtml(spectrumId, ratingValue)
          loadingElement.outerHTML = sliderHtml
        }
      })

      if (container.stimulusController) {
        container.stimulusController.initializeAllSliders()
      }
    } catch (error) {
      console.error('[SpectrumPicker] Error in batch update:', error)

      selectedIds.forEach(spectrumId => {
        const loadingElement = container.querySelector(`[data-spectrum-id="${spectrumId}"]`)
        if (loadingElement) {
          const sliderHtml = this.createSliderHtml(spectrumId, 0)
          loadingElement.outerHTML = sliderHtml
        }
      })

      if (container.stimulusController) {
        container.stimulusController.initializeAllSliders()
      }
    }
  }

  createLoadingPlaceholder(spectrumId) {
    const spectrumButton = this.spectrumButtonTargets.find(btn => btn.dataset.spectrumId === spectrumId)
    const spectrumName = spectrumButton ? spectrumButton.textContent.trim() : `Spectrum ${spectrumId}`

    return `
      <div class="rating-slider-instance" data-spectrum-id="${spectrumId}">
        <div class="slider-header">
          <span class="slider-label">${spectrumName}</span>
          <span class="slider-value">Loading...</span>
        </div>
        <div class="slider-control">
          <div class="loading-indicator">Fetching rating...</div>
        </div>
        <div class="slider-status">
          <span class="status-indicator">Loading</span>
        </div>
      </div>
    `
  }

  async fetchBatchRatingValues(targetType, targetId, spectrumIds) {
    const pluralType = targetType + 's'
    const spectrumIdsParam = spectrumIds.join(',')
    const url = `/${pluralType}/${targetId}/ratings/for_spectrums?spectrum_ids=${spectrumIdsParam}`

    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      const ratingsData = {}
      if (data.ratings) {
        Object.keys(data.ratings).forEach(spectrumId => {
          ratingsData[spectrumId] = data.ratings[spectrumId].value
        })
      }

      return ratingsData
    } catch (error) {
      console.error('[SpectrumPicker] Error fetching batch ratings:', error)
      throw error
    }
  }

  createSliderHtml(spectrumId, value) {
    const spectrumButton = this.spectrumButtonTargets.find(btn => btn.dataset.spectrumId === spectrumId)
    const spectrumName = spectrumButton ? spectrumButton.textContent.trim() : `Spectrum ${spectrumId}`

    return `
      <div class="rating-slider-instance" data-spectrum-id="${spectrumId}">
        <div class="slider-header">
          <span class="slider-label">${spectrumName}</span>
          <span class="slider-value" data-rating-slider-target="value_${spectrumId}">${value}</span>
        </div>
        <div class="slider-control">
          <input type="range"
                 min="-10000"
                 max="10000"
                 value="${value}"
                 step="100"
                 class="slider-input rating-slider-input"
                 data-rating-slider-target="slider_${spectrumId}"
                 data-action="input->rating-slider#updateValue change->rating-slider#submitRating"
                 data-rating-slider-spectrum-id-param="${spectrumId}"
                 data-rating-slider-original-step="100">
        </div>
        <div class="slider-status">
          <span class="status-indicator" data-rating-slider-target="status_${spectrumId}"></span>
        </div>
      </div>
    `
  }
}
