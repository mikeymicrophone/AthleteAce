import { Controller } from "@hotwired/stimulus"

// Handles collapsible sections
export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    this.isOpen = this.contentTarget.classList.contains("hidden") ? false : true
  }

  toggle() {
    this.isOpen = !this.isOpen

    this.contentTarget.classList.toggle("hidden", !this.isOpen)

    if (this.hasIconTarget) {
      this.iconTarget.classList.toggle("fa-chevron-down", !this.isOpen)
      this.iconTarget.classList.toggle("fa-chevron-up", this.isOpen)
    }
  }
}
