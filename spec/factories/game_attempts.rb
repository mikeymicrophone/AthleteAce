FactoryBot.define do
  factory :game_attempt do
    ace { nil }
    game_type { "MyString" }
    subject_entity { nil }
    target_entity { nil }
    options_presented { "MyText" }
    chosen_entity { nil }
    is_correct { false }
    time_elapsed_ms { 1 }
  end
end
