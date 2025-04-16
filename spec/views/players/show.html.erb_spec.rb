require 'rails_helper'

RSpec.describe "players/show", type: :view do
  before(:each) do
    assign(:player, Player.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/Nicknames/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/Current Position/)
    expect(rendered).to match(/6/)
    expect(rendered).to match(/7/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
  end
end
