class ShoutOutLeaderboard
  attr_reader :week, :kind, :model

  def initialize(week: nil, kind: "players", league_id: nil, sport_id: nil, now: Time.current)
    @current_week = now.utc.to_date.beginning_of_week(:monday)
    if week.present? && (!week.is_a?(String) || !week.match?(/\A\d{4}-\d{2}-\d{2}\z/))
      raise ArgumentError, "Choose a week as YYYY-MM-DD."
    end
    @week = week.present? ? Date.iso8601(week) : @current_week
    raise ArgumentError, "Choose a valid week." if @week.year < 1
    @week = @week.beginning_of_week(:monday)
    raise ArgumentError, "Future weeks are not available." if @week > @current_week
    @kind = kind
    @model = { "players" => Player, "teams" => Team }.fetch(kind) { raise ArgumentError, "Choose Players or Teams." }
    @league_id = league_id
    @sport_id = sport_id
  end

  def posts(week = @week)
    start = Time.utc(week.year, week.month, week.day)
    approvals = ModerationDecision.where(subject_type: "ShoutOut", action: "approved", created_at: start...(start + 7.days)).select(:subject_id)
    scope = ShoutOut.live.where(id: approvals, target_type: model.name, target_id: model.select(:id))
    scope = scope.where(league_id: @league_id) if @league_id
    scope = scope.where(league_id: League.where(sport_id: @sport_id).select(:id)) if @sport_id
    scope
  end

  def rows
    previous = counts(@week - 7).each_with_index.to_h { |(id, _count), index| [ id, index + 1 ] }
    counts(@week).each_with_index.map do |(id, count), index|
      rank = index + 1
      { id: id, count: count, rank: rank, movement: previous[id] && previous[id] - rank }
    end
  end

  def next_week
    @week + 7 if @week < @current_week
  end

  private

  def counts(week)
    posts(week).group(:target_id).order(Arel.sql("COUNT(*) DESC"), :target_id).count.to_a
  end
end
