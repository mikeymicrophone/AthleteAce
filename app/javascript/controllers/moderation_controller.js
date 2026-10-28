import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "previous", "next", "approve", "reject", "reason", "shortcuts"]

  keydown(event) {
    if (event.ctrlKey || event.metaKey || event.altKey || event.repeat) return
    if (event.target.closest("input, textarea, select, [contenteditable]")) return

    const key = event.key.toLowerCase()
    if (key === "?" && this.hasShortcutsTarget) {
      event.preventDefault()
      this.shortcutsTarget.open = !this.shortcutsTarget.open
    } else if (key === "j" || key === "k") {
      event.preventDefault()
      if (this.hasItemTarget) {
        const index = this.itemTargets.indexOf(document.activeElement)
        const next = index < 0 ? 0 : Math.max(0, Math.min(this.itemTargets.length - 1, index + (key === "j" ? 1 : -1)))
        this.itemTargets[next].focus()
      } else if (key === "j" && this.hasNextTarget) {
        this.nextTarget.click()
      } else if (key === "k" && this.hasPreviousTarget) {
        this.previousTarget.click()
      }
    } else if (key === "a" && this.hasApproveTarget) {
      event.preventDefault()
      this.approveTarget.click()
    } else if (key === "r" && this.hasRejectTarget) {
      event.preventDefault()
      this.reasonTarget.focus()
    }
  }
}
