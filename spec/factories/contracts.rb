FactoryBot.define do
  factory :contract do
    association :player
    association :organization
    team { nil }
    start_date { "2025-06-13" }
    end_date { "2025-06-13" }
    total_dollar_value { "9.99" }
    details { "" }
    seed_version { "MyString" }
    last_seeded_at { "2025-06-13 12:21:04" }
  end
end
