FactoryBot.define do
  factory :league do
    sequence(:name) { |n| "League #{n}" }
    association :sport
    association :jurisdiction, factory: :country
    
    trait :with_conferences do
      transient do
        conferences_count { 2 }
      end
      
      after(:create) do |league, evaluator|
        create_list(:conference, evaluator.conferences_count, league: league)
      end
    end
    
    factory :mlb do
      name { "Major League Baseball" }
      association :sport, factory: :baseball
    end
    
    factory :nba do
      name { "National Basketball Association" }
      association :sport, factory: :basketball
    end
    
    factory :nfl do
      name { "National Football League" }
      association :sport, factory: :football
    end
    
    factory :nhl do
      name { "National Hockey League" }
      association :sport, factory: :hockey
    end
    
    factory :mls do
      name { "Major League Soccer" }
      association :sport, factory: :soccer
    end
  end
end
