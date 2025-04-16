require 'rails_helper'

RSpec.describe "teams/index", type: :view do
  before(:each) do
    assign(:teams, [
      Team.create!(
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
      ),
      Team.create!(
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
      )
    ])
  end

  it "renders a list of teams" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Mascot".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Territory".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Abbreviation".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Logo Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Primary Color".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Secondary Color".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Coach Name".to_s), count: 2
  end
end
