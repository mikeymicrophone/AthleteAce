import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dropdown"
export default class extends Controller {
  static targets = ["menu"]
  
  connect() {
    // Close dropdown when clicking outside
    document.addEventListener("click", this.closeOnClickOutside.bind(this))
  }
  
  disconnect() {
    document.removeEventListener("click", this.closeOnClickOutside.bind(this))
  }
  
  toggle(event) {
    event.stopPropagation()
    const menu = this.menuTarget
    
    if (menu.classList.contains("active")) {
      this.close()
    } else {
      this.closeAllDropdowns()
      this.open()
    }
  }
  
  open() {
    this.menuTarget.classList.add("active")
  }
  
  close() {
    this.menuTarget.classList.remove("active")
  }
  
  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }
  
  closeAllDropdowns() {
    document.querySelectorAll(".nav-dropdown").forEach(dropdown => {
      dropdown.classList.remove("active")
    })
  }
}
