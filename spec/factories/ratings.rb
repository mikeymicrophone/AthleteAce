FactoryBot.define do
  factory :rating do
    value { rand(1..100) }
    association :ace
    association :spectrum
    association :target, factory: :player
    
    trait :with_player_target do
      association :target, factory: :player
    end
    
    trait :with_team_target do
      association :target, factory: :team
    end
    
    trait :with_stadium_target do
      association :target, factory: :stadium
    end
    
    trait :high_rating do
      value { rand(80..100) }
    end
    
    trait :medium_rating do
      value { rand(40..79) }
    end
    
    trait :low_rating do
      value { rand(1..39) }
    end
  end
end
