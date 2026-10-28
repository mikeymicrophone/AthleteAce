module Admin
  class GameDirectory
    attr_reader :query, :competition_id, :season_id, :team_id, :from, :to, :participation

    def initialize(params)
      %i[q competition_id season_id team_id from to participation].each do |key|
        raise ArgumentError, "Invalid game filter." unless params[key].nil? || params[key].is_a?(String)
      end
      @query = params[:q].to_s.strip.first(80)
      @competition_id, @season_id, @team_id = params.values_at(:competition_id, :season_id, :team_id).map(&:presence)
      raise ArgumentError, "Choose a competition, season or team." if [ competition_id, season_id, team_id ].compact.any? { |id| !id.match?(/\A[1-9]\d{0,17}\z/) }
      @from, @to = params.values_at(:from, :to).map do |value|
        next if value.blank?
        raise ArgumentError, "Use dates in YYYY-MM-DD format." unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        Date.iso8601(value)
      end
      raise ArgumentError, "End date must be on or after start date." if from && to && from > to
      @participation = params[:participation].presence
      raise ArgumentError, "Choose an appearance filter." if participation && !%w[recorded missing].include?(participation)
    rescue Date::Error
      raise ArgumentError, "Use valid calendar dates."
    end

    def records
      games = Game.all
      games = games.where("CONCAT_WS(' ', contests.name, contests.entity_code) ILIKE ?", "%#{Game.sanitize_sql_like(query)}%") if query.present?
      games = games.where(id: ContestGame.where(contest_id: competition_id).select(:game_id)) if competition_id
      if season_id || team_id
        campaigns = Campaign.all
        campaigns = campaigns.where(season_id: season_id) if season_id
        campaigns = campaigns.where(team_id: team_id) if team_id
        games = games.where(id: Contestant.where(campaign_id: campaigns.select(:id)).select(:contest_id))
      end
      games = games.where("contests.begin_date >= ?", from) if from
      games = games.where("contests.begin_date <= ?", to) if to
      if participation
        observed = Contestant.joins(:appearances).select(:contest_id)
        games = participation == "recorded" ? games.where(id: observed) : games.where.not(id: observed)
      end
      games.includes(competition_memberships: :contest, contestants: { campaign: [ :team, { season: [ :league, :year ] } ] })
        .order(Arel.sql("contests.begin_date DESC NULLS LAST, contests.id DESC"))
    end
  end
end
