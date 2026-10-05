require "rails_helper"

RSpec.describe Seeds::EntitySequenceResolver do
  let(:league) { create(:nfl, entity_code: "FTB-LEAGUE-NFL", sport: create(:football, entity_code: "SPORT-FTB")) }
  let(:conference) { create(:conference, league: league, abbreviation: "AFC", entity_code: "FTB-NFL-CONFERENCE-AFC") }
  let(:division) { create(:division, conference: conference, abbreviation: "WEST", entity_code: "FTB-NFL-DIVISION-AFC_WEST") }
  let(:team) { create(:team, league: league, abbreviation: "LV", entity_code: "FTB-NFL-TEAM-RAIDERS") }
  let(:year) { create(:year, number: 2019, entity_code: "YEAR-2019") }
  let!(:campaign) { Campaign.create!(team: team, season: create(:season, league: league, year: year), conference: conference, division: division, abbreviation: "OAK") }
  let(:registry) { MICharismaSeeders::SequenceRegistry.new({ 1 => { 10 => %w[Sport League Conference Division Year Team], 11 => %w[Sport League Team Year] } }) }

  it "resolves the proposed six-slot recipe through annual conference/division/team details" do
    parser = MICharismaEntityParser.select_entity_sequence("01_10", registry: registry, catalog: "ALA", adapter: described_class.new)
    expect(parser.resolve("MIC-ALA-FTB-NFL-AFC-WEST-2019-OAK")).to eq(team)
    expect { parser.resolve("FTB-NFL-AFC-WEST-2020-OAK") }.to raise_error(Seeds::LibraryImporter::MissingReference)
  end

  it "resolves parents independently of sequence position and returns the requested final entity" do
    parser = MICharismaEntityParser.select_entity_sequence("01_11", registry: registry, adapter: described_class.new)
    expect(parser.resolve("FTB-NFL-OAK-2019")).to eq(year)
  end

  it "rejects an ambiguous annual team abbreviation" do
    other = create(:team, league: league)
    Campaign.create!(team: other, season: campaign.season, conference: conference, division: division, abbreviation: "OAK")
    parser = MICharismaEntityParser.select_entity_sequence("01_10", registry: registry, adapter: described_class.new)
    expect { parser.resolve("FTB-NFL-AFC-WEST-2019-OAK") }.to raise_error(Seeds::LibraryImporter::Error, /Ambiguous/)
  end
end
