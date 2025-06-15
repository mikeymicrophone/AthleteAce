# UGC Preservation During Core Model Reseeding

## Overview

This document outlines a strategy for preserving User-Generated Content (UGC) while reseeding core sports hierarchy models. This allows fixing data quality issues (like teams in wrong leagues) without losing valuable development data.

## Problem Statement

- **Core models need reseeding**: Teams assigned to wrong leagues, architectural changes
- **UGC is valuable**: User accounts, ratings, quests, achievements created during development
- **Foreign keys will shift**: Core model IDs will change during reseed
- **Most FK changes are acceptable**: If a rating points to a different team post-reseed, that's usually fine
- **Some data is more sensitive**: Game attempts may need special handling

## Data Categories

### Category 1: Aces and Ratings
**Models**: `Ace`, `Rating`, `Spectrum`
- **Criticality**: High - user accounts and their ratings are core UGC
- **FK Stability**: High - Spectrums are stable, polymorphic target changes usually acceptable
- **Strategy**: Full preservation with smart FK mapping

### Category 2: Quest System
**Models**: `Quest`, `Achievement`, `Highlight`, `Goal`
- **Criticality**: High - represents user engagement and progress
- **FK Stability**: Medium - polymorphic achievement targets may shift
- **Strategy**: Preserve with flexible target remapping

### Category 3: Game Attempts
**Models**: `GameAttempt`
- **Criticality**: Low - currently only used for basic display logic
- **FK Stability**: Low - subject, target, chosen entities will all shift
- **Strategy**: Optional preservation, could be reset entirely

## Implementation Strategy

### Phase 1: Backup UGC Data

```ruby
# Rake task: rails ugc:backup
namespace :ugc do
  desc "Backup UGC data before core model reseed"
  task backup: :environment do
    backup_timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_dir = Rails.root.join("tmp", "ugc_backup_#{backup_timestamp}")
    FileUtils.mkdir_p(backup_dir)
    
    UgcBackupService.new(backup_dir).backup_all
    puts "UGC backup completed to: #{backup_dir}"
  end
end
```

### Phase 2: Core Model Reset

```ruby
# Rake task: rails ugc:reset_core_models
namespace :ugc do
  desc "Reset core sports hierarchy models"
  task reset_core_models: :environment do
    UgcResetService.new.reset_core_models
    puts "Core models reset completed"
  end
end
```

### Phase 3: Restore UGC Data

```ruby
# Rake task: rails ugc:restore[backup_timestamp]
namespace :ugc do
  desc "Restore UGC data after core model reseed"
  task :restore, [:backup_timestamp] => :environment do |t, args|
    backup_dir = Rails.root.join("tmp", "ugc_backup_#{args[:backup_timestamp]}")
    UgcRestoreService.new(backup_dir).restore_all
    puts "UGC restore completed from: #{backup_dir}"
  end
end
```

## YAML Export Format

### Category 1: Aces and Ratings

```yaml
# aces_and_ratings.yml
aces:
  - id: 1
    email: "user@example.com"
    created_at: "2024-01-15T10:30:00Z"
    # ... other ace attributes

spectrums:
  - id: 1
    name: "Skill"
    min_value: -10000
    max_value: 10000
    # ... other spectrum attributes

ratings:
  - id: 1
    ace_id: 1
    spectrum_id: 1
    target_type: "Player"
    target_id: 123
    target_identifier: "Aaron Judge"  # For remapping
    value: 8500
    created_at: "2024-01-15T11:00:00Z"
    # ... other rating attributes
```

### Category 2: Quest System

```yaml
# quest_system.yml
quests:
  - id: 1
    name: "NFC North Teams"
    description: "Learn all NFC North team players"
    created_at: "2024-01-10T09:00:00Z"

achievements:
  - id: 1
    name: "Team Expert"
    target_type: "Team"
    target_id: 456
    target_identifier: "Green Bay Packers"  # For remapping
    description: "Know all players on this team"

highlights:
  - id: 1
    quest_id: 1
    achievement_id: 1
    required: true
    position: 1

goals:
  - id: 1
    ace_id: 1
    quest_id: 1
    status: "in_progress"
    progress: 65
    started_at: "2024-01-15T12:00:00Z"
```

### Category 3: Game Attempts

```yaml
# game_attempts.yml
game_attempts:
  - id: 1
    ace_id: 1
    subject_entity_type: "Player"
    subject_entity_id: 789
    subject_identifier: "Tom Brady"  # For potential remapping
    target_entity_type: "Team"
    target_entity_id: 101
    target_identifier: "Tampa Bay Buccaneers"
    chosen_entity_type: "Team"
    chosen_entity_id: 101
    chosen_identifier: "Tampa Bay Buccaneers"
    correct: true
    game_type: "team_match"
    created_at: "2024-01-15T14:30:00Z"
```

## Smart Foreign Key Remapping

### Identifier-Based Remapping

For each polymorphic relationship, store both the original FK and a human-readable identifier:

```ruby
class UgcBackupService
  def export_ratings
    Rating.includes(:target).map do |rating|
      {
        id: rating.id,
        ace_id: rating.ace_id,
        spectrum_id: rating.spectrum_id,
        target_type: rating.target_type,
        target_id: rating.target_id,
        target_identifier: build_identifier(rating.target),
        value: rating.value,
        # ... other attributes
      }
    end
  end

  private

  def build_identifier(target)
    case target
    when Player
      "#{target.first_name} #{target.last_name}"
    when Team
      target.name
    when League
      target.name
    else
      target.to_s
    end
  end
end
```

### Restoration with Fallback Strategy

```ruby
class UgcRestoreService
  def restore_ratings(ratings_data)
    ratings_data.each do |rating_attrs|
      # Try to find new target by identifier
      new_target = find_target_by_identifier(
        rating_attrs[:target_type], 
        rating_attrs[:target_identifier]
      )
      
      if new_target
        # Create rating with new target
        Rating.create!(
          ace_id: rating_attrs[:ace_id],
          spectrum_id: rating_attrs[:spectrum_id],
          target: new_target,
          value: rating_attrs[:value],
          # ... other attributes
        )
      else
        # Log unmappable rating for manual review
        Rails.logger.warn "Could not remap rating for #{rating_attrs[:target_type]} '#{rating_attrs[:target_identifier]}'"
      end
    end
  end

  private

  def find_target_by_identifier(target_type, identifier)
    case target_type
    when "Player"
      first_name, last_name = identifier.split(" ", 2)
      Player.find_by(first_name: first_name, last_name: last_name)
    when "Team"
      Team.find_by(name: identifier) || Team.find_by(mascot: identifier.split.last)
    when "League"
      League.find_by(name: identifier)
    else
      nil
    end
  end
end
```

## Service Classes

### UgcBackupService

```ruby
class UgcBackupService
  def initialize(backup_dir)
    @backup_dir = backup_dir
  end

  def backup_all
    backup_aces_and_ratings
    backup_quest_system
    backup_game_attempts
  end

  private

  def backup_aces_and_ratings
    data = {
      aces: export_aces,
      spectrums: export_spectrums,
      ratings: export_ratings
    }
    write_yaml_file("aces_and_ratings.yml", data)
  end

  def backup_quest_system
    data = {
      quests: export_quests,
      achievements: export_achievements,
      highlights: export_highlights,
      goals: export_goals
    }
    write_yaml_file("quest_system.yml", data)
  end

  def backup_game_attempts
    data = {
      game_attempts: export_game_attempts
    }
    write_yaml_file("game_attempts.yml", data)
  end

  def write_yaml_file(filename, data)
    File.write(@backup_dir.join(filename), data.to_yaml)
  end
end
```

### UgcResetService

```ruby
class UgcResetService
  CORE_MODELS = [
    Country, State, City, Stadium,
    Sport, League, Conference, Division, Team, Player,
    Membership, Position, Role,
    Year, Season, Campaign, Contest, Contestant,
    Contract, Activation
  ].freeze

  def reset_core_models
    ActiveRecord::Base.transaction do
      # Clear core model data (preserving UGC)
      CORE_MODELS.reverse.each do |model|
        model.delete_all
      end
      
      # Reset auto-increment sequences
      reset_sequences
      
      # Run standard seeding
      Rails.application.load_seed
    end
  end

  private

  def reset_sequences
    CORE_MODELS.each do |model|
      ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
    end
  end
end
```

### UgcRestoreService

```ruby
class UgcRestoreService
  def initialize(backup_dir)
    @backup_dir = backup_dir
  end

  def restore_all
    restore_aces_and_ratings
    restore_quest_system
    restore_game_attempts  # Optional
  end

  private

  def restore_aces_and_ratings
    data = load_yaml_file("aces_and_ratings.yml")
    
    # Aces and Spectrums should restore cleanly (no core model FKs)
    restore_aces(data[:aces])
    restore_spectrums(data[:spectrums])
    
    # Ratings need smart FK remapping
    restore_ratings(data[:ratings])
  end

  def load_yaml_file(filename)
    YAML.load_file(@backup_dir.join(filename))
  end
end
```

## Usage Workflow

### Complete Reseed with UGC Preservation

```bash
# 1. Backup current UGC data
rails ugc:backup

# 2. Reset core models and reseed
rails ugc:reset_core_models

# 3. Restore UGC data (use timestamp from step 1)
rails ugc:restore[20241215_143022]
```

### Verification Steps

```bash
# Check restoration success
rails console
> Ace.count  # Should match pre-reseed count
> Rating.count  # Should be close to pre-reseed count
> Quest.count  # Should match pre-reseed count

# Check for unmapped entities
rails logs:tail  # Look for remapping warnings
```

## Edge Cases and Considerations

### 1. Duplicate Identifiers
- **Problem**: Multiple players with same name
- **Solution**: Include additional identifiers (team, birth year)

### 2. Missing Entities
- **Problem**: Player exists in backup but not in new seed data
- **Solution**: Log warnings, create manual review list

### 3. Spectrum Changes
- **Problem**: Rating spectrums modified between backup/restore
- **Solution**: Preserve spectrum definitions in backup

### 4. Polymorphic Target Type Changes
- **Problem**: Achievement target changes from Team to Division
- **Solution**: Configurable target type mapping rules

## Future Enhancements

1. **Incremental Backups**: Only backup changed UGC data
2. **Selective Restoration**: Choose which categories to restore
3. **Mapping Reports**: Generate detailed reports on FK remapping success
4. **Dry Run Mode**: Test restoration without making changes
5. **Web Interface**: Admin panel for managing UGC preservation

## Files to Create

1. `lib/tasks/ugc.rake` - Rake tasks
2. `app/services/ugc_backup_service.rb` - Backup logic
3. `app/services/ugc_reset_service.rb` - Core model reset
4. `app/services/ugc_restore_service.rb` - Restoration logic
5. `tmp/ugc_backup_*/*.yml` - Backup data files (git-ignored)

This strategy provides a robust, repeatable process for maintaining UGC while fixing core data issues, with clear separation of concerns and comprehensive error handling.