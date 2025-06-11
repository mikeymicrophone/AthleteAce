class SeedCampaigns
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Campaigns -----"
    
    # Process any JSON files for campaign notes or league changes (future use)
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading campaign data from #{SeedHelpers.relative_path(file_data[:path])}"
        # TODO: Handle campaign notes and league change data when needed
      end
    end
    
    # Generate campaigns from existing seasons and teams
    generate_campaigns_from_seasons
    
    SeedHelpers.log_and_puts "Campaigns seeding complete: #{Campaign.count} total"
  end
  
  private
  
  def self.generate_campaigns_from_seasons
    SeedHelpers.log_and_puts "Generating campaigns from existing seasons and teams..."
    
    Season.includes(:league).find_each do |season|
      league = season.league
      
      # Get all teams that belong to this league
      teams = Team.where(league: league)
      
      teams.find_each do |team|
        # Create or find campaign for this team in this season
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