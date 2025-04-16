require 'rails_helper'

RSpec.describe "teams/edit", type: :view do
  let(:team) {
    Team.create!(
      mascot: "MyString",
      territory: "MyString",
      league: nil,
      stadium: nil,
      founded_year: 1,
      abbreviation: "MyString",
      url: "MyString",
      logo_url: "MyString",
      primary_color: "MyString",
      secondary_color: "MyString",
      coach_name: "MyString"
    )
  }

  before(:each) do
    assign(:team, team)
  end

  it "renders the edit team form" do
    render

    assert_select "form[action=?][method=?]", team_path(team), "post" do

      assert_select "input[name=?]", "team[mascot]"

      assert_select "input[name=?]", "team[territory]"

      assert_select "input[name=?]", "team[league_id]"

      assert_select "input[name=?]", "team[stadium_id]"

      assert_select "input[name=?]", "team[founded_year]"

      assert_select "input[name=?]", "team[abbreviation]"

      assert_select "input[name=?]", "team[url]"

      assert_select "input[name=?]", "team[logo_url]"

      assert_select "input[name=?]", "team[primary_color]"

      assert_select "input[name=?]", "team[secondary_color]"

      assert_select "input[name=?]", "team[coach_name]"
    end
  end
end
