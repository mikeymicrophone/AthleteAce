import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rating-slider"
export default class extends Controller {
  // Targets are now dynamically handled based on spectrum_id, but we can define the pattern.
  // For instance, slider_*, value_*, status_*
  // We still need a general target for the sliders if we iterate them.
  static targets = [/* "slider", "value", "status" // These will be qualified by spectrum_id */]
  static values = { 
    targetId: Number,
    targetType: String
    // Using a more generic approach instead of specific model types
  }

  connect() {
    console.log('[RatingSlider] Controller connected', {
      element: this.element,
      hasTargetIdValue: this.hasTargetIdValue,
      targetIdValue: this.hasTargetIdValue ? this.targetIdValue : null,
      hasTargetTypeValue: this.hasTargetTypeValue,
      targetTypeValue: this.hasTargetTypeValue ? this.targetTypeValue : null
    });
    this.initializeAllSliders();
  }

  initializeAllSliders() {
    // Look for range inputs with the class that matches what's in the DOM
    const sliders = this.element.querySelectorAll('input[type="range"].rating-slider-input');
    console.log('[RatingSlider] Found sliders:', sliders.length);
    
    sliders.forEach(slider => {
      const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
      console.log('[RatingSlider] Initializing slider for spectrum:', spectrumId, slider);
      
      // Find the value display element
      const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
      if (valueDisplay) {
        this.updateValueDisplay(slider.value, valueDisplay);
        console.log('[RatingSlider] Updated value display for spectrum:', spectrumId);
      } else {
        console.error('[RatingSlider] Could not find value display for spectrum ID:', spectrumId);
      }
      
      // Set up enhanced slider control
      this.setupEnhancedSlider(slider, spectrumId);
    });
  }
  
  initializeSlider(slider, spectrumId) {
    if (!slider) return;
    
    const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
    const statusDisplay = this.element.querySelector(`[data-rating-slider-target="status_${spectrumId}"]`);
    
    // Store original step value for later restoration
    const originalStep = slider.dataset.ratingSliderOriginalStep || slider.getAttribute('step');
    
    // Variables for precision mode
    let inPrecisionMode = false;
    let startY = 0;
    let currentStep = originalStep;
    let currentPrecisionMode = this.element.dataset.ratingSliderPrecisionMode || 'coarse';
    let sliderContainer = slider.parentNode;
    
    // Create precision indicator element
    const precisionIndicator = document.createElement('div');
    precisionIndicator.className = 'precision-indicator hidden';
    sliderContainer.appendChild(precisionIndicator);
    
    // Ensure the slider container has position relative for absolute positioning of the indicator
    sliderContainer.style.position = 'relative';
    
    // Set initial slider sensitivity based on precision mode
    this.updateSliderSensitivity(slider, currentPrecisionMode);
    
    // Create a draggable handle for precision control
    const precisionHandle = document.createElement('div');
    precisionHandle.className = 'precision-handle hidden';
    precisionHandle.style.position = 'absolute';
    precisionHandle.style.width = '100%';
    precisionHandle.style.height = '30px';
    precisionHandle.style.bottom = '-35px';
    precisionHandle.style.left = '0';
    precisionHandle.style.cursor = 'ns-resize';
    precisionHandle.style.backgroundColor = 'rgba(0, 0, 0, 0.05)';
    precisionHandle.style.borderRadius = '4px';
    precisionHandle.style.zIndex = '10';
    precisionHandle.style.display = 'flex';
    precisionHandle.style.alignItems = 'center';
    precisionHandle.style.justifyContent = 'center';
    precisionHandle.innerHTML = '<span style="font-size: 10px; color: #666;">Pull down for precision</span>';
    sliderContainer.appendChild(precisionHandle);
    
    // Show the precision handle when hovering over the slider
    slider.addEventListener('mouseover', () => {
      precisionHandle.classList.remove('hidden');
    });
    
    slider.addEventListener('mouseout', (e) => {
      // Only hide if we're not moving to the precision handle
      if (!e.relatedTarget || !e.relatedTarget.classList.contains('precision-handle')) {
        if (!inPrecisionMode) {
          precisionHandle.classList.add('hidden');
        }
      }
    });
    
    // Precision handle events
    precisionHandle.addEventListener('mouseover', () => {
      precisionHandle.classList.remove('hidden');
    });
    
    precisionHandle.addEventListener('mouseout', (e) => {
      if (!inPrecisionMode) {
        precisionHandle.classList.add('hidden');
      }
    });
    
    // Main precision control logic
    const startPrecisionMode = (e) => {
      inPrecisionMode = true;
      startY = e.clientY;
      
      // Position the precision indicator
      precisionIndicator.style.left = '50%';
      precisionIndicator.style.transform = 'translateX(-50%)';
      precisionIndicator.style.top = '-25px';
      precisionIndicator.classList.remove('hidden');
      precisionIndicator.textContent = `Step: ${currentStep}`;
      
      // Prevent default to avoid text selection
      e.preventDefault();
      
      // Add global event listeners for drag tracking
      document.addEventListener('mousemove', updatePrecision);
      document.addEventListener('mouseup', endPrecisionMode);
      document.addEventListener('touchmove', updatePrecision, { passive: false });
      document.addEventListener('touchend', endPrecisionMode);
    };
    
    const updatePrecision = (e) => {
      if (!inPrecisionMode) return;
      
      // Get the current Y position
      const clientY = e.clientY || (e.touches && e.touches[0] ? e.touches[0].clientY : startY);
      
      // Calculate vertical distance from start point
      const verticalDistance = Math.max(0, clientY - startY);
      
      // Determine precision mode and step size based on vertical distance
      let newPrecisionMode = 'coarse';
      let newStep = 100; // Default is coarse control
      
      if (verticalDistance > 40) {
        newPrecisionMode = 'fine';
        newStep = 1;   // Fine control (1 by 1)
      } else if (verticalDistance > 20) {
        newPrecisionMode = 'medium';
        newStep = 10;  // Medium control (10s)
      }
      
      // Update precision mode if changed
      if (currentPrecisionMode !== newPrecisionMode) {
        currentPrecisionMode = newPrecisionMode;
        this.element.dataset.ratingSliderPrecisionMode = currentPrecisionMode;
        
        // Update slider sensitivity based on new precision mode
        this.updateSliderSensitivity(slider, currentPrecisionMode);
        
        // Update the indicator
        precisionIndicator.className = 'precision-indicator';
        precisionIndicator.classList.add(`precision-${currentPrecisionMode}`);
        precisionIndicator.textContent = `Step: ${newStep}`;
        
        // Update the slider step
        currentStep = newStep;
        slider.setAttribute('step', newStep.toString());
        
        // Log for debugging
        console.log(`Precision mode: ${currentPrecisionMode}, Step: ${newStep}, Distance: ${verticalDistance}`);
      }
      
      // Prevent default to avoid scrolling
      e.preventDefault();
    };
    
    const endPrecisionMode = () => {
      if (!inPrecisionMode) return;
      
      inPrecisionMode = false;
      
      // Remove global event listeners
      document.removeEventListener('mousemove', updatePrecision);
      document.removeEventListener('mouseup', endPrecisionMode);
      document.removeEventListener('touchmove', updatePrecision);
      document.removeEventListener('touchend', endPrecisionMode);
      
      // Hide the precision indicator
      precisionIndicator.classList.add('hidden');
      
      // Hide the precision handle if not hovering
      if (!slider.matches(':hover') && !precisionHandle.matches(':hover')) {
        precisionHandle.classList.add('hidden');
      }
    };
    
    // Attach the precision mode events to the handle
    precisionHandle.addEventListener('mousedown', startPrecisionMode);
    precisionHandle.addEventListener('touchstart', startPrecisionMode, { passive: false });
    
    // Also allow starting precision mode from the slider itself with a vertical drag
    let dragStartY = 0;
    let isDraggingVertically = false;
    
    slider.addEventListener('mousedown', (e) => {
      dragStartY = e.clientY;
    });
    
    slider.addEventListener('mousemove', (e) => {
      if (e.buttons !== 1) return; // Not dragging
      
      const verticalDelta = Math.abs(e.clientY - dragStartY);
      
      // If we're dragging more vertically than horizontally, enter precision mode
      if (verticalDelta > 10 && !isDraggingVertically) {
        isDraggingVertically = true;
        startPrecisionMode(e);
      }
    });
    
    slider.addEventListener('mouseup', () => {
      isDraggingVertically = false;
    });
  }
  
  // Update slider sensitivity based on precision mode
  updateSliderSensitivity(slider, precisionMode) {
    // Remove existing sensitivity classes
    slider.classList.remove('sensitivity-coarse', 'sensitivity-medium', 'sensitivity-fine');
    
    // Add appropriate sensitivity class
    slider.classList.add(`sensitivity-${precisionMode}`);
    
    // Set step based on precision mode
    let step;
    switch (precisionMode) {
      case 'fine':
        step = 1;
        break;
      case 'medium':
        step = 10;
        break;
      default: // coarse
        step = 100;
        break;
    }
    
    slider.setAttribute('step', step.toString());
  }

  // Update the value display for a specific slider
  updateValue(event) {
    const slider = event.target;
    const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
    
    const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
    
    if (valueDisplay) {
      this.updateValueDisplay(slider.value, valueDisplay);
    } else {
      console.error('[RatingSlider] Could not find value display for spectrum ID:', spectrumId);
    }
  }

  updateValueDisplay(value, valueDisplayElement) {
    valueDisplayElement.textContent = value;
    // Optional: Color update logic if desired per slider
    // const normalizedValue = (parseInt(value) + 10000) / 20000;
    // const hue = normalizedValue * 120; // 0 = red, 120 = green
    // valueDisplayElement.style.color = `hsl(${hue}, 80%, 40%)`;
  }

  // Submit the rating for a specific slider
  async submitRating(event) {
    const slider = event.target;
    const ratingValue = slider.value;
    const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
    
    console.log("[RatingSlider] Submitting rating:", {
      slider,
      ratingValue,
      spectrumId,
      dataset: slider.dataset
    });
    
    const statusDisplay = this.element.querySelector(`[data-rating-slider-target="status_${spectrumId}"]`);

    if (!spectrumId) {
      console.error("[RatingSlider] Spectrum ID not found for this slider in submitRating.");
      if (statusDisplay) statusDisplay.textContent = "Error: Spectrum ID missing";
      return;
    }
    
    // Get the target type and id either from values or data attributes
    let targetType, targetId, url;
    
    // First, try to get values from controller values
    if (this.hasTargetTypeValue && this.hasTargetIdValue) {
      targetType = this.targetTypeValue;
      targetId = this.targetIdValue;
    } 
    // Fallback to data attributes if not set as values
    else {
      targetType = this.element.dataset.ratingSliderTargetType;
      targetId = this.element.dataset.ratingSliderTargetId;
    }
    
    // Validate that we have a target
    if (!targetType || !targetId) {
      console.error("[RatingSlider] Target ID or Type not found in submitRating.", {
        hasTargetTypeValue: this.hasTargetTypeValue,
        targetTypeValue: this.targetTypeValue,
        hasTargetIdValue: this.hasTargetIdValue,
        targetIdValue: this.targetIdValue,
        elementDataset: this.element.dataset
      });
      if (statusDisplay) statusDisplay.textContent = "Error: Target missing";
      return;
    }
    
    // Ensure targetType is capitalized for the API
    targetType = targetType.charAt(0).toUpperCase() + targetType.slice(1);
    
    // Build the URL based on the target type and id
    const path = targetType.toLowerCase() + 's'; // pluralize
    url = `/${path}/${targetId}/ratings`;
    console.log('[RatingSlider] Submission details - URL:', url, 'Target ID:', targetId, 'Target Type:', targetType);

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']").content;
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
          // Send spectrum_id in the root too, some controllers might expect it for finding existing ratings
          spectrum_id: spectrumId 
        })
      });

      const data = await response.json();

      if (response.ok) {
        // Update the slider's value to the saved value, in case the controller adjusted it
        slider.value = data.rating.value;
        const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
        if (valueDisplay) this.updateValueDisplay(data.rating.value, valueDisplay);
      } else {
        console.error("Error saving rating:", data);
        console.error("Error saving rating:", data);
      }
    } catch (error) {
      console.error("Network or other error:", error);
    }
  }
}
