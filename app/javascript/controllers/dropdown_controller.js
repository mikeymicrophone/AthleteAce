import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "toggle"]

  connect() {
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    document.addEventListener("click", this.boundCloseOnClickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
  }

  toggle(event) {
    event.stopPropagation()
    if (this.menuTarget.classList.contains("active")) {
      this.close()
    } else {
      document.querySelectorAll(".nav-dropdown").forEach(menu => menu.classList.remove("active"))
      document.querySelectorAll("[data-dropdown-target='toggle']").forEach(toggle => toggle.setAttribute("aria-expanded", "false"))
      this.menuTarget.classList.add("active")
      this.toggleTarget.setAttribute("aria-expanded", "true")
    }
  }

  close() {
    this.menuTarget.classList.remove("active")
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  escape() {
    this.close()
    this.toggleTarget.focus()
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) this.close()
  }
}
