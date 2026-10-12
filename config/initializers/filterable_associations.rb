module FilterableAssociations
  # Define associations that can be used for filtering
  ASSOCIATIONS = {
    players: [:sport, :league, :stadium, :team, :state, :city],
    divisions: [:conference, :league, :country, :sport, :contest],
    conferences: [:league, :country, :sport, :stadium, :contest],
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
    contracts: [:player, :team, :sport, :league, :conference, :division, :state, :city, :stadium],
    activations: [:contract, :campaign, :player, :team, :season, :league, :sport, :state, :city, :stadium]
  }.freeze

  # Get filterable associations for a controller
  def self.for(controller_name)
    model_name = controller_name.to_s.sub('Controller', '').underscore.to_sym
    ASSOCIATIONS[model_name] || []
  end

  def self.from(model_name)
    ASSOCIATIONS.select { |k, v| v.include?(model_name) }.keys
  end
end
