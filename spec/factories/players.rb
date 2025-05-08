FactoryBot.define do
  factory :player do
    sequence(:first_name) { |n| "Player#{n}" }
    sequence(:last_name) { |n| "Lastname#{n}" }
    association :team
    
    trait :with_positions do
      transient do
        positions_count { 2 }
      end
      
      after(:create) do |player, evaluator|
        positions = create_list(:position, evaluator.positions_count)
        positions.each do |position|
          player.positions << position
        end
      end
    end
    
    trait :with_ratings do
      transient do
        ratings_count { 3 }
      end
      
      after(:create) do |player, evaluator|
        create_list(:rating, evaluator.ratings_count, target: player)
      end
    end
  end
end
