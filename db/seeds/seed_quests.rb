class SeedQuests
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Quests and Achievements -----"
    
    # Track achievements by reference for within-file lookups
    achievements_by_ref = {}
    
    # Check if we have quest patterns
    if glob_patterns && !glob_patterns.empty?
      glob_patterns.each do |pattern|
        SeedHelpers.load_json_files(pattern).each do |file_data|
          SeedHelpers.log_and_puts "Loading achievements and quests from #{SeedHelpers.relative_path(file_data[:path])}"
          
          # First, seed achievements if they exist
          if file_data[:data]['achievements']
            file_data[:data]['achievements'].each do |achievement_data|
              target = find_achievement_target(achievement_data['target_type'], achievement_data['target_name'])
              if target.nil?
                SeedHelpers.log_and_puts "Warning: Target not found: #{achievement_data['target_type']} '#{achievement_data['target_name']}'"
                next
              end
              
              attributes = achievement_data.except('ref', 'target_type', 'target_name').merge('target' => target)
              
              achievement = SeedHelpers.find_or_create_with_changes(
                Achievement,
                { name: achievement_data['name'] },
                attributes
              )
              
              # Store achievement by reference for quest linking
              achievements_by_ref[achievement_data['ref']] = achievement if achievement_data['ref']
            end
          end
          
          # Then, seed quests if they exist
          if file_data[:data]['quests']
            file_data[:data]['quests'].each do |quest_data|
              # Create the quest first
              quest = SeedHelpers.find_or_create_with_changes(
                Quest,
                { name: quest_data['name'] },
                quest_data.except('name', 'achievement_refs')
              )
              
              # Handle achievement references
              if quest_data['achievement_refs']
                # Clear existing highlights for this quest to rebuild them
                quest.highlights.destroy_all
                
                quest_data['achievement_refs'].each do |achievement_ref|
                  ref_code = achievement_ref['ref'] || achievement_ref
                  achievement = achievements_by_ref[ref_code]
                  
                  if achievement.nil?
                    SeedHelpers.log_and_puts "Warning: Achievement reference not found: #{ref_code}"
                    next
                  end
                  
                  # Create highlight with position and required status
                  quest.add_achievement(
                    achievement,
                    position: achievement_ref['position'],
                    required: achievement_ref.fetch('required', true)
                  )
                end
              end
            end
          end
        end
      end
    end
    
    SeedHelpers.log_and_puts "Quests and Achievements seeding complete: #{Quest.count} quests, #{Achievement.count} achievements"
  end
  
  private
  
  def self.find_achievement_target(target_type, target_name)
    case target_type
    when 'Team'
      Team.find_by(mascot: target_name)
    when 'Division'
      Division.find_by(name: target_name)
    when 'Conference'
      Conference.find_by(name: target_name)
    when 'League'
      League.find_by(name: target_name)
    when 'Sport'
      Sport.find_by(name: target_name)
    when 'Player'
      Player.find_by(name: target_name)
    else
      SeedHelpers.log_and_puts "Warning: Unknown target type: #{target_type}"
      nil
    end
  end
end