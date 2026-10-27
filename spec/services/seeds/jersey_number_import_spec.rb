require "rails_helper"
require "tmpdir"

RSpec.describe "Jersey-number seed import" do
  it "replays a dated assignment by semantic code without duplicating it or rewriting observations" do
    team = create(:team, entity_code: "BKT-NBA-TEAM-NYK")
    player = create(:player, team: team, entity_code: "BKT-NBA-PLAYER-EXAMPLE")
    manifest = {
      format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: [
        { type: "JerseyNumberAssignment", code: "BKT-NBA-TEAM-NYK-PLAYER-EXAMPLE-NUMBER_00-2023",
          attributes: { number: "00", start_date: "2023-10-01", end_date: "2025-01-14", source: { note: "Test source" } },
          references: { player: player.entity_code, team: team.entity_code } }
      ]
    }
    Dir.mktmpdir do |directory|
      path = File.join(directory, "numbers.json")
      File.write(path, JSON.generate(manifest))
      importer = Seeds::LibraryImporter.new
      expect(importer.call([ path ])[:created].size).to eq(1)
      expect(importer.call([ path ])[:unchanged].size).to eq(1)
      expect(JerseyNumberAssignment.count).to eq(1)
      expect(JerseyNumberAssignment.first.number).to eq("00")
      expect(JerseyNumberAssignment.first.start_date).to eq(Date.new(2023, 10, 1))
    end
  end

  it "reuses a covering same-number period for a later capture without inventing its introduction date" do
    team = create(:team, entity_code: "BKT-NBA-TEAM-NYK")
    player = create(:player, team: team, entity_code: "BKT-NBA-PLAYER-BRUNSON_JALEN")
    original = JerseyNumberAssignment.create!(team: team, player: player, number: "11", start_date: "2026-10-26", entity_code: "NYK-BRUNSON-NUMBER-2026_10_26")
    document = { format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: [
      { type: "JerseyNumberAssignment", code: "NYK-BRUNSON-NUMBER-2026_10_27", attributes: { number: "11", start_date: "2026-10-27" }, references: { team: team.entity_code, player: player.entity_code } }
    ] }
    Dir.mktmpdir do |directory|
      path = File.join(directory, "capture.json")
      File.write(path, JSON.generate(document))
      report = Seeds::LibraryImporter.new.call([ path ])
      expect(report[:created]).to be_empty
      expect(report[:conflicts].size).to eq(1)
      expect(JerseyNumberAssignment.sole).to eq(original)
      expect(original.reload.start_date).to eq(Date.new(2026, 10, 26))
      expect(Seeds::LibraryImporter.new.resolve_code("JerseyNumberAssignment", "NYK-BRUNSON-NUMBER-2026_10_27")).to eq(original)
    end
  end
end
