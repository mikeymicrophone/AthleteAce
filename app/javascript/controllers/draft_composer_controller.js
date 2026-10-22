import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["searchForm", "selected", "type", "id", "message", "count", "preview", "previewName", "save"]

  connect() {
    this.update()
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  search() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.searchFormTarget.requestSubmit(), 250)
  }

  choose(event) {
    const choice = event.currentTarget.dataset
    this.typeTarget.value = choice.targetType
    this.idTarget.value = choice.targetId
    this.selectedTarget.textContent = choice.targetName
    this.previewNameTarget.textContent = choice.targetName
    this.messageTarget.focus()
    this.update()
  }

  emoji(event) {
    const message = this.messageTarget
    message.setRangeText(event.currentTarget.dataset.emoji, message.selectionStart, message.selectionEnd, "end")
    message.focus()
    this.update()
  }

  update() {
    const message = this.messageTarget.value.replace(/^\p{White_Space}+|\p{White_Space}+$/gu, "")
    const length = Array.from(message).length
    this.countTarget.textContent = `${length} / 200 characters`
    this.previewTarget.textContent = message || "Your message will appear here."
    this.saveTarget.disabled = !this.idTarget.value || length === 0 || length > 200
  }
}
