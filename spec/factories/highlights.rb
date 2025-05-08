FactoryBot.define do
  factory :highlight do
    association :quest
    association :achievement
    position { 1 }
    required { true }
    
    trait :optional do
      required { false }
    end
    
    trait :with_specific_position do
      transient do
        specific_position { 1 }
      end
      
      after(:build) do |highlight, evaluator|
        highlight.position = evaluator.specific_position
      end
    end
  end
end
