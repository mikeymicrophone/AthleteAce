import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="spectrum-picker"
export default class extends Controller {
  static targets = ["dropdown", "buttonText", "multiToggle", "option"]
  static values = { 
    selectedSpectrums: Array,
    multiMode: Boolean,
    currentSpectrum: Number
  }

  connect() {
    this.multiModeValue = false
    
    // Initialize with default spectrum if provided
    if (this.hasCurrentSpectrumValue) {
      this.selectedSpectrumsValue = [this.currentSpectrumValue]
      
      // Update the button text with the default spectrum
      this.updateButtonText()
      
      // Update the current spectrum display in the UI
      this.updateCurrentSpectrumDisplay()
      
      // Mark the default spectrum as selected in the dropdown
      setTimeout(() => {
        this.updateOptionDisplay()
      }, 100)
      
      // Broadcast the selected spectrum to all rating sliders
      setTimeout(() => {
        this.broadcastSelectedSpectrums()
      }, 200)
    } else {
      this.selectedSpectrumsValue = []
    }
    
    // Close dropdown when clicking outside
    document.addEventListener('click', this.handleOutsideClick.bind(this))
  }
  
  disconnect() {
    document.removeEventListener('click', this.handleOutsideClick.bind(this))
  }
  
  // Handle clicks outside the dropdown to close it
  handleOutsideClick(event) {
    if (this.element.contains(event.target)) return
    this.closeDropdown()
  }
  
  // Toggle the dropdown visibility
  togglePicker(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.toggle('hidden')
  }
  
  // Close the dropdown
  closeDropdown() {
    this.dropdownTarget.classList.add('hidden')
  }
  
  // Toggle between single and multi-spectrum mode
  toggleMultiMode() {
    this.multiModeValue = !this.multiModeValue
    
    // Clear selected spectrums if switching to single mode and multiple are selected
    if (!this.multiModeValue && this.selectedSpectrumsValue.length > 1) {
      this.selectedSpectrumsValue = this.selectedSpectrumsValue.slice(0, 1)
    }
    
    this.updateOptionDisplay()
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
    }
    
    this.updateOptionDisplay()
  }
  
  // Clear all selected spectrums
  clearSelection() {
    this.selectedSpectrumsValue = []
    this.updateOptionDisplay()
  }
  
  // Apply the selection and close the dropdown
  applySelection() {
    this.closeDropdown()
    this.updateButtonText()
    this.updateCurrentSpectrumDisplay()
    
    // Broadcast the selected spectrums to all rating sliders
    this.broadcastSelectedSpectrums()
  }
  
  // Update the current spectrum display in the UI
  updateCurrentSpectrumDisplay() {
    if (this.selectedSpectrumsValue.length > 0) {
      const currentSpectrumId = this.selectedSpectrumsValue[0]
      const spectrumName = this.getSpectrumNameById(currentSpectrumId)
      
      // Update the current spectrum display if it exists
      const currentSpectrumElement = document.getElementById('current-spectrum')
      if (currentSpectrumElement) {
        currentSpectrumElement.textContent = spectrumName
      }
    }
  }
  
  // Update the display of options based on selection
  updateOptionDisplay() {
    if (this.hasOptionTargets) {
      this.optionTargets.forEach(option => {
        const spectrumId = parseInt(option.dataset.spectrumId)
        const selected = this.selectedSpectrumsValue.includes(spectrumId)
        
        option.classList.toggle('bg-blue-100', selected)
        option.classList.toggle('font-semibold', selected)
      })
    }
    
    this.updateButtonText()
  }
  
  // Update the button text based on selection
  updateButtonText() {
    if (this.hasButtonTextTarget) {
      if (this.selectedSpectrumsValue.length === 0) {
        this.buttonTextTarget.textContent = "Select spectrums"
      } else if (this.selectedSpectrumsValue.length === 1) {
        const spectrumName = this.getSpectrumNameById(this.selectedSpectrumsValue[0])
        this.buttonTextTarget.textContent = spectrumName
      } else {
        this.buttonTextTarget.textContent = `${this.selectedSpectrumsValue.length} spectrums selected`
      }
    }
  }
  
  // Helper to get spectrum name by ID
  getSpectrumNameById(id) {
    const spectrumElement = document.querySelector(`[data-spectrum-id="${id}"]`)
    return spectrumElement ? spectrumElement.textContent.trim() : `Spectrum ${id}`
  }
  
  // Broadcast the selected spectrums to all rating sliders
  broadcastSelectedSpectrums() {
    const event = new CustomEvent('spectrum-picker:selection-changed', {
      detail: {
        selectedSpectrums: this.selectedSpectrumsValue,
        multiMode: this.multiModeValue
      },
      bubbles: true
    })
    
    this.element.dispatchEvent(event)
  }
}
