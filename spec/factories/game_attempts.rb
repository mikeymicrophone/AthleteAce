FactoryBot.define do
  factory :game_attempt do
    association :ace
    game_type { "player_team_match" }
    association :subject_entity, factory: :player
    target_entity { subject_entity.team }
    chosen_entity { target_entity }
    options_presented { [] }
    is_correct { true }
    time_elapsed_ms { 1500 }
  end
end
