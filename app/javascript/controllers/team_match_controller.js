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
    "attemptsContainer",
    "attemptsGrid"
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
    
    // Get the correct team info
    let correctTeamName = "";
    let correctTeamLogoUrl = "";
    
    this.teamChoiceTargets.forEach(choice => {
      if (choice.dataset.correct === "true") {
        correctTeamName = choice.querySelector(".team-name").textContent;
        correctTeamLogoUrl = choice.dataset.teamLogoUrl || "";
      }
    });

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
    
    // Get player name from the player card
    const playerName = this.currentPlayerCardDisplayTarget.querySelector('.player-name')?.textContent || 'Player';
    const playerPhotoUrl = this.currentPlayerCardDisplayTarget.querySelector('.player-photo')?.src || '';

    // Add attempt to the grid with correct team data and chosen team data
    this.addAttemptToGrid({
      player: {
        name: playerName,
        photoUrl: playerPhotoUrl
      },
      correctTeam: {
        name: correctTeamName,
        logoUrl: correctTeamLogoUrl
      },
      chosenTeam: {
        name: teamName,
        logoUrl: chosenTeamLogoUrl || ''
      },
      isCorrect: isCorrect
    });

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
    }

    // Show the attempts container if it's not already visible
    this.attemptsContainerTarget.classList.remove('hidden');
    console.log("[TM Controller] checkAnswer() - attemptsContainer shown");
    
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

  addAttemptToGrid(attemptData) {
    // Get the template
    const templateElement = document.getElementById('attempt-template');
    if (!templateElement) {
      console.error("Attempt template not found");
      return;
    }

    // Clone the template
    const template = templateElement.querySelector('.attempt-card').cloneNode(true);
    
    // Set up team part - always show the CORRECT team
    const teamPart = template.querySelector('.team-part');
    const teamLogo = teamPart.querySelector('.team-logo');
    const teamName = teamPart.querySelector('.team-name');
    
    teamName.textContent = attemptData.correctTeam.name;
    if (attemptData.correctTeam.logoUrl) {
      teamLogo.src = attemptData.correctTeam.logoUrl;
      teamLogo.alt = `${attemptData.correctTeam.name} Logo`;
    } else {
      teamLogo.classList.add('hidden');
    }
    
    // Set up player part
    const playerPart = template.querySelector('.player-part');
    const playerPhoto = playerPart.querySelector('.player-photo');
    const playerName = playerPart.querySelector('.player-name');
    
    playerName.textContent = attemptData.player.name;
    if (attemptData.player.photoUrl) {
      playerPhoto.src = attemptData.player.photoUrl;
      playerPhoto.alt = `${attemptData.player.name} Photo`;
    } else {
      playerPhoto.classList.add('hidden');
    }
    
    // Add a small indicator for the chosen team if incorrect
    if (!attemptData.isCorrect) {
      const chosenTeamIndicator = document.createElement('div');
      chosenTeamIndicator.className = 'chosen-team-indicator text-xs text-red-600 mt-1';
      chosenTeamIndicator.textContent = `Selected: ${attemptData.chosenTeam.name}`;
      playerPart.appendChild(chosenTeamIndicator);
    }
    
    // Apply correct/incorrect styling
    if (attemptData.isCorrect) {
      teamPart.classList.add('bg-green-100');
      playerPart.classList.add('bg-green-50');
      template.classList.add('border-green-500');
    } else {
      teamPart.classList.add('bg-red-100');
      playerPart.classList.add('bg-red-50');
      template.classList.add('border-red-500');
    }
    
    // Add a timestamp data attribute for sorting/reference
    template.dataset.timestamp = Date.now();
    
    // Prepend to grid (newest first)
    this.attemptsGridTarget.prepend(template);
    
    // Limit to 20 most recent attempts
    const attemptCards = this.attemptsGridTarget.querySelectorAll('.attempt-card');
    if (attemptCards.length > 20) {
      for (let i = 20; i < attemptCards.length; i++) {
        attemptCards[i].remove();
      }
    }
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
