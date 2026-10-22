import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fallback"]

  connect() {
    this.fallbackTarget.hidden = true
  }

  update() {
    this.element.requestSubmit()
  }

  gameChanged() {
    if (!["player_team_match", "name_ciphers", "multiple_choice", "image_recognition"].includes(this.element.elements.game_type.value)) this.clearSeason()
    this.update()
  }

  groupChanged() {
    const snapshot = this.element.elements.goal_achievement_id
    if (snapshot) snapshot.disabled = true
    const filter = this.element.elements.practice_filter
    if (filter && !this.element.elements.player_group_id.value) filter.disabled = true
    this.update()
  }

  seasonChanged() {
    this.element.elements.team_query.value = ""
    this.update()
  }

  clearSeason() {
    const field = this.element.elements.season_id
    if (field) field.disabled = true
  }

  anyTeam() {
    for (const field of this.element.querySelectorAll('[name="team_ids[]"]')) {
      field.checked = false
    }
    this.update()
  }

  sportChanged() {
    this.element.elements.league_id.value = ""
    this.clearSeason()
    this.clearTeams()
    this.update()
  }

  leagueChanged() {
    this.clearSeason()
    this.clearTeams()
    this.update()
  }

  clearTeams() {
    this.element.elements.team_query.value = ""
    for (const field of this.element.querySelectorAll('[name="team_id"], [name="team_ids[]"], [name="conference_id"], [name="division_id"], [name="city_id"], [name="state_id"]')) {
      field.disabled = true
    }
  }
}
