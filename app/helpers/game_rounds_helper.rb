module GameRoundsHelper
  def round_question_prompt(round)
    return "Unscramble this player’s name. Choose the original below." if round.game_type == "name_ciphers"
    return "Which division is this team in?" if round.game_type == "guess_the_division"

    season_name = round.question["season_name"]
    season_name.present? ? "Which team is this player listed with for #{season_name}?" : "Which team is this player on?"
  end

  def round_team_badge(team)
    color = team.primary_color.to_s
    style = if color.match?(/\A#[0-9a-f]{6}\z/i)
      red, green, blue = color.delete_prefix("#").scan(/../).map { |part| part.to_i(16) }
      ink = (red * 299 + green * 587 + blue * 114) / 1000 > 155 ? "#131418" : "#FFFFFF"
      "--team-color: #{color}; --team-ink: #{ink};"
    end
    abbreviation = team.abbreviation.presence || team.name.split.filter_map { |word| word[0] }.first(3).join.upcase
    tag.span abbreviation, class: "round-team-badge", style: style, aria: { hidden: true }
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
    # A misses drill can contain fewer than ten questions; the setup offers the
    # usual round lengths while preserving its original sport/team scope.
    round.scope.except("drill").merge("length" => GameRound::LENGTHS.include?(round.length) ? round.length : 10)
  end
end
