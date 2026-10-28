require "rails_helper"
require "tmpdir"
require Rails.root.join("lib/micharisma_seeders/lib/micharisma_seeders").to_s

RSpec.describe Seeds::HomeVenueImporter do
  let(:data_root) { Rails.root.join("db/seeds/athlete_ace_data") }
  let(:bindings_path) { data_root.join("sources/geography_2026/bindings.json") }
  let(:bindings) { JSON.parse(bindings_path.read).fetch("teams") }
  let(:resolver) { Seeds::LibraryImporter.new }

  around do |example|
    Dir.mktmpdir("home-venues") do |directory|
      @source = Pathname.new(directory).join("bindings.json")
      example.run
    end
  end

  def sample_binding
    stadium = create(:stadium, name: "Madison Square Garden", entity_code: "STADIUM-MSG")
    stadium.city.update!(entity_code: "CITY-NEW_YORK")
    team = create(:team, territory: "New York", mascot: "Knicks", entity_code: "BKT-NBA-TEAM-NYK")
    season = create(:season, league: team.league, entity_code: "BKT-NBA-SEASON_2026_2027")
    campaign = Campaign.create!(team: team, season: season, entity_code: "BKT-NBA-SEASON_2026_2027-TEAM-NYK")
    entry = { "team" => team.entity_code, "campaign" => campaign.entity_code, "season" => season.entity_code,
      "stadium" => stadium.entity_code, "city" => stadium.city.entity_code }
    [ entry, team, campaign, stadium ]
  end

  def write_bindings(entries)
    @source.write(JSON.generate(teams: entries))
    described_class.new(source: @source)
  end

  it "imports complete geography, links all six leagues, shares buildings across sports, and replays unchanged" do
    library = data_root.join("yaml")
    registry = MICharismaSeeders::SequenceRegistry.read(library.join("entity_sequences.yaml"))
    catalog = Seeds::LibraryImporter.new(registry: registry)
    paths = Dir.glob(library.join("**/*.yaml")).reject { |path| path.end_with?("entity_sequences.yaml") }
    campaign_codes = bindings.map { |entry| entry.fetch("campaign") }
    types = %w[Country State City Stadium Sport League Federation Year Season Team]
    selected = catalog.read(paths).select { |row| types.include?(row.type) || (row.type == "Campaign" && campaign_codes.include?(row.code)) }
    rows = selected.map do |row|
      { "type" => row.type, "code" => row.code, "aliases" => row.aliases, "attributes" => row.attributes,
        "references" => row.references, "scope" => row.scope, "source" => row.source || {} }
    end
    path = @source.dirname.join("geography-graph.json")
    path.write(JSON.generate(format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: rows))
    expect(catalog.call([ path ])[:conflicts]).to be_empty
    importer = described_class.new(source: bindings_path)
    report = importer.call
    expect(report[:updated].size).to eq(348)
    expect(report[:conflicts]).to be_empty
    expect([ State.count, City.count, Stadium.count ]).to eq([ 34, 89, 160 ])
    expect(bindings.group_by { |entry| entry.fetch("league") }.transform_values(&:size)).to eq(
      "NBA" => 30, "NFL" => 32, "MLB" => 30, "NHL" => 32, "MLS" => 30, "EPL" => 20)
    bindings.each do |entry|
      campaign = resolver.resolve_code("Campaign", entry.fetch("campaign"))
      expect(campaign.stadium).to eq(campaign.team.stadium)
      expect(campaign.city).to eq(campaign.stadium.city)
      expect(campaign.city.state.country).to be_present
    end
    %w[MA-BOSTON-TD_GARDEN MI-DETROIT-LITTLE_CAESARS_ARENA NJ-EAST_RUTHERFORD-METLIFE_STADIUM CA-INGLEWOOD-SOFI_STADIUM].each do |suffix|
      expect(Stadium.find_by!(entity_code: "STADIUM-US-#{suffix}").teams.count).to eq(2)
    end
    expect(resolver.resolve_code("Team", "BKT-NBA-TEAM-GSW").stadium.name).to eq("Chase Center")
    expect(resolver.resolve_code("Team", "BKT-NBA-TEAM-LAC").stadium.name).to eq("Intuit Dome")
    expect(resolver.resolve_code("Team", "HCK-NHL-TEAM-WPG").stadium.city.name).to eq("Winnipeg")
    expect(resolver.resolve_code("Team", "SOC-MLS-TEAM-DAL").stadium.city.name).to eq("Frisco")
    expect(resolver.resolve_code("Team", "BSB-MLB-TEAM-ATH").stadium.city.name).to eq("West Sacramento")
    expect(resolver.resolve_code("Team", "SOC-EPL-TEAM-NFO").stadium.city.name).to eq("West Bridgford")
    replay = catalog.call([ path ])
    expect(replay[:created]).to be_empty
    expect(replay[:conflicts]).to be_empty
    expect(importer.call).to eq(updated: [], unchanged: report[:updated], conflicts: [])
  end

  it "fills only the selected season and leaves historical venue links alone" do
    entry, team, campaign, stadium = sample_binding
    old_season = create(:season, league: team.league)
    historical = Campaign.create!(team: team, season: old_season)
    report = write_bindings([ entry ]).call
    expect(report[:updated]).to eq([ team.entity_code, campaign.entity_code ])
    expect(campaign.reload.stadium).to eq(stadium)
    expect(historical.reload.stadium).to be_nil
  end

  it "preserves a different existing venue and does not fill the campaign with a conflicting city" do
    entry, team, campaign, = sample_binding
    chosen = create(:stadium, entity_code: "STADIUM-CHOSEN")
    team.update!(stadium: chosen)
    campaign.update!(stadium: chosen)
    report = write_bindings([ entry ]).call
    expect(report[:updated]).to be_empty
    expect(report[:conflicts].map { |row| row[:code] }).to eq([ team.entity_code, campaign.entity_code ])
    expect(team.reload.stadium).to eq(chosen)
    expect(campaign.reload.city).to be_nil
  end

  it "rolls back preceding links if any binding has a missing reference" do
    entry, team, campaign, = sample_binding
    importer = write_bindings([ entry, entry.merge("stadium" => "STADIUM-MISSING") ])
    expect { importer.call }.to raise_error(Seeds::LibraryImporter::MissingReference)
    expect(team.reload.stadium).to be_nil
    expect(campaign.reload.stadium).to be_nil
  end

  it "rejects bindings to a different team or an unrelated city" do
    entry, team, campaign, = sample_binding
    other_team = create(:team, entity_code: "BKT-NBA-TEAM-OTHER")
    importer = write_bindings([ entry.merge("team" => other_team.entity_code) ])
    expect { importer.call }.to raise_error(Seeds::LibraryImporter::Error, /disagrees/)
    expect(team.reload.stadium).to be_nil
    other_city = create(:city, entity_code: "CITY-OTHER")
    importer = write_bindings([ entry.merge("city" => other_city.entity_code) ])
    expect { importer.call }.to raise_error(Seeds::LibraryImporter::Error, /disagrees/)
    expect(campaign.reload.stadium).to be_nil
  end

  it "does not apply the default catalog's bindings to a custom library without its own bindings" do
    expect(described_class.new(source: @source).call).to eq(updated: [], unchanged: [], conflicts: [])
  end
end
