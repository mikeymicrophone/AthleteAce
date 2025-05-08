FactoryBot.define do
  factory :city do
    sequence(:name) { |n| "City #{n}" }
    association :state
    
    trait :with_stadiums do
      transient do
        stadiums_count { 1 }
      end
      
      after(:create) do |city, evaluator|
        create_list(:stadium, evaluator.stadiums_count, city: city)
      end
    end
  end
end
