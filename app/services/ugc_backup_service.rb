# UGC Backup Service Template
# Exports UGC data to YAML files with smart identifiers for FK remapping

class UgcBackupService
  def initialize(backup_dir)
    @backup_dir = backup_dir
    @backup_timestamp = Time.current
  end

  def backup_all
    Rails.logger.info "Starting UGC backup to #{@backup_dir}"
    
    backup_aces_and_ratings
    backup_quest_system
    backup_game_attempts
    write_backup_metadata
    
    Rails.logger.info "UGC backup completed"
  end

  private

  def backup_aces_and_ratings
    Rails.logger.info "Backing up aces and ratings..."
    
    data = {
      aces: export_aces,
      spectrums: export_spectrums,
      ratings: export_ratings
    }
    
    write_yaml_file("aces_and_ratings.yml", data)
    Rails.logger.info "Exported #{data[:aces].size} aces, #{data[:spectrums].size} spectrums, #{data[:ratings].size} ratings"
  end

  def backup_quest_system
    Rails.logger.info "Backing up quest system..."
    
    quests_with_children = export_quests_with_children
    orphaned_achievements = export_orphaned_achievements
    
    data = {
      quests: quests_with_children,
      orphaned_achievements: orphaned_achievements
    }
    
    write_yaml_file("quest_system.yml", data)
    Rails.logger.info "Exported #{data[:quests].size} quests, #{orphaned_achievements.size} orphaned achievements"
  end

  def backup_game_attempts
    Rails.logger.info "Backing up game attempts..."
    
    data = {
      game_attempts: export_game_attempts
    }
    
    write_yaml_file("game_attempts.yml", data)
    Rails.logger.info "Exported #{data[:game_attempts].size} game attempts"
  end

  # === ACES AND RATINGS EXPORT ===

  def export_aces
    Ace.all.map do |ace|
      ace.attributes.merge(
        "exported_at" => @backup_timestamp
      )
    end
  end

  def export_spectrums
    Spectrum.all.map(&:attributes)
  end

  def export_ratings
    Rating.includes(:target).map do |rating|
      rating.attributes.merge(
        "target_identifier" => build_target_identifier(rating.target),
        "target_sport_identifier" => extract_sport_identifier(rating.target),
        "target_league_identifier" => extract_league_identifier(rating.target),
        "target_team_identifier" => extract_team_identifier(rating.target),
        "target_conference_identifier" => extract_conference_identifier(rating.target)
      )
    end
  end

  # === QUEST SYSTEM EXPORT ===

  def export_quests_with_children
    Quest.includes(:achievements, :highlights, :goals).map do |quest|
      quest.attributes.merge(
        "achievements" => quest.achievements.map { |achievement| export_achievement(achievement) },
        "highlights" => quest.highlights.map(&:attributes),
        "goals" => quest.goals.map(&:attributes)
      )
    end
  end

  def export_orphaned_achievements
    # Achievements not associated with any quest via highlights
    achievement_ids_in_quests = Highlight.pluck(:achievement_id).uniq
    orphaned_achievements = Achievement.where.not(id: achievement_ids_in_quests)
    
    orphaned_achievements.includes(:target).map { |achievement| export_achievement(achievement) }
  end

  def export_achievement(achievement)
    achievement.attributes.merge(
      "target_identifier" => build_target_identifier(achievement.target),
      "target_sport_identifier" => extract_sport_identifier(achievement.target),
      "target_league_identifier" => extract_league_identifier(achievement.target),
      "target_team_identifier" => extract_team_identifier(achievement.target),
      "target_conference_identifier" => extract_conference_identifier(achievement.target)
    )
  end

  # === GAME ATTEMPTS EXPORT ===

  def export_game_attempts
    GameAttempt.includes(:subject_entity, :target_entity, :chosen_entity).map do |attempt|
      attempt.attributes.merge(
        # Subject entity identifiers
        "subject_identifier" => build_target_identifier(attempt.subject_entity),
        "subject_sport_identifier" => extract_sport_identifier(attempt.subject_entity),
        "subject_team_identifier" => extract_team_identifier(attempt.subject_entity),
        
        # Target entity identifiers  
        "target_identifier" => build_target_identifier(attempt.target_entity),
        "target_sport_identifier" => extract_sport_identifier(attempt.target_entity),
        "target_league_identifier" => extract_league_identifier(attempt.target_entity),
        "target_team_identifier" => extract_team_identifier(attempt.target_entity),
        "target_conference_identifier" => extract_conference_identifier(attempt.target_entity),
        
        # Chosen entity identifiers
        "chosen_identifier" => build_target_identifier(attempt.chosen_entity),
        "chosen_sport_identifier" => extract_sport_identifier(attempt.chosen_entity),
        "chosen_league_identifier" => extract_league_identifier(attempt.chosen_entity),
        "chosen_team_identifier" => extract_team_identifier(attempt.chosen_entity),
        "chosen_conference_identifier" => extract_conference_identifier(attempt.chosen_entity)
      )
    end
  end

  # === IDENTIFIER BUILDING HELPERS ===

  def build_target_identifier(target)
    return nil unless target
    
    case target
    when Player
      "#{target.first_name} #{target.last_name}"
    when Team
      target.name
    when League
      target.name
    when Division
      target.name
    when Conference
      target.name
    when Sport
      target.name
    when Position
      target.name
    when Stadium
      target.name
    when City
      target.name
    when State
      target.name
    when Country
      target.name
    else
      target.to_s
    end
  end

  def extract_sport_identifier(target)
    return nil unless target
    
    case target
    when Player
      target.team&.league&.sport&.name
    when Team
      target.league&.sport&.name
    when League
      target.sport&.name
    when Division
      target.conference&.league&.sport&.name
    when Conference
      target.league&.sport&.name
    when Sport
      target.name
    when Position
      target.sport&.name
    else
      nil
    end
  end

  def extract_league_identifier(target)
    return nil unless target
    
    case target
    when Player
      target.team&.league&.name
    when Team
      target.league&.name
    when League
      target.name
    when Division
      target.conference&.league&.name
    when Conference
      target.league&.name
    else
      nil
    end
  end

  def extract_team_identifier(target)
    return nil unless target
    
    case target
    when Player
      target.team&.name
    when Team
      target.name
    else
      nil
    end
  end

  def extract_conference_identifier(target)
    return nil unless target
    
    case target
    when Division
      target.conference&.name
    when Conference
      target.name
    else
      nil
    end
  end

  # === FILE OPERATIONS ===

  def write_yaml_file(filename, data)
    file_path = @backup_dir.join(filename)
    File.write(file_path, data.to_yaml)
  end

  def write_backup_metadata
    metadata = {
      backup_timestamp: @backup_timestamp,
      rails_env: Rails.env,
      seed_version: get_current_seed_version,
      total_records: calculate_total_records,
      backup_categories: ["aces_and_ratings", "quest_system", "game_attempts"]
    }
    
    write_yaml_file("backup_metadata.yml", metadata)
  end

  def get_current_seed_version
    # Get the most recent seed version from seeded models
    seeded_models = [Sport, League, Conference, Division, Team, Player, Stadium, Country, State, City]
    seeded_models.map do |model|
      model.seeded.maximum(:seed_version)
    end.compact.max
  end

  def calculate_total_records
    {
      aces: Ace.count,
      spectrums: Spectrum.count,
      ratings: Rating.count,
      quests: Quest.count,
      achievements: Achievement.count,
      highlights: Highlight.count,
      goals: Goal.count,
      game_attempts: GameAttempt.count
    }
  end
end