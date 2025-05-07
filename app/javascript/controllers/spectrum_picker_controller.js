import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="spectrum-picker"
export default class extends Controller {
  static targets = [
    "form",
    "summaryDisplay",
    "toggleIcon",
    "expandableContent",
    "multiSelectToggle",
    "checkboxContainer", // For the div holding all checkboxes
    "spectrumCheckbox"   // For individual spectrum checkboxes
  ]

  static values = {
    // We might pass initial selected IDs or all spectrums as JSON if needed later
    // For now, ERB handles initial state of checkboxes
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
    const checkedCheckboxes = this.spectrumCheckboxTargets.filter(cb => cb.checked);
    const selectedNames = checkedCheckboxes.map(cb => {
      const label = cb.closest('label').querySelector('span');
      return label ? label.textContent.trim() : 'Unknown';
    });

    if (selectedNames.length > 0) {
      this.summaryDisplayTarget.textContent = `Spectrums: ${selectedNames.join(', ')}`;
    } else {
      this.summaryDisplayTarget.textContent = "Spectrums: None";
    }
    // Truncate if too long (optional, can be done with CSS too)
    if (selectedNames.join(', ').length > 25) { // Adjust character limit as needed
        this.summaryDisplayTarget.textContent = `Spectrums: ${selectedNames.length} selected`;
    }
  }
  
  updateMultiSelectToggleState() {
    const checkedCount = this.spectrumCheckboxTargets.filter(cb => cb.checked).length;
    // If more than one is checked, or if none are checked but multi-select was intended (e.g. from previous state), keep it checked.
    // The ERB handles the initial 'checked' state of the multi-select toggle based on selected_spectrum_ids.count.
    // This JS primarily ensures consistency if we manipulate checkboxes client-side before form submission.
    if (this.hasMultiSelectToggleTarget) {
        // this.multiSelectToggleTarget.checked should already be set by ERB based on selected_spectrum_ids
        // This is more for future dynamic client-side updates if needed
    }
  }

  handleMultiSelectToggle(event) {
    const isMultiSelectEnabled = event.target.checked;
    if (!isMultiSelectEnabled) {
      // If multi-select is disabled, ensure only one (or zero) checkbox is selected.
      // Keep the last interacted one or the first checked one.
      const checkedCheckboxes = this.spectrumCheckboxTargets.filter(cb => cb.checked);
      if (checkedCheckboxes.length > 1) {
        // Uncheck all but the first one found (or based on a specific logic, e.g. last clicked prior to disabling)
        // For simplicity, let's keep the first one in the DOM order that's checked.
        const firstChecked = checkedCheckboxes[0];
        checkedCheckboxes.forEach(cb => {
          if (cb !== firstChecked) {
            cb.checked = false;
          }
        });
      }
    }
    this.updateSummaryDisplay();
  }

  handleCheckboxChange(event) {
    if (this.hasMultiSelectToggleTarget && !this.multiSelectToggleTarget.checked) {
      // Single-select mode: uncheck others if this one is checked
      if (event.target.checked) {
        this.spectrumCheckboxTargets.forEach(cb => {
          if (cb !== event.target) {
            cb.checked = false;
          }
        });
      }
    }
    this.updateSummaryDisplay();
  }

  submitForm(event) {
    event.preventDefault(); // Prevent default if called from an explicit button click within the form
    this.formTarget.requestSubmit();
  }
  
  // Helper to get all spectrum IDs that are currently checked
  getCheckedSpectrumIds() {
    return this.spectrumCheckboxTargets.filter(cb => cb.checked).map(cb => cb.value);
  }
}
