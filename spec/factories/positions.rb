FactoryBot.define do
  factory :position do
    sequence(:name) { |n| "Position #{n}" }
    association :sport
    
    trait :with_players do
      transient do
        players_count { 3 }
      end
      
      after(:create) do |position, evaluator|
        players = create_list(:player, evaluator.players_count)
        players.each do |player|
          player.positions << position
        end
      end
    end
  end
end
