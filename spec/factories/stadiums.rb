FactoryBot.define do
  factory :stadium do
    sequence(:name) { |n| "Stadium #{n}" }
    sequence(:capacity) { |n| 20000 + (n * 1000) }
    association :city
    
    # Add optional attributes that might be useful in tests
    opened_year { rand(1950..2020) }
    address { "123 Stadium Way" }
    
    trait :with_teams do
      transient do
        teams_count { 1 }
      end
      
      after(:create) do |stadium, evaluator|
        create_list(:team, evaluator.teams_count, stadium: stadium)
      end
    end
    
    trait :large do
      capacity { 60000 + rand(20000) }
    end
    
    trait :small do
      capacity { 10000 + rand(10000) }
    end
  end
end
