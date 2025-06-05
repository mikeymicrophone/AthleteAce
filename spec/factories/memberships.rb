FactoryBot.define do
  factory :membership do
    association :team
    association :division
    start_date { 1.year.ago }
    end_date { nil }
    active { true }
    
    trait :inactive do
      active { false }
      end_date { 1.month.ago }
    end
    
    trait :historical do
      start_date { 5.years.ago }
      end_date { 2.years.ago }
      active { false }
    end
  end
end