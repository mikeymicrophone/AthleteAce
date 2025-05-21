import { Controller } from "@hotwired/stimulus"

// Handles collapsible sections
export default class extends Controller {
  static targets = ["content"]
  
  connect() {
    // Initialize the collapse state
    this.isOpen = false
  }
  
  toggle() {
    this.isOpen = !this.isOpen
    
    if (this.isOpen) {
      this.contentTarget.classList.remove("hidden")
      // Update the icon if it exists
      const icon = this.element.querySelector(".fa-chevron-down")
      if (icon) {
        icon.classList.remove("fa-chevron-down")
        icon.classList.add("fa-chevron-up")
      }
    } else {
      this.contentTarget.classList.add("hidden")
      // Update the icon if it exists
      const icon = this.element.querySelector(".fa-chevron-up")
      if (icon) {
        icon.classList.remove("fa-chevron-up")
        icon.classList.add("fa-chevron-down")
      }
    }
  }
}
