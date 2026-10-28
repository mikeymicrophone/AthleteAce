require "rails_helper"

RSpec.describe Campaign, type: :model do
  it "keeps annual team attributes and league participation after current club details change" do
    sport = create :soccer
    historical_league = create :league, sport: sport, name: "English Premier League", abbreviation: "EPL"
    current_league = create :league, sport: sport, name: "Championship"
    season = create :season, league: historical_league, year: create(:year, number: 2024), label: "2024-25"
    stadium = create :stadium
    conference = create :conference, league: historical_league
    division = create :division, conference: conference
    team = create :team, league: historical_league, stadium: stadium
    campaign = described_class.create! team: team, season: season,
      display_name: "Historical Club", territory: "Historical City", mascot: "Club",
      abbreviation: "HC", logo_url: "https://example.com/2024-club.png",
      primary_color: "#112233", secondary_color: "#445566",
      stadium: stadium, city: stadium.city, conference: conference, division: division,
      details: { "source_season" => "2024-25" }

    team.update! league: current_league, territory: "Current City", mascot: "Current Club",
      abbreviation: "CC", logo_url: "https://example.com/current-club.png",
      primary_color: "#778899", secondary_color: "#AABBCC", stadium: create(:stadium)

    campaign.reload
    expect(campaign).to be_valid
    expect(campaign.name).to eq("Historical Club")
    expect(campaign.attributes.slice("territory", "mascot", "abbreviation", "logo_url", "primary_color", "secondary_color")).to eq(
      "territory" => "Historical City", "mascot" => "Club", "abbreviation" => "HC",
      "logo_url" => "https://example.com/2024-club.png", "primary_color" => "#112233", "secondary_color" => "#445566"
    )
    expect([campaign.stadium, campaign.city, campaign.conference, campaign.division]).to eq([stadium, stadium.city, conference, division])
    expect(campaign.details).to eq("source_season" => "2024-25")
    expect(campaign.league).to eq(historical_league)
    expect(historical_league.campaigns).to include(campaign)
    expect(current_league.campaigns).not_to include(campaign)
  end

  it "uses annual territory and mascot when no explicit display name was supplied" do
    campaign = described_class.new territory: "Historical City", mascot: "Historical Club"
    expect(campaign.name).to eq("Historical City Historical Club")
  end

  it "rejects a conference outside the season's league" do
    team = create :team
    season = create :season, league: team.league
    campaign = described_class.new team: team, season: season, conference: create(:conference)

    expect(campaign).not_to be_valid
    expect(campaign.errors[:conference]).to include("must belong to the season's league")
  end

  it "rejects a division outside the season's league even without an explicit conference" do
    team = create :team
    season = create :season, league: team.league
    campaign = described_class.new team: team, season: season, division: create(:division)

    expect(campaign).not_to be_valid
    expect(campaign.errors[:division]).to include("must belong to the season's league")
  end

  it "rejects a division from another conference in the same league" do
    team = create :team
    season = create :season, league: team.league
    conference = create :conference, league: team.league
    other_conference = create :conference, league: team.league
    division = create :division, conference: other_conference
    campaign = described_class.new team: team, season: season, conference: conference, division: division

    expect(campaign).not_to be_valid
    expect(campaign.errors[:division]).to include("must belong to the campaign's conference")
  end

  it "allows a matching historical division with no separately supplied conference" do
    team = create :team
    season = create :season, league: team.league
    conference = create :conference, league: team.league
    campaign = described_class.new team: team, season: season, division: create(:division, conference: conference)

    expect(campaign).to be_valid
  end

  it "retains a name fallback for legacy campaigns with no annual snapshot" do
    team = build :team
    expect(described_class.new(team: team).name).to eq(team.name)
  end
end
