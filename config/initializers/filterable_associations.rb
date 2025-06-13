module FilterableAssociations
  # Define associations that can be used for filtering
  ASSOCIATIONS = {
    players: [:sport, :league, :stadium, :team, :state, :city],
    divisions: [:conference, :league, :country, :sport],
    conferences: [:league, :country, :sport, :stadium],
    cities: [:state, :country],
    memberships: [:team, :division, :conference, :league, :sport, :country, :state, :city, :stadium],
    campaigns: [:team, :season, :league, :sport, :country, :state, :city, :stadium],
    contests: [:season, :league, :conference, :division, :sport, :country, :state, :city, :stadium],
    stadiums: [:city, :state, :country, :sport],
    sports: [:country],
    teams: [:sport, :league, :conference, :division, :state, :city, :stadium],
    countries: [:sport, :contest],
    leagues: [:sport, :country, :contest],
    states: [:country, :sport],
    seasons: [:contest],
    conferences: [:contest],
    divisions: [:contest],
    contracts: [:player, :team, :sport, :league, :conference, :division, :state, :city, :stadium],
    activations: [:contract, :campaign, :player, :team, :season, :league, :sport, :state, :city, :stadium]
  }.freeze

  # Define join paths for more complex associations that require intermediates
  # Format: { model: { filter_by: { joins: [:association1, :association2] } } }
  JOIN_PATHS = {
    players: {
      conference: { joins: [:team, :division] },
      league: { joins: [:team] }
    },
    teams: {
      country: { joins: [:state] },
      conference: { joins: [memberships: { division: :conference }] }
    },
    campaigns: {
      league: { joins: [:season] },
      sport: { joins: [season: :league] },
      country: { joins: [team: { stadium: [:city, :state] }] },
      state: { joins: [team: { stadium: :state }] },
      city: { joins: [team: { stadium: :city }] },
      stadium: { joins: [team: :stadium] }
    },
    contests: {
      league: { joins: [:season] },
      sport: { joins: [season: :league] },
      country: { joins: [season: { league: :country }] },
      state: { joins: [season: { league: :country }] },
      city: { joins: [season: { league: :country }] },
      stadium: { joins: [season: { league: :country }] }
    },
    contracts: {
      sport: { joins: [team: { league: :sport }] },
      league: { joins: [team: :league] },
      conference: { joins: [team: { division: :conference }] },
      division: { joins: [team: :division] },
      state: { joins: [team: { stadium: { city: :state } }] },
      city: { joins: [team: { stadium: :city }] },
      stadium: { joins: [team: :stadium] }
    },
    activations: {
      player: { joins: [:contract] },
      team: { joins: [:contract] },
      sport: { joins: [campaign: { season: { league: :sport } }] },
      league: { joins: [campaign: { season: :league }] },
      season: { joins: [:campaign] },
      state: { joins: [contract: { team: { stadium: { city: :state } } }] },
      city: { joins: [contract: { team: { stadium: :city } }] },
      stadium: { joins: [contract: { team: :stadium }] }
    }
    # Add more complex join paths as needed
  }.freeze

  # Get filterable associations for a controller
  def self.for(controller_name)
    model_name = controller_name.to_s.sub('Controller', '').underscore.to_sym
    ASSOCIATIONS[model_name] || []
  end

  def self.from(model_name)
    ASSOCIATIONS.select { |k, v| v.include?(model_name) }.keys
  end

  # Get join path for a specific association
  def self.join_path_for(model, association)
    return nil unless JOIN_PATHS[model] && JOIN_PATHS[model][association]
    JOIN_PATHS[model][association][:joins]
  end
end
