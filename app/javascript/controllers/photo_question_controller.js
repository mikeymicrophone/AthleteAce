import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["error"]

  connect() {
    const photo = this.element.querySelector("img")
    if (photo.complete && !photo.naturalWidth) this.failed()
  }

  failed() {
    this.errorTarget.hidden = false
    const frame = this.element.closest("turbo-frame")
    for (const button of frame.querySelectorAll('[name="choice_id"]')) button.disabled = true
  }
}
