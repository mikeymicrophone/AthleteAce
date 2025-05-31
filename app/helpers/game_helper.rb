module GameHelper
  # Renders a standardized game container with a title
  def unified_game_container(game_type, options = {}, &block)
    title = options[:title] || (game_type == "team_match" ? "Who does this player play for?" : "Which division does this team belong to?")
    
    tag.div(class: "game-container p-4 bg-white rounded-lg shadow-md") do
      tag.div(class: "game-header mb-4") do
        tag.h2 title, class: "text-xl font-bold text-center text-gray-800"
      end + capture(&block)
    end
  end
  
  # Renders a standardized progress display
  def game_progress_display(correct_count = 0)
    tag.div class: "flex items-center justify-between my-3" do
      tag.div(class: "text-sm font-medium") do
        "Correct: " + 
        tag.span(correct_count.to_s, class: "font-bold", data: { game_target: "progressCounter" })
      end +
      tag.div(class: "flex items-center") do
        tag.button(type: "button", class: "pause-button px-3 py-1 text-sm rounded-md flex items-center", 
                  data: { game_target: "pauseButton", action: "click->game#togglePause" }) do
          tag.i("", class: "fas fa-pause mr-1") +
          tag.span("Pause", data: { game_target: "pauseButtonText" })
        end
      end
    end
  end
  
  # Renders a shared choices grid for both game types
  def game_choices_grid(choices, correct_answer, game_type, options = {})
    columns = options[:columns] || (choices.size <= 3 ? choices.size : 2)
    choice_sizes = choices.size
    
    grid_classes = "choices-grid grid gap-4 mt-4"
    grid_classes += " grid-cols-#{columns} md:grid-cols-#{columns}"
    
    tag.div class: grid_classes do
      choices.map do |choice|
        game_choice_item(choice, correct_answer, game_type)
      end.join.html_safe
    end
  end
  
  # Renders an individual game choice (team or division)
  def game_choice_item(choice, correct_answer, game_type)
    is_correct = choice.id == correct_answer.id
    
    data_attributes = {
      game_target: "choiceItem",
      action: "click->game#checkAnswer",
      answer_id: choice.id,
      correct: is_correct.to_s
    }
    
    # Using CSS classes to create consistent styling with meaningful names
    choice_type = game_type == "team_match" ? "team" : "division"
    
    # Base classes shared between both game types
    base_classes = "p-3 border rounded-lg flex items-center justify-between hover:bg-gray-100 transition-colors"
    item_classes = "#{choice_type}-choice #{base_classes} w-full"
    
    tag.button class: item_classes, type: "button", data: data_attributes do
      render_choice_content choice, game_type
    end
  end
  
  # Renders the content of a choice (team or division)
  def render_choice_content(choice, game_type)
    entity_type = game_type == "team_match" ? "team" : "division"
    icon = game_type == "team_match" ? "shield-alt" : "sitemap"
    
    # Left side with logo and name
    left_content = if choice.logo_url.present?
      tag.img(src: choice.logo_url, alt: "#{choice.name} Logo", class: "w-8 h-8 mr-2 object-contain")
    else
      tag.div class: "w-8 h-8 mr-2 flex items-center justify-center bg-gray-200 rounded-full" do
        tag.i class: "fas fa-#{icon} text-gray-500"
      end
    end
    
    # Full content with name
    left_content + tag.span(choice.name, class: "#{entity_type}-name font-medium")
  end
  
  # Renders the correct answer overlay that appears after selecting an answer
  def game_correct_answer_overlay(game_type)
    # More consistent classes between game types with meaningful transition classes
    base_classes = "correct-answer-overlay fixed inset-0 flex items-center justify-center z-50 pointer-events-none"
    visibility_classes = "opacity-0 transition-opacity duration-300"
    
    tag.div class: "#{base_classes} #{visibility_classes}", data: { game_target: "overlayDisplay" } do
      tag.div class: "overlay-content p-6 bg-white rounded-lg shadow-xl text-center max-w-md" do
        tag.h3("Correct!", class: "mb-3 text-2xl font-bold text-green-600") +
        tag.div(data: { game_target: "overlayText" }, class: "text-xl font-bold")  
      end
    end
  end
  
  # Renders a subject card (player or team) with standardized styling
  def game_subject_card(subject, game_type, additional_data = {})
    data_attrs = { game_target: "subjectCardDisplay" }.merge(additional_data)
    
    tag.div class: "subject-card p-4 bg-white rounded-lg shadow-md", data: data_attrs do
      # Question text based on game type
      question = if game_type == "team_match"
        "Who does #{subject.full_name || subject.name} play for?"
      else
        "Which division does #{subject.name} belong to?"
      end
      
      tag.h3(question, class: "text-lg font-bold mb-4 text-center") +
      
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
    image_url = entity_type == :player ? entity.photo_url : entity.logo_url
    name = entity_type == :player ? (entity.full_name || entity.name) : entity.name
    subtitle = entity_type == :player ? entity.primary_position&.name : ""
    icon = entity_type == :player ? "user" : "shield-alt"
    image_class = entity_type == :player ? "object-cover rounded-full" : "object-contain"
    
    # Image container
    tag.div(class: "flex items-center justify-center mb-4") do
      if image_url.present?
        tag.img src: image_url, alt: name, class: "w-32 h-32 #{image_class}"
      else
        tag.div class: "w-32 h-32 flex items-center justify-center bg-gray-200 rounded-full" do
          tag.i class: "fas fa-#{icon} text-5xl text-gray-400"
        end
      end
    end +
    
    # Entity name and subtitle
    tag.h3(name, class: "text-center text-xl font-bold mb-2") +
    (subtitle.present? ? tag.div(subtitle, class: "text-center text-gray-600") : "")
  end
  
  # Renders a container for recent attempts
  def game_attempts_container(game_type)
    tag.div class: "attempts-container mt-8 p-4 bg-white rounded-lg shadow-md hidden", 
            data: { game_target: "attemptsContainer" } do
      tag.h3("Recent Attempts", class: "text-lg font-bold mb-4 text-center") +
      tag.div(class: "attempts-grid grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4", 
              data: { game_target: "attemptsGrid" }) do
        # Content will be dynamically populated by the controller
        ""
      end
    end
  end
  
  # Renders a standardized progress indicator with correct count and pause button
  def game_progress_display(correct_count = 0)
    tag.div class: "controls flex justify-between items-center mt-6", data: { game_target: "controls" } do
      # Progress counter
      tag.div(progress_counter(correct_count), class: "progress-indicator") +
      
      # Pause button
      tag.button(class: "pause-button flex items-center bg-gray-200 hover:bg-gray-300 font-medium py-2 px-4 rounded-lg transition-colors duration-200",
                data: { game_target: "pauseButton", action: "click->game#togglePause" }) do
        tag.i(class: "fa-solid fa-pause mr-2") +
        tag.span("Pause", data: { game_target: "pauseButtonText" })
      end
    end
  end

  def progress_counter(correct_count = 0)
    count = tag.span(correct_count.to_s, id: "progress_counter", class: "progress-counter font-bold", 
    data: { game_target: "progressCounter" })
    tag.span "Progress: #{count} correct".html_safe, class: "text-gray-600"
  end
end
