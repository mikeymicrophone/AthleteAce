import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { preference: String }

  connect() {
    document.documentElement.dataset.theme = this.preferenceValue
  }
}
