require "rails_helper"

RSpec.describe EntityCode, type: :model do
  let(:canonical_code) { "BKT-NBA-ATHLETE-BUTLER_JIMMY" }
  let(:player) { create :player, entity_code: canonical_code }
  let(:attributes) do
    { namespace: "MIC-ALA", catalog: "athlete_ace", code: "BKT-NBA-ATHLETE-BUTLER", canonical_code: canonical_code }
  end

  it "resolves a contextual alias only to its canonical entity" do
    binding = described_class.create! attributes.merge(record: player)
    expect(binding.record).to eq(player)
    expect(binding.resolved_record).to eq(player)
  end

  it "does not attach an alias to another entity after a cached database ID is reused" do
    binding = described_class.create! attributes.merge(record: player)
    binding.association(:record).load_target
    cached_id = player.id
    player.delete
    create :player, id: cached_id, entity_code: "BKT-NBA-ATHLETE-WADE_DWYANE"

    expect(binding.record).to be_nil
    expect(binding.reload.resolved_record).to be_nil
  end

  it "does not use a previously loaded association after its preferred code changes" do
    binding = described_class.create! attributes.merge(record: player)
    binding.association(:record).load_target
    Player.where(id: player.id).update_all entity_code: "BKT-NBA-ATHLETE-OTHER_CODE"

    expect(binding.resolved_record).to be_nil
  end

  it "allows an unresolved binding without a cached ID" do
    binding = described_class.create! attributes
    expect(binding.record).to be_nil
  end

  it "makes codes unique within their namespace and catalog" do
    described_class.create! attributes.merge(record: player)
    duplicate = described_class.new attributes

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
    expect(described_class.new(attributes.merge(catalog: "another_catalog"))).to be_valid
    expect(described_class.new(attributes.merge(namespace: "another_namespace"))).to be_valid
  end
end
