module GameRoundsHelper
  def round_question_mode(round)
    round.question.fetch("game_type", round.game_type)
  end

  def round_question_prompt(round)
    mode = round_question_mode(round)
    return "Name the player in this photo." if mode == "image_recognition"
    if mode == "multiple_choice"
      return "Which team is this player listed with for #{round.question["season_name"]}?" if round.question["fact_type"] == "team" && round.question["season_name"]
      return { "team" => "Which team is this player on?", "birth_city" => "Which city was this player born in?", "birth_country" => "Which country was this player born in?" }.fetch(round.question.fetch("fact_type"))
    end
    return "Unscramble this player’s name. Choose the original below." if mode == "name_ciphers"
    return "Which division is this team in?" if mode == "guess_the_division"

    season_name = round.question["season_name"]
    season_name.present? ? "Which team is this player listed with for #{season_name}?" : "Which team is this player on?"
  end

  def round_team_badge(team)
    abbreviation = team.abbreviation.presence || team.name.split.filter_map { |word| word[0] }.first(3).join.upcase
    tag.span abbreviation, class: "round-team-badge",
      style: team_palette_style(team.primary_color, team.text_color, team.secondary_color), aria: { hidden: true }
  end

  def round_answer_badge(choice)
    abbreviation = choice["abbreviation"].presence || choice.fetch("name").split.filter_map { |word| word[0] }.first(3).join.upcase
    tag.span abbreviation, class: "round-team-badge",
      style: team_palette_style(choice["primary_color"], choice["text_color"], choice["secondary_color"]), aria: { hidden: true }
  end

  def round_player_portrait(question, player)
    photo_url = question.key?("subject_photo_url") ? question["subject_photo_url"] : player&.photo_url
    tag.div class: "round-athlete-portrait",
      style: team_palette_style(question["subject_primary_color"], question["subject_text_color"], question["subject_secondary_color"]),
      data: { controller: "entity-image" }, aria: { hidden: true } do
      fallback = tag.div class: "round-jersey", data: { entity_image_target: "fallback" } do
        jersey_portrait_fallback(question["subject_name"] || player&.name, question["subject_jersey_number"])
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
