class GameHistory
  GAMES = { "player_team_match" => "Team Match", "guess_the_division" => "Guess the Division" }.freeze
  attr_reader :attempts, :game_type, :team, :today, :time_zone

  def initialize ace:, game_type: nil, team: nil, now: Time.current
    @game_type = game_type if GAMES.key? game_type
    @team = team
    @time_zone = Time.zone
    @today = now.in_time_zone(time_zone).to_date
    @attempts = ace.game_attempts.where(game_type: GAMES.keys).where(created_at: ..now)
    @attempts = attempts.where(game_type: @game_type) if @game_type
    if team
      # Attribute Team Match to the recorded answer, even if the player later moves teams.
      @attempts = attempts.where(game_type: "player_team_match", target_entity_type: "Team", target_entity_id: team.id)
        .or(attempts.where(game_type: "guess_the_division", subject_entity_type: "Team", subject_entity_id: team.id))
    end
  end

  def recent_attempts
    attempts.includes(:subject_entity, :target_entity, :chosen_entity).order(created_at: :desc, id: :desc)
  end

  def days
    @days ||= begin
      zone = GameAttempt.connection.quote time_zone.tzinfo.identifier
      date = Arel.sql "DATE(created_at AT TIME ZONE 'UTC' AT TIME ZONE #{zone})"
      counts = attempts.where(created_at: (today - 13).in_time_zone..).group(date, :is_correct).count
      ((today - 13)..today).map do |day|
        correct = counts.fetch [day, true], 0
        total = correct + counts.fetch([day, false], 0)
        { date: day, correct: correct, total: total, accuracy: accuracy(correct, total) }
      end
    end
  end

  def current_week
    summarize days.last(7)
  end

  def previous_week
    summarize days.first(7)
  end

  def accuracy_change
    return unless current_week[:accuracy] && previous_week[:accuracy]

    (current_week[:accuracy] - previous_week[:accuracy]).round
  end

  def team_stats
    @team_stats ||= begin
      counts = Hash.new { |hash, id| hash[id] = { correct: 0, total: 0 } }
      [
        [attempts.where(game_type: "player_team_match", target_entity_type: "Team"), :target_entity_id],
        [attempts.where(game_type: "guess_the_division", subject_entity_type: "Team"), :subject_entity_id]
      ].each do |scope, column|
        scope.group(column, :is_correct).count.each do |(id, correct), count|
          counts[id][:total] += count
          counts[id][:correct] += count if correct
        end
      end
      teams = Team.where(id: counts.keys).includes(league: :sport).index_by &:id
      counts.filter_map do |id, count|
        next unless teams[id]

        count.merge team: teams[id], accuracy: accuracy(count[:correct], count[:total])
      end.sort_by { |stat| [stat[:accuracy], -stat[:total], stat[:team].name] }
    end
  end

  def mixups
    @mixups ||= begin
      counts = attempts.where(game_type: "player_team_match", is_correct: false,
        target_entity_type: "Team", chosen_entity_type: "Team").where.not(chosen_entity_id: nil)
        .where("target_entity_id != chosen_entity_id")
        .group(Arel.sql("LEAST(target_entity_id, chosen_entity_id)"), Arel.sql("GREATEST(target_entity_id, chosen_entity_id)")).count
      teams = Team.where(id: counts.keys.flatten.uniq).includes(:division).index_by &:id
      counts.filter_map do |ids, count|
        pair = ids.filter_map { |id| teams[id] }
        { teams: pair, count: count } if pair.size == 2
      end.sort_by { |pair| [-pair[:count], pair[:teams].map(&:name).join] }.first(5)
    end
  end

  private

  def accuracy correct, total
    correct.fdiv(total) * 100 if total.positive?
  end

  def summarize days
    correct = days.sum { |day| day[:correct] }
    total = days.sum { |day| day[:total] }
    { correct: correct, total: total, accuracy: accuracy(correct, total) }
  end
end
