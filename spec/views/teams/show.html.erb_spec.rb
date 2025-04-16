require 'rails_helper'

RSpec.describe "teams/show", type: :view do
  before(:each) do
    assign(:team, Team.create!(
      mascot: "Mascot",
      territory: "Territory",
      league: nil,
      stadium: nil,
      founded_year: 2,
      abbreviation: "Abbreviation",
      url: "Url",
      logo_url: "Logo Url",
      primary_color: "Primary Color",
      secondary_color: "Secondary Color",
      coach_name: "Coach Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Mascot/)
    expect(rendered).to match(/Territory/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Abbreviation/)
    expect(rendered).to match(/Url/)
    expect(rendered).to match(/Logo Url/)
    expect(rendered).to match(/Primary Color/)
    expect(rendered).to match(/Secondary Color/)
    expect(rendered).to match(/Coach Name/)
  end
end
