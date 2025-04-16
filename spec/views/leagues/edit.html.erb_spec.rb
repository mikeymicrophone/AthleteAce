require 'rails_helper'

RSpec.describe "leagues/edit", type: :view do
  let(:league) {
    League.create!(
      name: "MyString",
      url: "MyString",
      ios_app_url: "MyString",
      year_of_origin: 1,
      official_rules_url: "MyString",
      sport: nil
    )
  }

  before(:each) do
    assign(:league, league)
  end

  it "renders the edit league form" do
    render

    assert_select "form[action=?][method=?]", league_path(league), "post" do

      assert_select "input[name=?]", "league[name]"

      assert_select "input[name=?]", "league[url]"

      assert_select "input[name=?]", "league[ios_app_url]"

      assert_select "input[name=?]", "league[year_of_origin]"

      assert_select "input[name=?]", "league[official_rules_url]"

      assert_select "input[name=?]", "league[sport_id]"
    end
  end
end
