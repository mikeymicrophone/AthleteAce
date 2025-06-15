# Era represents a time period when a team was part of a specific league
Era = Struct.new(:league, :start_year, :end_year) do
  def active_in_year?(year)
    year >= start_year && (end_year.nil? || year <= end_year)
  end
  
  def to_s
    end_str = end_year.nil? ? "present" : end_year.to_s
    "#{league.name} (#{start_year}-#{end_str})"
  end
end

class SeedCampaigns
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Campaigns -----"
    
    # Decorate teams with era information from expansion and transition files
    decorate_teams_with_eras(glob_patterns)
    
    # Generate campaigns based on era boundaries
    generate_campaigns_with_eras
    
    SeedHelpers.log_and_puts "Campaigns seeding complete: #{Campaign.count} total"
  end
  
  private
  
  def self.decorate_teams_with_eras(glob_patterns)
    SeedHelpers.log_and_puts "Processing team era data from expansion and transition files..."
    
    # Initialize all teams with their current league as an era
    initialize_current_league_eras
    
    # Process expansion and transition files
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        file_path = file_data[:path]
        SeedHelpers.log_and_puts "Loading era data from #{SeedHelpers.relative_path(file_path)}"
        
        if file_path.include?('expansions.json')
          process_expansions(file_data[:data])
        elsif file_path.include?('transitions.json')
          process_transitions(file_data[:data])
        end
      end
    end
  end
  
  def self.initialize_current_league_eras
    Team.includes(:league).find_each do |team|
      # Start with current league era (no end date means current)
      team.instance_variable_set(:@eras, [Era.new(team.league, team.founded_year || 1900, nil)])
    end
  end
  
  def self.process_expansions(expansion_data)
    return unless expansion_data['league_name'] && expansion_data['expansions']
    
    league = League.find_by(name: expansion_data['league_name'])
    unless league
      SeedHelpers.log_and_puts "Warning: League not found: #{expansion_data['league_name']}"
      return
    end
    
    expansion_data['expansions'].each do |expansion|
      team = find_team_by_league_and_name(league, expansion['team_name'])
      next unless team
      
      expansion_year = expansion['year']
      eras = team.instance_variable_get(:@eras) || []
      
      # Update the current league era to start from expansion year
      current_era = eras.find { |era| era.league == league }
      if current_era
        current_era.start_year = expansion_year
      else
        eras << Era.new(league, expansion_year, nil)
      end
      
      team.instance_variable_set(:@eras, eras)
      SeedHelpers.log_and_puts "  #{team.name} expanded into #{league.name} in #{expansion_year}"
    end
  end
  
  def self.process_transitions(transition_data)
    return unless transition_data['transitions']
    
    transition_data['transitions'].each do |transition|
      from_league = League.find_by(name: transition['from_league'])
      to_league = League.find_by(name: transition['to_league'])
      
      unless from_league && to_league
        SeedHelpers.log_and_puts "Warning: League not found for transition: #{transition}"
        next
      end
      
      team = find_team_by_league_and_name(to_league, transition['team_name'])
      next unless team
      
      transition_year = transition['year']
      eras = team.instance_variable_get(:@eras) || []
      
      # End the previous league era
      previous_era = eras.find { |era| era.league == from_league && era.end_year.nil? }
      if previous_era
        previous_era.end_year = transition_year - 1
      else
        # Add the previous league era if it doesn't exist
        start_year = transition['from_year'] || team.founded_year || 1900
        eras << Era.new(from_league, start_year, transition_year - 1)
      end
      
      # Start or update the new league era
      current_era = eras.find { |era| era.league == to_league }
      if current_era
        current_era.start_year = transition_year
      else
        eras << Era.new(to_league, transition_year, nil)
      end
      
      team.instance_variable_set(:@eras, eras)
      SeedHelpers.log_and_puts "  #{team.name} transitioned from #{from_league.name} to #{to_league.name} in #{transition_year}"
    end
  end
  
  def self.find_team_by_league_and_name(league, team_name)
    sport = league.sport
    Team.joins(league: :sport).find_by(
      mascot: team_name,
      sports: { name: sport.name }
    ) || Team.joins(league: :sport).find_by(
      territory: team_name,
      sports: { name: sport.name }
    )
  end
  
  def self.generate_campaigns_with_eras
    SeedHelpers.log_and_puts "Generating campaigns based on team eras..."
    
    Season.includes(:league, :year).find_each do |season|
      season_year = season.year.number
      league = season.league
      
      # Find all teams that were in this league during this season year
      Team.includes(:league).find_each do |team|
        eras = team.instance_variable_get(:@eras) || []
        
        # Check if team was in this league during this season
        active_era = eras.find { |era| era.league == league && era.active_in_year?(season_year) }
        
        if active_era
          # Create campaign for this team in this season
          campaign = SeedHelpers.find_or_create_with_changes(
            Campaign,
            { 
              team: team,
              season: season
            },
            {
              team: team,
              season: season
            }
          )
        end
      end
    end
  end
end