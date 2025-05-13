// app/javascript/controllers/team_match_controller.js
import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

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
  
  static values = {
    playerId: Number, 
    correctTeamId: Number 
  }

  connect() {
    this.correctAnswers = 0
    this.isPaused = false
    this.isAnimating = false 
    this.nextQuestionTimer = null
    this.startTime = Date.now() 
    console.log("Team Match Controller connected. Player ID:", this.playerIdValue, "Correct Team ID:", this.correctTeamIdValue);
  }
  
  disconnect() {
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }
  }
  
  checkAnswer(event) {
    if (this.isAnimating) return
    this.isAnimating = true
    
    const endTime = Date.now();
    const timeElapsedMs = endTime - this.startTime;
    const button = event.currentTarget
    const isCorrect = button.dataset.correct === "true"
    const chosenTeamId = parseInt(button.dataset.teamId)
    const teamName = button.querySelector(".team-name").textContent

    const optionsPresented = this.teamChoiceTargets.map(choice => ({
      id: parseInt(choice.dataset.teamId),
      type: "Team",
      name: choice.querySelector(".team-name").textContent
    }));

    const attemptData = {
      ace_id: null, 
      game_type: "player_team_match",
      subject_entity_id: this.playerIdValue,
      subject_entity_type: "Player",
      target_entity_id: this.correctTeamIdValue,
      target_entity_type: "Team",
      chosen_entity_id: chosenTeamId,
      chosen_entity_type: "Team",
      options_presented: optionsPresented,
      is_correct: isCorrect,
      time_elapsed_ms: timeElapsedMs
    };

    this.sendAttemptData(attemptData);

    if (isCorrect) {
      this.correctAnswers++
      this.progressCounterTarget.textContent = this.correctAnswers
    }
    
    if (isCorrect) {
      button.classList.add("correct", "pulsing")
      
      this.teamNameTextTarget.textContent = teamName
      this.teamNameOverlayTarget.classList.add("opacity-100")
      
      setTimeout(() => {
        this.teamNameOverlayTarget.classList.remove("opacity-100")
      }, 750)

      const correctTeamLogoUrl = button.dataset.teamLogoUrl; 
      const staticLogoEl = document.getElementById('lastCorrectTeamLogo');
      const staticNameEl = document.getElementById('lastCorrectTeamName');
      const staticPlaceholderEl = document.getElementById('lastCorrectTeamLogoPlaceholder');

      if (staticLogoEl && staticNameEl && staticPlaceholderEl && correctTeamLogoUrl) {
        staticLogoEl.src = correctTeamLogoUrl;
        staticLogoEl.alt = `${teamName} Logo`;
        staticLogoEl.classList.remove('hidden');
        staticNameEl.textContent = teamName;
        staticPlaceholderEl.classList.add('hidden');
      } else {
        if (!correctTeamLogoUrl) console.warn('Team logo URL not found on button dataset for static display.');
        if (!staticLogoEl || !staticNameEl || !staticPlaceholderEl) console.warn('Static display elements for last correct answer not found.');
      }
      
    } else {
      button.classList.add("incorrect")
      
      setTimeout(() => {
        this.teamChoiceTargets.forEach(choice => {
          if (choice.dataset.correct === "true") {
            choice.classList.add("correct-answer")
            
            const correctTeamName = choice.querySelector(".team-name").textContent
            this.teamNameTextTarget.textContent = correctTeamName
            this.teamNameOverlayTarget.classList.add("opacity-100")
            
            setTimeout(() => {
              this.teamNameOverlayTarget.classList.remove("opacity-100")
            }, 750)
          }
        })
      }, 500)
    }
    
    if (this.nextQuestionTimer) clearTimeout(this.nextQuestionTimer);

    this.nextQuestionTimer = setTimeout(() => {
      this.isAnimating = false
      if (!this.isPaused) {
        this.loadNextQuestion()
      }
    }, 3000)
  }

  async sendAttemptData(payload) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    if (!csrfToken) {
      console.error("CSRF token not found!");
      return;
    }

    try {
      const response = await fetch('/game_attempts', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ game_attempt: payload }) 
      });

      if (!response.ok) {
        const errorData = await response.json();
        console.error('Failed to save game attempt:', response.status, errorData.errors);
      } else {
        console.log('Game attempt saved successfully.');
      }
    } catch (error) {
      console.error('Error sending game attempt data:', error);
    }
  }
  
  loadNextQuestion() {
    const url = new URL(window.location.href)
    
    Turbo.visit(url.toString())
  }
  
  togglePause() {
    console.log('Pause Text Target:', this.pauseButtonTextTarget);
    this.isPaused = !this.isPaused
    const icon = this.pauseButtonTarget.querySelector('i')

    if (this.isPaused) {
      if (this.nextQuestionTimer) clearTimeout(this.nextQuestionTimer);
      icon.className = 'fa-solid fa-play mr-2'
      this.pauseButtonTextTarget.textContent = 'Resume'
    } else {
      icon.className = 'fa-solid fa-pause mr-2'
      this.pauseButtonTextTarget.textContent = 'Pause'   
      
      if (!this.isAnimating && this.nextQuestionTimer) {
      } else if (!this.isAnimating) {
         this.loadNextQuestion();
      }
    }
  }
}
