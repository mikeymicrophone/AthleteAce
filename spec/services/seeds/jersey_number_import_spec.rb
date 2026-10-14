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
end
