require "rails_helper"

RSpec.describe StaffTenure do
  it "supports coaching and broadcasting for the same former athlete across organizations" do
    person = create(:player).person
    coach = create :staff_tenure, person: person, start_date: "2015", end_date: "2020"
    broadcast = create :staff_tenure, :broadcaster, person: person, start_date: "2020-10", ongoing: true
    expect(person.staff_tenures).to contain_exactly(coach, broadcast)
    expect(broadcast.organization).not_to eq(coach.organization)
    expect(broadcast.team).to be_nil
  end

  it "allows concurrent appointments, same-day transitions and return tenures" do
    appointment = create :staff_tenure, start_date: "2024-07-01", end_date: "2025-07-01"
    concurrent = build :staff_tenure, person: appointment.person, organization: appointment.organization,
      start_date: "2024", end_date: "2025"
    returning = build :staff_tenure, person: appointment.person, organization: appointment.organization, start_date: "2025-07-01"
    expect(concurrent).to be_valid
    expect(returning).to be_valid
  end

  it "preserves year, month and day precision without filling unknown dates" do
    tenure = create :staff_tenure, start_date: "2024", end_date: "2025-02"
    expect(tenure.reload.attributes.values_at("start_date", "end_date")).to eq(%w[2024 2025-02])
    expect(build(:staff_tenure, start_date: nil, end_date: nil)).to be_valid
    expect(build(:staff_tenure, start_date: "2024-02-29", end_date: "2024")).to be_valid
  end

  it "rejects invalid calendar dates and provably reversed ranges" do
    [ "2025-02-29", "2025-13", "0000", "next spring" ].each do |date|
      record = build :staff_tenure, start_date: date
      expect(record).not_to be_valid
      expect(record.errors[:start_date]).to be_present
    end
    expect(build(:staff_tenure, start_date: "2025", end_date: "2024-12-31")).not_to be_valid
    expect(build(:staff_tenure, start_date: "2025-08", end_date: "2025-07")).not_to be_valid
  end

  it "requires affirmative ongoing status and a supported role with evidence" do
    tenure = build :staff_tenure
    expect(tenure).not_to be_ongoing
    expect(build(:staff_tenure, ongoing: true, end_date: "2025")).not_to be_valid
    expect(build(:staff_tenure, role: "admin")).not_to be_valid
    expect(build(:staff_tenure, source: {})).not_to be_valid
    expect(build(:staff_tenure, source: [])).not_to be_valid
    expect(build(:staff_tenure, role: "staff", title: "Player development director")).to be_valid
  end

  it "orders dated appointments deterministically before undated appointments" do
    undated = create :staff_tenure
    first = create :staff_tenure, start_date: "2025"
    second = create :staff_tenure, start_date: "2025"
    expect(described_class.chronological).to eq([ first, second, undated ])
  end
end
