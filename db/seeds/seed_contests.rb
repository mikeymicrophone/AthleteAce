class SeedContests
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Contests -----"
    
    glob_patterns.each do |pattern|
      SeedHelpers.load_json_files(pattern).each do |file_data|
        SeedHelpers.log_and_puts "Loading contests from #{SeedHelpers.relative_path(file_data[:path])}"
        
        # Find the season if specified in the file
        season = nil
        if file_data[:data]['league_name'] && file_data[:data]['season_year']
          league = League.find_by(name: file_data[:data]['league_name'])
          if league
            year = Year.find_by(number: file_data[:data]['season_year'])
            season = Season.find_by(league: league, year: year) if year
            SeedHelpers.log_and_puts "Found season: #{season.name}" if season
          end
        end
        
        file_data[:data]['contests'].each do |contest_data|
          context = find_context(contest_data['context_type'], contest_data['context_name'])
          if context.nil?
            SeedHelpers.log_and_puts "Warning: Context not found: #{contest_data['context_type']} '#{contest_data['context_name']}'"
            next
          end
          
          # Prepare attributes, excluding context fields since we'll set the polymorphic association
          attributes = contest_data.except('context_type', 'context_name').dup

          # Handle champion_id or champion_name
          if contest_data.key?('champion_id')
            attributes['champion_id'] = numeric_id_or_team_name(contest_data['champion_id'])
          elsif contest_data.key?('champion_name')
            attributes['champion_id'] = team_id_by_name(contest_data['champion_name'])
          end

          # Ensure comments is an array if present
          attributes['comments'] ||= []
          
          # Ensure details is a hash if present  
          attributes['details'] ||= {}
          
          # Determine contestant_ids
          raw_contestants = contest_data['contestant_ids'] || contest_data['contestant_names']
          contestants = if raw_contestants.to_s.downcase == 'all'
                          contestant_ids_for_context(context)
                        else
                          team_ids_from_mixed(raw_contestants)
                        end
          attributes['contestant_ids'] = contestants
          
          SeedHelpers.find_or_create_with_changes(
            Contest,
            { name: contest_data['name'], context: context },
            attributes.merge('context' => context, 'season' => season)
          )
        end
      end
    end
    
    SeedHelpers.log_and_puts "Contests seeding complete: #{Contest.count} total"
  end
  
  private
  
  def self.find_context(context_type, context_name)
    case context_type
    when 'Division'
      Division.find_by(name: context_name)
    when 'Conference'
      Conference.find_by(name: context_name)
    when 'League'
      League.find_by(name: context_name)
    else
      SeedHelpers.log_and_puts "Warning: Unknown context type: #{context_type}"
      nil
    end
  end
  
  # Returns an array of team IDs belonging to the given context.
  def self.contestant_ids_for_context(context)
    case context
    when Division
      context.teams.pluck(:id)
    when Conference
      context.divisions.includes(:teams).flat_map { |d| d.teams.pluck(:id) }.uniq
    when League
      # Prefer direct association if available (e.g., through memberships)
      if context.respond_to?(:teams) && context.teams.exists?
        context.teams.pluck(:id)
      else
        context.conferences.includes(divisions: :teams).flat_map { |conf| conf.divisions.flat_map { |d| d.teams.pluck(:id) } }.uniq
      end
    else
      []
    end
  end
  
  # Convert a value that may be numeric id or team name to numeric id
  def self.numeric_id_or_team_name(value)
    return value if value.is_a?(Integer) || value.to_s.match?(/^\d+$/)
    team_id_by_name(value)
  end
  
  def self.team_id_by_name(name)
    Team.find_by(name: name)&.id
  end
  
  def self.team_ids_from_mixed(values)
    Array(values).map { |v| numeric_id_or_team_name(v) }.compact
  end
end