// app/javascript/controllers/autosubmit_controller.js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="autosubmit"
export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }
}
