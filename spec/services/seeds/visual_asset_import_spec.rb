require "rails_helper"
require "tmpdir"

RSpec.describe "Visual asset seed import" do
  it "resolves asset owners out of order and preserves canonical files and dates on replay" do
    team = create(:team, entity_code: "BKT-NBA-TEAM-NYK")
    records = [
      { type: "AssetRepresentation", code: "NYK-LOGO-PNG", attributes: { canonical_path: "media/pilot/knicks.png", file_format: "png", view: "default", content_type: "image/png", byte_size: 123, sha256: "b" * 64 }, references: { subject: "NYK-LOGO" } },
      { type: "Logo", code: "NYK-LOGO", attributes: { name: "Knicks primary", ongoing: true }, references: { team: team.entity_code } }
    ]
    Dir.mktmpdir do |directory|
      path = File.join(directory, "logos.json")
      File.write(path, JSON.generate(format: "micharisma-seeds/v1", namespace: "MIC", catalog: "ALA", records: records))
      importer = Seeds::LibraryImporter.new
      expect(importer.call([ path ])[:created].size).to eq(2)
      expect(importer.call([ path ])[:conflicts]).to be_empty
      expect(AssetRepresentation.sole.subject).to eq(Logo.sole)
      expect(AssetRepresentation.sole.local_path.to_s).to end_with("/media/pilot/knicks.png")
      Logo.sole.update!(name: "Curated logo")
      report = importer.call([ path ])
      expect(report[:conflicts].map { |row| row.fetch(:code) }).to eq([ "NYK-LOGO" ])
      expect(Logo.sole.name).to eq("Curated logo")
    end
  end
end
