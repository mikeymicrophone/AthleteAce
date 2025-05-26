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
  
  setupEnhancedSlider(slider, spectrumId) {
    // Store the original step value
    const originalStep = slider.getAttribute('step');
    slider.dataset.originalStep = originalStep;
    
    // Track whether we're in precision mode
    let inPrecisionMode = false;
    let startY = 0;
    let currentStep = parseInt(originalStep);
    let valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
    
    // Create a precision indicator
    const precisionIndicator = document.createElement('div');
    precisionIndicator.className = 'precision-indicator hidden text-xs text-gray-500 absolute bg-white px-2 py-1 rounded-md shadow-sm';
    precisionIndicator.style.pointerEvents = 'none';
    slider.parentNode.style.position = 'relative';
    slider.parentNode.appendChild(precisionIndicator);
    
    // We'll use pointerdown/move/up for better mobile support
    slider.addEventListener('pointerdown', (e) => {
      // Don't interfere with the initial slider drag, just record the starting position
      startY = e.clientY;
      
      // Prepare the precision indicator but don't show it yet
      precisionIndicator.style.left = `${slider.offsetWidth / 2}px`;
      precisionIndicator.style.top = '25px';
    });
    
    // Listen for pointer moves on the document, not just the slider
    document.addEventListener('pointermove', (e) => {
      // Only activate precision mode if the slider is being interacted with
      if (e.buttons !== 1) return; // Left mouse button not pressed
      
      // Calculate vertical distance from start
      const verticalDistance = e.clientY - startY;
      
      // Only enter precision mode if there's significant vertical movement
      if (verticalDistance <= 5) {
        if (inPrecisionMode) {
          // Exit precision mode if user moves back up
          inPrecisionMode = false;
          slider.setAttribute('step', originalStep);
          precisionIndicator.classList.add('hidden');
        }
        return;
      }
      
      // We're now in precision mode
      inPrecisionMode = true;
      
      // Determine step size based on vertical distance
      // Default is now step=100, then 10, then 1 for finest control
      let newStep = 100; // Default is coarse control
      
      if (verticalDistance > 40) {
        newStep = 1;   // Fine control (1 by 1)
      } else if (verticalDistance > 20) {
        newStep = 10;  // Medium control (10s)
      }
      
      // Update the step
      currentStep = newStep;
      slider.setAttribute('step', newStep.toString());
      
      // Show the precision indicator
      precisionIndicator.classList.remove('hidden');
      precisionIndicator.textContent = `Step: ${newStep}`;
      
      // Apply different styles based on precision level
      precisionIndicator.className = 'precision-indicator text-xs absolute bg-white px-2 py-1 rounded-md shadow-sm';
      if (newStep === 1) {
        precisionIndicator.classList.add('text-green-600', 'font-bold'); // Fine precision (1s)
      } else if (newStep === 10) {
        precisionIndicator.classList.add('text-blue-600'); // Medium precision (10s)
      } else {
        precisionIndicator.classList.add('text-gray-500'); // Coarse precision (100s, default)
      }
    });
    
    const endPrecisionMode = () => {
      if (!inPrecisionMode) return;
      
      inPrecisionMode = false;
      slider.setAttribute('step', originalStep); // Reset to original step
      precisionIndicator.classList.add('hidden');
    };
    
    document.addEventListener('pointerup', endPrecisionMode);
    document.addEventListener('pointercancel', endPrecisionMode);
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
