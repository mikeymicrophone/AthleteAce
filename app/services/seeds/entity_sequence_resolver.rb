module Seeds
  class EntitySequenceResolver
    def initialize(importer = LibraryImporter.new, scope: {})
      @importer = importer
    end

    def resolve_sequence(mapping)
      entities = {}
      requested_type = LibraryImporter::MODELS.keys.find { |name| name.downcase == mapping.keys.last.downcase }
      ordered = mapping.sort_by do |slot, _|
        %w[country sport state city stadium league conference division year season team player contract campaign activation].index(slot.downcase) || 100
      end
      ordered.each do |slot, value|
        type = LibraryImporter::MODELS.keys.find { |name| name.downcase == slot.downcase }
        raise LibraryImporter::Error, "Unsupported sequence slot #{slot}" unless type
        target = @importer.resolve_code(type, value)
        target ||= lookup(type, value, entities)
        raise LibraryImporter::MissingReference, "Missing #{type} #{value} in selected sequence" unless target
        entities[type] = target
      end
      verify_hierarchy!(entities)
      entities.fetch(requested_type)
    end

    private

    def lookup(type, value, entities)
      case type
      when "Sport"
        @importer.resolve_code("Sport", "SPORT-#{value}")
      when "Year"
        Year.find_by(number: value) if value.to_s.match?(/\A\d{4}\z/)
      when "League"
        relation = League.where(abbreviation: value)
        relation = relation.where(sport: entities["Sport"]) if entities["Sport"]
        unique(relation)
      when "Conference"
        relation = Conference.where("abbreviation = ? OR name = ?", value, value.tr("_", " "))
        relation = relation.where(league: entities["League"]) if entities["League"]
        unique(relation)
      when "Division"
        relation = Division.where("abbreviation = ? OR name = ?", value, value.tr("_", " "))
        relation = relation.where(conference: entities["Conference"]) if entities["Conference"]
        unique(relation)
      when "Team"
        if entities["League"] && entities["Year"]
          campaigns = Campaign.joins(:season).where(seasons: { league_id: entities["League"].id, year_id: entities["Year"].id })
          campaigns = campaigns.where(conference: entities["Conference"]) if entities["Conference"]
          campaigns = campaigns.where(division: entities["Division"]) if entities["Division"]
          campaign = unique(campaigns.where(abbreviation: value))
          campaign&.team
        else
          relation = Team.where(abbreviation: value)
          relation = relation.where(league: entities["League"]) if entities["League"]
          unique(relation)
        end
      when "Player"
        return unless entities["Team"] && entities["League"] && entities["Year"]
        relation = Player.joins(activations: { campaign: :season }).where(
          campaigns: { team_id: entities["Team"].id },
          seasons: { league_id: entities["League"].id, year_id: entities["Year"].id }
        ).distinct
        name = value.upcase
        relation = relation.where("UPPER(players.last_name) = ? OR UPPER(CONCAT(players.last_name, '_', players.first_name)) = ?", name, name)
        unique(relation)
      end
    end

    def unique(relation)
      matches = relation.limit(2).to_a
      raise LibraryImporter::Error, "Ambiguous sequence component" if matches.length > 1
      matches.first
    end

    def verify_hierarchy!(entities)
      sport, league, conference, division, year, team = entities.values_at("Sport", "League", "Conference", "Division", "Year", "Team")
      if sport && league && league.sport_id != sport.id
        raise LibraryImporter::Error, "League is outside selected sport"
      end
      if conference && league && conference.league_id != league.id
        raise LibraryImporter::Error, "Conference is outside selected league"
      end
      if division && conference && division.conference_id != conference.id
        raise LibraryImporter::Error, "Division is outside selected conference"
      end
      return unless team && league && year
      campaign = Campaign.joins(:season).find_by(team: team, seasons: { league_id: league.id, year_id: year.id })
      raise LibraryImporter::MissingReference, "Team has no campaign in selected league/year" unless campaign
      if (conference && campaign.conference_id != conference.id) || (division && campaign.division_id != division.id)
        raise LibraryImporter::Error, "Team campaign is outside selected conference/division"
      end
    end

  end
end
