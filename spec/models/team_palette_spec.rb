require "rails_helper"

RSpec.describe TeamPalette do
  it "saves readable text with a team palette and recalculates when its primary color changes" do
    team = create(:team, primary_color: "#000000")
    expect(team.reload.text_color).to eq("#FFFFFF")
    team.update!(primary_color: "#F58426")
    expect(team.reload.text_color).to eq("#131418")
    team.update!(mascot: "New name")
    expect(team.reload.text_color).to eq("#131418")
    team.update!(primary_color: nil)
    expect(team.reload.text_color).to be_nil
  end

  it "rejects malformed colors and chooses dark text on white" do
    expect(described_class.text_color("#FFFFFF")).to eq("#131418")
    expect(described_class.text_color("red; color: white")).to be_nil
    expect(described_class.text_color("#fff")).to be_nil
  end
end
