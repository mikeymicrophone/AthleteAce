require "rails_helper"

RSpec.describe JerseyPortraitHelper, type: :helper do
  it "preserves zeroes on a jersey and uses initials when the number is unknown or malformed" do
    expect(helper.jersey_portrait_fallback("Aaron Judge", "00")).to include('class="jersey-number">00</span>')
    expect(helper.jersey_portrait_fallback("Aaron Judge", nil)).to eq('<span class="jersey-initials">AJ</span>')
    expect(helper.jersey_portrait_fallback("Aaron Judge", "<script>")).to eq('<span class="jersey-initials">AJ</span>')
  end

  it "labels a dated observation without claiming the number lasted the whole season" do
    expect(helper.round_jersey_caption("subject_jersey_number" => "00", "subject_jersey_number_on" => "2025-01-02")).to eq(
      "No. 00 · recorded Jan 2, 2025")
    expect(helper.round_jersey_caption({})).to be_nil
  end
end
