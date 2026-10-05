require "rails_helper"

RSpec.describe Contract, type: :model do
  it "returns duration as integer days and leaves incomplete intervals unknown" do
    contract = described_class.new start_date: Date.new(2024, 10, 1), end_date: Date.new(2024, 10, 31)
    expect(contract.duration).to eq(30)
    expect(contract.duration).to be_a(Integer)

    contract.end_date = nil
    expect(contract.duration).to be_nil
    contract.assign_attributes start_date: nil, end_date: Date.new(2024, 10, 31)
    expect(contract.duration).to be_nil
  end

  it "allows unknown or same-day dates but rejects a reversed interval" do
    player = create :player
    contract = described_class.new player: player, team: player.team
    expect(contract).to be_valid

    contract.assign_attributes start_date: Date.new(2024, 10, 1), end_date: Date.new(2024, 10, 1)
    expect(contract).to be_valid

    contract.end_date = Date.new(2024, 9, 30)
    expect(contract).not_to be_valid
    expect(contract.errors[:end_date]).to be_present
  end
end
