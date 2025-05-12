// app/javascript/controllers/team_match_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "gameContainer", 
    "choicesGrid", 
    "teamChoice", 
    "teamNameOverlay", 
    "teamNameText",
    "progressCounter",
    "pauseButton",
    "pauseButtonText"
  ]
  
  connect() {
    this.correctAnswers = 0
    this.isPaused = false
    this.nextQuestionTimer = null
  }
  
  disconnect() {
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }
  }
  
  checkAnswer(event) {
    // Prevent multiple clicks during animation
    if (this.isAnimating) return
    this.isAnimating = true
    
    const button = event.currentTarget
    const isCorrect = button.dataset.correct === "true"
    const teamId = button.dataset.teamId
    const teamName = button.querySelector(".team-name").textContent
    
    // Update progress counter if correct
    if (isCorrect) {
      this.correctAnswers++
      this.progressCounterTarget.textContent = this.correctAnswers
    }
    
    // Show result
    if (isCorrect) {
      // Correct answer - show green and pulse
      button.classList.add("correct", "pulsing")
      
      // Show team name overlay
      this.teamNameTextTarget.textContent = teamName
      this.teamNameOverlayTarget.classList.add("opacity-100")
      
      // Hide overlay after 750ms
      setTimeout(() => {
        this.teamNameOverlayTarget.classList.remove("opacity-100")
      }, 750)
      
    } else {
      // Incorrect answer - show red
      button.classList.add("incorrect")
      
      // After 500ms, show correct answer
      setTimeout(() => {
        // Find and highlight correct answer
        this.teamChoiceTargets.forEach(choice => {
          if (choice.dataset.correct === "true") {
            choice.classList.add("correct-answer")
            
            // Show team name overlay
            const correctTeamName = choice.querySelector(".team-name").textContent
            this.teamNameTextTarget.textContent = correctTeamName
            this.teamNameOverlayTarget.classList.add("opacity-100")
            
            // Hide overlay after 750ms
            setTimeout(() => {
              this.teamNameOverlayTarget.classList.remove("opacity-100")
            }, 750)
          }
        })
      }, 500)
    }
    
    // Schedule next question after 3 seconds (if not paused)
    this.nextQuestionTimer = setTimeout(() => {
      this.isAnimating = false
      if (!this.isPaused) {
        this.loadNextQuestion()
      }
    }, 3000)
  }
  
  loadNextQuestion() {
    // Get current URL with params
    const url = new URL(window.location.href)
    
    // Reload the page to get a new question
    window.location.href = url.toString()
  }
  
  togglePause() {
    console.log('Pause Text Target:', this.pauseButtonTextTarget);
    this.isPaused = !this.isPaused
    const icon = this.pauseButtonTarget.querySelector('i')

    if (this.isPaused) {
      icon.className = 'fa-solid fa-play mr-2'
      this.pauseButtonTextTarget.textContent = 'Resume'
    } else {
      icon.className = 'fa-solid fa-pause mr-2'
      this.pauseButtonTextTarget.textContent = 'Pause'   
      
      // If we're not currently animating, load the next question
      if (!this.isAnimating) {
        this.loadNextQuestion()
      }
    }
  }
}
