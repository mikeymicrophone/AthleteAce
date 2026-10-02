module GameHelper
  # Renders a standardized game container with a title
  def unified_game_container(game_type, options = {}, &block)
    title = options[:title] || (game_type == "team_match" ? "Who does this player play for?" : "Which division does this team belong to?")

    tag.div(class: "game-container") do
      tag.div(class: "game-header") do
        tag.h2 title, class: "game-title"
      end + capture(&block)
    end
  end

  # Renders a grid of choices with appropriate data attributes
  def game_choices_grid(choices, correct_answer, game_type, options = {})
    columns = options[:columns] || (choices.size <= 3 ? choices.size : (choices.size >= 6 ? 3 : 2))
    grid_classes = "choices-grid choices-grid-#{columns}"

    tag.div class: grid_classes do
      raw(choices.map { |choice|
        game_choice_item(choice, correct_answer, game_type)
      }.join)
    end
  end

  # Renders a single choice item button with appropriate data attributes
  def game_choice_item(choice, correct_answer, game_type)
    is_correct = (choice.id == correct_answer.id)
    choice_classes = "choice-item"

    data_attrs = {
      action: "click->game#checkAnswer",
      game_target: "answerChoice"
    }

    # Add game-specific data attributes
    if game_type == "team_match"
      data_attrs[:guessable_id] = choice.id
      data_attrs[:correct] = is_correct.to_s
    else
      data_attrs[:guessable_id] = choice.id
      data_attrs[:correct] = is_correct.to_s
    end

    button_tag type: "button", class: choice_classes, data: data_attrs do
      render_choice_content(choice, game_type) +
        tag.span(class: "choice-status choice-status-correct") { icon("check", size: 16) + "Correct" } +
        tag.span(class: "choice-status choice-status-incorrect") { icon("x", size: 16) + "Incorrect" }
    end
  end

  # Renders the content inside a choice button
  def render_choice_content(choice, game_type)
    if game_type == "team_match"
      entity_name_class = "team-name"
    else
      entity_name_class = "division-name"
    end

    content = ""

    # Image part
    content += tag.div(class: "choice-image-container") do
      entity_avatar choice
    end

    # Name part
    content += tag.div(choice.name, class: "choice-name #{entity_name_class}")

    content.html_safe
  end

  # Renders the answer overlay that appears after selecting an answer
  def game_correct_answer_overlay(game_type)
    # Use the clean answer overlay for all game types - focuses on reinforcing the correct answer
    tag.div(class: "answer-overlay", data: { game_target: "answerOverlay" }) do
      tag.div("", class: "answer-text", role: "status", aria: { live: "polite" }, data: { game_target: "answerText" })
    end
  end

  # Renders a subject card (player or team) with standardized styling
  def game_subject_card(subject, game_type, additional_data = {})
    data_attrs = { game_target: "questionCard" }

    # Add appropriate data attributes based on game type
    if game_type == "team_match"
      # For team match, subject is a player and the answer is their team
      data_attrs[:player_id] = subject.id
      data_attrs[:guessable_id] = subject.team_id if subject.respond_to?(:team_id)
    else
      # For division guess, subject is a team and answer is their division
      data_attrs[:guessable_id] = subject.id
    end

    data_attrs.merge!(additional_data)

    tag.div(class: "subject-card", data: data_attrs) do
      # Question text based on game type
      question = if game_type == "team_match"
        "Who does #{subject.full_name || subject.name} play for?"
      else
        "Which division do the #{subject.name} belong to?"
      end

      tag.h3(question, class: "subject-question") +

      # Card content based on subject type
      if game_type == "team_match"
        render_card_entity(subject, :player)
      else
        render_card_entity(subject, :team)
      end
    end
  end

  # Unified method to render either a player or team card
  def render_card_entity(entity, entity_type)
    subtitle = entity_type == :player ? entity.primary_position&.name : nil
    entity_avatar(entity, size: :large) +
      tag.h3(entity.name, class: "entity-name") +
      (subtitle.present? ? tag.div(subtitle, class: "entity-subtitle") : "")
  end

  # Renders a container for recent attempts
  def game_attempts_container(game_type)
    tag.div(class: "attempts-container hidden",
            data: { game_target: "attemptsContainer" }) do
      tag.h3("Recent Attempts", class: "attempts-heading") +
      tag.div(class: "attempts-grid",
              data: { game_target: "attemptsGrid" }) do
        # Content will be dynamically populated by the controller
        ""
      end
    end
  end

  # Renders a standardized progress indicator with correct count and pause button
  def game_progress_display(correct_count = 0)
    tag.div(class: "controls", data: { game_target: "controls" }) do
      # Progress counter
      tag.div(progress_counter(correct_count), class: "progress-indicator") +

      # Pause button
      tag.button(type: "button", class: "pause-button-main tool-button", aria: { pressed: false },
                data: { game_target: "pauseButton", action: "click->game#togglePause" }) do
        icon("player-pause", size: 18, class: "pause-symbol") + icon("player-play", size: 18, class: "resume-symbol") +
        tag.span("Pause", class: "pause-button-text", data: { game_target: "pauseButtonText" })
      end
    end
  end

  def progress_counter(correct_count = 0)
    count = tag.span(correct_count.to_s, id: "progress_counter", class: "progress-counter",
    data: { game_target: "progressCounter" })
    tag.span("Progress: #{count} correct".html_safe, class: "progress-label")
  end

  # Creates the CSS classes for result status indicators
  def attempt_result_classes(is_correct)
    if is_correct
      {
        card: "correct-attempt",
        indicator: "correct-indicator",
        icon: "check",
        text: "Correct"
      }
    else
      {
        card: "incorrect-attempt",
        indicator: "incorrect-indicator",
        icon: "x",
        text: "Incorrect"
      }
    end
  end

  # Renders an individual recent attempt item
  def game_attempt_item(entity_name, result, game_type, additional_data = {})
    classes = attempt_result_classes(result)
    entity_type = game_type == "team_match" ? "Player" : "Team"

    tag.div(class: "attempt-item #{classes[:card]}") do
      tag.div(class: "attempt-content") do
        icon(classes[:icon], size: 18, class: result ? "correct-icon" : "incorrect-icon") +
        tag.span(entity_name, class: "attempt-entity-name")
      end +
      tag.div(class: "attempt-result #{classes[:indicator]}") do
        classes[:text]
      end
    end
  end
end
