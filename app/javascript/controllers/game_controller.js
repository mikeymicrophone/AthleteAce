import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = [
    "gameContainer",
    "answerChoice",
    "answerOverlay",
    "answerText",
    "progressCounter",
    "pauseButton",
    "pauseButtonText",
    "questionCard",
    "attemptsContainer",
    "attemptsGrid"
  ]

  static values = {
    subjectId: Number,
    correctAnswerId: Number,
    gameType: String,
    frameId: String,
    subjectType: { type: String, default: "" },
    answerType: { type: String, default: "" }
  }

  connect() {
    this.correctAnswers = 0
    this.gamePaused = false
    this.animatingTransition = false
    this.nextQuestionTimer = null
    this.startTime = Date.now()

    if (!this.hasSubjectTypeValue || !this.subjectTypeValue) {
      this.subjectTypeValue = this.gameTypeValue === "team_match" ? "Player" : "Team"
    }

    if (!this.hasAnswerTypeValue || !this.answerTypeValue) {
      this.answerTypeValue = this.gameTypeValue === "team_match" ? "Team" : "Division"
    }

    document.addEventListener("turbo:frame-render", this.handleFrameRender.bind(this))

    if (this.hasAttemptsGridTarget) {
      this.loadRecentAttempts()
    }
  }

  disconnect() {
    if (this.nextQuestionTimer) {
      clearTimeout(this.nextQuestionTimer)
    }
    document.removeEventListener("turbo:frame-render", this.handleFrameRender.bind(this))
  }

  checkAnswer(event) {
    if (this.gamePaused || this.animatingTransition) return

    this.animatingTransition = true

    const button = event.currentTarget
    const isCorrect = button.dataset.correct === "true"
    const chosenId = parseInt(button.dataset.guessableId)
    const chosenName = this.gameTypeValue === "team_match"
      ? button.querySelector(".team-name")?.textContent
      : button.querySelector(".division-name")?.textContent

    this.answerChoiceTargets.forEach(choice => choice.disabled = true)

    const optionsPresented = this.answerChoiceTargets.map(choice => parseInt(choice.dataset.guessableId))

    this.sendAttemptData(chosenId, isCorrect, optionsPresented)
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
    this.correctAnswers++
    this.progressCounterTarget.textContent = this.correctAnswers

    button.classList.add("correct-choice")

    this.answerTextTarget.textContent = chosenName || "Correct Answer"
    this.answerOverlayTarget.classList.add("visible")

    this.nextQuestionTimer = setTimeout(() => {
      this.answerOverlayTarget.classList.remove("visible")
      setTimeout(() => this.loadNextQuestion(), 300)
    }, 1500)
  }

  handleIncorrectAnswer(button) {
    button.classList.add("incorrect-choice")

    setTimeout(() => {
      const correctButton = this.answerChoiceTargets.find(choice => choice.dataset.correct === "true")
      if (correctButton) {
        correctButton.classList.add("correct-answer")

        const correctName = this.gameTypeValue === "team_match"
          ? correctButton.querySelector(".team-name")?.textContent
          : correctButton.querySelector(".division-name")?.textContent

        this.answerTextTarget.textContent = correctName || "Correct Answer"
        this.answerOverlayTarget.classList.add("visible")

        this.nextQuestionTimer = setTimeout(() => {
          this.answerOverlayTarget.classList.remove("visible")
          setTimeout(() => this.loadNextQuestion(), 300)
        }, 1500)
      }
    }, 500)
  }

  async sendAttemptData(chosenId, isCorrect, optionsPresented) {
    const endTime = Date.now()
    const timeElapsedMs = endTime - this.startTime

    try {
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
        const savedAttempt = await response.json()

        if (this.hasAttemptsContainerTarget) {
          this.attemptsContainerTarget.classList.remove("hidden")
        }

        setTimeout(() => this.addAttemptToGrid(savedAttempt), 500)
      }
    } catch (error) {
      console.error("Error saving attempt:", error)
    }
  }

  loadNextQuestion() {
    this.animatingTransition = false

    const currentUrl = new URL(window.location.href)
    currentUrl.searchParams.set('t', Date.now())

    Turbo.visit(currentUrl.toString(), { frame: this.frameIdValue })
    this.startTime = Date.now()
  }

  handleFrameRender(event) {
    if (event.target.id !== this.frameIdValue) return

    const cardDisplay = this.questionCardTarget
    if (!cardDisplay) return

    if (this.gameTypeValue === "team_match") {
      const newPlayerId = cardDisplay.dataset.playerId
      const newGuessableId = cardDisplay.dataset.guessableId

      if (newPlayerId && newPlayerId !== String(this.subjectIdValue)) {
        this.subjectIdValue = parseInt(newPlayerId)
      }

      if (newGuessableId && newGuessableId !== String(this.correctAnswerIdValue)) {
        this.correctAnswerIdValue = parseInt(newGuessableId)
      }
    } else if (this.gameTypeValue === "division_guess") {
      const newSubjectId = cardDisplay.dataset.guessableId
      const newCorrectAnswerId = cardDisplay.dataset.guessableAnswerId

      if (newSubjectId && newSubjectId !== String(this.subjectIdValue)) {
        this.subjectIdValue = parseInt(newSubjectId)
      }

      if (newCorrectAnswerId && newCorrectAnswerId !== String(this.correctAnswerIdValue)) {
        this.correctAnswerIdValue = parseInt(newCorrectAnswerId)
      }
    }

    this.startTime = Date.now()

    if (this.hasProgressCounterTarget) {
      this.progressCounterTarget.textContent = this.correctAnswers
    }
  }

  loadRecentAttempts() {
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

  addAttemptToGrid(attempt) {
    if (this.gameTypeValue === "team_match") {
      this.addTeamMatchAttemptToGrid(attempt)
    } else {
      this.addDivisionGuessAttemptToGrid(attempt)
    }
  }

  addTeamMatchAttemptToGrid(attempt) {
    const template = document.getElementById("attempt-template")
    if (!template) return

    const attemptCard = template.content.cloneNode(true)
    const card = attemptCard.querySelector(".attempt-card")

    if (attempt.is_correct) {
      card.classList.add("border-green-500")
      card.querySelector(".attempt-result").textContent = "Correct"
      card.querySelector(".attempt-result").classList.add("bg-green-100", "text-green-800")
    } else {
      card.classList.add("border-red-500")
      card.querySelector(".attempt-result").textContent = "Incorrect"
      card.querySelector(".attempt-result").classList.add("bg-red-100", "text-red-800")
    }

    const subjectImage = card.querySelector(".attempt-subject-image")
    const subjectName = card.querySelector(".attempt-subject-name")

    subjectName.textContent = attempt.subject_entity.name
    if (attempt.subject_entity.photo_url) {
      subjectImage.src = attempt.subject_entity.photo_url
      subjectImage.alt = `${attempt.subject_entity.name} photo`
    } else {
      subjectImage.classList.add('hidden')
    }

    const answerImage = card.querySelector(".attempt-answer-image")
    const answerName = card.querySelector(".attempt-answer-name")

    if (attempt.is_correct) {
      answerName.textContent = attempt.chosen_entity.name
      if (attempt.chosen_entity.logo_url) {
        answerImage.src = attempt.chosen_entity.logo_url
        answerImage.alt = `${attempt.chosen_entity.name} logo`
      } else {
        answerImage.classList.add('hidden')
      }
    } else {
      answerName.textContent = attempt.target_entity.name
      if (attempt.target_entity.logo_url) {
        answerImage.src = attempt.target_entity.logo_url
        answerImage.alt = `${attempt.target_entity.name} logo`
      } else {
        answerImage.classList.add('hidden')
      }
    }

    const timeDisplay = card.querySelector(".attempt-time")
    if (timeDisplay) {
      const date = new Date(attempt.created_at || Date.now())
      timeDisplay.textContent = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      card.dataset.timestamp = date.getTime()
    }

    this.attemptsGridTarget.prepend(card)

    const attempts = this.attemptsGridTarget.children
    if (attempts.length > 20) {
      attempts[20].remove()
    }
  }

  addDivisionGuessAttemptToGrid(attempt) {
    const template = document.getElementById("attempt-template")
    if (!template) return

    const attemptCard = template.content.cloneNode(true)
    const card = attemptCard.querySelector(".attempt-card")

    if (attempt.is_correct) {
      card.classList.add("border-green-500")
      card.querySelector(".attempt-result").textContent = "Correct"
      card.querySelector(".attempt-result").classList.add("bg-green-100", "text-green-800")
    } else {
      card.classList.add("border-red-500")
      card.querySelector(".attempt-result").textContent = "Incorrect"
      card.querySelector(".attempt-result").classList.add("bg-red-100", "text-red-800")
    }

    const subjectImage = card.querySelector(".attempt-subject-image")
    const subjectName = card.querySelector(".attempt-subject-name")

    subjectName.textContent = attempt.subject_entity.name
    if (attempt.subject_entity.logo_url) {
      subjectImage.src = attempt.subject_entity.logo_url
      subjectImage.alt = `${attempt.subject_entity.name} logo`
    } else {
      subjectImage.parentElement.innerHTML = '<i class="fas fa-shield-alt text-3xl text-gray-400"></i>'
    }

    const answerImage = card.querySelector(".attempt-answer-image")
    const answerName = card.querySelector(".attempt-answer-name")

    answerName.textContent = attempt.chosen_entity.name

    if (attempt.chosen_entity.logo_url) {
      answerImage.src = attempt.chosen_entity.logo_url
      answerImage.alt = `${attempt.chosen_entity.name} logo`
    } else {
      answerImage.classList.add('hidden')
    }

    const timeDisplay = card.querySelector(".attempt-time")
    if (timeDisplay) {
      const date = new Date(attempt.created_at || Date.now())
      timeDisplay.textContent = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      card.dataset.timestamp = date.getTime()
    }

    this.attemptsGridTarget.prepend(card)

    const attempts = this.attemptsGridTarget.children
    if (attempts.length > 20) {
      attempts[20].remove()
    }
  }

  togglePause() {
    this.gamePaused = !this.gamePaused
    this.pauseButtonTextTarget.textContent = this.gamePaused ? "Resume" : "Pause"

    if (this.gameTypeValue === "team_match") {
      this.pauseButtonTarget.querySelector("i").classList.toggle("fa-pause")
      this.pauseButtonTarget.querySelector("i").classList.toggle("fa-play")
    } else {
      this.pauseButtonTarget.querySelector("i").classList.toggle("fa-pause")
    }
  }
}
