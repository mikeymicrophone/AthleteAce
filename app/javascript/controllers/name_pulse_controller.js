import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstName", "lastName"]
  static values = {
    sequence: Object
  }

  static SHRINK_DURATION = 300

  connect() {
    this.animationTimer = null

    if (!this.hasSequenceValue) {
      this.sequenceValue = {
        initialDelay: 1000,
        firstName: {
          growDuration: 500,
          holdDuration: 500
        },
        pause: 800,
        lastName: {
          growDuration: 800,
          holdDuration: 800
        }
      }
    }

    this.startPulseSequence()
  }

  disconnect() {
    if (this.animationTimer) {
      clearTimeout(this.animationTimer)
    }
  }

  startPulseSequence() {
    this.animationTimer = setTimeout(() => {
      this.pulseFirstName()
    }, this.sequenceValue.initialDelay)
  }

  pulseFirstName() {
    this.firstNameTarget.style.setProperty('--grow-duration', `${this.sequenceValue.firstName.growDuration}ms`)
    this.firstNameTarget.style.setProperty('--shrink-duration', `${this.constructor.SHRINK_DURATION}ms`)

    this.firstNameTarget.classList.add('pulse-grow')
    this.firstNameTarget.classList.remove('pulse-shrink')

    this.animationTimer = setTimeout(() => {
      this.firstNameTarget.classList.remove('pulse-grow')
      this.firstNameTarget.classList.add('pulse-shrink')

      this.animationTimer = setTimeout(() => {
        this.animationTimer = setTimeout(() => {
          this.pulseLastName()
        }, this.sequenceValue.pause)
      }, this.constructor.SHRINK_DURATION)
    }, this.sequenceValue.firstName.holdDuration)
  }

  pulseLastName() {
    this.lastNameTarget.style.setProperty('--grow-duration', `${this.sequenceValue.lastName.growDuration}ms`)
    this.lastNameTarget.style.setProperty('--shrink-duration', `${this.constructor.SHRINK_DURATION}ms`)

    this.lastNameTarget.classList.add('pulse-grow')
    this.lastNameTarget.classList.remove('pulse-shrink')

    this.animationTimer = setTimeout(() => {
      this.lastNameTarget.classList.remove('pulse-grow')
      this.lastNameTarget.classList.add('pulse-shrink')

      this.animationTimer = setTimeout(() => {
        this.startPulseSequence()
      }, this.constructor.SHRINK_DURATION)
    }, this.sequenceValue.lastName.holdDuration)
  }
}
