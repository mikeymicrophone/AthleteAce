FactoryBot.define do
  factory :spectrum do
    sequence(:name) { |n| "Spectrum #{n}" }
    low_label { "Low" }
    high_label { "High" }
    
    trait :with_ratings do
      transient do
        ratings_count { 5 }
      end
      
      after(:create) do |spectrum, evaluator|
        create_list(:rating, evaluator.ratings_count, spectrum: spectrum)
      end
    end
    
    factory :familiarity do
      name { "Familiarity" }
      low_label { "Unfamiliar" }
      high_label { "Very Familiar" }
    end
    
    factory :skill do
      name { "Skill" }
      low_label { "Unskilled" }
      high_label { "Highly Skilled" }
    end
    
    factory :popularity do
      name { "Popularity" }
      low_label { "Unpopular" }
      high_label { "Very Popular" }
    end
  end
end
