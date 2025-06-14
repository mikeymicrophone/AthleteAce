# UGC Restore Service Template
# Imports UGC data from YAML files with intelligent FK remapping

class UgcRestoreService
  def initialize(backup_dir)
    @backup_dir = backup_dir
    @restoration_log = []
    @failed_mappings = []
  end

  def restore_all
    Rails.logger.info "Starting UGC restoration from #{@backup_dir}"
    
    ActiveRecord::Base.transaction do
      restore_aces_and_ratings
      restore_quest_system
      restore_game_attempts
    end
    
    generate_restoration_report
    Rails.logger.info "UGC restoration completed"
  end

  private

  # === ACES AND RATINGS RESTORATION ===

  def restore_aces_and_ratings
    Rails.logger.info "Restoring aces and ratings..."
    data = load_yaml_file("aces_and_ratings.yml")
    
    restore_aces(data[:aces] || data["aces"])
    restore_spectrums(data[:spectrums] || data["spectrums"])
    restore_ratings(data[:ratings] || data["ratings"])
  end

  def restore_aces(aces_data)
    aces_data.each do |ace_attrs|
      # Remove exported_at and other non-model attributes
      clean_attrs = ace_attrs.except("exported_at")
      
      # Skip validations since we're restoring encrypted passwords
      ace = Ace.new(clean_attrs)
      ace.save!(validate: false)
      log_success("Ace", ace_attrs["email"], ace.id)
    end
  end

  def restore_spectrums(spectrums_data)
    spectrums_data.each do |spectrum_attrs|
      # Spectrums should restore cleanly (no core model dependencies)
      spectrum = Spectrum.find_or_create_by(name: spectrum_attrs["name"]) do |s|
        s.assign_attributes(spectrum_attrs.except("id"))
      end
      log_success("Spectrum", spectrum_attrs["name"], spectrum.id)
    end
  end

  def restore_ratings(ratings_data)
    # Build a mapping of old spectrum IDs to current spectrum IDs by name
    spectrum_id_mapping = {}
    
    ratings_data.each do |rating_attrs|
      ace = Ace.find(rating_attrs["ace_id"])
      
      # Get the current spectrum ID for this rating
      old_spectrum_id = rating_attrs["spectrum_id"]
      unless spectrum_id_mapping[old_spectrum_id]
        # Find first available spectrum with similar characteristics, or create a default
        spectrum = Spectrum.first || Spectrum.create!(name: "Default Spectrum", min_value: 0, max_value: 10000)
        spectrum_id_mapping[old_spectrum_id] = spectrum.id
      end
      
      spectrum = Spectrum.find(spectrum_id_mapping[old_spectrum_id])
      
      # Find target using identifier-based mapping
      target = find_target_by_identifiers(
        rating_attrs["target_type"],
        rating_attrs["target_identifier"],
        rating_attrs["target_sport_identifier"],
        rating_attrs["target_league_identifier"],
        rating_attrs["target_team_identifier"],
        rating_attrs["target_conference_identifier"]
      )
      
      if target
        # Check for existing rating first to avoid constraint violation
        existing_rating = Rating.find_by(
          ace: ace,
          spectrum: spectrum,
          target: target,
          archived: false
        )
        
        if existing_rating
          Rails.logger.warn "Skipping duplicate rating: #{rating_attrs['target_type']}:#{rating_attrs['target_identifier']}"
          log_success("Rating (skipped duplicate)", "#{rating_attrs['target_type']}:#{rating_attrs['target_identifier']}", existing_rating.id)
        else
          rating = Rating.create!(
            ace: ace,
            spectrum: spectrum,
            target: target,
            value: rating_attrs["value"],
            archived: rating_attrs["archived"],
            created_at: rating_attrs["created_at"],
            updated_at: rating_attrs["updated_at"]
          )
          log_success("Rating", "#{rating_attrs['target_type']}:#{rating_attrs['target_identifier']}", rating.id)
        end
      else
        log_failure("Rating", rating_attrs["target_type"], rating_attrs["target_identifier"], "Target not found")
      end
    end
  end

  # === QUEST SYSTEM RESTORATION ===

  def restore_quest_system
    Rails.logger.info "Restoring quest system..."
    data = load_yaml_file("quest_system.yml")
    
    restore_quests_with_children(data[:quests] || data["quests"])
    restore_orphaned_achievements(data[:orphaned_achievements] || data["orphaned_achievements"])
  end

  def restore_quests_with_children(quests_data)
    quests_data.each do |quest_data|
      # Create quest first
      quest_attrs = quest_data.except("achievements", "highlights", "goals")
      quest = Quest.create!(quest_attrs.except("id"))
      
      # Create nested achievements with quest reference
      achievement_id_mapping = {}
      quest_data["achievements"].each do |achievement_data|
        old_achievement_id = achievement_data["id"]
        
        target = find_target_by_identifiers(
          achievement_data["target_type"],
          achievement_data["target_identifier"],
          achievement_data["target_sport_identifier"],
          achievement_data["target_league_identifier"],
          achievement_data["target_team_identifier"],
          achievement_data["target_conference_identifier"]
        )
        
        if target
          achievement = Achievement.create!(
            name: achievement_data["name"],
            description: achievement_data["description"],
            target: target,
            details: achievement_data["details"],
            created_at: achievement_data["created_at"],
            updated_at: achievement_data["updated_at"]
          )
          achievement_id_mapping[old_achievement_id] = achievement.id
          log_success("Achievement", achievement_data["name"], achievement.id)
        else
          log_failure("Achievement", achievement_data["target_type"], achievement_data["target_identifier"], "Target not found")
        end
      end
      
      # Create highlights using achievement ID mapping
      quest_data["highlights"].each do |highlight_data|
        old_achievement_id = highlight_data["achievement_id"]
        new_achievement_id = achievement_id_mapping[old_achievement_id]
        
        if new_achievement_id
          Highlight.create!(
            quest: quest,
            achievement_id: new_achievement_id,
            required: highlight_data["required"],
            position: highlight_data["position"],
            created_at: highlight_data["created_at"],
            updated_at: highlight_data["updated_at"]
          )
        end
      end
      
      # Create goals
      quest_data["goals"].each do |goal_data|
        ace = Ace.find(goal_data["ace_id"])
        Goal.create!(
          ace: ace,
          quest: quest,
          status: goal_data["status"],
          progress: goal_data["progress"],
          created_at: goal_data["created_at"],
          updated_at: goal_data["updated_at"]
        )
      end
      
      log_success("Quest", quest_data["name"], quest.id)
    end
  end

  def restore_orphaned_achievements(orphaned_data)
    return unless orphaned_data
    
    orphaned_data.each do |achievement_data|
      target = find_target_by_identifiers(
        achievement_data["target_type"],
        achievement_data["target_identifier"],
        achievement_data["target_sport_identifier"],
        achievement_data["target_league_identifier"],
        achievement_data["target_team_identifier"],
        achievement_data["target_conference_identifier"]
      )
      
      if target
        achievement = Achievement.create!(
          name: achievement_data["name"],
          description: achievement_data["description"],
          target: target,
          details: achievement_data["details"],
          created_at: achievement_data["created_at"],
          updated_at: achievement_data["updated_at"]
        )
        log_success("Orphaned Achievement", achievement_data["name"], achievement.id)
      else
        log_failure("Orphaned Achievement", achievement_data["target_type"], achievement_data["target_identifier"], "Target not found")
      end
    end
  end

  # === GAME ATTEMPTS RESTORATION ===

  def restore_game_attempts
    Rails.logger.info "Restoring game attempts..."
    data = load_yaml_file("game_attempts.yml")
    
    # Game attempts are optional - skip if restoration seems too fragile
    return unless should_restore_game_attempts?
    
    restore_game_attempts_data(data[:game_attempts] || data["game_attempts"])
  end

  def should_restore_game_attempts?
    # Could implement logic to decide whether game attempts are worth restoring
    # For now, default to true but make it configurable
    ENV.fetch("RESTORE_GAME_ATTEMPTS", "true") == "true"
  end

  def restore_game_attempts_data(attempts_data)
    attempts_data.each do |attempt_data|
      ace = Ace.find(attempt_data["ace_id"])
      
      # Find all three entities
      subject_entity = find_target_by_identifiers(
        attempt_data["subject_entity_type"],
        attempt_data["subject_identifier"],
        attempt_data["subject_sport_identifier"],
        nil, # league not needed for subject
        attempt_data["subject_team_identifier"]
      )
      
      target_entity = find_target_by_identifiers(
        attempt_data["target_entity_type"],
        attempt_data["target_identifier"],
        attempt_data["target_sport_identifier"],
        attempt_data["target_league_identifier"],
        attempt_data["target_team_identifier"],
        attempt_data["target_conference_identifier"]
      )
      
      chosen_entity = find_target_by_identifiers(
        attempt_data["chosen_entity_type"],
        attempt_data["chosen_identifier"],
        attempt_data["chosen_sport_identifier"],
        attempt_data["chosen_league_identifier"],
        attempt_data["chosen_team_identifier"],
        attempt_data["chosen_conference_identifier"]
      )
      
      if subject_entity && target_entity && chosen_entity
        game_attempt = GameAttempt.create!(
          ace: ace,
          subject_entity: subject_entity,
          target_entity: target_entity,
          chosen_entity: chosen_entity,
          is_correct: attempt_data["correct"] || attempt_data["is_correct"],
          game_type: attempt_data["game_type"],
          difficulty_level: attempt_data["difficulty"] || attempt_data["difficulty_level"],
          time_elapsed_ms: attempt_data["response_time_ms"] || attempt_data["time_elapsed_ms"],
          options_presented: attempt_data["options_presented"],
          created_at: attempt_data["created_at"],
          updated_at: attempt_data["updated_at"]
        )
        log_success("GameAttempt", attempt_data["game_type"], game_attempt.id)
      else
        missing_entities = []
        missing_entities << "subject" unless subject_entity
        missing_entities << "target" unless target_entity
        missing_entities << "chosen" unless chosen_entity
        
        log_failure("GameAttempt", attempt_data["game_type"], attempt_data["id"], "Missing entities: #{missing_entities.join(', ')}")
      end
    end
  end

  # === IDENTIFIER-BASED TARGET FINDING ===

  def find_target_by_identifiers(target_type, identifier, sport_id = nil, league_id = nil, team_id = nil, conference_id = nil)
    return nil unless target_type && identifier
    
    case target_type
    when "Player"
      find_player_by_identifier(identifier, sport_id, team_id)
    when "Team"
      find_team_by_identifier(identifier, sport_id, league_id)
    when "League"
      find_league_by_identifier(identifier, sport_id)
    when "Division"
      find_division_by_identifier(identifier, sport_id, league_id, conference_id)
    when "Conference"
      find_conference_by_identifier(identifier, sport_id, league_id)
    when "Sport"
      Sport.find_by(name: identifier)
    when "Position"
      find_position_by_identifier(identifier, sport_id)
    when "Stadium"
      Stadium.find_by(name: identifier)
    when "City"
      City.find_by(name: identifier)
    when "State"
      State.find_by(name: identifier)
    when "Country"
      Country.find_by(name: identifier)
    else
      nil
    end
  end

  def find_player_by_identifier(identifier, sport_identifier = nil, team_identifier = nil)
    first_name, last_name = identifier.split(" ", 2)
    return nil unless first_name && last_name
    
    query = Player.where(first_name: first_name, last_name: last_name)
    
    if sport_identifier
      query = query.joins(team: { league: :sport }).where(sports: { name: sport_identifier })
    end
    
    if team_identifier
      # Use CONCAT for team name since teams have territory + mascot
      query = query.joins(:team).where("CONCAT(teams.territory, ' ', teams.mascot) = ?", team_identifier)
    end
    
    query.first
  end

  def find_team_by_identifier(identifier, sport_identifier = nil, league_identifier = nil)
    # Try full team name match by combining territory + mascot
    query = Team.where("CONCAT(territory, ' ', mascot) = ?", identifier)
    
    # Fall back to mascot-only match if no exact match
    if query.empty?
      mascot = identifier.split.last
      query = Team.where(mascot: mascot)
    end
    
    # Apply sport filter if provided
    if sport_identifier && !query.empty?
      query = query.joins(league: :sport).where(sports: { name: sport_identifier })
    end
    
    # Apply league filter if provided
    if league_identifier && !query.empty?
      query = query.joins(:league).where(leagues: { name: league_identifier })
    end
    
    query.first
  end

  def find_league_by_identifier(identifier, sport_identifier = nil)
    query = League.where(name: identifier)
    
    if sport_identifier
      query = query.joins(:sport).where(sports: { name: sport_identifier })
    end
    
    query.first
  end

  def find_division_by_identifier(identifier, sport_identifier = nil, league_identifier = nil, conference_identifier = nil)
    query = Division.where(name: identifier)
    
    if conference_identifier
      query = query.joins(:conference).where(conferences: { name: conference_identifier })
    end
    
    if league_identifier
      query = query.joins(conference: :league).where(leagues: { name: league_identifier })
    end
    
    if sport_identifier
      query = query.joins(conference: { league: :sport }).where(sports: { name: sport_identifier })
    end
    
    query.first
  end

  def find_conference_by_identifier(identifier, sport_identifier = nil, league_identifier = nil)
    query = Conference.where(name: identifier)
    
    if league_identifier
      query = query.joins(:league).where(leagues: { name: league_identifier })
    end
    
    if sport_identifier
      query = query.joins(league: :sport).where(sports: { name: sport_identifier })
    end
    
    query.first
  end

  def find_position_by_identifier(identifier, sport_identifier = nil)
    query = Position.where(name: identifier)
    
    if sport_identifier
      query = query.joins(:sport).where(sports: { name: sport_identifier })
    end
    
    query.first
  end

  # === UTILITY METHODS ===

  def load_yaml_file(filename)
    file_path = @backup_dir.join(filename)
    YAML.load_file(file_path, permitted_classes: [ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, Time, Date, Symbol], aliases: true)
  end

  def log_success(model_type, identifier, new_id)
    @restoration_log << {
      status: "success",
      model_type: model_type,
      identifier: identifier,
      new_id: new_id
    }
  end

  def log_failure(model_type, target_type, identifier, reason)
    @failed_mappings << {
      model_type: model_type,
      target_type: target_type,
      identifier: identifier,
      reason: reason
    }
  end

  def generate_restoration_report
    report_path = @backup_dir.join("restoration_report.yml")
    
    report = {
      restoration_timestamp: Time.current,
      successful_restorations: @restoration_log.size,
      failed_mappings: @failed_mappings.size,
      success_by_model: @restoration_log.group_by { |entry| entry[:model_type] }.transform_values(&:size),
      failures_by_model: @failed_mappings.group_by { |entry| entry[:model_type] }.transform_values(&:size),
      failed_mappings_detail: @failed_mappings
    }
    
    File.write(report_path, report.to_yaml)
    Rails.logger.info "Restoration report written to #{report_path}"
    
    if @failed_mappings.any?
      Rails.logger.warn "#{@failed_mappings.size} entities could not be remapped. See restoration report for details."
    end
  end
end