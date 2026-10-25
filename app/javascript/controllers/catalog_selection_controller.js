import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["all", "item", "count", "submit"]

  connect() {
    this.itemTargets.forEach(item => { item.checked = false })
    this.update()
  }

  toggleAll() {
    this.itemTargets.forEach(item => { item.checked = this.allTarget.checked })
    this.update()
  }

  update() {
    const count = this.itemTargets.filter(item => item.checked).length
    this.countTarget.textContent = `${count} selected`
    this.allTarget.checked = count > 0 && count === this.itemTargets.length
    this.allTarget.indeterminate = count > 0 && count < this.itemTargets.length
    this.allTarget.disabled = this.itemTargets.length === 0
    this.submitTarget.disabled = count === 0
  }
}
