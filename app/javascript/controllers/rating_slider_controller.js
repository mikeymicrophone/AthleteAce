import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="rating-slider"
export default class extends Controller {
  // Targets are now dynamically handled based on spectrum_id, but we can define the pattern.
  // For instance, slider_*, value_*, status_*
  // We still need a general target for the sliders if we iterate them.
  static targets = [/* "slider", "value", "status" // These will be qualified by spectrum_id */]
  static values = { 
    playerId: Number,
    teamId: Number
    // currentSpectrum, selectedSpectrums, multiMode are no longer needed here
  }

  connect() {
    this.initializeAllSliders();
  }

  initializeAllSliders() {
    const sliders = this.element.querySelectorAll('.rating-slider-input');
    sliders.forEach(slider => {
      const spectrumId = slider.dataset.ratingSliderSpectrumIdParam;
      const valueDisplay = this.element.querySelector(`[data-rating-slider-target="value_${spectrumId}"]`);
      if (valueDisplay) {
        this.updateValueDisplay(slider.value, valueDisplay);
      }
    });
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
    
    const statusDisplay = this.element.querySelector(`[data-rating-slider-target="status_${spectrumId}"]`);

    if (!spectrumId) {
      console.error("[RatingSlider] Spectrum ID not found for this slider in submitRating.");
      if (statusDisplay) statusDisplay.textContent = "Error: Spectrum ID missing";
      return;
    }

    let targetId, targetType, url;
    if (this.hasPlayerIdValue && this.playerIdValue) {
      targetId = this.playerIdValue;
      targetType = 'Player';
      url = `/players/${targetId}/ratings`;
    } else if (this.hasTeamIdValue && this.teamIdValue) {
      targetId = this.teamIdValue;
      targetType = 'Team';
      url = `/teams/${targetId}/ratings`;
    } else {
      console.error("[RatingSlider] Target ID or Type not found in submitRating.");
      if (statusDisplay) statusDisplay.textContent = "Error: Target missing";
      return;
    }
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
