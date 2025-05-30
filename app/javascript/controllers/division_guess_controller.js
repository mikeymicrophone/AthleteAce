import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = [
    "gameContainer",
    "divisionChoice",
    "teamNameOverlay",
    "teamNameText",
    "progressCounter",
    "pauseButton",
    "pauseButtonText",
    "currentTeamCardDisplay",
    "attemptsContainer",
    "attemptsGrid"
  ]

  static values = {
    teamId: Number,
    correctDivisionId: Number
  }

  connect() {
    console.log("[DG Controller] connect() called")
    this.correctAnswers = 0
    this.isPaused = false
    this.isAnimating = false
    this.nextQuestionTimer = null
    this.startTime = Date.now()
    console.log("Division Guess Controller connected. Team ID:", this.teamIdValue, "Correct Division ID:", this.correctDivisionIdValue)
    
    // Listen for Turbo frame responses to update team values after a frame refresh
    document.addEventListener("turbo:frame-render", this.handleFrameRender.bind(this))
    this.loadRecentAttempts()
  }

  checkAnswer(event) {
    if (this.isPaused || this.isAnimating) return

    const button = event.currentTarget
    const divisionId = parseInt(button.dataset.divisionId)
    const isCorrect = divisionId === this.correctDivisionIdValue

    // Disable all buttons during animation
    this.divisionChoiceTargets.forEach(choice => {
      choice.disabled = true
    })

    // Show the result
    if (isCorrect) {
      button.classList.add("bg-green-500", "text-white")
      this.correctAnswers++
      this.progressCounterTarget.textContent = this.correctAnswers
    } else {
      button.classList.add("bg-red-500", "text-white")
      // Highlight the correct answer
      this.divisionChoiceTargets.find(choice => 
        parseInt(choice.dataset.divisionId) === this.correctDivisionIdValue
      ).classList.add("bg-green-500", "text-white")
    }

    // Send attempt data to server
    this.sendAttemptData(divisionId, isCorrect)

    // Show the team name overlay
    this.teamNameTextTarget.textContent = button.querySelector(".division-name").textContent
    this.teamNameOverlayTarget.classList.remove("opacity-0")
    this.teamNameOverlayTarget.classList.add("opacity-100")

    // Wait for animation to complete before loading next question
    setTimeout(() => {
      this.teamNameOverlayTarget.classList.remove("opacity-100")
      this.teamNameOverlayTarget.classList.add("opacity-0")
      
      // The next question will be loaded via Turbo Stream in the sendAttemptData method
      // No need to reload the page
    }, 1500)
  }

  async sendAttemptData(guessedDivisionId, isCorrect) {
    try {
      const response = await fetch("/play/guess-the-division", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          guessed_division_id: guessedDivisionId
        })
      })

      if (!response.ok) {
        console.error("Failed to save attempt:", await response.text())
      } else {
        // Process the Turbo Stream response
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const streamElements = doc.querySelectorAll('turbo-stream')
        
        // Apply each turbo-stream action
        streamElements.forEach(element => {
          Turbo.renderStreamMessage(element.outerHTML)
        })
      }
    } catch (error) {
      console.error("Error saving attempt:", error)
    }
  }

  loadRecentAttempts() {
    fetch("/game_attempts.json?game_type=guess_the_division&limit=10")
      .then(response => response.json())
      .then(data => {
        if (data && data.length > 0) {
          this.attemptsContainerTarget.classList.remove("hidden")
          data.forEach(attempt => this.addAttemptToGrid(attempt))
        }
      })
      .catch(error => console.error("Error loading recent attempts:", error))
  }

  addAttemptToGrid(attemptData) {
    const template = document.getElementById("attempt-template")
    const attemptCard = template.content.cloneNode(true)
    const card = attemptCard.querySelector(".attempt-card")

    // Add correct/incorrect styling
    if (attemptData.is_correct) {
      card.classList.add("border-green-500")
    } else {
      card.classList.add("border-red-500")
    }

    // Set team info
    const teamLogo = card.querySelector(".attempt-team-logo")
    const teamName = card.querySelector(".attempt-team-name")
    
    if (attemptData.subject_entity.logo_url) {
      teamLogo.src = attemptData.subject_entity.logo_url
      teamLogo.alt = `${attemptData.subject_entity.name} logo`
    } else {
      teamLogo.parentElement.innerHTML = '<i class="fas fa-shield-alt text-3xl text-gray-400"></i>'
    }
    
    teamName.textContent = attemptData.subject_entity.name

    // Set division info
    const divisionName = card.querySelector(".attempt-division-name")
    divisionName.textContent = attemptData.chosen_entity.name

    // Add to grid
    this.attemptsGridTarget.appendChild(attemptCard)

    // Limit to 20 attempts
    const attempts = this.attemptsGridTarget.children
    if (attempts.length > 20) {
      attempts[0].remove()
    }
  }

  handleFrameRender(event) {
    // Only process events for our game frame
    if (event.target.id === "division_guess_game") {
      console.log("[DG Controller] Frame rendered - updating team values")
      
      // Get new values from data attributes on the current team card
      const teamCard = this.currentTeamCardDisplayTarget
      if (teamCard) {
        const newTeamId = teamCard.dataset.teamId
        const newDivisionId = teamCard.dataset.teamDivisionId
        
        if (newTeamId && newTeamId !== String(this.teamIdValue)) {
          console.log(`[DG Controller] Updating team ID from ${this.teamIdValue} to ${newTeamId}`)
          this.teamIdValue = parseInt(newTeamId)
        }
        
        if (newDivisionId && newDivisionId !== String(this.correctDivisionIdValue)) {
          console.log(`[DG Controller] Updating correct division ID from ${this.correctDivisionIdValue} to ${newDivisionId}`)
          this.correctDivisionIdValue = parseInt(newDivisionId)
        }
        
        // Reset the timer for the new question
        this.startTime = Date.now()
      }
    }
  }

  loadNextQuestion() {
    Turbo.visit(window.location.pathname, { action: "replace" })
  }

  togglePause() {
    this.isPaused = !this.isPaused
    this.pauseButtonTextTarget.textContent = this.isPaused ? "Resume" : "Pause"
    this.pauseButtonTarget.querySelector("i").classList.toggle("fa-pause")
    this.pauseButtonTarget.querySelector("i").classList.toggle("fa-play")
    
    if (!this.isPaused && !this.isAnimating) {
      this.loadNextQuestion()
    }
  }
} 