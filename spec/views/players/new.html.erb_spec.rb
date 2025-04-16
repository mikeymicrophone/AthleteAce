require 'rails_helper'

RSpec.describe "players/new", type: :view do
  before(:each) do
    assign(:player, Player.new(
      first_name: "MyString",
      last_name: "MyString",
      nicknames: "MyString",
      birth_city: nil,
      birth_country: nil,
      height_ft: 1,
      height_in: 1,
      weight_lb: 1,
      jersey_number: 1,
      current_position: "MyString",
      debut_year: 1,
      draft_year: 1,
      active: false,
      bio: "MyText",
      photo_urls: "MyText",
      team: nil
    ))
  end

  it "renders new player form" do
    render

    assert_select "form[action=?][method=?]", players_path, "post" do

      assert_select "input[name=?]", "player[first_name]"

      assert_select "input[name=?]", "player[last_name]"

      assert_select "input[name=?]", "player[nicknames]"

      assert_select "input[name=?]", "player[birth_city_id]"

      assert_select "input[name=?]", "player[birth_country_id]"

      assert_select "input[name=?]", "player[height_ft]"

      assert_select "input[name=?]", "player[height_in]"

      assert_select "input[name=?]", "player[weight_lb]"

      assert_select "input[name=?]", "player[jersey_number]"

      assert_select "input[name=?]", "player[current_position]"

      assert_select "input[name=?]", "player[debut_year]"

      assert_select "input[name=?]", "player[draft_year]"

      assert_select "input[name=?]", "player[active]"

      assert_select "textarea[name=?]", "player[bio]"

      assert_select "textarea[name=?]", "player[photo_urls]"

      assert_select "input[name=?]", "player[team_id]"
    end
  end
end
