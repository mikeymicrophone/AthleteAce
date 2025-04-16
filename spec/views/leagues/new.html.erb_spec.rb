require 'rails_helper'

RSpec.describe "leagues/new", type: :view do
  before(:each) do
    assign(:league, League.new(
      name: "MyString",
      url: "MyString",
      ios_app_url: "MyString",
      year_of_origin: 1,
      official_rules_url: "MyString",
      sport: nil
    ))
  end

  it "renders new league form" do
    render

    assert_select "form[action=?][method=?]", leagues_path, "post" do

      assert_select "input[name=?]", "league[name]"

      assert_select "input[name=?]", "league[url]"

      assert_select "input[name=?]", "league[ios_app_url]"

      assert_select "input[name=?]", "league[year_of_origin]"

      assert_select "input[name=?]", "league[official_rules_url]"

      assert_select "input[name=?]", "league[sport_id]"
    end
  end
end
