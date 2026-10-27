require "rails_helper"

RSpec.describe "Expanded seasonal seed catalog" do
  let(:root) { Rails.root.join("db/seeds/athlete_ace_data") }
  let(:library) { root.join("yaml") }
  let(:capture) { JSON.parse(File.read(root.join("sources/coverage_2025.json"))) }
  let(:registry) { MICharismaSeeders::SequenceRegistry.read(library.join("entity_sequences.yaml")) }
  let(:paths) { Dir.glob(library.join("**/*.yaml")).sort.reject { |path| path.end_with?("entity_sequences.yaml") || path.include?("/coverage_2026/") } }
  let(:importer) { Seeds::LibraryImporter.new(registry: registry) }
  let(:full_rosters) { { "NBA" => "NYK", "NFL" => "SF", "NHL" => "STL" } }

  it "imports full captured NBA and NHL player lists plus the other selected source listings" do
    report = importer.call(paths)
    expect(report[:conflicts]).to be_empty
    expect(Team.count).to eq(114)
    { "NBA" => 30, "NFL" => 32, "NHL" => 32, "EPL" => 20 }.each do |abbreviation, count|
      league = League.find_by!(abbreviation: abbreviation)
      expect(league.teams.count).to eq(count)
      label = abbreviation == "NFL" ? "2025" : "2025_2026"
      expect(league.seasons.find_by!(label: label).campaigns.count).to eq(count)
    end
    capture.fetch("teams").each do |source|
      league = League.find_by!(abbreviation: source.fetch("league"))
      season = league.seasons.find_by!(label: source.fetch("season"))
      campaign = season.campaigns.find_by!(abbreviation: source.fetch("abbreviation"))
      complete = full_rosters[source.fetch("league")] == source.fetch("abbreviation")
      expanded = %w[NBA NHL].include?(source.fetch("league"))
      selected = complete || expanded ? source.fetch("players") : source.fetch("players").first(2)
      expected_names = selected.map { |player| [ player.fetch("first_name"), player.fetch("last_name") ] }.sort
      expect(campaign.activated_players.map { |player| [ player.first_name, player.last_name ] }.sort).to eq(expected_names)
      expect(campaign.activated_players.count).to be >= 2
      expect(campaign.details.fetch("roster_coverage")).to eq(complete ? "complete_source_listing" : "two_player_sample")
    end
    expect(Player.where.not(team_id: nil)).to be_empty
    petterssons = Player.where(first_name: "Elias", last_name: "Pettersson")
    expect(petterssons.count).to eq(2)
    expect(petterssons.pluck(:entity_code)).to contain_exactly(
      "HCK-NHL-PLAYER-PETTERSSON_ELIAS_SOURCE_8480012", "HCK-NHL-PLAYER-PETTERSSON_ELIAS_SOURCE_8483678"
    )
    expect(EntityCode.all.all? { |binding| binding.resolved_record.present? }).to be(true)
  end

  it "replays the expanded catalog in reverse file order without new records or conflicts" do
    importer.call(paths)
    original = Seeds::LibraryImporter::MODELS.transform_values { |model| model.order(:id).pluck(:id, :entity_code) }
    report = importer.call(paths.reverse)
    expect(report[:created]).to be_empty
    expect(report[:conflicts]).to be_empty
    expect(report[:aliases_added]).to be_empty
    expect(Seeds::LibraryImporter::MODELS.transform_values { |model| model.order(:id).pluck(:id, :entity_code) }).to eq(original)
  end

  it "seeds all club organizations and independently sourced roster observations" do
    importer.call(paths)
    expect(Organization.joins(:organization_affiliations).distinct.count).to eq(114)
    expect(OrganizationAffiliation.count).to eq(114)
    expect(Team.all.all? { |team| team.current_organization.present? }).to be(true)
    person = importer.resolve_code("Person", "PERSON-KERR_STEVE")
    expect(person.player.name).to eq("Steve Kerr")
    expect(person.staff_tenures.pluck(:role)).to contain_exactly("coach", "broadcaster")
    broadcast = person.staff_tenures.broadcaster.sole
    expect(broadcast.organization.name).to eq("TNT")
    expect(broadcast.team).to be_nil
    expect(broadcast.end_date).to be_nil
    expect(broadcast).not_to be_ongoing
    expect(Roster.count).to eq(83)
    expect(RosterEntry.count).to eq(281)
    expect(Roster.where(coverage: "complete").map { |roster| roster.campaign.abbreviation }).to match_array(%w[NYK SF])
    expect(Roster.where(kind: "senior_registration").pluck(:effective_on).uniq).to eq([ Date.new(2025, 9, 12) ])
    expect(Roster.where(kind: "published_season_player_inventory").where.not(effective_on: nil)).to be_empty
    expect(Roster.joins(campaign: :season).where(seasons: { label: "2025_2026" }).joins(campaign: :team).where(teams: { league_id: League.find_by!(abbreviation: "NHL").id })).to be_empty
    expect(RosterEntry.where.not(stint_id: nil)).to be_empty
    expect(Roster.all.all? { |roster| roster.source.fetch("url").present? }).to be(true)
    expect(RosterEntry.all.all? { |entry| entry.source.fetch("url").present? }).to be(true)
  end

  it "imports sourced contracts, events, assignments, and actual game statistics without guessing missing dates" do
    importer.call(paths)
    expect([ Contract.count, Transaction.count, TransactionPlayer.count, Stint.count, Contest.count, Contestant.count, Appearance.count ]).to eq([ 1, 2, 2, 1, 1, 2, 1 ])
    contract = Contract.sole
    expect(contract.organization.name).to eq("St. Louis Blues")
    expect([ contract.team, contract.start_date, contract.end_date ]).to eq([ nil, nil, nil ])
    expect(contract.total_dollar_value).to eq(16000000)
    appearance = Appearance.sole
    boxscore = JSON.parse(File.read(root.join("sources/leddy_game_20220322.json")))
    expect(appearance.player.entity_code).to eq("HCK-NHL-CHI-2010-LEDDY_NICK")
    expect(appearance.team.abbreviation).to eq(boxscore.fetch("away_team").fetch("abbrev"))
    expect(appearance.contest.kind).to eq("game")
    expect(appearance.contest.context).to eq(League.find_by!(abbreviation: "NHL"))
    expect(appearance.contest.begin_date.iso8601).to eq(boxscore.fetch("game").fetch("gameDate"))
    expect(appearance.statistics).to eq({ "goals" => boxscore.fetch("player").fetch("goals"), "assists" => boxscore.fetch("player").fetch("assists"),
      "points" => boxscore.fetch("player").fetch("points"), "shots_on_goal" => boxscore.fetch("player").fetch("sog"), "time_on_ice" => boxscore.fetch("player").fetch("toi") })
    expect(appearance.starter).to be_nil
    expect(appearance.stint.start_transaction.kind).to eq("trade")
    expect(appearance.stint.contract).to be_nil
    expect(appearance.stint.end_date).to be_nil
    expect(appearance.source.fetch("url")).to eq(boxscore.fetch("url"))
  end

  it "preserves edited game facts and reports their differences during replay" do
    importer.call(paths)
    appearance = Appearance.sole
    appearance.update! statistics: { "points" => 99 }
    report = importer.call(paths.reverse)
    expect(report[:created]).to be_empty
    expect(report[:conflicts].pluck(:code)).to eq([ appearance.entity_code ])
    expect(appearance.reload.statistics).to eq({ "points" => 99 })
  end

  it "restores a missing observation entry with a new id and repairs its code binding" do
    importer.call(paths)
    entry = RosterEntry.first
    code, old_id = entry.entity_code, entry.id
    entry.destroy!
    report = importer.call(paths.reverse)
    expect(report[:created]).to eq([ code ])
    expect(report[:conflicts]).to be_empty
    restored = importer.resolve_code("RosterEntry", code)
    expect(restored.id).not_to eq(old_id)
    expect(EntityCode.find_by!(code: code).resolved_record).to eq(restored)
  end
end
