FactoryBot.define do
  factory :quest do
    sequence(:name) { |n| "Test Quest #{n}" }
    description { "This is a test quest description" }
    
    # Define a trait for quests with achievements
    trait :with_achievements do
      transient do
        achievements_count { 3 }
        required_count { 2 }
      end
      
      after(:create) do |quest, evaluator|
        achievements = create_list(:achievement, evaluator.achievements_count)
        
        # Add some as required achievements
        achievements.take(evaluator.required_count).each_with_index do |achievement, index|
          quest.add_achievement(achievement, position: index + 1, required: true)
        end
        
        # Add the rest as optional achievements
        achievements.drop(evaluator.required_count).each_with_index do |achievement, index|
          quest.add_achievement(achievement, position: index + evaluator.required_count + 1, required: false)
        end
      end
    end
    
    # Define a trait for quests with participants
    trait :with_participants do
      transient do
        participants_count { 2 }
      end
      
      after(:create) do |quest, evaluator|
        create_list(:ace, evaluator.participants_count).each do |ace|
          ace.adopt_quest(quest)
        end
      end
    end
  end
end
