import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = [
    "gameContainer",
    "choiceItem",        // Generic name for team/division choices
    "overlayDisplay",    // Overlay container
    "overlayText",       // Text inside overlay
    "progressCounter",   // Counter for correct answers
    "pauseButton",       // Pause button
    "pauseButtonText",   // Text inside pause button
    "subjectCardDisplay", // Player card or team card
    "attemptsContainer",  // Container for recent attempts
    "attemptsGrid",       // Grid of attempt cards
    "recentAttemptsList"  // List of recent attempts
  ]

  static values = {
    subjectId: Number,       // Player ID or Team ID
    correctAnswerId: Number, // Team ID or Division ID
    gameType: String,        // "team_match" or "division_guess"
    frameId: String,         // ID of the Turbo frame to target
    subjectType: { type: String, default: "" },  // "Player" or "Team"
    answerType: { type: String, default: "" }    // "Team" or "Division"
  }

  connect() {
    console.log(`[Game Controller] connect() called for ${this.gameTypeValue}`)
    this.correctAnswers = 0
    this.isPaused = false
    this.isAnimating = false
    this.nextQuestionTimer = null
    this.startTime = Date.now()
    
    // Set default entity types based on game type if not explicitly provided
    if (!this.hasSubjectTypeValue || !this.subjectTypeValue) {
      this.subjectTypeValue = this.gameTypeValue === "team_match" ? "Player" : "Team"
    }
    
    if (!this.hasAnswerTypeValue || !this.answerTypeValue) {
      this.answerTypeValue = this.gameTypeValue === "team_match" ? "Team" : "Division"
    }
    
    console.log(`Game controller initialized for ${this.gameTypeValue}`)
    console.log(`Subject: ${this.subjectTypeValue} (ID: ${this.subjectIdValue})`)
    console.log(`Answer: ${this.answerTypeValue} (Correct ID: ${this.correctAnswerIdValue})`)
    console.log(`Frame target: ${this.frameIdValue}`)
    
    // Listen for Turbo frame responses to update values after a frame refresh
    document.addEventListener("turbo:frame-render", this.handleFrameRender.bind(this))
    
    // Load recent attempts if we have the targets
    if (this.hasAttemptsGridTarget) {
      this.loadRecentAttempts()
    }
  }

  disconnect() {
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }
    
    // Clean up event listener
    document.removeEventListener("turbo:frame-render", this.handleFrameRender.bind(this))
  }

  checkAnswer(event) {
    if (this.isPaused || this.isAnimating) {
      console.log(`[${this.gameTypeValue}] checkAnswer() - bailing: isPaused or isAnimating is true`)
      return
    }
    
    console.log(`[${this.gameTypeValue}] checkAnswer() - proceeding`)
    this.isAnimating = true
    console.log(`[${this.gameTypeValue}] checkAnswer() - isAnimating set to true`)
    
    const button = event.currentTarget
    let chosenId, isCorrect, chosenName
    
    // Get correct status consistently from data-correct attribute
    isCorrect = button.dataset.correct === "true"
    
    // Extract data based on game type
    if (this.gameTypeValue === "team_match") {
      chosenId = parseInt(button.dataset.teamId)
      chosenName = button.querySelector(".team-name")?.textContent
    } else if (this.gameTypeValue === "division_guess") {
      chosenId = parseInt(button.dataset.divisionId)
      chosenName = button.querySelector(".division-name")?.textContent
    }
    
    // Disable all choices during animation
    this.choiceItemTargets.forEach(choice => {
      choice.disabled = true
    })
    
    // Send attempt data to server
    this.sendAttemptData(chosenId, isCorrect)
    
    // Handle UI updates for correct/incorrect
    this.handleAnswerUI(button, isCorrect, chosenName)
  }
  
  handleAnswerUI(button, isCorrect, chosenName) {
    if (isCorrect) {
      this.handleCorrectAnswer(button, chosenName)
    } else {
      this.handleIncorrectAnswer(button)
    }
  }
  
  handleCorrectAnswer(button, chosenName) {
    console.log(`[${this.gameTypeValue}] handleCorrectAnswer() - answer IS correct`)
    
    // Update progress counter
    this.correctAnswers++
    this.progressCounterTarget.textContent = this.correctAnswers
    
    // Style the button - apply appropriate classes based on game type
    if (this.gameTypeValue === "team_match") {
      button.classList.add("correct-choice", "pulsing")
    } else {
      button.classList.add("correct-choice", "pulsing", "bg-green-500", "text-white")
    }
    
    // Set the overlay title and class
    const overlayTitle = this.overlayDisplayTarget.querySelector("h3")
    if (overlayTitle) {
      overlayTitle.textContent = "Correct!"
      overlayTitle.classList.add("text-green-600")
      overlayTitle.classList.remove("text-red-600")
    }
    
    // Update overlay container for correct styling
    const overlayContent = this.overlayDisplayTarget.querySelector(".overlay-content")
    if (overlayContent) {
      overlayContent.classList.add("border-green-500")
      overlayContent.classList.remove("border-red-500")
      
      // Add animation classes
      overlayContent.classList.add("transform", "scale-100")
      setTimeout(() => {
        overlayContent.classList.add("scale-105")
        setTimeout(() => {
          overlayContent.classList.remove("scale-105")
        }, 200)
      }, 100)
    }
    
    // Show overlay with correct name and appropriate styling
    this.overlayTextTarget.textContent = chosenName || "Correct Answer"
    this.overlayTextTarget.classList.add("text-green-700")
    this.overlayTextTarget.classList.remove("text-red-700")
    
    // Add to recent attempts list
    if (this.hasRecentAttemptsListTarget) {
      this.addRecentAttempt(chosenName, true)
    }
    
    // Apply appropriate classes for overlay visibility
    this.overlayDisplayTarget.classList.remove("opacity-0")
    this.overlayDisplayTarget.classList.add("opacity-100")
    
    // Set timer to hide overlay and load next question
    this.nextQuestionTimer = setTimeout(() => {
      this.overlayDisplayTarget.classList.remove("opacity-100")
      this.overlayDisplayTarget.classList.add("opacity-0")
      
      // Wait for transition to complete before loading next question
      setTimeout(() => {
        this.loadNextQuestion()
      }, 300)
    }, 1500)
  }
  
  handleIncorrectAnswer(button) {
    console.log(`[${this.gameTypeValue}] handleIncorrectAnswer() - answer IS NOT correct`)
    
    // Get the chosen name for recent attempts list
    let chosenName = this.gameTypeValue === "team_match" 
      ? button.querySelector(".team-name")?.textContent
      : button.querySelector(".division-name")?.textContent
    
    // Style the button - apply appropriate classes based on game type
    if (this.gameTypeValue === "team_match") {
      button.classList.add("incorrect-choice")
    } else {
      button.classList.add("incorrect-choice", "bg-red-500", "text-white")
    }
    
    // Find and highlight the correct answer after a delay
    setTimeout(() => {
      let correctButton, correctName
      
      // Find the correct button using the correct="true" data attribute for both game types
      correctButton = this.choiceItemTargets.find(choice => choice.dataset.correct === "true")
      
      if (!correctButton) {
        console.error(`[${this.gameTypeValue}] Could not find the correct button`)
        return // Early return to prevent errors
      }
      
      // Apply styling based on game type
      if (this.gameTypeValue === "team_match") {
        correctButton.classList.add("correct-answer")
      } else {
        correctButton.classList.add("correct-answer", "bg-green-500", "text-white")
      }
      
      // Get the name from the correct element
      correctName = this.gameTypeValue === "team_match" 
        ? correctButton.querySelector(".team-name")?.textContent
        : correctButton.querySelector(".division-name")?.textContent
      
      // Set the overlay title and class for incorrect answer
      const overlayTitle = this.overlayDisplayTarget.querySelector("h3")
      if (overlayTitle) {
        overlayTitle.textContent = "Incorrect!"
        overlayTitle.classList.add("text-red-600")
        overlayTitle.classList.remove("text-green-600")
      }
      
      // Update overlay container for incorrect styling
      const overlayContent = this.overlayDisplayTarget.querySelector(".overlay-content")
      if (overlayContent) {
        overlayContent.classList.add("border-red-500")
        overlayContent.classList.remove("border-green-500")
        
        // Add animation classes
        overlayContent.classList.add("transform", "scale-100")
        setTimeout(() => {
          overlayContent.classList.add("scale-105")
          setTimeout(() => {
            overlayContent.classList.remove("scale-105")
          }, 200)
        }, 100)
      }
      
      // Show overlay with correct name and appropriate styling
      this.overlayTextTarget.textContent = `The correct answer is: ${correctName || "Not available"}`
      this.overlayTextTarget.classList.add("text-red-700")
      this.overlayTextTarget.classList.remove("text-green-700")
      
      // Add to recent attempts list if we have the target
      if (this.hasRecentAttemptsListTarget) {
        this.addRecentAttempt(chosenName, false)
      }
      
      // Apply appropriate classes for overlay visibility
      this.overlayDisplayTarget.classList.remove("opacity-0")
      this.overlayDisplayTarget.classList.add("opacity-100")
      
      // Set timer to hide overlay and load next question
      this.nextQuestionTimer = setTimeout(() => {
        this.overlayDisplayTarget.classList.remove("opacity-100")
        this.overlayDisplayTarget.classList.add("opacity-0")
        
        // Wait for transition to complete before loading next question
        setTimeout(() => {
          this.loadNextQuestion()
        }, 300)
      }, 1500)
    }, 500)
  }
  
  async sendAttemptData(chosenId, isCorrect) {
    const endTime = Date.now()
    const timeElapsedMs = endTime - this.startTime
    
    try {
      // Determine game type string for the backend
      const gameTypeString = this.gameTypeValue === "team_match" 
        ? "player_team_match" 
        : "guess_the_division"
      
      const response = await fetch("/game_attempts", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          game_attempt: {
            game_type: gameTypeString,
            subject_entity_id: this.subjectIdValue,
            subject_entity_type: this.subjectTypeValue,
            target_entity_id: this.correctAnswerIdValue,
            target_entity_type: this.answerTypeValue,
            chosen_entity_id: chosenId,
            chosen_entity_type: this.answerTypeValue,
            is_correct: isCorrect,
            time_elapsed_ms: timeElapsedMs
          }
        })
      })

      if (!response.ok) {
        console.error("Failed to save attempt:", await response.text())
      } else {
        console.log("Game attempt saved successfully")
      }
    } catch (error) {
      console.error("Error saving attempt:", error)
    }
  }
  
  loadNextQuestion() {
    console.log(`[${this.gameTypeValue}] loadNextQuestion() called`)
    this.isAnimating = false
    console.log(`[${this.gameTypeValue}] loadNextQuestion() - isAnimating reset to false`)
    
    const currentUrl = new URL(window.location.href)
    
    // Add a timestamp parameter to force a fresh request
    currentUrl.searchParams.set('t', Date.now())
    
    // Visit the URL but target only the specific game frame
    console.log(`[${this.gameTypeValue}] Visiting with frame target: ${this.frameIdValue}`)
    Turbo.visit(currentUrl.toString(), { frame: this.frameIdValue })
    
    // Reset the timer for the next question
    this.startTime = Date.now()
  }
  
  handleFrameRender(event) {
    // Only process events for our specific game frame
    if (event.target.id === this.frameIdValue) {
      console.log(`[${this.gameTypeValue}] Frame rendered - updating values`)
      
      // Get new values from data attributes on the current card
      const cardDisplay = this.subjectCardDisplayTarget
      if (cardDisplay) {
        // Get data attributes based on game type
        if (this.gameTypeValue === "team_match") {
          const newPlayerId = cardDisplay.dataset.playerId
          const newTeamId = cardDisplay.dataset.playerTeamId
          
          if (newPlayerId && newPlayerId !== String(this.subjectIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating subject ID from ${this.subjectIdValue} to ${newPlayerId}`)
            this.subjectIdValue = parseInt(newPlayerId)
          }
          
          if (newTeamId && newTeamId !== String(this.correctAnswerIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating correct answer ID from ${this.correctAnswerIdValue} to ${newTeamId}`)
            this.correctAnswerIdValue = parseInt(newTeamId)
          }
        } else if (this.gameTypeValue === "division_guess") {
          const newTeamId = cardDisplay.dataset.teamId
          const newDivisionId = cardDisplay.dataset.teamDivisionId
          
          if (newTeamId && newTeamId !== String(this.subjectIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating subject ID from ${this.subjectIdValue} to ${newTeamId}`)
            this.subjectIdValue = parseInt(newTeamId)
          }
          
          if (newDivisionId && newDivisionId !== String(this.correctAnswerIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating correct answer ID from ${this.correctAnswerIdValue} to ${newDivisionId}`)
            this.correctAnswerIdValue = parseInt(newDivisionId)
          }
        }
        
        // Reset the timer for the new question
        this.startTime = Date.now()
        
        // Update the progress counter target with the current correct answers count
        if (this.hasProgressCounterTarget) {
          console.log(`[${this.gameTypeValue}] Updating progress counter to ${this.correctAnswers}`)
          this.progressCounterTarget.textContent = this.correctAnswers
        }
      }
    }
  }
  
  loadRecentAttempts() {
    // Determine game type string for the backend
    const gameTypeString = this.gameTypeValue === "team_match" 
      ? "player_team_match" 
      : "guess_the_division"
      
    fetch(`/game_attempts.json?game_type=${gameTypeString}&limit=10`)
      .then(response => response.json())
      .then(data => {
        if (data && data.length > 0 && this.hasAttemptsGridTarget) {
          this.attemptsContainerTarget.classList.remove("hidden")
          data.forEach(attempt => this.addAttemptToGrid(attempt))
        }
      })
      .catch(error => console.error(`Error loading recent ${this.gameTypeValue} attempts:`, error))
  }
  
  addRecentAttempt(entityName, isCorrect) {
    console.log(`[${this.gameTypeValue}] Adding recent attempt: ${entityName}, correct: ${isCorrect}`)
    
    // Clear the "No guesses yet" placeholder if it exists
    const placeholder = this.recentAttemptsListTarget.querySelector(".text-gray-500.italic")
    if (placeholder) {
      placeholder.remove()
    }
    
    // Create a new attempt item using the helper method
    const itemHTML = this.createAttemptItemHTML(entityName, isCorrect)
    
    // Insert the new attempt at the top of the list
    this.recentAttemptsListTarget.insertAdjacentHTML('afterbegin', itemHTML)
    
    // Limit the list to 5 attempts
    const attempts = this.recentAttemptsListTarget.children
    if (attempts.length > 5) {
      attempts[5].remove()
    }
  }
  
  createAttemptItemHTML(entityName, isCorrect) {
    const resultClass = isCorrect ? "text-green-600" : "text-red-600"
    const iconClass = isCorrect ? "fa-check text-green-600" : "fa-xmark text-red-600"
    const resultText = isCorrect ? "Correct" : "Incorrect"
    
    return `
      <div class="attempt-item flex items-center justify-between p-2 border-b border-gray-100">
        <div class="flex items-center">
          <i class="fas ${iconClass} mr-2"></i>
          <span class="font-medium">${entityName || 'Unknown'}</span>
        </div>
        <div class="text-sm ${resultClass} font-semibold">${resultText}</div>
      </div>
    `
  }
  
  addAttemptToGrid(attempt) {
    if (this.gameTypeValue === "team_match") {
      this.addTeamMatchAttemptToGrid(attempt)
    } else {
      this.addDivisionGuessAttemptToGrid(attempt)
    }
  }
  
  addTeamMatchAttemptToGrid(attempt) {
    // Implementation for team match attempts
    const template = document.getElementById("attempt-template")
    if (!template) return
    
    const attemptCard = template.content.cloneNode(true)
    const card = attemptCard.querySelector(".attempt-card")
    
    // Add correct/incorrect styling
    if (attempt.is_correct) {
      card.classList.add("correct-attempt")
    } else {
      card.classList.add("incorrect-attempt")
    }
    
    // Set team info
    const teamPart = card.querySelector(".attempt-team-part")
    const teamLogo = teamPart.querySelector(".attempt-team-logo")
    const teamName = teamPart.querySelector(".attempt-team-name")
    
    // Set appropriate team data
    if (attempt.is_correct) {
      teamName.textContent = attempt.chosen_entity.name
      if (attempt.chosen_entity.logo_url) {
        teamLogo.src = attempt.chosen_entity.logo_url
        teamLogo.alt = `${attempt.chosen_entity.name} Logo`
      } else {
        teamLogo.classList.add('hidden')
      }
    } else {
      teamName.textContent = attempt.target_entity.name
      if (attempt.target_entity.logo_url) {
        teamLogo.src = attempt.target_entity.logo_url
        teamLogo.alt = `${attempt.target_entity.name} Logo`
      } else {
        teamLogo.classList.add('hidden')
      }
    }
    
    // Set player info
    const playerPart = card.querySelector(".attempt-player-part")
    const playerPhoto = playerPart.querySelector(".attempt-player-photo")
    const playerName = playerPart.querySelector(".attempt-player-name")
    
    playerName.textContent = attempt.subject_entity.name
    if (attempt.subject_entity.photo_url) {
      playerPhoto.src = attempt.subject_entity.photo_url
      playerPhoto.alt = `${attempt.subject_entity.name} Photo`
    } else {
      playerPhoto.classList.add('hidden')
    }
    
    // Add a timestamp
    card.dataset.timestamp = new Date(attempt.created_at).getTime()
    
    // Prepend to grid (newest first)
    this.attemptsGridTarget.prepend(card)
    
    // Limit to 20 attempts
    const attempts = this.attemptsGridTarget.children
    if (attempts.length > 20) {
      attempts[20].remove()
    }
  }
  
  addDivisionGuessAttemptToGrid(attempt) {
    // Implementation for division guess attempts
    const template = document.getElementById("attempt-template")
    if (!template) return
    
    const attemptCard = template.content.cloneNode(true)
    const card = attemptCard.querySelector(".attempt-card")
    
    // Add correct/incorrect styling
    if (attempt.is_correct) {
      card.classList.add("border-green-500")
    } else {
      card.classList.add("border-red-500")
    }
    
    // Set team info
    const teamLogo = card.querySelector(".attempt-team-logo")
    const teamName = card.querySelector(".attempt-team-name")
    
    if (attempt.subject_entity.logo_url) {
      teamLogo.src = attempt.subject_entity.logo_url
      teamLogo.alt = `${attempt.subject_entity.name} logo`
    } else {
      teamLogo.parentElement.innerHTML = '<i class="fas fa-shield-alt text-3xl text-gray-400"></i>'
    }
    
    teamName.textContent = attempt.subject_entity.name
    
    // Set division info
    const divisionName = card.querySelector(".attempt-division-name")
    divisionName.textContent = attempt.chosen_entity.name
    
    // Add to grid
    this.attemptsGridTarget.appendChild(attemptCard)
    
    // Limit to 20 attempts
    const attempts = this.attemptsGridTarget.children
    if (attempts.length > 20) {
      attempts[0].remove()
    }
  }
  
  togglePause() {
    this.isPaused = !this.isPaused
    this.pauseButtonTextTarget.textContent = this.isPaused ? "Resume" : "Pause"
    
    // Toggle icon based on game type
    if (this.gameTypeValue === "team_match") {
      this.pauseButtonTarget.querySelector("i").classList.toggle("fa-pause")
      this.pauseButtonTarget.querySelector("i").classList.toggle("fa-play")
    } else {
      this.pauseButtonTarget.querySelector("i").classList.toggle("fa-pause")
    }
    
    if (this.isPaused) {
      console.log(`[${this.gameTypeValue}] Game paused`)
    } else {
      console.log(`[${this.gameTypeValue}] Game resumed`)
    }
  }
}
