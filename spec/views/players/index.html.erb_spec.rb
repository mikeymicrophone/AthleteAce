require 'rails_helper'

RSpec.describe "players/index", type: :view do
  before(:each) do
    assign(:players, [
      Player.create!(
        first_name: "First Name",
        last_name: "Last Name",
        nicknames: "Nicknames",
        birth_city: nil,
        birth_country: nil,
        height_ft: 2,
        height_in: 3,
        weight_lb: 4,
        jersey_number: 5,
        current_position: "Current Position",
        debut_year: 6,
        draft_year: 7,
        active: false,
        bio: "MyText",
        photo_urls: "MyText",
        team: nil
      ),
      Player.create!(
        first_name: "First Name",
        last_name: "Last Name",
        nicknames: "Nicknames",
        birth_city: nil,
        birth_country: nil,
        height_ft: 2,
        height_in: 3,
        weight_lb: 4,
        jersey_number: 5,
        current_position: "Current Position",
        debut_year: 6,
        draft_year: 7,
        active: false,
        bio: "MyText",
        photo_urls: "MyText",
        team: nil
      )
    ])
  end

  it "renders a list of players" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("First Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Last Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Nicknames".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(4.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(5.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Current Position".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(6.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(7.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(false.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
