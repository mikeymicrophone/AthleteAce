require "rails_helper"

RSpec.describe Seeds::CatalogContract do
  it "exports the live adapter allowlist without database IDs or protected fields" do
    contract = described_class.document
    expect(contract.fetch("entities").keys).to match_array(Seeds::LibraryImporter::MODELS.keys)
    expect(contract.values_at("namespace", "catalog")).to eq(%w[MIC ALA])
    contract.fetch("entities").each do |name, entity|
      expect(entity.fetch("attributes").keys.grep(/_id\z/)).to be_empty
      expect(entity.fetch("attributes").keys & Seeds::LibraryImporter::PROTECTED_ATTRIBUTES).to be_empty
      expect(entity.fetch("references")).to match_array(Seeds::LibraryImporter::MODELS.fetch(name).reflect_on_all_associations(:belongs_to).map { |association| association.name.to_s })
    end
  end

  it "describes nullable values and PostgreSQL arrays without requiring repeated relationships" do
    entities = described_class.document.fetch("entities")
    expect(entities.fetch("Campaign").fetch("attributes").fetch("comments").dig("anyOf", 0, "type")).to eq("array")
    expect(entities.fetch("Player").fetch("attributes").fetch("first_name").fetch("anyOf")).to include({ "type" => "null" })
    expect(entities.fetch("League").fetch("attributes")).not_to have_key("jurisdiction_type")
  end
end
