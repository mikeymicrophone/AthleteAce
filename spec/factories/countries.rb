FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:abbreviation) { |n| "C#{n}" }
    
    trait :with_states do
      transient do
        states_count { 3 }
      end
      
      after(:create) do |country, evaluator|
        create_list(:state, evaluator.states_count, country: country)
      end
    end
    
    factory :usa do
      name { "United States" }
      abbreviation { "US" }
    end
    
    factory :canada do
      name { "Canada" }
      abbreviation { "CA" }
    end
  end
end
