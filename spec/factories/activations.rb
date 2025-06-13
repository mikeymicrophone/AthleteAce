FactoryBot.define do
  factory :activation do
    contract { nil }
    campaign { nil }
    start_date { "2025-06-13" }
    end_date { "2025-06-13" }
    details { "" }
    seed_version { "MyString" }
    last_seeded_at { "2025-06-13 12:21:56" }
  end
end
