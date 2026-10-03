import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fallback"]

  connect() {
    this.fallbackTarget.hidden = true
  }

  update() {
    this.element.requestSubmit()
  }

  sportChanged() {
    this.element.elements.league_id.value = ""
    this.clearTeams()
    this.update()
  }

  leagueChanged() {
    this.clearTeams()
    this.update()
  }

  clearTeams() {
    for (const field of this.element.querySelectorAll('[name="team_id"], [name="team_ids[]"], [name="conference_id"], [name="division_id"], [name="city_id"], [name="state_id"]')) {
      field.disabled = true
    }
  }
}
