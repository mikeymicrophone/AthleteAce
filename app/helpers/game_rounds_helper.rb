module GameRoundsHelper
  def round_question_prompt(round)
    return "Unscramble this player’s name. Choose the original below." if round.game_type == "name_ciphers"
    return "Which division is this team in?" if round.game_type == "guess_the_division"

    season_name = round.question["season_name"]
    season_name.present? ? "Which team is this player listed with for #{season_name}?" : "Which team is this player on?"
  end

  def round_team_badge(team)
    abbreviation = team.abbreviation.presence || team.name.split.filter_map { |word| word[0] }.first(3).join.upcase
    tag.span abbreviation, class: "round-team-badge", style: round_color_style(team.primary_color), aria: { hidden: true }
  end

  def round_color_style(color)
    color = color.to_s
    return unless color.match?(/\A#[0-9a-f]{6}\z/i)

    red, green, blue = color.delete_prefix("#").scan(/../).map { |part| part.to_i(16) }
    ink = (red * 299 + green * 587 + blue * 114) / 1000 > 155 ? "#131418" : "#FFFFFF"
    "--team-color: #{color}; --team-ink: #{ink};"
  end

  def round_answer_badge(choice)
    abbreviation = choice["abbreviation"].presence || choice.fetch("name").split.filter_map { |word| word[0] }.first(3).join.upcase
    tag.span abbreviation, class: "round-team-badge", style: round_color_style(choice["primary_color"]), aria: { hidden: true }
  end

  def round_player_portrait(question, player)
    photo_url = question.key?("subject_photo_url") ? question["subject_photo_url"] : player&.photo_url
    tag.div class: "round-athlete-portrait", style: round_color_style(question["subject_primary_color"]),
      data: { controller: "entity-image" }, aria: { hidden: true } do
      fallback = tag.div class: "round-jersey", data: { entity_image_target: "fallback" } do
        icon("jersey", size: 112)
      end
      photo = if photo_url.present?
        tag.img src: photo_url, alt: "", class: "round-athlete-photo hidden",
          data: { entity_image_target: "image", action: "load->entity-image#loaded error->entity-image#failed" }
      end
      safe_join [ fallback, photo ].compact
    end
  end

  def round_scope_fields(form, setup, except: [])
    safe_join setup.scope_params.except(*except.map(&:to_s)).map { |key, value|
      if value.is_a? Array
        safe_join value.map { |id| hidden_field_tag "#{key}[]", id }
      else
        form.hidden_field key, value: value
      end
    }
  end

  def round_choice_class(choice, attempt, question)
    classes = [ "round-choice" ]
    if attempt
      classes << if choice.fetch("id") == question.fetch("target_id")
        "round-choice-correct"
      elsif choice.fetch("id") == attempt.chosen_entity_id
        "round-choice-wrong"
      else
        "round-choice-muted"
      end
    end
    classes.join " "
  end

  def round_duration(milliseconds)
    seconds = milliseconds / 1000
    "#{seconds / 60}:#{format('%02d', seconds % 60)}"
  end

  def round_replay_params(round)
    # Short pools and misses drills retain the originally requested round size.
    requested = round.scope.fetch("length", round.length).to_i
    round.scope.except("drill").merge("length" => GameRound::LENGTHS.include?(requested) ? requested : 10)
  end
end
