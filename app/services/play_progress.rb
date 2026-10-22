# Read learning progress from saved attempts; correcting a miss clears it immediately.
class PlayProgress
  attr_reader :ace, :now, :time_zone

  def initialize(ace:, now: Time.current)
    @ace = ace
    @now = now
    @time_zone = ace.play_time_zone
  end

  def streaks
    @streaks ||= begin
      zone = GameAttempt.connection.quote(time_zone.tzinfo.identifier)
      date = Arel.sql("DATE(created_at AT TIME ZONE 'UTC' AT TIME ZONE #{zone})")
      days = attempts.distinct.order(date).pluck(date)
      run = best = 0
      previous = nil
      days.each do |day|
        run = previous == day - 1 ? run + 1 : 1
        best = [ best, run ].max
        previous = day
      end
      today = now.in_time_zone(time_zone).to_date
      { current: days.last && days.last >= today - 1 ? run : 0, best: best }
    end
  end

  def names_known
    known_player_ids.size
  end

  def known_player_ids
    memories.select { |memory| memory[:latest_correct] && memory[:correct] >= 2 }.map { |memory| memory[:player_id] }
  end

  def misses(limit: 3)
    ordered = memories.select { |memory| memory[:misses].positive? }
      .sort_by { |memory| [ -memory[:misses], -memory[:last_seen].to_f, memory[:player_id] ] }
    ids = ordered.map { |memory| memory[:player_id] }
    players = Player.where(id: ids).includes(team: :league).index_by(&:id)
    latest = attempts.where(id: ordered.map { |memory| memory[:attempt_id] }).includes(:game_round).index_by(&:subject_entity_id)
    recorded = latest.transform_values do |attempt|
      attempt.game_round&.questions&.[](attempt.round_position)
    end
    recorded_teams = Team.where(id: recorded.values.compact.map { |question| question["team_id"] || (question["target_id"] if question["target_type"] == "Team") }).index_by(&:id)
    playable = GameRoundSetup.new(include_inactive: true).subjects.where(id: ids).pluck(:id)
    ordered.filter_map do |memory|
      player = players[memory[:player_id]]
      next unless player

      question = recorded[player.id]
      team = question ? recorded_teams[question["team_id"] || (question["target_id"] if question["target_type"] == "Team")] : player.team
      next unless question || (team && playable.include?(player.id))
      question = question.merge("game_type" => question.fetch("game_type", latest[player.id].game_type)) if question

      memory.merge(player: player, team: team, question: question, season_name: question&.dig("season_name"))
    end.first(limit)
  end

  def players_today
    since = now.in_time_zone(time_zone).beginning_of_day
    ids = attempts.where(subject_entity_type: "Player", created_at: since..now).select(:subject_entity_id)
    Player.where(id: ids).includes(:team).order(:last_name, :first_name, :id).limit(4)
  end

  private

  def attempts
    ace.game_attempts.where(game_type: GameRound::GAMES.keys, created_at: ..now)
  end

  def player_attempts
    attempts.where(subject_entity_type: "Player", subject_entity_id: Player.select(:id))
  end

  def memories
    @memories ||= begin
      # Count wrong attempts after the last correct answer, with id breaking timestamp ties.
      ranked = player_attempts.select(<<~SQL.squish)
        id, subject_entity_id, is_correct, created_at,
        ROW_NUMBER() OVER (PARTITION BY subject_entity_id ORDER BY created_at DESC, id DESC) AS recency,
        COUNT(*) FILTER (WHERE is_correct) OVER (PARTITION BY subject_entity_id) AS total_correct,
        COUNT(*) FILTER (WHERE is_correct) OVER (
          PARTITION BY subject_entity_id ORDER BY created_at DESC, id DESC
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS newer_correct
      SQL
      GameAttempt.unscoped.from("(#{ranked.to_sql}) AS memory").group(:subject_entity_id).pluck(
        :subject_entity_id, Arel.sql("MAX(total_correct)"),
        Arel.sql("BOOL_OR(is_correct) FILTER (WHERE recency = 1)"),
        Arel.sql("COUNT(*) FILTER (WHERE NOT is_correct AND newer_correct = 0)"),
        Arel.sql("MAX(created_at)"), Arel.sql("MAX(id) FILTER (WHERE recency = 1)")
      ).map do |id, correct, latest_correct, misses, last_seen, attempt_id|
        { player_id: id, correct: correct, latest_correct: latest_correct, misses: misses, last_seen: last_seen, attempt_id: attempt_id }
      end
    end
  end
end
