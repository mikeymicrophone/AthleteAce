require "rails_helper"

RSpec.describe JerseyNumberAssignment do
  let(:team) { create(:team) }
  let(:player) { create(:player, team: team) }

  def assignment(**attributes)
    described_class.new(player: player, team: team, number: "00", **attributes)
  end

  it "spans seasons, preserves zeroes, and permits a mid-season change on the next day" do
    original = assignment(start_date: "2023-09-01", end_date: "2025-01-14")
    original.save!
    expect(original.reload.number).to eq("00")
    expect(original.covers?(Date.new(2024, 1, 1), Date.new(2024, 12, 31))).to be(true)
    expect(assignment(number: "0", start_date: "2025-01-15")).to be_valid
    expect(assignment(number: "7", start_date: "2025-01-14")).not_to be_valid
    expect(assignment(team: create(:team, league: team.league))).to be_valid
  end

  it "rejects ambiguous overlapping and duplicate periods even when dates are open-ended" do
    assignment.save!
    expect(assignment(number: "7")).not_to be_valid
    expect(assignment(start_date: "2025-01-01", end_date: "2025-12-31")).not_to be_valid
  end

  it "enforces overlap protection in the database when validation is bypassed" do
    assignment(start_date: "2025-01-01", end_date: "2025-06-01").save!
    expect {
      described_class.transaction(requires_new: true) do
        assignment(number: "7", start_date: "2025-03-01").save!(validate: false)
      end
    }.to raise_error(ActiveRecord::StatementInvalid, /jersey_numbers_do_not_overlap/)
  end

  it "rejects reversed dates, malformed numbers, incompatible sports, and invalid metadata" do
    expect(assignment(start_date: "2025-02-01", end_date: "2025-01-01")).not_to be_valid
    expect(assignment(number: "Unknown")).not_to be_valid
    expect(assignment(number: "<script>")).not_to be_valid
    expect(assignment(player: create(:player, sport: create(:sport)))).not_to be_valid
    expect(assignment(source: [])).not_to be_valid
  end
end
