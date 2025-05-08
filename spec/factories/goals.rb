FactoryBot.define do
  factory :goal do
    association :ace
    association :quest
    status { "not_started" }
    progress { 0 }
    
    trait :completed do
      status { "completed" }
      progress { 100 }
    end
    
    trait :in_progress do
      status { "in_progress" }
      
      transient do
        completion_percentage { 50 }
      end
      
      after(:create) do |goal, evaluator|
        goal.update(progress: evaluator.completion_percentage)
      end
    end
  end
end
