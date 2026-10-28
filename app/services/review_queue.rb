class ReviewQueue
  MODELS = { "Player" => Player, "Team" => Team, "Division" => Division, "City" => City, "Country" => Country }.freeze

  def initialize(ace:, teams: nil, player_id: nil, players: nil, now: Time.current)
    @ace, @teams, @player_id, @players, @now = ace, teams, player_id, players, now
  end

  def entries
    return [] unless @ace

    @entries ||= begin
      scope = @ace.practice_reviews.due(@now)
      scope = scope.where("(question ->> 'team_id')::bigint IN (?)", @teams.pluck(:id)) if @teams
      scope = scope.where(subject_type: "Player", subject_id: @player_id) if @player_id
      if @players
        scope = scope.where(subject_type: "Player", subject_id: @players.select(:id))
          .or(scope.where(subject_type: "Team", subject_id: @players.select(:team_id)))
      end
      candidates = scope.to_a
      existing = MODELS.transform_values do |model|
        ids = candidates.flat_map do |review|
          subject = review.subject_type == model.name ? [ review.subject_id ] : []
          choices = review.target_type == model.name ? review.question.fetch("choices").map { |choice| choice.fetch("id") } : []
          subject + choices
        end
        model.where(id: ids).pluck(:id).to_set
      end
      candidates.select do |review|
        choices = review.question.fetch("choices")
        existing.fetch(review.subject_type).include?(review.subject_id) && choices.size >= 2 &&
          choices.all? { |choice| existing.fetch(review.target_type).include?(choice.fetch("id")) }
      end.uniq { |review| [ review.subject_type, review.subject_id ] }
    end
  end

  def questions(length:)
    entries.first(length).map(&:question)
  end
end
