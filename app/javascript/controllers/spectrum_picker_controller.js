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
    if (!isMulti) {
      const selected = this.spectrumButtonTargets.filter(btn => !btn.classList.contains('bg-gray-200'));
      if (selected.length > 1) selected.slice(1).forEach(btn => this.toggleButtonSelection(btn, false));
    }
    this.updateSummaryDisplay();
  }

  toggleSpectrum(event) {
    const btn = event.currentTarget;
    const id = btn.dataset.spectrumId;
    const form = this.formTarget;
    const isSelected = !btn.classList.contains('bg-gray-200');
    // Toggle UI
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

  submitForm(event) {
    event.preventDefault(); // Prevent default if called from an explicit button click within the form
    this.formTarget.requestSubmit();
  }
}
