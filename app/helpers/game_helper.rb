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
  
  # Renders a standardized progress display
  def game_progress_display(correct_count = 0)
    tag.div class: "game-progress" do
      tag.div(class: "progress-text") do
        "Correct: " + 
        tag.span(correct_count.to_s, class: "progress-count", data: { game_target: "progressCounter" })
      end +
      tag.div(class: "progress-controls") do
        tag.button(type: "button", class: "pause-button", 
                  data: { game_target: "pauseButton", action: "click->game#togglePause" }) do
          tag.i("", class: "fas fa-pause pause-icon") +
          tag.span("Pause", class: "pause-text", data: { game_target: "pauseButtonText" })
        end
      end
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
      game_target: "choiceItem"
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
      render_choice_content(choice, game_type)
    end
  end
  
  # Renders the content inside a choice button
  def render_choice_content(choice, game_type)
    if game_type == "team_match"
      entity_name_class = "team-name"
      entity_image_class = "team-logo"
    else
      entity_name_class = "division-name"
      entity_image_class = "division-logo"
    end
    
    content = ""
    
    # Image part
    content += tag.div(class: "choice-image-container") do
      if choice.logo_url.present?
        tag.img src: choice.logo_url, alt: "#{choice.name} Logo", class: "choice-image #{entity_image_class}"
      else
        tag.div(class: "choice-image-placeholder") do
          tag.i(class: "fas fa-shield-alt choice-placeholder-icon")
        end
      end
    end
    
    # Name part
    content += tag.div(choice.name, class: "choice-name #{entity_name_class}")
    
    content.html_safe
  end
  
  # Renders the answer overlay that appears after selecting an answer
  def game_correct_answer_overlay(game_type)
    # Use the clean answer overlay for all game types - focuses on reinforcing the correct answer
    tag.div(class: "answer-overlay", data: { game_target: "answerOverlay" }) do
      tag.div("", class: "answer-text", data: { game_target: "answerText" })
    end
  end
  
  # Renders a subject card (player or team) with standardized styling
  def game_subject_card(subject, game_type, additional_data = {})
    data_attrs = { game_target: "subjectCardDisplay" }
    
    # Add appropriate data attributes based on game type
    if game_type == "team_match"
      # For team match, subject is a player and the answer is their team
      data_attrs[:player_id] = subject.id
      data_attrs[:guessable_id] = subject.team_id if subject.respond_to?(:team_id)
    else
      # For division guess, subject is a team and answer is their division
      data_attrs[:guessable_id] = subject.id #TODO: check this
      data_attrs[:guessable_answer_id] = subject.division_id if subject.respond_to?(:division_id)
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
  
  # UNUSED
  # Unified method to render either a player or team card
  def render_card_entity(entity, entity_type)
    image_url = entity_type == :player ? entity.photo_url : entity.logo_url
    name = entity_type == :player ? (entity.full_name || entity.name) : entity.name
    subtitle = entity_type == :player ? entity.primary_position&.name : ""
    icon = entity_type == :player ? "user" : "shield-alt"
    image_class = entity_type == :player ? "entity-image-player" : "entity-image-team"
    
    # Image container
    tag.div(class: "entity-image-container") do
      if image_url.present?
        tag.img(src: image_url, alt: name, class: "entity-image #{image_class}")
      else
        tag.div(class: "entity-image-placeholder") do
          tag.i(class: "fas fa-#{icon} entity-placeholder-icon #{entity_type == :player ? 'player-icon' : 'team-icon'}")
        end
      end
    end +
    
    # Entity name and subtitle
    tag.h3(name, class: "entity-name") +
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
      tag.button(class: "pause-button-main",
                data: { game_target: "pauseButton", action: "click->game#togglePause" }) do
        tag.i(class: "fa-solid fa-pause pause-button-icon") +
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
        icon: "fa-check correct-icon",
        text: "Correct"
      }
    else
      {
        card: "incorrect-attempt",
        indicator: "incorrect-indicator",
        icon: "fa-xmark incorrect-icon",
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
        tag.i(class: "fas #{classes[:icon]}") +
        tag.span(entity_name, class: "attempt-entity-name")
      end +
      tag.div(class: "attempt-result #{classes[:indicator]}") do
        classes[:text]
      end
    end
  end
end
