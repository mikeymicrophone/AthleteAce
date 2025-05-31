// app/javascript/controllers/division_game_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "attemptsContainer",
    "attemptsGrid"
  ];
  
  static values = {
    teamId: Number,
    correctDivisionId: Number
  };

  connect() {
    console.log("Division Game Controller connected");
    this.loadRecentAttempts();
  }
  
  // Load recent attempts for the current user
  loadRecentAttempts() {
    fetch("/game_attempts.json?game_type=guess_the_division&limit=10")
      .then(response => response.json())
      .then(data => {
        if (data && data.length > 0) {
          this.attemptsContainerTarget.classList.remove("hidden");
          data.forEach(attempt => this.addAttemptToGrid(attempt));
        }
      })
      .catch(error => console.error("Error loading recent attempts:", error));
  }
  
  // Add an attempt to the attempts grid
  addAttemptToGrid(attemptData) {
    // Get the template
    const templateContent = document.getElementById("division-attempt-template").innerHTML;
    const attemptCard = document.createElement("div");
    attemptCard.innerHTML = templateContent;
    
    // Get the card element from the template content
    const card = attemptCard.querySelector("#division-attempt-card");
    
    // Set unique ID for the card
    card.id = `division-attempt-${attemptData.id}`;
    
    // Add correct/incorrect class
    if (attemptData.is_correct) {
      card.classList.add("correct-attempt", "border-green-500");
    } else {
      card.classList.add("incorrect-attempt", "border-red-500");
    }
    
    // Set team info
    const teamPart = card.querySelector("#team-part");
    const teamLogo = teamPart.querySelector("#team-logo");
    const teamName = teamPart.querySelector("#team-name");
    
    if (attemptData.subject_entity.logo_url) {
      teamLogo.src = attemptData.subject_entity.logo_url;
      teamLogo.alt = `${attemptData.subject_entity.name} logo`;
    } else {
      // Replace with icon if no logo
      const logoContainer = teamPart.querySelector("#team-logo-container");
      logoContainer.innerHTML = '<i class="fas fa-shield-alt text-3xl text-gray-400"></i>';
    }
    
    teamName.textContent = attemptData.subject_entity.name;
    
    // Set division info
    const divisionPart = card.querySelector("#division-part");
    const divisionIcon = divisionPart.querySelector("#division-icon");
    const divisionName = divisionPart.querySelector("#division-name");
    
    // Use different icon colors for correct/incorrect
    if (attemptData.is_correct) {
      divisionIcon.classList.add("text-green-500");
    } else {
      divisionIcon.classList.add("text-red-500");
    }
    
    // Show the chosen division name
    divisionName.textContent = attemptData.chosen_entity.name;
    
    // Add timestamp as a tooltip
    const timestamp = new Date(attemptData.created_at);
    card.setAttribute("title", `Attempt made on ${timestamp.toLocaleString()}`);
    
    // Add the card to the grid
    this.attemptsGridTarget.appendChild(card);
  }
}
