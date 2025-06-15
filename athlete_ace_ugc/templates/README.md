# AthleteAce UGC Preservation Templates

This directory contains templates for implementing the UGC (User-Generated Content) preservation system during core model reseeding.

## Overview

When core sports data needs to be reseeded (due to team reassignments, league changes, etc.), this system preserves valuable user-generated content like user accounts, ratings, quests, and achievements while allowing the underlying sports hierarchy to be completely rebuilt.

## Template Files

### Data Export Templates

- **`aces_and_ratings.yml`** - Template for user accounts and rating data
- **`quest_system.yml`** - Template for quest/achievement system with nested relationships  
- **`game_attempts.yml`** - Template for game interaction data
- **`backup_metadata.yml`** - Metadata about backup process and data integrity
- **`restoration_report.yml`** - Report generated after UGC restoration

### Service Class Templates

- **`ugc_backup_service.rb`** - Service for exporting UGC data with smart identifiers
- **`ugc_restore_service.rb`** - Service for importing UGC data with FK remapping
- **`ugc_reset_service.rb`** - Service for safely clearing core models
- **`ugc_rake_tasks.rake`** - Rake tasks for the complete workflow

## Key Design Principles

### 1. Identifier-Based Foreign Key Remapping

Instead of relying on fragile database IDs, the system uses human-readable identifiers:

```yaml
# Example: Rating with multiple context identifiers
- id: 1
  target_type: "Player"
  target_id: 123
  target_identifier: "Aaron Judge"           # Primary identifier
  target_team_identifier: "Yankees"          # Context for disambiguation
  target_sport_identifier: "Baseball"        # Additional context
  value: 8500
```

### 2. Nested Relationship Preservation

The quest system uses nested YAML structure to preserve internal relationships:

```yaml
quests:
  - id: 1
    name: "NFC North Teams"
    achievements:           # Nested within quest
      - id: 1
        name: "Packers Expert"
        target_identifier: "Green Bay Packers"
    highlights:             # References nested achievements
      - achievement_id: 1   # Internal reference
        required: true
```

### 3. Three-Tier Data Classification

- **Category 1**: Aces and Ratings (highest priority, most stable)
- **Category 2**: Quest System (high priority, moderate FK complexity)  
- **Category 3**: Game Attempts (low priority, complex polymorphic FKs)

## Implementation Steps

### 1. Copy Templates to Application

```bash
# Copy service classes
cp athlete_ace_ugc/templates/ugc_*_service.rb app/services/

# Copy rake tasks  
cp athlete_ace_ugc/templates/ugc_rake_tasks.rake lib/tasks/

# Create backup directory
mkdir -p athlete_ace_ugc/backups
```

### 2. Customize for Your Data

- Update `CORE_MODELS` and `UGC_MODELS` lists in `ugc_reset_service.rb`
- Adjust identifier building logic in `ugc_backup_service.rb`
- Modify remapping logic in `ugc_restore_service.rb` for your specific models

### 3. Test the Workflow

```bash
# Validate setup
rails ugc:validate

# Preview what would be reset
rails ugc:preview_reset

# Run complete workflow
rails ugc:full_reseed
```

## Workflow Commands

### Manual Step-by-Step

```bash
# 1. Backup UGC data
rails ugc:backup

# 2. Reset core models and reseed
rails ugc:reset_core_models  

# 3. Restore UGC data
rails ugc:restore[20241215_143022]
```

### Automated Workflow

```bash
# Complete workflow with prompts
rails ugc:full_reseed
```

### Utility Commands

```bash
# List available backups
rails ugc:list_backups

# Get backup details
rails ugc:backup_info[20241215_143022]

# Clean up old backups
rails ugc:cleanup_backups

# Validate dependencies
rails ugc:validate
```

## Identifier Remapping Strategies

### Player Identification

```ruby
# Primary: Name matching
"Aaron Judge" -> Player.find_by(first_name: "Aaron", last_name: "Judge")

# With context: Team-scoped search
Player.joins(:team).where(
  first_name: "Aaron", 
  last_name: "Judge",
  teams: { name: "New York Yankees" }
)
```

### Team Identification

```ruby
# Primary: Full name
"New York Yankees" -> Team.find_by(name: "New York Yankees")

# Fallback: Mascot only
"Yankees" -> Team.find_by(mascot: "Yankees")

# With sport context
Team.joins(league: :sport).where(
  name: "New York Yankees",
  sports: { name: "Baseball" }
)
```

## Error Handling and Recovery

### Graceful Degradation

- Failed remappings are logged but don't crash the process
- Detailed restoration reports show what couldn't be mapped
- Manual review lists help identify systematic issues

### Common Failure Scenarios

1. **Team Relocations**: "Oakland Raiders" → "Las Vegas Raiders"
2. **League Reorganizations**: "NFC Central" → "NFC North"  
3. **Player Retirements**: Players no longer in seed data
4. **Name Conflicts**: Multiple players with same name

### Recovery Strategies

1. **Update identifier mapping rules** based on failure patterns
2. **Add additional context identifiers** for disambiguation
3. **Manual data correction** for systematic mismatches
4. **Selective restoration** of specific data categories

## File Structure After Implementation

```
athlete_ace_ugc/
├── backups/
│   ├── backup_20241215_143022/
│   │   ├── aces_and_ratings.yml
│   │   ├── quest_system.yml
│   │   ├── game_attempts.yml
│   │   ├── backup_metadata.yml
│   │   └── restoration_report.yml
│   └── backup_20241216_091234/
│       └── ...
└── templates/
    └── ... (this directory)

app/services/
├── ugc_backup_service.rb
├── ugc_restore_service.rb
└── ugc_reset_service.rb

lib/tasks/
└── ugc_rake_tasks.rake

tmp/
├── core_model_reset_20241215_152345.yml
└── ... (reset reports)
```

## Customization Points

### Model Classification

Update the model lists in `ugc_reset_service.rb`:

```ruby
CORE_MODELS = [
  # Add/remove models based on what you consider "core data"
  Country, State, City, Team, Player, # ...
]

UGC_MODELS = [
  # Add/remove models based on what you consider "user content"  
  Ace, Rating, Quest, Achievement, # ...
]
```

### Identifier Building

Customize identifier logic in `ugc_backup_service.rb`:

```ruby
def build_target_identifier(target)
  case target
  when CustomModel
    "#{target.custom_field} - #{target.other_field}"
  # ... existing cases
  end
end
```

### Remapping Rules

Add custom remapping logic in `ugc_restore_service.rb`:

```ruby
def find_target_by_identifiers(target_type, identifier, ...)
  case target_type
  when "CustomModel"
    find_custom_model_by_identifier(identifier, ...)
  # ... existing cases
  end
end
```

## Testing and Validation

### Pre-Implementation Testing

1. **Run validation**: `rails ugc:validate`
2. **Check model dependencies**: Review warnings about FK relationships
3. **Test with small dataset**: Create minimal test data and run workflow

### Post-Implementation Testing

1. **Verify core functionality**: Login, view ratings, access quests
2. **Check data integrity**: Run Rails console queries to verify relationships
3. **Test edge cases**: Ratings for non-existent teams, incomplete quests
4. **Performance testing**: Measure backup/restore times with full dataset

### Monitoring and Maintenance

1. **Review restoration reports** after each reseed
2. **Update identifier mapping rules** based on failure patterns  
3. **Archive successful backups** for disaster recovery
4. **Monitor backup storage usage** and clean up old backups

This template system provides a robust foundation for maintaining UGC during major data reorganizations while being flexible enough to adapt to specific application needs.