FactoryBot.define do
  factory :staff_tenure do
    person
    organization
    role { "coach" }
    title { "Assistant coach" }
    entity_code { "APPOINTMENT-#{SecureRandom.uuid.upcase}" }
    source { { "title" => "Organization staff directory", "url" => "https://example.com/staff" } }

    trait :broadcaster do
      role { "broadcaster" }
      title { "Color commentator" }
      source { { "title" => "Broadcast team announcement", "url" => "https://example.com/broadcast-team" } }
    end
  end
end
