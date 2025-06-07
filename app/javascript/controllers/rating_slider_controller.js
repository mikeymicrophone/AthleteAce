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
    console.log('[RatingSlider] TEMP: connect() called');
    this.initializeAllSliders();
  }

  initializeAllSliders() {
    console.log('[RatingSlider] TEMP: initializeAllSliders() called');
    // Look for range inputs with the class that matches what's in the DOM
    const sliders = this.element.querySelectorAll('input[type="range"].rating-slider-input');
    console.log('[RatingSlider] Found sliders:', sliders.length);
    console.log('[RatingSlider] TEMP: Found', sliders.length, 'sliders');
    
    sliders.forEach((slider, index) => {
      const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
      console.log(`[RatingSlider] TEMP: Processing slider ${index + 1}/${sliders.length} for spectrum:`, spectrumId);
      console.log('[RatingSlider] Initializing slider for spectrum:', spectrumId, slider);
      
      // Find the value display element
      const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
      if (valueDisplay) {
        this.updateValueDisplay(slider.value, valueDisplay);
        console.log('[RatingSlider] Updated value display for spectrum:', spectrumId);
        console.log('[RatingSlider] TEMP: Successfully updated value display');
      } else {
        console.error('[RatingSlider] Could not find value display for spectrum ID:', spectrumId);
        console.error('[RatingSlider] TEMP: Failed to find value display');
      }
      
      // Set up enhanced slider control
      console.log('[RatingSlider] TEMP: About to call initializeSlider()');
      this.initializeSlider(slider, spectrumId);
      console.log('[RatingSlider] TEMP: Completed initializeSlider()');
    });
    console.log('[RatingSlider] TEMP: initializeAllSliders() completed');
  }
  
  initializeSlider(slider, spectrumId) {
    console.log('[RatingSlider] TEMP: initializeSlider() called with spectrumId:', spectrumId);
    if (!slider) {
      console.log('[RatingSlider] TEMP: No slider provided, returning early');
      return;
    }
    
    const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
    const statusDisplay = this.element.querySelector(`[data-rating-slider-target="status_${spectrumId}"]`);
    
    // Store original step value for later restoration
    const originalStep = slider.dataset.ratingSliderOriginalStep || slider.getAttribute('step');
    
    // Variables for precision mode
    let inPrecisionMode = false;
    let startY = 0;
    let currentStep = originalStep;
    let currentPrecisionMode = 'coarse'; // Always start in coarse mode
    let sliderContainer = slider.parentNode;
    
    // Create precision indicator element
    const precisionIndicator = document.createElement('div');
    precisionIndicator.className = 'precision-indicator hidden';
    sliderContainer.appendChild(precisionIndicator);
    
    // Ensure the slider container has position relative for absolute positioning of the indicator
    sliderContainer.style.position = 'relative';
    
    // Store initial value as base value
    slider._baseValue = parseInt(slider.value);
    
    // Initialize the element's precision mode dataset
    this.element.dataset.ratingSliderPrecisionMode = currentPrecisionMode;
    
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
      console.log('[RatingSlider] TEMP: startPrecisionMode() called');
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
      console.log('[RatingSlider] TEMP: updatePrecision() called, inPrecisionMode:', inPrecisionMode);
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
        console.log('[RatingSlider] TEMP: Precision mode changing from', currentPrecisionMode, 'to', newPrecisionMode);
        currentPrecisionMode = newPrecisionMode;
        this.element.dataset.ratingSliderPrecisionMode = currentPrecisionMode;
        
        // Update the base value to the current slider value when switching modes
        slider._baseValue = parseInt(slider.value);
        console.log('[RatingSlider] TEMP: Updated slider._baseValue to', slider._baseValue);
        
        // Update slider sensitivity based on new precision mode
        console.log('[RatingSlider] TEMP: About to call updateSliderSensitivity()');
        this.updateSliderSensitivity(slider, currentPrecisionMode);
        
        // Update the indicator
        precisionIndicator.className = 'precision-indicator';
        precisionIndicator.classList.add(`precision-${currentPrecisionMode}`);
        precisionIndicator.textContent = `Step: ${newStep}`;
        
        // Update the slider step
        currentStep = newStep;
        
        // Log for debugging
        console.log(`Precision mode: ${currentPrecisionMode}, Step: ${newStep}, Distance: ${verticalDistance}`);
      }
      
      // Prevent default to avoid scrolling
      e.preventDefault();
    };
    
    const endPrecisionMode = () => {
      console.log('[RatingSlider] TEMP: endPrecisionMode() called, inPrecisionMode:', inPrecisionMode);
      if (!inPrecisionMode) return;
      
      inPrecisionMode = false;
      
      // Remove global event listeners
      document.removeEventListener('mousemove', updatePrecision);
      document.removeEventListener('mouseup', endPrecisionMode);
      document.removeEventListener('touchmove', updatePrecision);
      document.removeEventListener('touchend', endPrecisionMode);
      
      // Hide the precision indicator
      precisionIndicator.classList.add('hidden');
      
      // Reset to coarse mode
      currentPrecisionMode = 'coarse';
      this.element.dataset.ratingSliderPrecisionMode = currentPrecisionMode;
      
      // Clean up precision handler
      if (slider._precisionInputHandler) {
        slider.removeEventListener('input', slider._precisionInputHandler);
        slider._precisionInputHandler = null;
      }
      
      this.updateSliderSensitivity(slider, currentPrecisionMode);
      
      // Hide the precision handle if not hovering
      if (!slider.matches(':hover') && !precisionHandle.matches(':hover')) {
        precisionHandle.classList.add('hidden');
      }
    };
    
    // Attach the precision mode events to the handle
    precisionHandle.addEventListener('mousedown', startPrecisionMode);
    precisionHandle.addEventListener('touchstart', startPrecisionMode, { passive: false });
    
    // Enhanced mouse tracking for precision mode activation only
    let dragStartY = 0;
    let dragStartX = 0;
    let isDraggingVertically = false;
    let hasMovedHorizontally = false;
    
    slider.addEventListener('mousedown', (e) => {
      dragStartY = e.clientY;
      dragStartX = e.clientX;
      isDraggingVertically = false;
      hasMovedHorizontally = false;
    });
    
    slider.addEventListener('mousemove', (e) => {
      if (e.buttons !== 1) return; // Not dragging
      
      const verticalDelta = Math.abs(e.clientY - dragStartY);
      const horizontalDelta = Math.abs(e.clientX - dragStartX);
      
      // Track if we've moved horizontally (normal slider usage)
      if (horizontalDelta > 5) {
        hasMovedHorizontally = true;
      }
      
      // Only enter precision mode if:
      // 1. We haven't moved horizontally much (not normal slider usage)
      // 2. Vertical movement is substantial (50px+)
      // 3. Vertical movement is much more than horizontal movement
      // 4. We're not already in precision mode
      if (!hasMovedHorizontally && 
          verticalDelta > 50 && 
          verticalDelta > horizontalDelta * 3 && 
          !isDraggingVertically && 
          !inPrecisionMode) {
        isDraggingVertically = true;
        startPrecisionMode(e);
        e.preventDefault();
      }
    });
    
    slider.addEventListener('mouseup', () => {
      isDraggingVertically = false;
      hasMovedHorizontally = false;
    });
    
    // Add a basic input listener for normal slider operation
    slider.addEventListener('input', (e) => {
      console.log('[RatingSlider] TEMP: Basic input listener triggered, value:', e.target.value);
      // This will be handled by the Stimulus action in the HTML: "input->rating-slider#updateValue"
    });
  }
  
  // Update slider sensitivity based on precision mode
  updateSliderSensitivity(slider, precisionMode) {
    console.log('[RatingSlider] TEMP: updateSliderSensitivity() called with precisionMode:', precisionMode);
    // Remove existing sensitivity classes
    slider.classList.remove('sensitivity-coarse', 'sensitivity-medium', 'sensitivity-fine');
    
    // Add appropriate sensitivity class
    slider.classList.add(`sensitivity-${precisionMode}`);
    console.log('[RatingSlider] TEMP: Added CSS class sensitivity-' + precisionMode);
    
    // Always keep step at a reasonable size for responsiveness, but store precision mode
    slider.setAttribute('step', '100'); // Keep step consistent for responsiveness
    
    // Store the current precision mode for custom handling
    slider.dataset.currentPrecisionMode = precisionMode;
    console.log('[RatingSlider] TEMP: Set slider.dataset.currentPrecisionMode to:', precisionMode);
    
    // Set up custom input handling for precision modes
    console.log('[RatingSlider] TEMP: About to call setupPrecisionInputHandling()');
    this.setupPrecisionInputHandling(slider, precisionMode);
    console.log('[RatingSlider] TEMP: updateSliderSensitivity() completed');
  }
  
  // Set up custom input handling for precision modes
  setupPrecisionInputHandling(slider, precisionMode) {
    console.log('[RatingSlider] TEMP: setupPrecisionInputHandling() called with precisionMode:', precisionMode);
    // Remove any existing precision input listener
    if (slider._precisionInputHandler) {
      console.log('[RatingSlider] TEMP: Removing existing precision input handler');
      slider.removeEventListener('input', slider._precisionInputHandler);
    }
    
    // Only add custom handling for non-coarse modes
    if (precisionMode !== 'coarse') {
      console.log('[RatingSlider] TEMP: Setting up custom precision input handling for', precisionMode, 'mode');
      const baseValue = slider._baseValue || parseInt(slider.value);
      const startValue = parseInt(slider.value);
      
      slider._precisionInputHandler = (e) => {
        console.log('[RatingSlider] TEMP: Precision input handler triggered');
        
        // Only apply precision handling if we're actually in precision mode
        const currentPrecisionMode = this.element.dataset.ratingSliderPrecisionMode;
        if (currentPrecisionMode === 'coarse') {
          console.log('[RatingSlider] TEMP: In coarse mode, letting normal handling proceed');
          return; // Let the normal updateValue handle it
        }
        
        const currentSliderValue = parseInt(e.target.value);
        const rawDelta = currentSliderValue - baseValue;
        console.log('[RatingSlider] TEMP: currentSliderValue:', currentSliderValue, 'baseValue:', baseValue, 'rawDelta:', rawDelta);
        
        // Apply sensitivity scaling
        let sensitivity;
        let snapStep;
        switch (precisionMode) {
          case 'fine':
            sensitivity = 0.1; // Very fine control
            snapStep = 1;
            break;
          case 'medium':
            sensitivity = 0.3; // Medium control
            snapStep = 10;
            break;
          default:
            sensitivity = 1;
            snapStep = 100;
        }
        
        // Calculate the scaled value
        const scaledDelta = rawDelta * sensitivity;
        let newValue = startValue + scaledDelta;
        console.log('[RatingSlider] TEMP: scaledDelta:', scaledDelta, 'startValue:', startValue, 'newValue before snap:', newValue);
        
        // Snap to the appropriate step
        newValue = Math.round(newValue / snapStep) * snapStep;
        console.log('[RatingSlider] TEMP: newValue after snap:', newValue, 'snapStep:', snapStep);
        
        // Clamp to bounds
        newValue = Math.max(parseInt(slider.min), Math.min(parseInt(slider.max), newValue));
        console.log('[RatingSlider] TEMP: newValue after clamp:', newValue);
        
        // Update the actual value without triggering this handler again
        slider.removeEventListener('input', slider._precisionInputHandler);
        slider.value = newValue;
        slider.addEventListener('input', slider._precisionInputHandler);
        
        // Update the display
        console.log("Slider dataset:", slider.dataset);
        const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
        console.log("spectrumId:", spectrumId);
        const selector = `[data-rating-slider-target="value_${spectrumId}"]`;
        console.log("Selector for valueDisplay:", selector);
        console.log("this.element for querySelector:", this.element);
        const valueDisplay = this.element.querySelector(selector);
        console.log("valueDisplay element:", valueDisplay);
        if (valueDisplay) {
          this.updateValueDisplay(newValue, valueDisplay);
        }
      };
      
      slider.addEventListener('input', slider._precisionInputHandler);
      console.log('[RatingSlider] TEMP: Added precision input handler');
    } else {
      console.log('[RatingSlider] TEMP: Coarse mode - no custom input handling needed');
    }
    
    // Store the base value for precision calculations
    slider._baseValue = parseInt(slider.value);
    console.log('[RatingSlider] TEMP: setupPrecisionInputHandling() completed, baseValue set to:', slider._baseValue);
  }

  // Update the value display for a specific slider
  updateValue(event) {
    console.log('[RatingSlider] TEMP: updateValue() called');
    const slider = event.target;
    const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
    console.log('[RatingSlider] TEMP: updateValue() spectrumId:', spectrumId, 'slider value:', slider.value);
    
    const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
    
    if (valueDisplay) {
      this.updateValueDisplay(slider.value, valueDisplay);
      console.log('[RatingSlider] TEMP: updateValue() completed successfully');
    } else {
      console.error('[RatingSlider] Could not find value display for spectrum ID:', spectrumId);
      console.error('[RatingSlider] TEMP: updateValue() failed - no value display found');
    }
  }

  updateValueDisplay(value, valueDisplayElement) {
    console.log('[RatingSlider] TEMP: updateValueDisplay() called with value:', value);
    // Update the value display with the current value
    if (valueDisplayElement) {
      valueDisplayElement.textContent = value;
      console.log('[RatingSlider] TEMP: updateValueDisplay() completed - updated element to:', value);
    } else {
      console.log('[RatingSlider] TEMP: updateValueDisplay() - no valueDisplayElement provided');
    }
  }
  
  // Handle spectrum selection changes
  updateSelectedSpectrum(event) {
    const selectElement = event.target;
    const spectrumId = selectElement.value;
    const playerId = selectElement.dataset.playerId;
    
    console.log('[RatingSlider] Spectrum selection changed:', {
      spectrumId,
      playerId,
      selectElement
    });
    
    // Find the player's rating container
    const playerContainer = selectElement.closest('.player-section');
    if (!playerContainer) {
      console.error('[RatingSlider] Could not find player container');
      return;
    }
    
    // Find the rating slider container
    const ratingContainer = playerContainer.querySelector('.rating-slider-group-container');
    if (!ratingContainer) {
      console.error('[RatingSlider] Could not find rating container');
      return;
    }
    
    // Make an AJAX request to get the slider for the selected spectrum
    fetch(`/players/${playerId}/ratings/new?spectrum_id=${spectrumId}`, {
      headers: {
        'Accept': 'text/html',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.text())
    .then(html => {
      // Replace the current slider with the new one
      ratingContainer.innerHTML = html;
      
      // Re-initialize the sliders
      this.initializeAllSliders();
    })
    .catch(error => {
      console.error('[RatingSlider] Error fetching spectrum slider:', error);
    });
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
