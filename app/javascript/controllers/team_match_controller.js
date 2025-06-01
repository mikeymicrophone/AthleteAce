// // app/javascript/controllers/team_match_controller.js
// import { Controller } from "@hotwired/stimulus";
// import { Turbo } from "@hotwired/turbo-rails";

// export default class extends Controller {
//   static targets = [
//     "gameContainer", 
//     "choicesGrid", 
//     "teamChoice", 
//     "teamNameOverlay", 
//     "teamNameText",
//     "progressCounter",
//     "pauseButton",
//     "pauseButtonText",
//     "currentPlayerCardDisplay", 
//     "attemptsContainer",
//     "attemptsGrid"
//   ];
  
//   static values = {
//     playerId: Number, 
//     correctTeamId: Number 
//   };

//   connect() {
//     console.log("[TM Controller] connect() called");
//     this.correctAnswers = 0;
//     this.isPaused = false;
//     this.isAnimating = false;
//     console.log("[TM Controller] connect() - isAnimating set to:", this.isAnimating);
//     this.nextQuestionTimer = null;
//     this.startTime = Date.now();
//     console.log("Team Match Controller connected. Player ID:", this.playerIdValue, "Correct Team ID:", this.correctTeamIdValue);
    
//     // Listen for Turbo frame responses to update player values after a frame refresh
//     document.addEventListener("turbo:frame-render", this.handleFrameRender.bind(this));
//   }
  
//   disconnect() {
//     console.log("[TM Controller] disconnect() called");
//     if (this.nextQuestionTimer) {
//       clearTimeout(this.nextQuestionTimer);
//     }
    
//     // Clean up event listener
//     document.removeEventListener("turbo:frame-render", this.handleFrameRender.bind(this));
//   }
  
//   checkAnswer(event) {
//     console.log("[TM Controller] checkAnswer() called");
//     if (this.isAnimating) {
//       console.log("[TM Controller] checkAnswer() - bailing: isAnimating is true");
//       return;
//     }
//     console.log("[TM Controller] checkAnswer() - proceeding: isAnimating is false");
//     this.isAnimating = true;
//     console.log("[TM Controller] checkAnswer() - isAnimating set to true");
    
//     const endTime = Date.now();
//     const timeElapsedMs = endTime - this.startTime;
//     const button = event.currentTarget;
//     const isCorrect = button.dataset.correct === "true";
//     const chosenTeamId = parseInt(button.dataset.teamId);
//     const teamName = button.querySelector(".team-name").textContent;
//     const chosenTeamLogoUrl = button.dataset.teamLogoUrl;
    
//     // Get the correct team info
//     let correctTeamName = "";
//     let correctTeamLogoUrl = "";
    
//     this.teamChoiceTargets.forEach(choice => {
//       if (choice.dataset.correct === "true") {
//         correctTeamName = choice.querySelector(".team-name").textContent;
//         correctTeamLogoUrl = choice.dataset.teamLogoUrl || "";
//       }
//     });

//     const optionsPresented = this.teamChoiceTargets.map(choice => ({
//       id: parseInt(choice.dataset.teamId),
//       type: "Team",
//       name: choice.querySelector(".team-name").textContent
//     }));

//     const attemptData = {
//       ace_id: null, 
//       game_type: "player_team_match",
//       subject_entity_id: this.playerIdValue,
//       subject_entity_type: "Player",
//       target_entity_id: this.correctTeamIdValue,
//       target_entity_type: "Team",
//       chosen_entity_id: chosenTeamId,
//       chosen_entity_type: "Team",
//       options_presented: optionsPresented,
//       is_correct: isCorrect,
//       time_elapsed_ms: timeElapsedMs
//     };

//     this.sendAttemptData(attemptData);
    
//     // Get player name from the player card based on its known structure
//     let playerName = 'Player';
    
//     // First try to find the element with data-player-name attribute
//     let nameElement = this.currentPlayerCardDisplayTarget.querySelector('[data-player-name]');
    
//     // Fallback to ID selector in case it's not transformed
//     if (!nameElement) {
//       nameElement = this.currentPlayerCardDisplayTarget.querySelector('[id$="_name"]');
//     }
    
//     // Final fallback to transformed class selector (if the preprocessor changed it)
//     if (!nameElement) {
//       nameElement = this.currentPlayerCardDisplayTarget.querySelector('.player-name');
//     }
    
//     if (nameElement) {
//       playerName = nameElement.textContent.trim();
//     }
    
//     // Get player photo from the player card
//     let playerPhotoUrl = '';
//     const imageContainer = this.currentPlayerCardDisplayTarget.querySelector('.player-image-container');
//     if (imageContainer) {
//       const imgElement = imageContainer.querySelector('.player-photo');
//       if (imgElement && imgElement.src) {
//         playerPhotoUrl = imgElement.src;
//       }
//     } else {
//       // Fallback to any image in the card
//       const imgElement = this.currentPlayerCardDisplayTarget.querySelector('img');
//       if (imgElement && imgElement.src) {
//         playerPhotoUrl = imgElement.src;
//       }
//     }

//     // Add attempts to the grid with correct team data and chosen team data
//     this.addAttemptToGrid({
//       player: {
//         name: playerName,
//         photoUrl: playerPhotoUrl
//       },
//       correctTeam: {
//         name: correctTeamName,
//         logoUrl: correctTeamLogoUrl
//       },
//       chosenTeam: {
//         name: teamName,
//         logoUrl: chosenTeamLogoUrl || ''
//       },
//       isCorrect: isCorrect
//     });
    
//     // Highlight the player name in the player card
//     const playerNameElement = this.currentPlayerCardDisplayTarget.querySelector('.player-name');
//     if (playerNameElement) {
//       // Add highlight class to trigger animation
//       playerNameElement.classList.add('highlight');
      
//       // Remove highlight class after animation completes
//       setTimeout(() => {
//         playerNameElement.classList.remove('highlight');
//       }, 1250);
//     }
    
//     if (isCorrect) {
//       console.log("[TM Controller] checkAnswer() - answer IS correct");
//       this.correctAnswers++;
//       this.progressCounterTarget.textContent = this.correctAnswers;
//       button.classList.add("correct", "pulsing");
      
//       this.teamNameTextTarget.textContent = teamName;
//       this.teamNameOverlayTarget.classList.add("visible");
      
//       setTimeout(() => {
//         this.teamNameOverlayTarget.classList.remove("visible");
//       }, 1250);

//     } else {
//       console.log("[TM Controller] checkAnswer() - answer IS NOT correct");
//       button.classList.add("incorrect");
      
//       setTimeout(() => {
//         this.teamChoiceTargets.forEach(choice => {
//           if (choice.dataset.correct === "true") {
//             choice.classList.add("correct-answer");
            
//             const correctTeamName = choice.querySelector(".team-name").textContent;
//             this.teamNameTextTarget.textContent = correctTeamName;
//             this.teamNameOverlayTarget.classList.add("visible");
            
//             setTimeout(() => {
//               this.teamNameOverlayTarget.classList.remove("visible");
//             }, 1250);
//           }
//         });
//       }, 500);
//     }

//     // Show the attempts container if it's not already visible
//     this.attemptsContainerTarget.classList.remove("hidden");
//     console.log("[TM Controller] checkAnswer() - attemptsContainer shown");
    
//     if (this.nextQuestionTimer) clearTimeout(this.nextQuestionTimer);
//     console.log("[TM Controller] checkAnswer() - scheduling nextQuestionTimer");
//     this.nextQuestionTimer = setTimeout(() => {
//       console.log("[TM Controller] setTimeout callback - setting isAnimating to false");
//       this.isAnimating = false;
//       if (!this.isPaused) {
//         console.log("[TM Controller] setTimeout callback - calling loadNextQuestion()");
//         this.loadNextQuestion();
//       } else {
//         console.log("[TM Controller] setTimeout callback - game is paused, not loading next question");
//       }
//     }, 3000);
//   }

//   addAttemptToGrid(attemptData) {
//     // Get the template
//     const templateElement = document.getElementById('attempt-template');
//     if (!templateElement) {
//       console.error("Attempt template not found");
//       return;
//     }
    
//     // Clone the template
//     const template = templateElement.querySelector('.attempt-card').cloneNode(true);
    
//     // Set up team part
//     const teamPart = template.querySelector('.attempt-team-part');
//     const teamLogo = teamPart.querySelector('.attempt-team-logo');
//     const teamName = teamPart.querySelector('.attempt-team-name');
    
//     // Set the team info - always show the correct team in the card
//     if (attemptData.isCorrect) {
//       // If correct, show the chosen team (which is the correct team)
//       teamName.textContent = attemptData.chosenTeam.name;
//       if (attemptData.chosenTeam.logoUrl) {
//         teamLogo.src = attemptData.chosenTeam.logoUrl;
//         teamLogo.alt = `${attemptData.chosenTeam.name} Logo`;
//       } else {
//         teamLogo.classList.add('hidden');
//       }
//     } else {
//       // If incorrect, show the correct team in the card
//       teamName.textContent = attemptData.correctTeam.name;
//       if (attemptData.correctTeam.logoUrl) {
//         teamLogo.src = attemptData.correctTeam.logoUrl;
//         teamLogo.alt = `${attemptData.correctTeam.name} Logo`;
//       } else {
//         teamLogo.classList.add('hidden');
//       }
//     }
    
//     // Set up player part
//     const playerPart = template.querySelector('.attempt-player-part');
//     const playerPhoto = playerPart.querySelector('.attempt-player-photo');
//     const playerName = playerPart.querySelector('.attempt-player-name');
    
//     playerName.textContent = attemptData.player.name;
//     if (attemptData.player.photoUrl) {
//       playerPhoto.src = attemptData.player.photoUrl;
//       playerPhoto.alt = `${attemptData.player.name} Photo`;
//     } else {
//       playerPhoto.classList.add('hidden');
//     }
    
//     // Add a small indicator for the chosen team if incorrect
//     if (!attemptData.isCorrect) {
//       const chosenTeamIndicator = document.createElement('div');
//       chosenTeamIndicator.className = 'chosen-team-indicator';
//       chosenTeamIndicator.textContent = `Your Guess: ${attemptData.chosenTeam.name}`;
//       playerPart.appendChild(chosenTeamIndicator);
//     }
    
//     // Apply styling based on correctness
//     if (attemptData.isCorrect) {
//       template.classList.add('correct-attempt');
//       teamPart.classList.add('correct-team-part');
//       playerPart.classList.add('correct-player-part');
//     } else {
//       template.classList.add('incorrect-attempt');
//       teamPart.classList.add('incorrect-team-part');
//       playerPart.classList.add('incorrect-player-part');
//     }
    
//     // Add a timestamp data attribute for sorting/reference
//     template.dataset.timestamp = Date.now();
    
//     // Prepend to grid (newest first)
//     this.attemptsGridTarget.prepend(template);
    
//     // Limit to 20 most recent attempts
//     const attemptCards = this.attemptsGridTarget.querySelectorAll('.attempt-card');
//     if (attemptCards.length > 20) {
//       for (let i = 20; i < attemptCards.length; i++) {
//         attemptCards[i].remove();
//       }
//     }
//   }

//   async sendAttemptData(payload) {
//     const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
//     if (!csrfToken) {
//       console.error("CSRF token not found!");
//       return;
//     }

//     try {
//       const response = await fetch('/game_attempts', {
//         method: 'POST',
//         headers: {
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//           'X-CSRF-Token': csrfToken
//         },
//         body: JSON.stringify({ game_attempt: payload }) 
//       });

//       if (!response.ok) {
//         const errorData = await response.json();
//         console.error('Failed to save game attempt:', response.status, errorData.errors);
//       } else {
//         console.log('Game attempt saved successfully.');
//       }
//     } catch (error) {
//       console.error('Error sending game attempt data:', error);
//     }
//   }
  
//   loadNextQuestion() {
//     console.log("[TM Controller] loadNextQuestion() called");
//     const currentUrl = new URL(window.location.href);
    
//     // Add a timestamp parameter to force a fresh request
//     currentUrl.searchParams.set('t', Date.now());
    
//     // Visit the URL but target only the team_match_game frame
//     console.log("[TM Controller] Visiting with frame target");
//     Turbo.visit(currentUrl.toString(), { frame: "team_match_game" });
    
//     // Reset the timer and animation state for the next question
//     this.isAnimating = false;
//     this.startTime = Date.now();
//   }
  
//   togglePause() {
//     console.log("[TM Controller] togglePause() called");
//     this.isPaused = !this.isPaused;
    
//     if (this.isPaused) {
//       this.pauseButtonTextTarget.textContent = "Resume Game";
//       this.gameContainerTarget.classList.add("paused");
      
//       // If we have a pending timer, clear it
//       if (this.nextQuestionTimer) {
//         clearTimeout(this.nextQuestionTimer);
//         this.nextQuestionTimer = null;
//       }
//     } else {
//       this.pauseButtonTextTarget.textContent = "Pause Game";
//       this.gameContainerTarget.classList.remove("paused");
      
//       // Restart the timer if we're in the middle of an answer delay
//       if (this.isAnimating) {
//         this.nextQuestionTimer = setTimeout(() => this.loadNextQuestion(), 800);
//       }
//     }
//   }
  
//   handleFrameRender(event) {
//     // Only process events for our game frame
//     if (event.target.id === "team_match_game") {
//       console.log("[TM Controller] Frame rendered - updating player values");
      
//       // Get new values from data attributes on the current player card
//       const playerCard = this.currentPlayerCardDisplayTarget;
//       if (playerCard) {
//         const newPlayerId = playerCard.dataset.playerId;
//         const newTeamId = playerCard.dataset.playerTeamId;
        
//         if (newPlayerId && newPlayerId !== String(this.playerIdValue)) {
//           console.log(`[TM Controller] Updating player ID from ${this.playerIdValue} to ${newPlayerId}`);
//           this.playerIdValue = parseInt(newPlayerId);
//         }
        
//         if (newTeamId && newTeamId !== String(this.correctTeamIdValue)) {
//           console.log(`[TM Controller] Updating correct team ID from ${this.correctTeamIdValue} to ${newTeamId}`);
//           this.correctTeamIdValue = parseInt(newTeamId);
//         }
        
//         // Reset the timer for the new question
//         this.startTime = Date.now();
//       }
//     }
//   }
// }
