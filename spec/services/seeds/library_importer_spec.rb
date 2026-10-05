require "rails_helper"
require "tmpdir"
require "fileutils"

RSpec.describe Seeds::LibraryImporter do
  let(:library) { Rails.root.join("db/seeds/athlete_ace_data/yaml") }
  let(:registry) { MICharismaSeeders::SequenceRegistry.read(library.join("entity_sequences.yaml")) }
  let(:paths) { Dir.glob(library.join("*.yaml")).sort.reject { |path| path.end_with?("entity_sequences.yaml") } }
  let(:importer) { described_class.new(registry: registry) }

  around do |example|
    Dir.mktmpdir("seed-library") do |directory|
      @directory = directory
      example.run
    end
  end

  def write_document(records:, scope: {}, groups: [], format: :yaml, **options)
    document = { "format" => "micharisma-seeds/v1", "namespace" => "MIC", "catalog" => "ALA",
      "scope" => scope, "records" => records, "groups" => groups }.merge(options.transform_keys(&:to_s))
    path = File.join(@directory, "#{Dir.children(@directory).length}.#{format}")
    File.write(path, format == :json ? JSON.generate(document) : YAML.dump(document))
    path
  end

  def definition(type, code, attributes = {}, references = {}, **options)
    { "type" => type, "code" => code, "attributes" => attributes, "references" => references }.merge(options.transform_keys(&:to_s))
  end

  def seed_pilot
    importer.call(paths)
  end

  def counts
    described_class::MODELS.transform_values(&:count).merge("EntityCode" => EntityCode.count)
  end

  it "imports sourced transfers and historical team details without contracts or current player teams" do
    expect(importer.validate(paths)).to eq(records: 89, codes: 94, files: 14)
    report = seed_pilot
    expect(report[:created].length).to eq(89)
    expect(report[:conflicts]).to be_empty
    expect([Season.count, Team.count, Player.count, Campaign.count, Activation.count]).to eq([41, 8, 3, 10, 6])
    expect(Contract.count).to eq(0)
    expect(Player.where.not(team_id: nil)).to be_empty
    Player.find_each { |player| expect(player.campaigns.count).to eq(2) }
    %w[NBA NFL NHL EPL].each { |abbreviation| expect(League.find_by!(abbreviation: abbreviation).seasons.count).to eq(10) }

    raiders = importer.resolve_code("Team", "FTB-NFL-TEAM-RAIDERS")
    expect(raiders.campaigns.order(:id).pluck(:territory)).to match_array(["Oakland", "Las Vegas"])
    fulham = importer.resolve_code("Team", "SOC-EPL-TEAM-FUL")
    expect(fulham.league.abbreviation).to eq("EPL")
    expect(fulham.campaigns.map { |campaign| campaign.league.abbreviation }).to match_array(["EPL", "EFL_CHAMPIONSHIP"])
  end

  it "replays in reversed file order after files move and are renamed without changing IDs or values" do
    seed_pilot
    original_counts = counts
    original_ids = Player.pluck(:entity_code, :id).to_h
    moved = paths.reverse.each_with_index.map do |path, index|
      target = File.join(@directory, "unrelated-name-#{index}.yaml")
      FileUtils.cp(path, target)
      target
    end
    report = importer.call(moved)
    expect(counts).to eq(original_counts)
    expect(Player.pluck(:entity_code, :id).to_h).to eq(original_ids)
    expect(report[:created]).to be_empty
    expect(report[:conflicts]).to be_empty
  end

  it "preserves edited fields and recreates missing memberships" do
    seed_pilot
    hart = importer.resolve_code("Player", "BKT-NBA-LAL-2017-HART_JOSH")
    hart.update!(first_name: "Joshua")
    hart.activations.first.destroy!
    report = importer.call(paths)
    expect(hart.reload.first_name).to eq("Joshua")
    expect(hart.activations.count).to eq(2)
    expect(report[:created].length).to eq(1)
    expect(report[:conflicts].first[:differences]["first_name"]).to eq(existing: "Joshua", incoming: "Josh")
  end

  it "reconstructs the complete pilot after a catalog wipe with different primary keys" do
    seed_pilot
    original_counts = counts
    original_player_ids = Player.pluck(:entity_code, :id).to_h
    membership_codes = lambda do
      Activation.includes(:player, campaign: [:team, :season]).map do |activation|
        [activation.player.entity_code, activation.campaign.team.entity_code, activation.campaign.season.entity_code]
      end.sort
    end
    original_memberships = membership_codes.call
    EntityCode.delete_all
    described_class::MODELS.values.reverse_each(&:delete_all)

    expect(importer.call(paths.reverse)[:created].length).to eq(89)
    expect(counts).to eq(original_counts)
    expect(membership_codes.call).to eq(original_memberships)
    Player.find_each { |player| expect(player.id).not_to eq(original_player_ids.fetch(player.entity_code)) }
  end

  it "repairs code bindings after deletion even if an unrelated player reuses the numeric ID" do
    seed_pilot
    original = importer.resolve_code("Player", "BKT-NBA-LAL-2017-HART_JOSH")
    old_id = original.id
    binding = EntityCode.find_by!(code: "BKT-NBA-PLAYER-HART_JOSH")
    expect(binding.record).to eq(original)
    original.destroy!
    unrelated = Player.create!(id: old_id, first_name: "Marcus", last_name: "Thornton", entity_code: "PLAYER-THORNTON_MARCUS")
    expect(binding.record).to be_nil
    seed_pilot
    restored = importer.resolve_code("Player", "MIC-ALA-BKT-NBA-PLAYER-HART_JOSH")
    expect(restored.id).not_to eq(old_id)
    expect(restored.first_name).to eq("Josh")
    expect(restored.activations.count).to eq(2)
    expect(unrelated.reload.first_name).to eq("Marcus")
    expect(binding.reload.record).to eq(restored)
  end

  it "supports YAML and JSON with file, nested group, and row scope overrides" do
    seed_pilot
    base = { "sport" => "SPORT-BKT", "league" => "BKT-LEAGUE-NBA", "year" => "YEAR-2023" }
    group = { "scope" => { "team" => "BKT-NBA-TEAM-NYK" }, "groups" => [
      { "records" => [definition("Campaign", "BKT-NBA-SEASON_2023_2024-TEAM-POR",
        { "display_name" => "Portland Trail Blazers", "abbreviation" => "POR" }, {},
        scope: { "team" => "BKT-NBA-TEAM-POR" })] }
    ] }
    yaml = write_document(records: [], scope: base, groups: [group])
    json = write_document(records: [], scope: base, groups: [group], format: :json)
    expect(importer.call([yaml])[:created].length).to eq(1)
    expect(importer.call([json])[:created]).to be_empty
    campaign = Campaign.find_by!(entity_code: "BKT-NBA-SEASON_2023_2024-TEAM-POR")
    expect(campaign.team.abbreviation).to eq("POR")
    expect(campaign.season.year.number).to eq(2023)
  end

  it "adds aliases without renaming the preferred entity code" do
    seed_pilot
    path = write_document(records: [definition("Player", "BKT-NBA-PLAYER-HART_JOSH", {}, {}, aliases: ["NBA-HART_JOSH"])])
    expect(importer.call([path])[:aliases_added]).to eq(["NBA-HART_JOSH"])
    expect(importer.resolve_code("Player", "NBA-HART_JOSH").entity_code).to eq("BKT-NBA-LAL-2017-HART_JOSH")
  end

  it "rolls back the entire import when a required parent is unresolved" do
    path = write_document(records: [definition("Sport", "SPORT-BKT", { "name" => "Basketball" }),
      definition("Player", "BKT-PLAYER-HART_JOSH", { "first_name" => "Josh", "last_name" => "Hart" }, { "sport" => "SPORT-MISSING" })])
    expect { importer.call([path]) }.to raise_error(described_class::Error, /Unresolved seed dependencies/)
    expect(Sport.count).to eq(0)
    expect(EntityCode.count).to eq(0)
    expect(importer.report.values.flatten).to be_empty
  end

  it "rejects contradictory definitions through transitive aliases before writing" do
    path = write_document(records: [
      definition("Sport", "SPORT-A", { "name" => "Basketball" }, {}, aliases: ["SPORT-B"]),
      definition("Sport", "SPORT-C", {}, {}, aliases: ["SPORT-B", "SPORT-D"]),
      definition("Sport", "SPORT-D", { "name" => "Hockey" })
    ])
    expect { importer.call([path]) }.to raise_error(described_class::Error, /contradictory/)
    expect(Sport.count).to eq(0)
  end

  it "rejects protected IDs, unknown reference sequences, and qualified definition codes in preflight" do
    id_path = write_document(records: [definition("Sport", "SPORT-BKT", { "id" => 8 })])
    expect { importer.validate([id_path]) }.to raise_error(described_class::Error, /unsupported.*attribute id/)
    sequence_path = write_document(records: [definition("Player", "PLAYER-HART", {}, { "sport" => { "code" => "BKT", "entity_sequence" => "99_99" } })])
    expect { importer.validate([sequence_path]) }.to raise_error(MICharismaSeeders::UnknownSequenceError)
    qualified = write_document(records: [definition("Sport", "MIC-ALA-SPORT-BKT")])
    expect { importer.validate([qualified]) }.to raise_error(described_class::Error, /invalid local entity code/)
    expect(Sport.count).to eq(0)
  end

  it "resolves a file-selected shorthand player through that season's roster, preserving both teams" do
    seed_pilot
    scope = { "sport" => "SPORT-BKT", "league" => "BKT-LEAGUE-NBA", "team" => "BKT-NBA-TEAM-NYK", "year" => "YEAR-2022" }
    path = write_document(records: [definition("Activation", "BKT-NBA-SEASON_2022_2023-TEAM-NYK-PLAYER-HART_JOSH", {}, { "player" => "HART_JOSH" })],
      scope: scope, entity_sequence: "05_22")
    expect(importer.call([path])[:conflicts]).to be_empty
    hart = importer.resolve_code("Player", "BKT-NBA-LAL-2017-HART_JOSH")
    expect(hart.campaigns.count).to eq(2)
  end

  it "resolves an explicit fully qualified sequence reference" do
    seed_pilot
    path = write_document(records: [definition("Contract", "BKT-NBA-CONTRACT-HART_JOSH-NYK", {}, {
      "player" => "BKT-NBA-LAL-2017-HART_JOSH",
      "team" => { "code" => "MIC-ALA-BKT-NBA-2022-NYK", "entity_sequence" => "01_11" }
    })])
    expect(importer.call([path])[:created]).to eq(["BKT-NBA-CONTRACT-HART_JOSH-NYK"])
    expect(Contract.last.team.abbreviation).to eq("NYK")
  end
end
