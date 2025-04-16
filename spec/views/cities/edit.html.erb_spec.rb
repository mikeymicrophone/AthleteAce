require 'rails_helper'

RSpec.describe "cities/edit", type: :view do
  let(:city) {
    City.create!(
      name: "MyString",
      state: nil
    )
  }

  before(:each) do
    assign(:city, city)
  end

  it "renders the edit city form" do
    render

    assert_select "form[action=?][method=?]", city_path(city), "post" do

      assert_select "input[name=?]", "city[name]"

      assert_select "input[name=?]", "city[state_id]"
    end
  end
end
