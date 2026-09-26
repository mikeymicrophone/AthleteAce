FactoryBot.define do
  factory :year do
    sequence(:number) { |n| 1900 + n }
  end
end
