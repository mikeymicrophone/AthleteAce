require "rails_helper"

RSpec.describe TeamPaletteHelper, type: :helper do
  it "uses the stored text and secondary colors without recalculating contrast" do
    expect(TeamPalette).not_to receive(:text_color)
    expect(helper.team_palette_style("#006BB6", "#FFFFFF", "#F58426")).to eq(
      "--team-color: #006BB6; --team-ink: #FFFFFF; --team-secondary: #F58426;")
  end

  it "uses the neutral fallback for incomplete old snapshots and rejects unsafe CSS values" do
    expect(helper.team_palette_style("#FFFFFF", nil)).to be_nil
    expect(helper.team_palette_style("red; display:none", "#FFFFFF")).to be_nil
    expect(helper.team_palette_style("#FFFFFF", "#131418", "invalid")).to eq(
      "--team-color: #FFFFFF; --team-ink: #131418;")
  end
end
