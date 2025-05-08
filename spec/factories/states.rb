FactoryBot.define do
  factory :state do
    sequence(:name) { |n| "State #{n}" }
    sequence(:abbreviation) { |n| "S#{n}" }
    association :country
    
    trait :with_cities do
      transient do
        cities_count { 3 }
      end
      
      after(:create) do |state, evaluator|
        create_list(:city, evaluator.cities_count, state: state)
      end
    end
  end
end
