class SeedQuests
  include SeedHelpers
  
  def self.run(glob_patterns)
    SeedHelpers.log_and_puts "\n----- Seeding Quests and Achievements -----"
    
    # Check if we have quest patterns
    if glob_patterns && !glob_patterns.empty?
      glob_patterns.each do |pattern|
        SeedHelpers.load_json_files(pattern).each do |file_data|
          SeedHelpers.log_and_puts "Loading quests from #{SeedHelpers.relative_path(file_data[:path])}"
          
          # Handle both array format and object format
          quests_data = file_data[:data].is_a?(Array) ? file_data[:data] : file_data[:data]['quests']
          
          quests_data.each do |quest_data|
            SeedHelpers.find_or_create_with_changes(
              Quest,
              { name: quest_data['name'] },
              quest_data.except('name')
            )
          end
        end
      end
    end
    
    # Check if we have achievement patterns - for now, skip this section
    # since we're now receiving a simple array instead of a hash
    if false # glob_patterns[:achievements]
      # glob_patterns[:achievements].each do |pattern|
        SeedHelpers.load_json_files(pattern).each do |file_data|
          SeedHelpers.log_and_puts "Loading achievements from #{SeedHelpers.relative_path(file_data[:path])}"
          
          # Handle both array format and object format
          achievements_data = file_data[:data].is_a?(Array) ? file_data[:data] : file_data[:data]['achievements']
          
          achievements_data.each do |achievement_data|
            # Find associated quest if specified
            quest = nil
            if achievement_data['quest_name']
              quest = Quest.find_by(name: achievement_data['quest_name'])
              if quest.nil?
                SeedHelpers.log_and_puts "Warning: Quest not found: #{achievement_data['quest_name']}"
              end
            end
            
            attributes = achievement_data.except('quest_name')
            attributes['quest'] = quest if quest
            
            SeedHelpers.find_or_create_with_changes(
              Achievement,
              { name: achievement_data['name'] },
              attributes.except('name')
            )
          end
        end
      end
    end
    
    SeedHelpers.log_and_puts "Quests and Achievements seeding complete: #{Quest.count} quests, #{Achievement.count} achievements"
  end
end