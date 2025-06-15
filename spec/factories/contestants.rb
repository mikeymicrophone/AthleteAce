FactoryBot.define do
  factory :contestant do
    contest { nil }
    campaign { nil }
    placing { 1 }
    wins { 1 }
    losses { 1 }
    tiebreakers { "" }
  end
end
