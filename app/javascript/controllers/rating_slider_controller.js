import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rating-slider"
export default class extends Controller {
  static targets = ["slider", "value", "spectrumSelector", "spectrumPicker", "multiToggle", "spectrumItem"]
  static values = { 
    playerId: Number,
    teamId: Number,
    currentSpectrum: Number,
    selectedSpectrums: Array,
    multiMode: Boolean
  }

  connect() {
    this.multiModeValue = false
    this.selectedSpectrumsValue = []
    
    // Set initial spectrum if provided
    if (this.hasCurrentSpectrumValue && this.currentSpectrumValue) {
      this.selectedSpectrumsValue = [this.currentSpectrumValue]
    }
    
    this.updateSliderColors()
    
    // Listen for spectrum selection events from the spectrum picker
    document.addEventListener('spectrum-picker:selection-changed', this.handleSpectrumSelection.bind(this))
  }
  
  disconnect() {
    // Clean up event listener
    document.removeEventListener('spectrum-picker:selection-changed', this.handleSpectrumSelection.bind(this))
  }
  
  // Handle spectrum selection events from the spectrum picker
  handleSpectrumSelection(event) {
    const { selectedSpectrums, multiMode } = event.detail
    
    // Update our local values
    this.multiModeValue = multiMode
    this.selectedSpectrumsValue = selectedSpectrums
    
    // Update UI
    this.updateSpectrumSelection()
    this.updateSliderColors()
  }

  // Toggle the spectrum picker dropdown
  toggleSpectrumPicker() {
    this.spectrumPickerTarget.classList.toggle('hidden')
  }

  // Toggle between single and multi-spectrum mode
  toggleMultiMode() {
    this.multiModeValue = !this.multiModeValue
    
    // Clear selected spectrums if switching to single mode and multiple are selected
    if (!this.multiModeValue && this.selectedSpectrumsValue.length > 1) {
      this.selectedSpectrumsValue = [this.selectedSpectrumsValue[0]]
    }
    
    this.updateSliderColors()
    this.updateSpectrumSelection()
  }

  // Select a spectrum from the picker
  selectSpectrum(event) {
    const spectrumId = parseInt(event.currentTarget.dataset.spectrumId)
    
    if (this.multiModeValue) {
      // Multi-mode: toggle the spectrum in the array
      const index = this.selectedSpectrumsValue.indexOf(spectrumId)
      
      if (index === -1 && this.selectedSpectrumsValue.length < 4) {
        // Add spectrum if not already selected and under the limit
        this.selectedSpectrumsValue = [...this.selectedSpectrumsValue, spectrumId]
      } else if (index !== -1) {
        // Remove spectrum if already selected
        this.selectedSpectrumsValue = [
          ...this.selectedSpectrumsValue.slice(0, index),
          ...this.selectedSpectrumsValue.slice(index + 1)
        ]
      }
    } else {
      // Single mode: replace the current selection
      this.selectedSpectrumsValue = [spectrumId]
      this.toggleSpectrumPicker() // Close picker in single mode
    }
    
    this.updateSpectrumSelection()
    this.updateSliderColors()
  }

  // Update the visual selection state of spectrum items
  updateSpectrumSelection() {
    if (this.hasSpectrumItemTargets) {
      this.spectrumItemTargets.forEach(item => {
        const spectrumId = parseInt(item.dataset.spectrumId)
        const selected = this.selectedSpectrumsValue.includes(spectrumId)
        
        item.classList.toggle('bg-blue-100', selected)
        item.classList.toggle('font-semibold', selected)
      })
    }
    
    // Update the spectrum selector text
    if (this.hasSpectrumSelectorTarget) {
      if (this.selectedSpectrumsValue.length === 0) {
        this.spectrumSelectorTarget.textContent = "Select spectrum"
      } else if (this.selectedSpectrumsValue.length === 1) {
        const spectrumName = this.getSpectrumNameById(this.selectedSpectrumsValue[0])
        this.spectrumSelectorTarget.textContent = spectrumName
      } else {
        this.spectrumSelectorTarget.textContent = `${this.selectedSpectrumsValue.length} spectrums selected`
      }
    }
  }

  // Helper to get spectrum name by ID
  getSpectrumNameById(id) {
    const spectrumElement = document.querySelector(`[data-spectrum-id="${id}"]`)
    return spectrumElement ? spectrumElement.textContent.trim() : `Spectrum ${id}`
  }

  // Update the slider value display
  updateValue(event) {
    if (this.hasValueTarget) {
      const value = event.target.value
      this.valueTarget.textContent = value
      
      // Determine color based on value
      const normalizedValue = (parseInt(value) + 10000) / 20000
      const hue = normalizedValue * 120 // 0 = red, 120 = green
      this.valueTarget.style.color = `hsl(${hue}, 80%, 40%)`
    }
  }

  // Update slider colors based on selected spectrums
  updateSliderColors() {
    if (this.hasSliderTarget && this.selectedSpectrumsValue.length > 0) {
      if (this.selectedSpectrumsValue.length === 1) {
        // Single spectrum - blue gradient
        this.sliderTarget.style.background = 'linear-gradient(to right, #3b82f6, #93c5fd)'
      } else {
        // Multiple spectrums - create a gradient with colors for each spectrum
        const colors = [
          '#3b82f6', // blue
          '#10b981', // green
          '#f59e0b', // yellow
          '#ef4444'  // red
        ]
        
        const colorStops = this.selectedSpectrumsValue
          .slice(0, 4)
          .map((_, index) => colors[index])
          .join(', ')
        
        this.sliderTarget.style.background = `linear-gradient(to right, ${colorStops})`
      }
    }
  }

  // Submit the rating
  submitRating(event) {
    event.preventDefault()
    
    if (this.selectedSpectrumsValue.length === 0 || !this.hasSliderTarget) {
      return
    }
    
    const value = this.sliderTarget.value
    const playerId = this.playerIdValue
    const teamId = this.teamIdValue
    
    // Create a form data object for the request
    const formData = new FormData()
    formData.append('rating[value]', value)
    
    // Submit a rating for each selected spectrum
    this.selectedSpectrumsValue.forEach(spectrumId => {
      // Clone the form data and add the spectrum ID
      const spectrumFormData = new FormData(formData)
      spectrumFormData.append('rating[spectrum_id]', spectrumId)
      
      // Determine the target URL based on what we're rating
      let url
      if (playerId) {
        url = `/players/${playerId}/ratings`
      } else if (teamId) {
        url = `/teams/${teamId}/ratings`
      } else {
        return
      }
      
      // Send the AJAX request
      fetch(url, {
        method: 'POST',
        body: spectrumFormData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      .then(response => {
        if (response.ok) {
          // Show success feedback
          this.showFeedback('Rating saved', 'success')
        } else {
          // Show error feedback
          this.showFeedback('Failed to save rating', 'error')
        }
      })
      .catch(error => {
        console.error('Error saving rating:', error)
        this.showFeedback('Error saving rating', 'error')
      })
    })
  }
  
  // Show feedback message
  showFeedback(message, type) {
    const feedbackElement = document.createElement('div')
    feedbackElement.textContent = message
    feedbackElement.classList.add(
      'fixed', 'bottom-4', 'right-4', 'px-4', 'py-2', 'rounded-md',
      'shadow-md', 'transition-opacity', 'duration-500'
    )
    
    if (type === 'success') {
      feedbackElement.classList.add('bg-green-100', 'text-green-800')
    } else {
      feedbackElement.classList.add('bg-red-100', 'text-red-800')
    }
    
    document.body.appendChild(feedbackElement)
    
    // Remove after 3 seconds
    setTimeout(() => {
      feedbackElement.classList.add('opacity-0')
      setTimeout(() => {
        feedbackElement.remove()
      }, 500)
    }, 3000)
  }
}
