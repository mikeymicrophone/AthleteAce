FactoryBot.define do
  factory :organization_affiliation do
    association :organization
    association :team
    start_date { Date.new(2024, 1, 1) }
    end_date { nil }
    details { {} }
  end
end
