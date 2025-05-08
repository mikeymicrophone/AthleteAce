FactoryBot.define do
  factory :team do
    sequence(:territory) { |n| "City #{n}" }
    sequence(:mascot) { |n| "Mascot #{n}" }
    sequence(:abbreviation) { |n| "TM#{n}" }
    association :league
    # Stadium is optional in the model, so we'll set it to nil by default
    stadium { nil }
    
    trait :with_players do
      transient do
        players_count { 5 }
      end
      
      after(:create) do |team, evaluator|
        create_list(:player, evaluator.players_count, team: team)
      end
    end
    
    trait :with_stadium do
      association :stadium
    end
  end
end
