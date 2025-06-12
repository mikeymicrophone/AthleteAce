FactoryBot.define do
  factory :contest do
    name { "2024 Regular Season" }
    description { "Complete regular season schedule and standings" }
    association :context, factory: :division
    contestant_ids { [1, 2, 3, 4] }
    begin_date { Date.new(2024, 4, 1) }
    end_date { Date.new(2024, 9, 30) }
    association :champion, factory: :team
    comments { ["Season completed successfully", "High attendance throughout"] }
    details { { "total_games" => 162, "attendance" => 2500000 } }

    trait :regular_season do
      name { "2024 Regular Season" }
      description { "Complete regular season schedule and standings" }
      begin_date { Date.new(2024, 4, 1) }
      end_date { Date.new(2024, 9, 30) }
      details { { "total_games" => 162, "attendance" => 2500000, "type" => "regular_season" } }
    end

    trait :playoffs do
      name { "2024 Division Championship" }
      description { "Best-of-seven series to determine division champion" }
      begin_date { Date.new(2024, 10, 1) }
      end_date { Date.new(2024, 10, 15) }
      details { { 
        "format" => "best_of_seven", 
        "rounds" => ["Division Series", "Championship Series"],
        "bracket" => { "semifinals" => [1, 4, 2, 3], "finals" => [1, 2] }
      } }
    end

    trait :championship_series do
      name { "2024 World Series" }
      description { "Championship series between league winners" }
      association :context, factory: :league
      begin_date { Date.new(2024, 10, 20) }
      end_date { Date.new(2024, 10, 28) }
      details { { 
        "format" => "best_of_seven",
        "home_field_advantage" => "american_league",
        "tv_ratings" => 15.2
      } }
    end

    trait :season_series do
      name { "Yankees vs Red Sox 2024" }
      description { "Head-to-head season series between division rivals" }
      contestant_ids { [1, 2] }
      begin_date { Date.new(2024, 4, 15) }
      end_date { Date.new(2024, 9, 15) }
      details { { 
        "total_games" => 19,
        "home_games" => { "1" => 10, "2" => 9 },
        "series_record" => { "1" => 11, "2" => 8 }
      } }
    end

    trait :conference_championship do
      name { "AFC Championship" }
      description { "Conference championship game" }
      association :context, factory: :conference
      contestant_ids { [1, 2] }
      begin_date { Date.new(2024, 1, 21) }
      end_date { Date.new(2024, 1, 21) }
      details { { 
        "format" => "single_elimination",
        "location" => "higher_seed_home",
        "weather" => "cold"
      } }
    end
  end
end
