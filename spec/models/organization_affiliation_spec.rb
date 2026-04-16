require "rails_helper"

RSpec.describe OrganizationAffiliation, type: :model do
  it "prevents overlapping affiliations for the same team" do
    team = create :team
    create :organization_affiliation, team: team, start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 12, 31)

    overlapping_affiliation = build :organization_affiliation,
      team: team,
      start_date: Date.new(2024, 6, 1),
      end_date: Date.new(2025, 1, 1)

    expect(overlapping_affiliation).not_to be_valid
    expect(overlapping_affiliation.errors[:base]).to include(/overlap/i)
  end

  it "allows non-overlapping affiliations for the same team" do
    team = create :team
    create :organization_affiliation, team: team, start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 6, 30)

    later_affiliation = build :organization_affiliation,
      team: team,
      start_date: Date.new(2024, 7, 1),
      end_date: nil

    expect(later_affiliation).to be_valid
  end
end
