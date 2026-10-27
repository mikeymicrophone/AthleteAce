import { Controller } from "@hotwired/stimulus"

// Steps through flash cards. With a delay, each card shows its team, fades in
// the position partway through, then moves on by itself.
export default class extends Controller {
  static targets = ["card", "counter", "progress", "finish", "previous", "pause", "next"]
  static values = { delay: Number }

  connect() {
    this.playing = this.delayValue > 0
    this.show(0)
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
      this.cardTargets[this.index]?.classList.add("flash-card-revealed")
    }
  }

  key(event) {
    if (event.target.closest("button, a, input, select, textarea")) return

    if (event.key === "ArrowRight") this.next()
    else if (event.key === "ArrowLeft") this.previous()
    else if (event.key === " " && this.delayValue > 0) this.toggle()
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
      card.classList.toggle("flash-card-revealed", !this.playing)
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

    this.revealTimer = setTimeout(() => card.classList.add("flash-card-revealed"), this.delayValue * 350)
    this.advanceTimer = setTimeout(() => this.next(), this.delayValue * 1000)
  }

  clearTimers() {
    clearTimeout(this.revealTimer)
    clearTimeout(this.advanceTimer)
  }
}
