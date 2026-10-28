FactoryBot.define do
  factory :ace do
    sequence(:email) { |n| "ace#{n}@example.com" }
    sequence(:username) { |n| "courtside_#{n}" }
    display_name { "Tess Moreno" }
    password { "password123" }
    password_confirmation { "password123" }
    confirmed_at { Time.current }

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :without_identity do
      username { nil }
      display_name { nil }
      to_create { |ace| ace.save! validate: false }
    end

    trait :admin do
      admin { true }
    end

    trait :with_goals do
      transient do
        goals_count { 3 }
      end

      after(:create) do |ace, evaluator|
        create_list(:goal, evaluator.goals_count, ace: ace)
      end
    end
  end
end
