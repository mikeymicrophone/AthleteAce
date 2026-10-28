import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { preference: String }

  preferenceValueChanged() {
    document.documentElement.dataset.theme = this.preferenceValue
  }
}
