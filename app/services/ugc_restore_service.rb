# UGC Restore Service Template
# Imports UGC data from YAML files with intelligent FK remapping
#
# Safe to run more than once: records that already exist are matched and skipped.

class UgcRestoreService
  def initialize(backup_dir)
    @backup_dir = backup_dir
    @restoration_log = []
    @failed_mappings = []
    @ace_ids = {}      # backup ace id => current ace id, matched by email
    @spectrum_ids = {} # backup spectrum id => current spectrum id, matched by name
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
      ace = Ace.find_by(email: ace_attrs["email"])

      if ace
        log_success("Ace (existing)", ace_attrs["email"], ace.id)
      else
        # Skip validations since we're restoring encrypted passwords
        ace = Ace.new(ace_attrs.except("exported_at", "id").slice(*Ace.column_names))
        ace.save!(validate: false)
        log_success("Ace", ace_attrs["email"], ace.id)
      end

      @ace_ids[ace_attrs["id"]] = ace.id
    end
  end

  def restore_spectrums(spectrums_data)
    spectrums_data.each do |spectrum_attrs|
      spectrum = Spectrum.find_or_create_by!(name: spectrum_attrs["name"]) do |s|
        s.assign_attributes(spectrum_attrs.except("id", "name").slice(*Spectrum.column_names))
      end
      @spectrum_ids[spectrum_attrs["id"]] = spectrum.id
      log_success("Spectrum", spectrum_attrs["name"], spectrum.id)
    end
  end

  def restore_ratings(ratings_data)
    ratings_data.each do |rating_attrs|
      label = "#{rating_attrs['target_type']}:#{rating_attrs['target_identifier']}"
      ace_id = @ace_ids[rating_attrs["ace_id"]]
      spectrum_id = @spectrum_ids[rating_attrs["spectrum_id"]]
      target = find_target_by_identifiers(
        rating_attrs["target_type"],
        rating_attrs["target_identifier"],
        rating_attrs["target_sport_identifier"],
        rating_attrs["target_league_identifier"],
        rating_attrs["target_team_identifier"],
        rating_attrs["target_conference_identifier"]
      )

      missing = { "ace" => ace_id, "spectrum" => spectrum_id, "target" => target }.select { |_, found| found.nil? }.keys
      if missing.any?
        log_failure("Rating", rating_attrs["target_type"], rating_attrs["target_identifier"], "Not found: #{missing.join(', ')}")
        next
      end

      existing = Rating.where(ace_id: ace_id, spectrum_id: spectrum_id, target: target)
      if existing.exists?(created_at: rating_attrs["created_at"])
        log_success("Rating (skipped duplicate)", label, nil)
        next
      end

      # Only one rating per ace, spectrum, and target can be active; keep the one already here
      archived = rating_attrs["archived"] || existing.active.exists?

      rating = Rating.create!(
        ace_id: ace_id,
        spectrum_id: spectrum_id,
        target: target,
        value: rating_attrs["value"],
        notes: rating_attrs["notes"],
        archived: archived,
        created_at: rating_attrs["created_at"],
        updated_at: rating_attrs["updated_at"]
      )
      log_success("Rating", label, rating.id)
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
      quest = Quest.find_by(name: quest_data["name"])
      if quest
        log_success("Quest (existing)", quest_data["name"], quest.id)
      else
        quest_attrs = quest_data.except("id", "creator_id", "achievements", "highlights", "goals").slice(*Quest.column_names)
        quest = Quest.create!(quest_attrs.merge("creator_id" => @ace_ids[quest_data["creator_id"]]))
        log_success("Quest", quest_data["name"], quest.id)
      end

      # Map the backup's achievement ids to current ones for this quest's highlights
      achievement_ids = {}
      quest_data["achievements"].each do |achievement_data|
        achievement = restore_achievement(achievement_data, "Achievement")
        achievement_ids[achievement_data["id"]] = achievement.id if achievement
      end

      quest_data["highlights"].each do |highlight_data|
        achievement_id = achievement_ids[highlight_data["achievement_id"]]
        next unless achievement_id

        Highlight.find_or_create_by!(quest: quest, achievement_id: achievement_id) do |highlight|
          highlight.required = highlight_data["required"]
          highlight.position = highlight_data["position"]
          highlight.created_at = highlight_data["created_at"]
          highlight.updated_at = highlight_data["updated_at"]
        end
      end

      quest_data["goals"].each do |goal_data|
        ace_id = @ace_ids[goal_data["ace_id"]]
        unless ace_id
          log_failure("Goal", "Ace", goal_data["ace_id"], "Ace not in backup")
          next
        end

        Goal.find_or_create_by!(ace_id: ace_id, quest: quest) do |goal|
          goal.status = goal_data["status"]
          goal.progress = goal_data["progress"]
          goal.created_at = goal_data["created_at"]
          goal.updated_at = goal_data["updated_at"]
        end
      end
    end
  end

  def restore_orphaned_achievements(orphaned_data)
    return unless orphaned_data

    orphaned_data.each do |achievement_data|
      restore_achievement(achievement_data, "Orphaned Achievement")
    end
  end

  # Finds or creates the achievement, matching on name and target
  def restore_achievement(achievement_data, log_label)
    target = find_target_by_identifiers(
      achievement_data["target_type"],
      achievement_data["target_identifier"],
      achievement_data["target_sport_identifier"],
      achievement_data["target_league_identifier"],
      achievement_data["target_team_identifier"],
      achievement_data["target_conference_identifier"]
    )

    unless target
      log_failure(log_label, achievement_data["target_type"], achievement_data["target_identifier"], "Target not found")
      return
    end

    achievement = Achievement.find_by(name: achievement_data["name"], target: target)
    if achievement
      log_success("#{log_label} (existing)", achievement_data["name"], achievement.id)
      return achievement
    end

    achievement = Achievement.create!(
      name: achievement_data["name"],
      description: achievement_data["description"],
      target: target,
      details: achievement_data["details"],
      created_at: achievement_data["created_at"],
      updated_at: achievement_data["updated_at"]
    )
    log_success(log_label, achievement_data["name"], achievement.id)
    achievement
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
      ace_id = @ace_ids[attempt_data["ace_id"]]

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

      missing_entities = []
      missing_entities << "ace" unless ace_id
      missing_entities << "subject" unless subject_entity
      missing_entities << "target" unless target_entity
      # A timed-out attempt has no chosen entity; only report one that couldn't be found
      missing_entities << "chosen" if attempt_data["chosen_entity_type"] && chosen_entity.nil?

      if missing_entities.any?
        log_failure("GameAttempt", attempt_data["game_type"], attempt_data["id"], "Missing entities: #{missing_entities.join(', ')}")
        next
      end

      if GameAttempt.exists?(ace_id: ace_id, game_type: attempt_data["game_type"], subject_entity: subject_entity, created_at: attempt_data["created_at"])
        log_success("GameAttempt (skipped duplicate)", attempt_data["game_type"], nil)
        next
      end

      game_attempt = GameAttempt.create!(
        ace_id: ace_id,
        subject_entity: subject_entity,
        target_entity: target_entity,
        chosen_entity: chosen_entity,
        is_correct: attempt_data.key?("is_correct") ? attempt_data["is_correct"] : attempt_data["correct"],
        game_type: attempt_data["game_type"],
        difficulty_level: attempt_data["difficulty"] || attempt_data["difficulty_level"],
        time_elapsed_ms: attempt_data["response_time_ms"] || attempt_data["time_elapsed_ms"],
        options_presented: attempt_data["options_presented"],
        created_at: attempt_data["created_at"],
        updated_at: attempt_data["updated_at"]
      )
      log_success("GameAttempt", attempt_data["game_type"], game_attempt.id)
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
    words = identifier.split(" ")

    # The identifier is "first last", and either part can have spaces, so try each split point
    (1...words.size).each do |split_at|
      query = Player.where(first_name: words[0...split_at].join(" "), last_name: words[split_at..].join(" "))

      if sport_identifier
        query = query.joins(team: { league: :sport }).where(sports: { name: sport_identifier })
      end

      if team_identifier
        # Use CONCAT for team name since teams have territory + mascot
        query = query.joins(:team).where("CONCAT(teams.territory, ' ', teams.mascot) = ?", team_identifier)
      end

      player = query.first
      return player if player
    end

    nil
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