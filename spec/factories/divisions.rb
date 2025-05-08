FactoryBot.define do
  factory :division do
    sequence(:name) { |n| "Division #{n}" }
    association :conference
    
    trait :with_teams do
      transient do
        teams_count { 4 }
      end
      
      after(:create) do |division, evaluator|
        create_list(:team, evaluator.teams_count, division: division)
      end
    end
  end
end
