require "rails_helper"

RSpec.describe Season, type: :model do
  it "uses explicit split-year labels while retaining the starting-year anchor" do
    year = create :year, number: 2024
    leagues = [create(:nba), create(:nhl), create(:league, sport: create(:soccer), name: "English Premier League")]

    leagues.each do |league|
      season = described_class.create! year: year, league: league, label: "2024-25"
      expect(season.reload.name).to eq("2024-25 #{league.name}")
      expect(season.year.number).to eq(2024)
    end
  end

  it "keeps the existing year-based name when a season has no label" do
    season = build :season, year: build(:year, number: 2024), label: nil
    expect(season.name).to eq("2024 #{season.league.name}")
  end
end
