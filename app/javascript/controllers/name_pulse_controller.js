import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["firstName", "lastName"]
  static values = {
    sequence: Object
  }

  connect() {
    // Set default sequence if not provided
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
    
    // Start the animation cycle
    this.startPulseSequence()
  }

  disconnect() {
    // Clear any pending timeouts when controller disconnects
    if (this.pulseTimeout) {
      clearTimeout(this.pulseTimeout)
    }
  }

  startPulseSequence() {
    // Start with initial delay
    this.pulseTimeout = setTimeout(() => {
      this.pulseFirstName()
    }, this.sequenceValue.initialDelay)
  }

  pulseFirstName() {
    // Configure animation durations
    this.firstNameTarget.style.setProperty('--grow-duration', `${this.sequenceValue.firstName.growDuration}ms`)
    this.firstNameTarget.style.setProperty('--shrink-duration', '300ms')
    
    // Start the grow animation
    this.firstNameTarget.classList.add('pulse-grow')
    this.firstNameTarget.classList.remove('pulse-shrink')
    
    // Hold at the larger size
    this.pulseTimeout = setTimeout(() => {
      // Start the shrink animation after hold duration
      this.firstNameTarget.classList.remove('pulse-grow')
      this.firstNameTarget.classList.add('pulse-shrink')
      
      // Wait for shrink animation and pause before pulsing last name
      this.pulseTimeout = setTimeout(() => {
        // Wait for pause before pulsing last name
        this.pulseTimeout = setTimeout(() => {
          this.pulseLastName()
        }, this.sequenceValue.pause)
      }, 300) // Shrink duration
    }, this.sequenceValue.firstName.holdDuration)
  }

  pulseLastName() {
    // Configure animation durations
    this.lastNameTarget.style.setProperty('--grow-duration', `${this.sequenceValue.lastName.growDuration}ms`)
    this.lastNameTarget.style.setProperty('--shrink-duration', '300ms')
    
    // Start the grow animation
    this.lastNameTarget.classList.add('pulse-grow')
    this.lastNameTarget.classList.remove('pulse-shrink')
    
    // Hold at the larger size
    this.pulseTimeout = setTimeout(() => {
      // Start the shrink animation after hold duration
      this.lastNameTarget.classList.remove('pulse-grow')
      this.lastNameTarget.classList.add('pulse-shrink')
      
      // Wait for shrink animation before restarting cycle
      this.pulseTimeout = setTimeout(() => {
        // Restart the cycle
        this.startPulseSequence()
      }, 300) // Shrink duration
    }, this.sequenceValue.lastName.holdDuration)
  }
}
