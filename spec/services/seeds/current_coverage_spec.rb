require "rails_helper"
require Rails.root.join("lib/micharisma_seeders/lib/micharisma_seeders").to_s

RSpec.describe "2026 seed coverage" do
  let(:root) { Rails.root.join("db/seeds/athlete_ace_data") }

  it "keeps a federation jurisdiction from being mistaken for a country with the same numeric ID" do
    country = create(:country)
    federation = Federation.create!(id: country.id, name: "Union of European Football Associations", abbreviation: "UEFA")
    league = create(:league, jurisdiction: federation)
    expect(league.reload.jurisdiction).to eq(federation)
    expect(league.country).to be_nil
    league.update!(jurisdiction: country)
    expect(league.country).to eq(country)
  end

  it "captures all requested teams, nonempty complete source lists, and genuine historical NBA seasons" do
    { nba: 30, nfl: 32, mlb: 30, nhl: 32, mls: 30, epl: 20, ucl: 36, nba_2023: 30, nba_2024: 30, nba_2025: 30 }.each do |name, count|
      capture = JSON.parse(root.join("sources/coverage_2026/#{name}.json").read)
      expect(capture.fetch("teams").size).to eq(count)
      capture.fetch("teams").each do |team|
        expect(team.fetch("players")).not_to be_empty
        expect(team.fetch("players").map { |player| player.fetch("source_id") }.uniq.size).to eq(team.fetch("players").size)
      end
    end
    historical = JSON.parse(root.join("sources/coverage_2026/nba_2023.json").read)
    nyk = historical.fetch("teams").find { |team| team.fetch("abbreviation") == "NYK" }
    names = nyk.fetch("players").map { |player| "#{player.fetch('first_name')} #{player.fetch('last_name')}" }
    expect(names).to include("Jalen Brunson", "RJ Barrett", "OG Anunoby")
    expect(names).not_to include("Karl-Anthony Towns")
  end

  it "has one NHL game identity, two opponents, and 84 games per team without fabricated results" do
    registry = MICharismaSeeders::SequenceRegistry.read(root.join("yaml/entity_sequences.yaml"))
    rows = MICharismaSeeders::Reader.new(registry: registry).read(root.join("yaml/coverage_2026/nhl.yaml"))
    games = rows.select { |row| row.type == "Game" }
    entries = rows.select { |row| row.type == "Contestant" }
    expect(games.size).to eq(1344)
    expect(games.map(&:code).uniq.size).to eq(1344)
    expect(entries.group_by { |row| row.references.fetch("contest") }.values.map(&:size).uniq).to eq([ 2 ])
    expect(entries.group_by { |row| row.references.fetch("campaign") }.values.map(&:size).uniq).to eq([ 84 ])
    expect(entries.all? { |row| row.attributes.fetch("tiebreakers").keys == [ "side" ] }).to be(true)
    expect(rows.none? { |row| row.type == "Appearance" }).to be(true)
  end

  it "uses independent number periods and shares EPL club identities with the Champions League" do
    registry = MICharismaSeeders::SequenceRegistry.read(root.join("yaml/entity_sequences.yaml"))
    reader = MICharismaSeeders::Reader.new(registry: registry)
    rows = Dir.glob(root.join("yaml/coverage_2026/*.yaml")).flat_map { |path| reader.read(path) }
    numbers = rows.select { |row| row.type == "JerseyNumberAssignment" }
    expect(numbers.size).to be > 6000
    expect(numbers.map { |row| [ row.references.fetch("player"), row.references.fetch("team") ] }.uniq.size).to eq(numbers.size)
    expect(rows.select { |row| row.type == "RosterEntry" }.none? { |row| row.attributes.key?("jersey_number") }).to be(true)
    arsenal = rows.select { |row| row.type == "Campaign" && row.references["team"] == "SOC-EPL-TEAM-ARS" }
    expect(arsenal.map { |row| row.references.fetch("season") }).to contain_exactly("SOC-EPL-SEASON_2026_2027", "SOC-UCL-SEASON_2026_2027")
    bayern = rows.find { |row| row.type == "Team" && row.attributes["mascot"] == "Bayern Munich" && !row.attributes.key?("territory") }
    expect(bayern.code).to eq("SOC-CLUB-ESPN_132")
  end

  it "accounts for every provider player ID, including reused official NHL identities" do
    report = JSON.parse(root.join("sources/coverage_2026/report.json").read)
    bindings = report.fetch("identity_bindings").map { |row| [ row.fetch("provider"), row.fetch("sport"), row.fetch("source_id") ] }
    expect(bindings.uniq.size).to eq(bindings.size)
    sports = { "NBA" => "BKT", "NFL" => "FTB", "NHL" => "HCK", "MLB" => "BSB", "EPL" => "SOC", "MLS" => "SOC", "UCL" => "SOC" }
    %w[nba nfl mlb nhl mls epl ucl nba_2023 nba_2024 nba_2025].each do |name|
      capture = JSON.parse(root.join("sources/coverage_2026/#{name}.json").read)
      keys = capture.fetch("teams").flat_map do |team|
        team.fetch("players").map { |player| [ capture.fetch("provider"), sports.fetch(capture.fetch("league")), player.fetch("source_id") ] }
      end
      expect(keys.uniq - bindings).to be_empty
    end
  end

  it "does not merge a new provider ID into an existing official NHL identity through a shared name" do
    require root.join("scripts/build_2026").to_s
    builder = Sports2026Builder.new(check: true)
    capture = { "league" => "NHL", "provider" => "nhl" }
    player = { "source_id" => "9000000000", "first_name" => "Nick", "last_name" => "Leddy" }
    expect(builder.player_code(capture, player, {})).to eq("HCK-NHL-PLAYER-LEDDY_NICK_SOURCE_NHL_9000000000")
  end
end
