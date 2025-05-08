FactoryBot.define do
  factory :conference do
    sequence(:name) { |n| "Conference #{n}" }
    association :league
    
    trait :with_divisions do
      transient do
        divisions_count { 2 }
      end
      
      after(:create) do |conference, evaluator|
        create_list(:division, evaluator.divisions_count, conference: conference)
      end
    end
  end
end
