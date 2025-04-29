import { Controller } from "@hotwired/stimulus"

// Manages the cipher solution reveal functionality
export default class extends Controller {
  static targets = ["solution"]
  
  toggleSolution(event) {
    this.solutionTarget.classList.toggle("hidden")
    
    // Toggle button text
    const button = event.currentTarget
    button.textContent = this.solutionTarget.classList.contains("hidden") 
      ? "Reveal Solution" 
      : "Hide Solution"
  }
}
