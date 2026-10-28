import { Controller } from "@hotwired/stimulus"

// Handles collapsible sections
export default class extends Controller {
  static targets = ["content", "icon"]

  connect() {
    this.isOpen = this.contentTarget.classList.contains("hidden") ? false : true
  }

  toggle(event) {
    this.isOpen = !this.isOpen

    this.contentTarget.classList.toggle("hidden", !this.isOpen)

    event.currentTarget.setAttribute("aria-expanded", String(this.isOpen))

    if (this.hasIconTarget) {
      this.iconTarget.style.transform = this.isOpen ? "rotate(180deg)" : ""
    }
  }
}
