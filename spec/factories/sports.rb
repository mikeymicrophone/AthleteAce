FactoryBot.define do
  factory :sport do
    sequence(:name) { |n| "Sport #{n}" }
    
    trait :with_positions do
      transient do
        positions_count { 3 }
      end
      
      after(:create) do |sport, evaluator|
        create_list(:position, evaluator.positions_count, sport: sport)
      end
    end
    
    trait :with_teams do
      transient do
        teams_count { 4 }
      end
      
      after(:create) do |sport, evaluator|
        create_list(:team, evaluator.teams_count, sport: sport)
      end
    end
    
    factory :basketball do
      name { "Basketball" }
    end
    
    factory :baseball do
      name { "Baseball" }
    end
    
    factory :football do
      name { "Football" }
    end
    
    factory :hockey do
      name { "Hockey" }
    end
    
    factory :soccer do
      name { "Soccer" }
    end
  end
end
