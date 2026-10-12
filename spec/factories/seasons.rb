FactoryBot.define do
  factory :season do
    association :year
    association :league
    comments { ["A season"] }
  end
end
