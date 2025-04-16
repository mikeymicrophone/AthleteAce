require 'rails_helper'

RSpec.describe "stadia/new", type: :view do
  before(:each) do
    assign(:stadium, Stadium.new(
      name: "MyString",
      city: nil,
      capacity: 1,
      opened_year: 1,
      url: "MyString",
      address: "MyString"
    ))
  end

  it "renders new stadium form" do
    render

    assert_select "form[action=?][method=?]", stadia_path, "post" do

      assert_select "input[name=?]", "stadium[name]"

      assert_select "input[name=?]", "stadium[city_id]"

      assert_select "input[name=?]", "stadium[capacity]"

      assert_select "input[name=?]", "stadium[opened_year]"

      assert_select "input[name=?]", "stadium[url]"

      assert_select "input[name=?]", "stadium[address]"
    end
  end
end
