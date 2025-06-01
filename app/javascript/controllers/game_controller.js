import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = [
    "gameContainer",
    "choiceItem",        // Generic name for team/division choices
    "answerOverlay",     // Unified overlay for both game types
    "answerText",        // Unified answer text for both game types
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
    
    // Extract data with unified approach using guessableId
    chosenId = parseInt(button.dataset.guessableId)
    
    // Get name based on game type
    if (this.gameTypeValue === "team_match") {
      chosenName = button.querySelector(".team-name")?.textContent
    } else if (this.gameTypeValue === "division_guess") {
      chosenName = button.querySelector(".division-name")?.textContent
    }
    
    // Disable all choices during animation
    this.choiceItemTargets.forEach(choice => {
      choice.disabled = true
    })
    
    // Get options presented
    const optionsPresented = this.choiceItemTargets.map(choice => (parseInt(choice.dataset.guessableId)));
    
    // Send attempt data to server
    this.sendAttemptData(chosenId, isCorrect, optionsPresented)
    
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
    
    // Style the button
    button.classList.add("correct-choice")
    
    // Show the correct answer for memory reinforcement
    this.answerTextTarget.textContent = chosenName || "Correct Answer"
    this.answerOverlayTarget.classList.add("visible")
    
    // Set timer to hide overlay and load next question
    this.nextQuestionTimer = setTimeout(() => {
      this.answerOverlayTarget.classList.remove("visible")
      
      setTimeout(() => {
        this.loadNextQuestion()
      }, 300)
    }, 1500)
  }
  
  handleIncorrectAnswer(button) {
    console.log(`[${this.gameTypeValue}] handleIncorrectAnswer() - answer IS NOT correct`)
    
    // Style the incorrect button
    button.classList.add("incorrect-choice")
    
    // Find and show the correct answer after a brief delay
    setTimeout(() => {
      const correctButton = this.choiceItemTargets.find(choice => choice.dataset.correct === "true")
      if (correctButton) {
        correctButton.classList.add("correct-answer")
        
        // Get the correct answer name
        const correctName = this.gameTypeValue === "team_match" 
          ? correctButton.querySelector(".team-name")?.textContent
          : correctButton.querySelector(".division-name")?.textContent
        
        // Show the correct answer for memory reinforcement
        this.answerTextTarget.textContent = correctName || "Correct Answer"
        this.answerOverlayTarget.classList.add("visible")
        
        // Set timer to hide overlay and load next question
        this.nextQuestionTimer = setTimeout(() => {
          this.answerOverlayTarget.classList.remove("visible")
          
          setTimeout(() => {
            this.loadNextQuestion()
          }, 300)
        }, 1500)
      }
    }, 500)
  }
  
  async sendAttemptData(chosenId, isCorrect, optionsPresented) {
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
            options_presented: optionsPresented,
            is_correct: isCorrect,
            time_elapsed_ms: timeElapsedMs
          }
        })
      })

      if (!response.ok) {
        console.error("Failed to save attempt:", await response.text())
      } else {
        console.log("Game attempt saved successfully")
        // Get the saved attempt data from the response
        const savedAttempt = await response.json()
        
        // Make sure the attempts container is visible
        if (this.hasAttemptsContainerTarget) {
          this.attemptsContainerTarget.classList.remove("hidden")
        }
        
        // Add the attempt to the UI with a slight delay for better UX
        setTimeout(() => {
          this.addAttemptToGrid(savedAttempt)
        }, 500)
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
        if (this.gameTypeValue === "team_match") {
          // For team match game, we need to update from player card
          const newPlayerId = cardDisplay.dataset.playerId;
          const newGuessableId = cardDisplay.dataset.guessableId;
          
          if (newPlayerId && newPlayerId !== String(this.subjectIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating subject ID from ${this.subjectIdValue} to ${newPlayerId}`);
            this.subjectIdValue = parseInt(newPlayerId);
          }
          
          // If this element has guessable ID and it's different from current, update it
          if (newGuessableId && newGuessableId !== String(this.correctAnswerIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating correct answer ID from ${this.correctAnswerIdValue} to ${newGuessableId}`);
            this.correctAnswerIdValue = parseInt(newGuessableId);
          }
        } else if (this.gameTypeValue === "division_guess") {
          // For division guess game, we need to update from team card
          const newSubjectId = cardDisplay.dataset.guessableId;
          const newCorrectAnswerId = cardDisplay.dataset.guessableAnswerId;
          
          if (newSubjectId && newSubjectId !== String(this.subjectIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating subject ID from ${this.subjectIdValue} to ${newSubjectId}`);
            this.subjectIdValue = parseInt(newSubjectId);
          }
          
          if (newCorrectAnswerId && newCorrectAnswerId !== String(this.correctAnswerIdValue)) {
            console.log(`[${this.gameTypeValue}] Updating correct answer ID from ${this.correctAnswerIdValue} to ${newCorrectAnswerId}`);
            this.correctAnswerIdValue = parseInt(newCorrectAnswerId);
          }
        }
        
        // Reset the timer for the new question
        this.startTime = Date.now();
        
        // Update the progress counter target with the current correct answers count
        if (this.hasProgressCounterTarget) {
          console.log(`[${this.gameTypeValue}] Updating progress counter to ${this.correctAnswers}`);
          this.progressCounterTarget.textContent = this.correctAnswers;
        }
      }
    }
  }
  
  loadRecentAttempts() {
    // Determine game type string for the backend
    const gameTypeString = this.gameTypeValue === "team_match" 
      ? "player_team_match" 
      : "guess_the_division"
    
    // Handle attempts grid if it exists
    const loadGridAttempts = (data) => {
      if (data && data.length > 0 && this.hasAttemptsGridTarget) {
        this.attemptsContainerTarget.classList.remove("hidden")
        data.forEach(attempt => this.addAttemptToGrid(attempt))
      }
    }
    
    // Handle recent attempts list if it exists
    const loadRecentAttemptsList = (data) => {
      if (this.hasRecentAttemptsListTarget) {
        console.log(`[${this.gameTypeValue}] Populating recent attempts list with ${data.length} attempts`)
        
        // Clear existing attempts (but not the template)
        const existingCards = this.recentAttemptsListTarget.querySelectorAll('.attempt-card')
        existingCards.forEach(card => card.remove())
        
        // Remove the placeholder if it exists
        const placeholder = this.recentAttemptsListTarget.querySelector('.no-attempts-message')
        if (placeholder) {
          placeholder.remove()
        }
        
        // If no attempts, show a message
        if (data.length === 0) {
          const noAttemptsMsg = document.createElement('div')
          noAttemptsMsg.className = 'no-attempts-message'
          noAttemptsMsg.textContent = 'No guesses yet'
          this.recentAttemptsListTarget.appendChild(noAttemptsMsg)
          return
        }
        
        // Process up to 5 most recent attempts in reverse order (newest first)
        const recentAttempts = data.slice(-5).reverse()
        recentAttempts.forEach(attempt => {
          const isCorrect = attempt.correct || attempt.is_correct
          let entityName = ''
          
          if (this.gameTypeValue === "team_match") {
            entityName = attempt.subject_entity?.name || attempt.player_name || 'Unknown Player'
          } else {
            entityName = attempt.subject_entity?.name || attempt.team_name || 'Unknown Team'
          }
          
          this.addRecentAttempt(entityName, isCorrect)
        })
      }
    }
    
    // Fetch attempts from the server
    fetch(`/game_attempts.json?game_type=${gameTypeString}&limit=10`)
      .then(response => response.json())
      .then(data => {
        // Update both interfaces if they exist
        loadGridAttempts(data)
        loadRecentAttemptsList(data)
      })
      .catch(error => {
        console.error(`Error loading recent ${this.gameTypeValue} attempts:`, error)
        
        // Handle error in recent attempts list if it exists
        if (this.hasRecentAttemptsListTarget) {
          // Clear existing attempts
          const existingCards = this.recentAttemptsListTarget.querySelectorAll('.attempt-card:not(#attempt-template .attempt-card)')
          existingCards.forEach(card => card.remove())
          
          // Show error message
          const errorMsg = document.createElement('div')
          errorMsg.className = 'text-red-500 italic text-sm'
          errorMsg.textContent = 'Error loading attempts'
          this.recentAttemptsListTarget.appendChild(errorMsg)
        }
      })
  }
  
  addRecentAttempt(entityName, isCorrect) {
    console.log(`[${this.gameTypeValue}] Adding recent attempt: ${entityName}, correct: ${isCorrect}`)
    
    // Get the template
    const templateElement = document.getElementById('attempt-template')
    if (!templateElement) {
      console.error("Attempt template not found")
      return
    }
    
    // Clone the template content (for <template> tags)
    const template = templateElement.content.cloneNode(true)
    const card = template.querySelector('.attempt-card')
    
    // Clear the "No guesses yet" placeholder if it exists
    const placeholder = this.recentAttemptsListTarget.querySelector(".no-attempts-message")
    if (placeholder) {
      placeholder.remove()
    }
    
    // Set up subject part
    const subjectImage = card.querySelector('.attempt-subject-image')
    const subjectName = card.querySelector('.attempt-subject-name')
    
    // Set the subject info based on game type
    if (this.gameTypeValue === "team_match") {
      // For team match, subject is the player
      subjectName.textContent = entityName || 'Unknown Player'
      // You might want to set the player image here if available
      subjectImage.style.display = 'none' // Hide if no image
    } else {
      // For division guess, subject is the team
      subjectName.textContent = entityName || 'Unknown Team'
      // You might want to set the team logo here if available
      subjectImage.style.display = 'none' // Hide if no image
    }
    
    // Set up answer part - this would show what they guessed
    const answerImage = card.querySelector('.attempt-answer-image')
    const answerName = card.querySelector('.attempt-answer-name')
    const resultElement = card.querySelector('.attempt-result')
    
    // Hide answer image for now
    answerImage.style.display = 'none'
    answerName.textContent = 'Your guess' // You could make this more specific
    
    // Set result
    resultElement.textContent = isCorrect ? 'Correct' : 'Incorrect'
    
    // Apply styles based on result
    if (isCorrect) {
      card.classList.add('correct-attempt')
      resultElement.classList.add('correct-result')
    } else {
      card.classList.add('incorrect-attempt')
      resultElement.classList.add('incorrect-result')
    }
    
    // Set timestamp
    const timeElement = card.querySelector('.attempt-time')
    timeElement.textContent = 'Just now'
    
    // Add to list (newest first)
    this.recentAttemptsListTarget.prepend(card)
    
    // Limit the list to 5 attempts
    const attempts = this.recentAttemptsListTarget.querySelectorAll('.attempt-card')
    if (attempts.length > 5) {
      for (let i = 5; i < attempts.length; i++) {
        attempts[i].remove()
      }
    }
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
      card.querySelector(".attempt-result").textContent = "Correct"
      card.querySelector(".attempt-result").classList.add("bg-green-100", "text-green-800")
    } else {
      card.classList.add("border-red-500")
      card.querySelector(".attempt-result").textContent = "Incorrect"
      card.querySelector(".attempt-result").classList.add("bg-red-100", "text-red-800")
    }
    
    // Set subject (team) info
    const subjectImage = card.querySelector(".attempt-subject-image")
    const subjectName = card.querySelector(".attempt-subject-name")
    
    subjectName.textContent = attempt.subject_entity.name
    if (attempt.subject_entity.logo_url) {
      subjectImage.src = attempt.subject_entity.logo_url
      subjectImage.alt = `${attempt.subject_entity.name} logo`
    } else {
      subjectImage.parentElement.innerHTML = '<i class="fas fa-shield-alt text-3xl text-gray-400"></i>'
    }
    
    // Set answer (division) info
    const answerImage = card.querySelector(".attempt-answer-image")
    const answerName = card.querySelector(".attempt-answer-name")
    
    // For division guessing, the answer is the chosen division
    answerName.textContent = attempt.chosen_entity.name
    
    // Divisions don't typically have logos, but if they did:
    if (attempt.chosen_entity.logo_url) {
      answerImage.src = attempt.chosen_entity.logo_url
      answerImage.alt = `${attempt.chosen_entity.name} logo`
    } else {
      answerImage.classList.add('hidden')
    }
    
    // Add timestamp
    const timeDisplay = card.querySelector(".attempt-time")
    if (timeDisplay) {
      const date = new Date(attempt.created_at || Date.now())
      timeDisplay.textContent = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      card.dataset.timestamp = date.getTime()
    }
    
    // Prepend to grid (newest first)
    this.attemptsGridTarget.prepend(card)
    
    // Limit to 20 attempts
    const attempts = this.attemptsGridTarget.children
    if (attempts.length > 20) {
      attempts[20].remove()
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
