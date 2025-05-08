FactoryBot.define do
  factory :achievement do
    sequence(:name) { |n| "Achievement #{n}" }
    description { "Test achievement description" }
    
    # Create a simple target for the polymorphic association
    after(:build) do |achievement|
      # If no target is set, create a minimal sport as the target
      if achievement.target.nil?
        # Create a sport directly without using the factory to avoid circular dependencies
        sport = Sport.create!(name: "Test Sport #{rand(1000)}")
        achievement.target = sport
      end
    end
    
    # Define traits for different target types
    trait :for_player do
      after(:build) do |achievement|
        # Create a sport first
        sport = Sport.create!(name: "Test Sport #{rand(1000)}")
        # Create a team with that sport
        team = Team.create!(name: "Test Team #{rand(1000)}", sport: sport)
        # Create a player with that team
        player = Player.create!(first_name: "Player", last_name: "#{rand(1000)}", team: team)
        achievement.target = player
      end
    end
    
    trait :for_team do
      after(:build) do |achievement|
        # Create a sport first
        sport = Sport.create!(name: "Test Sport #{rand(1000)}")
        # Create a team with that sport
        team = Team.create!(name: "Test Team #{rand(1000)}", sport: sport)
        achievement.target = team
      end
    end
    
    trait :for_sport do
      after(:build) do |achievement|
        sport = Sport.create!(name: "Test Sport #{rand(1000)}")
        achievement.target = sport
      end
    end
  end
end
