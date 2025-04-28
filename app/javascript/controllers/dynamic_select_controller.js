import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["targetType", "targetIdSelect"]
  static values = {
    selectedId: Number
  }

  connect() {
    // Load options when the controller connects, if a target_type is selected
    if (this.targetTypeTarget.value) {
      this.loadOptionsForType(this.targetTypeTarget.value);
    }
  }

  updateTargetOptions(event) {
    const type = event.target.value;
    if (!type) return;
    this.loadOptionsForType(type);
  }

  loadOptionsForType(type) {
    // Show loading state
    this.targetIdSelectTarget.disabled = true;
    
    fetch(`/achievements/target_options?type=${type}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        this.targetIdSelectTarget.innerHTML = "";
        
        // Add a blank option first
        const blankOpt = document.createElement("option");
        blankOpt.value = "";
        blankOpt.text = "Select...";
        this.targetIdSelectTarget.appendChild(blankOpt);
        
        // Add all options from the response
        data.forEach(option => {
          const opt = document.createElement("option");
          opt.value = option.id;
          opt.text = option.name;
          
          // If we have a previously selected ID, select it
          if (this.hasSelectedIdValue && option.id === this.selectedIdValue) {
            opt.selected = true;
          }
          
          this.targetIdSelectTarget.appendChild(opt);
        });
        
        // Re-enable the select
        this.targetIdSelectTarget.disabled = false;
      })
      .catch(error => {
        console.error("Error fetching target options:", error);
        this.targetIdSelectTarget.innerHTML = "<option>Error loading options</option>";
        this.targetIdSelectTarget.disabled = false;
      });
  }
}
