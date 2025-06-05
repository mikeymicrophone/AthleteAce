FactoryBot.define do
  factory :league do
    sequence(:name) { |n| "League #{n}" }
    sequence(:abbreviation) { |n| "L#{n}" }
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
      abbreviation { "MLB" }
      association :sport, factory: :baseball
    end
    
    factory :nba do
      name { "National Basketball Association" }
      abbreviation { "NBA" }
      association :sport, factory: :basketball
    end
    
    factory :nfl do
      name { "National Football League" }
      abbreviation { "NFL" }
      association :sport, factory: :football
    end
    
    factory :nhl do
      name { "National Hockey League" }
      abbreviation { "NHL" }
      association :sport, factory: :hockey
    end
    
    factory :mls do
      name { "Major League Soccer" }
      abbreviation { "MLS" }
      association :sport, factory: :soccer
    end
  end
end
