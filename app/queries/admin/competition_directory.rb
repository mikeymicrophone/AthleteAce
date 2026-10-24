module Admin
  class CompetitionDirectory
    attr_reader :query, :kind, :season_id, :team_id, :titles

    def initialize(params)
      %i[q kind season_id team_id titles].each do |key|
        raise ArgumentError, "Invalid competition filter." unless params[key].nil? || params[key].is_a?(String)
      end
      @query = params[:q].to_s.strip.first(80)
      @kind, @season_id, @team_id, @titles = params.values_at(:kind, :season_id, :team_id, :titles).map(&:presence)
      raise ArgumentError, "Competition kind is too long." if kind && kind.length > 80
      raise ArgumentError, "Choose a season or team." if [ season_id, team_id ].compact.any? { |id| !id.match?(/\A[1-9]\d{0,17}\z/) }
      raise ArgumentError, "Choose a title filter." if titles && !%w[awarded none].include?(titles)
    end

    def records
      competitions = Contest.competitions
      competitions = competitions.where("CONCAT_WS(' ', contests.name, contests.entity_code) ILIKE ?", "%#{Contest.sanitize_sql_like(query)}%") if query.present?
      competitions = competitions.where(kind: kind) if kind
      if season_id || team_id
        campaigns = Campaign.all
        campaigns = campaigns.where(season_id: season_id) if season_id
        campaigns = campaigns.where(team_id: team_id) if team_id
        competitions = competitions.where(id: Contestant.where(campaign_id: campaigns.select(:id)).select(:contest_id))
      end
      if titles
        awarded = TitleAward.select(:contest_id)
        competitions = titles == "awarded" ? competitions.where(id: awarded) : competitions.where.not(id: awarded)
      end
      competitions.includes(season: [ :year, :league ]).order(Arel.sql("contests.begin_date DESC NULLS LAST, contests.id DESC"))
    end
  end
end
