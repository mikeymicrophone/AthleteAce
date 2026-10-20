import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["account", "toggle"]

  open() {
    this.accountTarget.showModal()
    this.toggleTarget.setAttribute("aria-expanded", "true")
  }

  close() {
    this.accountTarget.close()
  }

  closed() {
    this.toggleTarget.setAttribute("aria-expanded", "false")
  }

  backdrop(event) {
    if (event.target === this.accountTarget) this.close()
  }
}
