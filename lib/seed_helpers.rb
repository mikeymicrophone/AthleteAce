module SeedHelpers
  # Root directory for all seed JSON data
  SEED_DATA_ROOT = Rails.root.join('db/seeds/athlete_ace_data')
  
  # Initialize seed logging
  def self.init_logging
    @log_file = Rails.root.join('log/seeding.log')
    @log_file.dirname.mkpath unless @log_file.dirname.exist?
    File.open(@log_file, 'a') do |f|
      f.puts "\n===== Seeding started at #{Time.current} ====="
    end
  end
  
  # Log and output message with timestamp
  def self.log_and_puts(message)
    timestamped_message = "[#{Time.current.strftime('%H:%M:%S')}] #{message}"
    puts timestamped_message
    File.open(@log_file, 'a') do |f|
      f.puts timestamped_message
    end
  end
  
  # Find or create record with change detection
  def self.find_or_create_with_changes(model_class, find_attributes, all_attributes = {})
    record = model_class.find_or_initialize_by(find_attributes)
    
    # Merge find_attributes into all_attributes if all_attributes is provided
    attributes_to_assign = all_attributes.any? ? all_attributes : find_attributes
    
    # Track if this is a new record
    is_new = record.new_record?
    
    # Track changes if existing record
    changed_attributes = []
    if !is_new
      attributes_to_assign.each do |key, value|
        current_value = record.send(key)
        if current_value != value
          changed_attributes << "#{key}: #{current_value.inspect} → #{value.inspect}"
        end
      end
    end
    
    # Apply attributes
    record.assign_attributes(attributes_to_assign)
    
    # Save and log if there are changes
    if is_new || record.changed?
      record.save!
      
      if is_new
        log_and_puts "Created #{model_class.name}: #{record_display_name(record)}"
      elsif changed_attributes.any?
        log_and_puts "Updated #{model_class.name}: #{record_display_name(record)} (#{changed_attributes.join(', ')})"
      end
    end
    
    record
  end
  
  # Get display name for a record
  def self.record_display_name(record)
    if record.respond_to?(:name)
      record.name
    elsif record.respond_to?(:title)
      record.title
    elsif record.respond_to?(:first_name) && record.respond_to?(:last_name)
      "#{record.first_name} #{record.last_name}"
    elsif record.respond_to?(:number)
      record.number.to_s
    else
      record.id.to_s
    end
  end
  
  # Load JSON files matching glob pattern
  def self.load_json_files(glob_pattern)
    full_pattern = SEED_DATA_ROOT.join(glob_pattern)
    Dir.glob(full_pattern).filter_map do |file_path|
      begin
        file_content = File.read(file_path)
        
        # Handle multi-team JSON format (multiple JSON objects separated by newlines)
        if file_content.lines.count > 1 && file_content.lines.all? { |line| line.strip.start_with?('{') }
          # Parse each line as a separate JSON object
          file_content.lines.filter_map do |line|
            next if line.strip.empty?
            begin
              {
                path: file_path,
                data: JSON.parse(line.strip),
                multi_team_format: true
              }
            rescue JSON::ParserError => e
              log_and_puts "Warning: Skipping invalid JSON line in #{relative_path(file_path)}: #{e.message}"
              nil
            end
          end
        else
          # Single JSON object format
          {
            path: file_path,
            data: JSON.parse(file_content),
            multi_team_format: false
          }
        end
      rescue JSON::ParserError => e
        log_and_puts "Warning: Skipping invalid JSON file #{relative_path(file_path)}: #{e.message}"
        nil
      end
    end.flatten.compact
  end
  
  # Get relative path from seed data root for logging
  def self.relative_path(file_path)
    Pathname.new(file_path).relative_path_from(SEED_DATA_ROOT)
  end
  
  # Validate required associations exist
  def self.validate_association(model_class, field_name, value)
    case field_name.to_s
    when /country/
      Country.find_by(name: value) || (log_and_puts "Warning: Country not found: #{value}"; nil)
    when /state/
      State.find_by(name: value) || State.find_by(abbreviation: value) || (log_and_puts "Warning: State not found: #{value}"; nil)
    when /city/
      City.find_by(name: value) || (log_and_puts "Warning: City not found: #{value}"; nil)
    when /sport/
      Sport.find_by(name: value) || (log_and_puts "Warning: Sport not found: #{value}"; nil)
    when /league/
      League.find_by(name: value) || (log_and_puts "Warning: League not found: #{value}"; nil)
    when /year/
      Year.find_by(number: value) || (log_and_puts "Warning: Year not found: #{value}"; nil)
    else
      value
    end
  end
  
  # Clean up legacy seed files
  def self.cleanup_legacy_files
    legacy_files = [
      'db/seeds/baseball_positions.rb',
      'db/seeds/basketball_positions.rb', 
      'db/seeds/football_positions.rb',
      'db/seeds/hockey_positions.rb',
      'db/seeds/soccer_positions.rb',
      'db/seeds/leagues.rb',
      'db/seeds/locations.rb',
      'db/seeds/players.rb',
      'db/seeds/spectrums.rb',
      'db/seeds/sports.rb',
      'db/seeds/stadiums.rb',
      'db/seeds/teams.rb'
    ]
    
    legacy_files.each do |file|
      file_path = Rails.root.join(file)
      if file_path.exist?
        log_and_puts "Removing legacy seed file: #{file}"
        file_path.delete
      end
    end
    
    # Also clean up the players subdirectory
    players_dir = Rails.root.join('db/seeds/players')
    if players_dir.exist?
      log_and_puts "Removing legacy players directory"
      players_dir.rmtree
    end
    
    # And teams subdirectory
    teams_dir = Rails.root.join('db/seeds/teams')
    if teams_dir.exist?
      log_and_puts "Removing legacy teams directory"
      teams_dir.rmtree
    end
  end
end