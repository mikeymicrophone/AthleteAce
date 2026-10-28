require "rails_helper"

RSpec.describe IconHelper, type: :helper do
  it "renders accessible decorative SVGs without a font or remote stylesheet" do
    svg = Nokogiri::HTML.fragment helper.icon_for_resource(:players, size: 20)
    expect(svg.at_css("svg").attributes.transform_values(&:value)).to include(
      "width" => "20", "stroke" => "currentColor", "stroke-width" => "2", "aria-hidden" => "true"
    )
    expect(svg.at_css("path")).to be_present
  end

  it "rejects names outside the vendored icon set" do
    expect { helper.icon "../../config/database" }.to raise_error(KeyError)
  end
end
