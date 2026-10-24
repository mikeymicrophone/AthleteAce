require "csv"

module Admin
  class SportsDirectory
    EXPORT_LIMIT = 10_000
    CSV_HEADERS = {
      "players" => %w[record_id entity_code first_name last_name nicknames_json birthdate current_position active sport_code sport_name current_team_code current_team_name current_league_code current_league_name photo_urls_json debut_year draft_year updated_at_utc],
      "teams" => %w[record_id entity_code territory mascot abbreviation league_code league_name division_code division_name primary_color secondary_color text_color current_player_count stadium_code stadium_name website_url logo_url founded_year updated_at_utc]
    }.freeze
    attr_reader :kind, :query, :league_id, :team_id, :status, :position, :photo, :edited

    def initialize(params)
      %i[kind q league_id team_id status position photo edited].each do |key|
        raise ArgumentError, "Invalid sports filter." unless params[key].nil? || params[key].is_a?(String)
      end
      @kind = params[:kind].presence || "players"
      @model = EditCatalog.model_for(kind)
      @query = params[:q].to_s.strip.first(80)
      @league_id, @team_id = params[:league_id].presence, params[:team_id].presence
      @status, @position, @photo, @edited = params.values_at(:status, :position, :photo, :edited).map(&:presence)
      raise ArgumentError, "Choose a league or team." if [ league_id, team_id ].compact.any? { |id| !id.match?(/\A[1-9]\d{0,17}\z/) }
      raise ArgumentError, "Choose a player status." if status && !%w[active inactive unknown].include?(status)
      raise ArgumentError, "Choose a photo filter." if photo && !%w[present missing].include?(photo)
      raise ArgumentError, "Choose an edit filter." if edited && edited != "yes"
      raise ArgumentError, "Position is too long." if position && position.length > 100
      raise ArgumentError, "Player filters do not apply to teams." if kind == "teams" && [ team_id, status, position, photo ].any?
    end

    def records
      records = @model.all
      if query.present?
        fields = kind == "players" ? "players.first_name, players.last_name, array_to_string(players.nicknames, ' '), players.entity_code" : "teams.territory, teams.mascot, teams.abbreviation, teams.entity_code"
        records = records.where("CONCAT_WS(' ', #{fields}) ILIKE ?", "%#{@model.sanitize_sql_like(query)}%")
      end
      records = records.merge(edited_records) if edited
      if kind == "players"
        records = records.joins(:team).where(teams: { league_id: league_id }) if league_id
        records = records.where(team_id: team_id) if team_id
        records = records.where(active: { "active" => true, "inactive" => false, "unknown" => nil }.fetch(status)) if status
        records = records.where(current_position: position) if position
        if photo
          condition = "EXISTS (SELECT 1 FROM unnest(players.photo_urls) AS photo_url WHERE btrim(photo_url) <> '')"
          records = records.where(photo == "present" ? condition : "NOT #{condition}")
        end
        records.includes(team: :league).order(:last_name, :first_name, :id)
      else
        records = records.where(league_id: league_id) if league_id
        records.includes(:league, :division, :stadium).select("teams.*", "(SELECT COUNT(*) FROM players WHERE players.team_id = teams.id) AS player_count").order(:territory, :mascot, :id)
      end
    end

    def edited_records
      edits = CatalogEdit.where(record_type: @model.name)
      @model.where(entity_code: edits.select(:entity_code)).or(
        @model.where(entity_code: nil, id: edits.where(entity_code: nil).select(:record_id)))
    end

    def csv
      scope = records
      scope = scope.includes(:sport) if kind == "players"
      rows = scope.limit(EXPORT_LIMIT + 1).to_a
      raise ArgumentError, "Export exceeds #{EXPORT_LIMIT} records. Narrow the filters." if rows.size > EXPORT_LIMIT

      CSV.generate(encoding: "UTF-8") do |csv|
        csv << CSV_HEADERS.fetch(kind)
        rows.each do |record|
          csv << csv_values(record).map { |value| value.is_a?(String) && value.match?(/\A(?:[\t\r\n]|[[:space:]\x00-\x1f]*[=+\-@])/) ? "'#{value}" : value }
        end
      end
    end

    private

    def csv_values(record)
      if kind == "players"
        team = record.team
        league = team&.league
        [ record.id, record.entity_code, record.first_name, record.last_name, record.nicknames.to_json,
          record.birthdate&.iso8601, record.current_position, record.active, record.sport&.entity_code, record.sport&.name,
          team&.entity_code, team&.name, league&.entity_code, league&.name, record.photo_urls.to_json,
          record.debut_year, record.draft_year, record.updated_at.utc.iso8601(6) ]
      else
        [ record.id, record.entity_code, record.territory, record.mascot, record.abbreviation,
          record.league&.entity_code, record.league&.name, record.division&.entity_code, record.division&.name,
          record.primary_color, record.secondary_color, record.text_color, record.player_count,
          record.stadium&.entity_code, record.stadium&.name, record.url, record.logo_url, record.founded_year,
          record.updated_at.utc.iso8601(6) ]
      end
    end
  end
end
