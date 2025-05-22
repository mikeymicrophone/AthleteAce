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
    "pauseButtonText",
    "currentPlayerCardDisplay", 
    "lastAttemptContainer",     
    "lastAttemptPlayerCard",    
    "lastAttemptChosenTeamDisplay", 
    "lastAttemptChosenTeamLogo",  
    "lastAttemptChosenTeamLogoPlaceholder", 
    "lastAttemptChosenTeamName"   
  ]
  
  static values = {
    playerId: Number, 
    correctTeamId: Number 
  }

  connect() {
    console.log("[TM Controller] connect() called");
    this.correctAnswers = 0
    this.isPaused = false
    this.isAnimating = false 
    console.log("[TM Controller] connect() - isAnimating set to:", this.isAnimating);
    this.nextQuestionTimer = null
    this.startTime = Date.now() 
    // console.log("Team Match Controller connected. Player ID:", this.playerIdValue, "Correct Team ID:", this.correctTeamIdValue);
  }
  
  disconnect() {
    console.log("[TM Controller] disconnect() called");
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }
  }
  
  checkAnswer(event) {
    console.log("[TM Controller] checkAnswer() called");
    if (this.isAnimating) {
      console.log("[TM Controller] checkAnswer() - bailing: isAnimating is true");
      return
    }
    console.log("[TM Controller] checkAnswer() - proceeding: isAnimating is false");
    this.isAnimating = true
    console.log("[TM Controller] checkAnswer() - isAnimating set to true");
    
    const endTime = Date.now();
    const timeElapsedMs = endTime - this.startTime;
    const button = event.currentTarget
    const isCorrect = button.dataset.correct === "true"
    const chosenTeamId = parseInt(button.dataset.teamId)
    const teamName = button.querySelector(".team-name").textContent
    const chosenTeamLogoUrl = button.dataset.teamLogoUrl;

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

    // --- Update Last Attempt Display --- 
    console.log("[TM Controller] checkAnswer() - updating last attempt display");
    this.lastAttemptPlayerCardTarget.innerHTML = this.currentPlayerCardDisplayTarget.innerHTML;
    this.lastAttemptChosenTeamNameTarget.textContent = teamName;

    if (chosenTeamLogoUrl) {
      this.lastAttemptChosenTeamLogoTarget.src = chosenTeamLogoUrl;
      this.lastAttemptChosenTeamLogoTarget.alt = `${teamName} Logo`;
      this.lastAttemptChosenTeamLogoTarget.classList.remove('hidden');
      this.lastAttemptChosenTeamLogoPlaceholderTarget.classList.add('hidden');
    } else {
      this.lastAttemptChosenTeamLogoTarget.classList.add('hidden');
      this.lastAttemptChosenTeamLogoPlaceholderTarget.classList.remove('hidden');
      this.lastAttemptChosenTeamLogoPlaceholderTarget.textContent = "Logo N/A";
    }

    // Clear previous color coding
    this.lastAttemptPlayerCardTarget.classList.remove('bg-green-100', 'border-green-500', 'bg-red-100', 'border-red-500');
    this.lastAttemptChosenTeamDisplayTarget.classList.remove('bg-green-100', 'border-green-500', 'bg-red-100', 'border-red-500');

    if (isCorrect) {
      console.log("[TM Controller] checkAnswer() - answer IS correct");
      this.correctAnswers++
      this.progressCounterTarget.textContent = this.correctAnswers
      button.classList.add("correct", "pulsing")
      
      this.teamNameTextTarget.textContent = teamName
      this.teamNameOverlayTarget.classList.add("opacity-100")
      
      setTimeout(() => {
        this.teamNameOverlayTarget.classList.remove("opacity-100")
      }, 750)
      
      // Apply correct styling to last attempt display
      this.lastAttemptPlayerCardTarget.classList.add('bg-green-100', 'border-green-500');
      this.lastAttemptChosenTeamDisplayTarget.classList.add('bg-green-100', 'border-green-500');

    } else {
      console.log("[TM Controller] checkAnswer() - answer IS NOT correct");
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

      // Apply incorrect styling to last attempt display
      this.lastAttemptPlayerCardTarget.classList.add('bg-red-100', 'border-red-500');
      this.lastAttemptChosenTeamDisplayTarget.classList.add('bg-red-100', 'border-red-500');
    }

    this.lastAttemptContainerTarget.classList.remove('hidden'); // Show the container
    console.log("[TM Controller] checkAnswer() - lastAttemptContainer shown");
    
    if (this.nextQuestionTimer) clearTimeout(this.nextQuestionTimer);
    console.log("[TM Controller] checkAnswer() - scheduling nextQuestionTimer");
    this.nextQuestionTimer = setTimeout(() => {
      console.log("[TM Controller] setTimeout callback - setting isAnimating to false");
      this.isAnimating = false
      if (!this.isPaused) {
        console.log("[TM Controller] setTimeout callback - calling loadNextQuestion()");
        this.loadNextQuestion()
      } else {
        console.log("[TM Controller] setTimeout callback - game is paused, not loading next question");
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
    console.log("[TM Controller] loadNextQuestion() called");
    const currentUrl = new URL(window.location.href);
    
    // Add a timestamp parameter to force a fresh request
    currentUrl.searchParams.set('t', Date.now());
    
    // Visit the URL but target only the team_match_game frame
    console.log("[TM Controller] Visiting with frame target");
    Turbo.visit(currentUrl.toString(), { frame: "team_match_game" });
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
