require 'rails_helper'

RSpec.describe "stadia/edit", type: :view do
  let(:stadium) {
    Stadium.create!(
      name: "MyString",
      city: nil,
      capacity: 1,
      opened_year: 1,
      url: "MyString",
      address: "MyString"
    )
  }

  before(:each) do
    assign(:stadium, stadium)
  end

  it "renders the edit stadium form" do
    render

    assert_select "form[action=?][method=?]", stadium_path(stadium), "post" do

      assert_select "input[name=?]", "stadium[name]"

      assert_select "input[name=?]", "stadium[city_id]"

      assert_select "input[name=?]", "stadium[capacity]"

      assert_select "input[name=?]", "stadium[opened_year]"

      assert_select "input[name=?]", "stadium[url]"

      assert_select "input[name=?]", "stadium[address]"
    end
  end
end
