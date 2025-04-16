require 'rails_helper'

RSpec.describe "leagues/show", type: :view do
  before(:each) do
    assign(:league, League.create!(
      name: "Name",
      url: "Url",
      ios_app_url: "Ios App Url",
      year_of_origin: 2,
      official_rules_url: "Official Rules Url",
      sport: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Url/)
    expect(rendered).to match(/Ios App Url/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Official Rules Url/)
    expect(rendered).to match(//)
  end
end
