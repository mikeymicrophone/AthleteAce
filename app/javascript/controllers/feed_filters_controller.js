import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  preserve(event) {
    if (event.target === this.element) event.preventDefault()
  }
}
