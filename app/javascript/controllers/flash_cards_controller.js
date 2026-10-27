import { Controller } from "@hotwired/stimulus"

// Steps through flash cards. With a delay, each card shows the name, then
// fades in the team, then the position, and moves on by itself. A card's
// data-step (1 name, 2 team, 3 position) drives the fades.
export default class extends Controller {
  static targets = ["card", "counter", "progress", "finish", "previous", "pause", "next", "pace", "paceLink", "delay"]
  static values = { delay: Number }

  connect() {
    this.playing = this.delayValue > 0
    this.show(0)
  }

  // Switching pace mid-deck restarts the current card at the new pace and
  // keeps the URL and links in step, so a reload or shuffle keeps it too.
  changeDelay(event) {
    this.delayValue = Number(event.currentTarget.dataset.delay)
    for (const button of this.delayTargets) button.setAttribute("aria-pressed", button === event.currentTarget)
    this.playing = this.delayValue > 0
    this.pauseTarget.textContent = "Pause"
    this.pauseTarget.setAttribute("aria-pressed", false)
    this.paceTarget.textContent = this.playing ? `${this.delayValue}s per card` : "At your pace"
    const location = new URL(window.location.href)
    location.searchParams.set("delay", this.delayValue)
    window.history.replaceState(window.history.state, "", location)
    for (const link of this.paceLinkTargets) {
      const url = new URL(link.href)
      url.searchParams.set("delay", this.delayValue)
      link.href = url
    }
    this.show(this.index)
  }

  disconnect() {
    this.clearTimers()
  }

  next() {
    this.show(this.index + 1)
  }

  previous() {
    if (this.index > 0) this.show(this.index - 1)
  }

  toggle() {
    this.playing = !this.playing
    this.pauseTarget.textContent = this.playing ? "Pause" : "Play"
    this.pauseTarget.setAttribute("aria-pressed", !this.playing)
    if (this.playing) {
      this.schedule()
    } else {
      this.clearTimers()
      const card = this.cardTargets[this.index]
      if (card) card.dataset.step = 3
    }
  }

  key(event) {
    if (event.target.closest("input, select, textarea")) return

    if (event.key === "ArrowRight") this.next()
    else if (event.key === "ArrowLeft") this.previous()
    else if (event.key === " " && this.delayValue > 0 && !event.target.closest("button, a")) this.toggle()
    else return
    event.preventDefault()
  }

  show(index) {
    this.clearTimers()
    const total = this.cardTargets.length
    this.index = Math.min(index, total)
    const finished = this.index === total

    this.cardTargets.forEach((card, position) => {
      card.hidden = position !== this.index
      card.dataset.step = this.playing ? 1 : 3
    })
    this.finishTarget.hidden = !finished
    this.counterTarget.textContent = `${Math.min(this.index + 1, total)} / ${total}`
    this.progressTarget.value = Math.min(this.index + 1, total)
    this.previousTarget.disabled = this.index === 0
    this.nextTarget.hidden = finished
    this.pauseTarget.hidden = finished || this.delayValue === 0
    if (this.playing && !finished) this.schedule()
  }

  schedule() {
    const card = this.cardTargets[this.index]
    if (!card) return

    this.teamTimer = setTimeout(() => card.dataset.step = Math.max(card.dataset.step, 2), this.delayValue * 300)
    this.positionTimer = setTimeout(() => card.dataset.step = 3, this.delayValue * 600)
    this.advanceTimer = setTimeout(() => this.next(), this.delayValue * 1000)
  }

  clearTimers() {
    clearTimeout(this.teamTimer)
    clearTimeout(this.positionTimer)
    clearTimeout(this.advanceTimer)
  }
}
