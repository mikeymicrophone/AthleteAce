import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["choice", "next", "heading", "feedback"]

  connect() {
    this.busy = false
  }

  headingTargetConnected(element) { element.focus({ preventScroll: true }) }
  feedbackTargetConnected(element) { element.focus({ preventScroll: true }) }

  submitting() { this.busy = true }
  submitted() { this.busy = false }

  key(event) {
    if (this.busy || event.repeat || event.altKey || event.ctrlKey || event.metaKey) return
    if (event.target.closest("input, select, textarea, a, button")) return
    if (/^[1-6]$/.test(event.key)) {
      const choice = this.choiceTargets[Number(event.key) - 1]
      if (choice && !choice.disabled) {
        event.preventDefault()
        choice.click()
      }
    } else if (event.key === "Enter" && this.hasNextTarget) {
      event.preventDefault()
      this.nextTarget.click()
    }
  }
}
