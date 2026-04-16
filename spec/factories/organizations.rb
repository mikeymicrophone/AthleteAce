FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    sequence(:abbreviation) { |n| "ORG#{n}" }
    description { "Multi-team organization" }
    url { "https://example.com/organization" }
    logo_url { "https://example.com/logo.png" }
  end
end
