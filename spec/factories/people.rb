FactoryBot.define do
  factory :person do
    name { Faker::Name.name }
    entity_code { "PERSON-#{SecureRandom.uuid.upcase}" }
  end
end
