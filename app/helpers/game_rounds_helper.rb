module GameRoundsHelper
  def round_scope_fields form, setup, except: []
    safe_join setup.scope_params.except(*except.map(&:to_s)).map { |key, value|
      if value.is_a? Array
        safe_join value.map { |id| hidden_field_tag "#{key}[]", id }
      else
        form.hidden_field key, value: value
      end
    }
  end

  def round_choice_class choice, attempt, question
    classes = ["round-choice"]
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

  def round_duration milliseconds
    seconds = milliseconds / 1000
    "#{seconds / 60}:#{format('%02d', seconds % 60)}"
  end

  def round_replay_params round
    # A misses drill can contain fewer than ten questions; the setup offers the
    # usual round lengths while preserving its original sport/team scope.
    round.scope.except("drill").merge("length" => GameRound::LENGTHS.include?(round.length) ? round.length : 10)
  end
end
