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
    subjectId: Number,
    correctAnswerId: Number
  }

  connect() {
    console.log("[DG Controller] connect() called")
    this.correctAnswers = 0
    this.isPaused = false
    this.isAnimating = false
    this.nextQuestionTimer = null
    this.startTime = Date.now()
    console.log("Division Guess Controller connected. Subject ID:", this.subjectIdValue, "Correct Answer ID:", this.correctAnswerIdValue)
    
    // Listen for Turbo frame responses to update team values after a frame refresh
    document.addEventListener("turbo:frame-render", this.handleFrameRender.bind(this))
    this.loadRecentAttempts()
  }

  disconnect() {
    console.log("[DG Controller] disconnect() called")
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }
    
    // Clean up event listener
    document.removeEventListener("turbo:frame-render", this.handleFrameRender.bind(this))
  }

  checkAnswer(event) {
    console.log("[DG Controller] checkAnswer() called")
    if (this.isPaused || this.isAnimating) {
      console.log("[DG Controller] checkAnswer() - bailing: isPaused or isAnimating is true")
      return
    }
    
    console.log("[DG Controller] checkAnswer() - proceeding")
    this.isAnimating = true
    console.log("[DG Controller] checkAnswer() - isAnimating set to true")

    const button = event.currentTarget
    const guessableId = parseInt(button.dataset.guessableId)
    const isCorrect = guessableId === this.correctAnswerIdValue

    // Disable all buttons during animation
    this.divisionChoiceTargets.forEach(choice => {
      choice.disabled = true
    })

    // Send attempt data to server (without expecting next question in response)
    this.sendAttemptData(guessableId, isCorrect)

    if (isCorrect) {
      console.log("[DG Controller] checkAnswer() - answer IS correct")
      button.classList.add("bg-green-500", "text-white", "pulsing")
      this.correctAnswers++
      this.progressCounterTarget.textContent = this.correctAnswers
      
      // Show the correct division name in overlay
      this.teamNameTextTarget.textContent = button.querySelector(".division-name").textContent
      this.teamNameOverlayTarget.classList.remove("opacity-0")
      this.teamNameOverlayTarget.classList.add("opacity-100")
      
      // Set timer to hide overlay and load next question
      this.nextQuestionTimer = setTimeout(() => {
        this.teamNameOverlayTarget.classList.remove("opacity-100")
        this.teamNameOverlayTarget.classList.add("opacity-0")
        this.loadNextQuestion()
      }, 1500)
    } else {
      console.log("[DG Controller] checkAnswer() - answer IS NOT correct")
      button.classList.add("bg-red-500", "text-white")
      
      // Find and highlight the correct answer
      const correctButton = this.divisionChoiceTargets.find(choice => 
        parseInt(choice.dataset.guessableId) === this.correctAnswerIdValue
      )
      correctButton.classList.add("bg-green-500", "text-white")
      
      // Show the correct division name in overlay after a short delay
      setTimeout(() => {
        // Show the correct division name in overlay
        this.teamNameTextTarget.textContent = correctButton.querySelector(".division-name").textContent
        this.teamNameOverlayTarget.classList.remove("opacity-0")
        this.teamNameOverlayTarget.classList.add("opacity-100")
        
        // Set timer to hide overlay and load next question
        this.nextQuestionTimer = setTimeout(() => {
          this.teamNameOverlayTarget.classList.remove("opacity-100")
          this.teamNameOverlayTarget.classList.add("opacity-0")
          this.loadNextQuestion()
        }, 1500)
      }, 500)
    }
  }

  async sendAttemptData(guessedId, isCorrect) {
    const endTime = Date.now()
    const timeElapsedMs = endTime - this.startTime
    
    try {
      // Just save the attempt data without expecting a turbo stream for next question
      const response = await fetch("/game_attempts", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          game_attempt: {
            game_type: "guess_the_division",
            subject_entity_id: this.subjectIdValue,
            subject_entity_type: "Team",
            target_entity_id: this.correctAnswerIdValue,
            target_entity_type: "Division",
            chosen_entity_id: guessedId,
            chosen_entity_type: "Division",
            is_correct: isCorrect,
            time_elapsed_ms: timeElapsedMs
          }
        })
      })

      if (!response.ok) {
        console.error("Failed to save attempt:", await response.text())
      } else {
        console.log("Game attempt saved successfully.")
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
    if (event.target.id === "division_game_frame") {
      console.log("[DG Controller] Frame rendered - updating team values")
      
      // Get new values from data attributes on the current team card
      const teamCard = this.currentTeamCardDisplayTarget
      if (teamCard) {
        const newSubjectId = teamCard.dataset.guessableId
        const newAnswerId = teamCard.dataset.guessableAnswerId
        
        if (newSubjectId && newSubjectId !== String(this.subjectIdValue)) {
          console.log(`[DG Controller] Updating subject ID from ${this.subjectIdValue} to ${newSubjectId}`)
          this.subjectIdValue = parseInt(newSubjectId)
        }
        
        if (newAnswerId && newAnswerId !== String(this.correctAnswerIdValue)) {
          console.log(`[DG Controller] Updating correct answer ID from ${this.correctAnswerIdValue} to ${newAnswerId}`)
          this.correctAnswerIdValue = parseInt(newAnswerId)
        }
        
        // Reset the timer for the new question
        this.startTime = Date.now()
      }
    }
  }

  loadNextQuestion() {
    console.log("[DG Controller] loadNextQuestion() called")
    this.isAnimating = false
    console.log("[DG Controller] loadNextQuestion() - isAnimating reset to false")
    
    const currentUrl = new URL(window.location.href)
    
    // Add a timestamp parameter to force a fresh request
    currentUrl.searchParams.set('t', Date.now())
    
    // Visit the URL but target only the division_game_frame
    console.log("[DG Controller] Visiting with frame target")
    Turbo.visit(currentUrl.toString(), { frame: "division_game_frame" })
    
    // Reset the timer for the next question
    this.startTime = Date.now()
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