FactoryBot.define do
  factory :ace do
    sequence(:email) { |n| "ace#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }
    
    trait :unconfirmed do
      confirmed_at { nil }
    end
    
    trait :with_goals do
      transient do
        goals_count { 3 }
      end
      
      after(:create) do |ace, evaluator|
        create_list(:goal, evaluator.goals_count, ace: ace)
      end
    end
  end
end
