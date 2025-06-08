import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="spectrum-picker"
export default class extends Controller {
  static targets = [
    "form",
    "summaryDisplay",
    "toggleIcon",
    "expandableContent",
    "multiSelectToggle",
    "buttonContainer",
    "spectrumButton"
  ]

  static values = {
    highlightColor: String
  }

  connect() {
    this.isExpanded = false;
    this.updateSummaryDisplay();
    // Ensure multi-select toggle reflects current selection state accurately
    this.updateMultiSelectToggleState();
  }

  toggleExpand() {
    this.isExpanded = !this.isExpanded;
    this.expandableContentTarget.classList.toggle("hidden", !this.isExpanded);
    this.toggleIconTarget.classList.toggle("rotate-180", this.isExpanded);
  }

  updateSummaryDisplay() {
    const selectedButtons = this.spectrumButtonTargets.filter(btn => !btn.classList.contains('bg-gray-200'));
    const selectedNames = selectedButtons.map(btn => btn.textContent.trim());
    if (selectedNames.length > 0) {
      this.summaryDisplayTarget.textContent = selectedNames.join(', ');
    } else {
      this.summaryDisplayTarget.textContent = 'None';
    }
    if (selectedNames.join(', ').length > 25) {
      this.summaryDisplayTarget.textContent = `${selectedNames.length} selected`;
    }
  }
  
  updateMultiSelectToggleState() {
    const selectedButtons = this.spectrumButtonTargets.filter(btn => !btn.classList.contains('bg-gray-200'));
    // If more than one is checked, or if none are checked but multi-select was intended (e.g. from previous state), keep it checked.
    // The ERB handles the initial 'checked' state of the multi-select toggle based on selected_spectrum_ids.count.
    // This JS primarily ensures consistency if we manipulate checkboxes client-side before form submission.
    if (this.hasMultiSelectToggleTarget) {
        // this.multiSelectToggleTarget.checked should already be set by ERB based on selected_spectrum_ids
        // This is more for future dynamic client-side updates if needed
    }
  }

  handleMultiSelectToggle(event) {
    const isMulti = event.target.checked;
    const form = this.formTarget;
    
    if (!isMulti) {
      // Single select mode - keep only the first selected spectrum
      const selected = this.spectrumButtonTargets.filter(btn => !btn.classList.contains('bg-gray-200'));
      if (selected.length > 1) {
        selected.slice(1).forEach(btn => {
          this.toggleButtonSelection(btn, false);
          // Remove hidden input for deselected spectrum
          const input = form.querySelector(`input[type=hidden][name='spectrum_ids[]'][value='${btn.dataset.spectrumId}']`);
          if (input) input.remove();
        });
      }
    }
    
    this.updateSummaryDisplay();
    
    // Apply changes immediately
    this.applySpectrumChange();
  }

  toggleSpectrum(event) {
    const btn = event.currentTarget;
    const id = btn.dataset.spectrumId;
    const form = this.formTarget;
    const isSelected = !btn.classList.contains('bg-gray-200');
    
    // Check if multi-select is enabled
    const isMultiSelectEnabled = this.hasMultiSelectToggleTarget && this.multiSelectToggleTarget.checked;
    
    if (!isMultiSelectEnabled && !isSelected) {
      // Single select mode - deselect all other buttons first
      this.spectrumButtonTargets.forEach(otherBtn => {
        if (otherBtn !== btn && !otherBtn.classList.contains('bg-gray-200')) {
          this.toggleButtonSelection(otherBtn, false);
          // Remove hidden input for deselected spectrum
          const otherInput = form.querySelector(`input[type=hidden][name='spectrum_ids[]'][value='${otherBtn.dataset.spectrumId}']`);
          if (otherInput) otherInput.remove();
        }
      });
    }
    
    // Toggle current button
    this.toggleButtonSelection(btn, !isSelected);
    
    // Manage hidden inputs
    if (!isSelected) {
      const input = document.createElement('input');
      input.type = 'hidden'; input.name = 'spectrum_ids[]'; input.value = id;
      input.dataset.spectrum = id;
      form.appendChild(input);
    } else {
      const input = form.querySelector(`input[type=hidden][name='spectrum_ids[]'][value='${id}']`);
      if (input) input.remove();
    }
    
    this.updateSummaryDisplay();
    
    // Apply changes immediately without page refresh
    this.applySpectrumChange();
  }

  // Apply or remove highlight classes
  toggleButtonSelection(btn, select) {
    const highlightClasses = this.highlightColorValue.split(' ');
    if (select) {
      btn.classList.remove('bg-gray-200','text-gray-700');
      btn.classList.add(...highlightClasses);
    } else {
      btn.classList.remove(...highlightClasses);
      btn.classList.add('bg-gray-200','text-gray-700');
    }
  }

  // Apply spectrum changes immediately without page refresh
  applySpectrumChange() {
    // Get currently selected spectrum IDs
    const selectedIds = Array.from(this.formTarget.querySelectorAll('input[name="spectrum_ids[]"]'))
                             .map(input => input.value)
                             .filter(id => id !== ''); // Remove empty values
    
    console.log('Applying spectrum change:', selectedIds);
    
    // Update all rating slider containers on the page
    this.updateRatingSliders(selectedIds);
  }
  
  // Update rating sliders for all ratable objects on the page
  updateRatingSliders(selectedIds) {
    // Find all rating slider containers
    const containers = document.querySelectorAll('[data-controller*="rating-slider"]');
    
    // Update each container (async operations will run in parallel)
    containers.forEach(container => {
      this.updateSingleRatingSlider(container, selectedIds);
    });
  }
  
  // Update a single rating slider container using batch fetching for better performance
  async updateSingleRatingSlider(container, selectedIds) {
    const targetType = container.dataset.ratingSliderTargetTypeValue || container.dataset.ratingSliderTargetType;
    const targetId = container.dataset.ratingSliderTargetIdValue || container.dataset.ratingSliderTargetId;
    
    if (!targetType || !targetId) {
      console.warn('Rating slider container missing target type or ID:', container);
      return;
    }
    
    // Remove existing sliders
    const existingSliders = container.querySelectorAll('.rating-slider-instance');
    existingSliders.forEach(slider => slider.remove());
    
    // If no spectrums selected, show empty state
    if (selectedIds.length === 0) {
      container.innerHTML = '<p class="empty-state-message">Select a spectrum to see rating sliders.</p>';
      return;
    }
    
    try {
      // First, add loading placeholders for all spectrums
      selectedIds.forEach(spectrumId => {
        const loadingHtml = this.createLoadingPlaceholder(targetType, targetId, spectrumId);
        container.insertAdjacentHTML('beforeend', loadingHtml);
      });
      
      // Fetch all ratings in one batch request
      const ratingsData = await this.fetchBatchRatingValues(targetType, targetId, selectedIds);
      
      // Replace each loading placeholder with the actual slider
      selectedIds.forEach(spectrumId => {
        const loadingElement = container.querySelector(`[data-spectrum-id="${spectrumId}"]`);
        if (loadingElement) {
          const ratingValue = ratingsData[spectrumId] || 0;
          const sliderHtml = this.createSliderWithValue(targetType, targetId, spectrumId, ratingValue);
          loadingElement.outerHTML = sliderHtml;
        }
      });
      
      // Re-initialize the rating slider controller for the new content
      if (container.stimulusController) {
        container.stimulusController.initializeAllSliders();
      }
    } catch (error) {
      console.error('[SpectrumPicker] Error in batch update:', error);
      
      // Fall back to individual slider creation with default values
      selectedIds.forEach(spectrumId => {
        const loadingElement = container.querySelector(`[data-spectrum-id="${spectrumId}"]`);
        if (loadingElement) {
          const sliderHtml = this.createSliderWithValue(targetType, targetId, spectrumId, 0);
          loadingElement.outerHTML = sliderHtml;
        }
      });
      
      // Re-initialize even on error
      if (container.stimulusController) {
        container.stimulusController.initializeAllSliders();
      }
    }
  }
  
  // Fetch and add a slider for a specific spectrum
  async fetchAndAddSlider(container, targetType, targetId, spectrumId) {
    try {
      // First, create a loading placeholder
      const loadingHtml = this.createLoadingPlaceholder(targetType, targetId, spectrumId);
      container.insertAdjacentHTML('beforeend', loadingHtml);
      
      // Fetch the actual rating value
      const ratingValue = await this.fetchRatingValue(targetType, targetId, spectrumId);
      
      // Replace the loading placeholder with the actual slider
      const loadingElement = container.querySelector(`[data-spectrum-id="${spectrumId}"]`);
      if (loadingElement) {
        const sliderHtml = this.createSliderWithValue(targetType, targetId, spectrumId, ratingValue);
        loadingElement.outerHTML = sliderHtml;
      }
      
      // Re-initialize the rating slider controller for the new content
      if (container.stimulusController) {
        container.stimulusController.initializeAllSliders();
      }
    } catch (error) {
      console.error('[SpectrumPicker] Error fetching rating value:', error);
      
      // Fall back to placeholder with value 0
      const loadingElement = container.querySelector(`[data-spectrum-id="${spectrumId}"]`);
      if (loadingElement) {
        const sliderHtml = this.createSliderWithValue(targetType, targetId, spectrumId, 0);
        loadingElement.outerHTML = sliderHtml;
      }
      
      // Re-initialize even on error
      if (container.stimulusController) {
        container.stimulusController.initializeAllSliders();
      }
    }
  }
  
  // Create a loading placeholder while fetching the actual rating
  createLoadingPlaceholder(targetType, targetId, spectrumId) {
    const spectrumButton = this.spectrumButtonTargets.find(btn => btn.dataset.spectrumId === spectrumId);
    const spectrumName = spectrumButton ? spectrumButton.textContent.trim() : `Spectrum ${spectrumId}`;
    
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
    `;
  }

  // Fetch rating values for multiple spectrums in one batch request (more efficient)
  async fetchBatchRatingValues(targetType, targetId, spectrumIds) {
    const pluralType = targetType + 's'; // Convert 'player' to 'players'
    const spectrumIdsParam = spectrumIds.join(',');
    const url = `/${pluralType}/${targetId}/ratings/for_spectrums?spectrum_ids=${spectrumIdsParam}`;
    
    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      // Convert to a simple object mapping spectrum_id to rating value
      const ratingsData = {};
      if (data.ratings) {
        Object.keys(data.ratings).forEach(spectrumId => {
          ratingsData[spectrumId] = data.ratings[spectrumId].value;
        });
      }
      
      return ratingsData;
    } catch (error) {
      console.error('[SpectrumPicker] Error fetching batch ratings:', error);
      throw error;
    }
  }

  // Fetch the actual rating value for a target and spectrum
  async fetchRatingValue(targetType, targetId, spectrumId) {
    const pluralType = targetType + 's'; // Convert 'player' to 'players'
    const url = `/${pluralType}/${targetId}/ratings/for_spectrums?spectrum_ids=${spectrumId}`;
    
    try {
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      // Check if we have a rating for this spectrum
      if (data.ratings && data.ratings[spectrumId]) {
        return data.ratings[spectrumId].value;
      } else {
        // No existing rating, return default value
        return 0;
      }
    } catch (error) {
      console.error('[SpectrumPicker] Error fetching rating:', error);
      throw error;
    }
  }

  // Create a slider with a specific value (replaces both placeholder methods)
  createSliderWithValue(targetType, targetId, spectrumId, value) {
    const spectrumButton = this.spectrumButtonTargets.find(btn => btn.dataset.spectrumId === spectrumId);
    const spectrumName = spectrumButton ? spectrumButton.textContent.trim() : `Spectrum ${spectrumId}`;
    
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
    `;
  }

  // Create a placeholder slider that will load the actual rating lazily (kept for backwards compatibility)
  createSliderPlaceholder(targetType, targetId, spectrumId) {
    return this.createSliderWithValue(targetType, targetId, spectrumId, 0);
  }
}
