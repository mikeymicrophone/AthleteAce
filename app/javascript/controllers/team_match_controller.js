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

    // Always remove both color classes and border first
    this.pauseButtonTextTarget.classList.remove('!text-white', '!text-gray-800', 'bg-yellow-300') // Remove temp bg
    this.pauseButtonTarget.classList.remove('border-2', 'border-black') // Use new border classes

    if (this.isPaused) {
      icon.className = 'fa-solid fa-play mr-2'
      this.pauseButtonTextTarget.textContent = 'Resume'
      this.pauseButtonTarget.classList.remove('bg-gray-200', 'hover:bg-gray-300')
      this.pauseButtonTarget.classList.add('bg-blue-500', 'hover:bg-blue-600', 'border-2', 'border-black') // Add obvious border
      this.pauseButtonTextTarget.classList.add('!text-white', 'bg-yellow-300') // Add !important white text and temp yellow bg
    } else {
      icon.className = 'fa-solid fa-pause mr-2'
      this.pauseButtonTextTarget.textContent = 'Pause'   
      this.pauseButtonTarget.classList.remove('bg-blue-500', 'hover:bg-blue-600', 'border-2', 'border-black') // Remove obvious border
      this.pauseButtonTarget.classList.add('bg-gray-200', 'hover:bg-gray-300')
      this.pauseButtonTextTarget.classList.add('!text-gray-800') // Add !important gray text
      
      // If we're not currently animating, load the next question
      if (!this.isAnimating) {
        this.loadNextQuestion()
      }
    }
  }
}
