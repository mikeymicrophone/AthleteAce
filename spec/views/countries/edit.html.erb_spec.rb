require 'rails_helper'

RSpec.describe "countries/edit", type: :view do
  let(:country) {
    Country.create!(
      name: "MyString",
      abbreviation: "MyString"
    )
  }

  before(:each) do
    assign(:country, country)
  end

  it "renders the edit country form" do
    render

    assert_select "form[action=?][method=?]", country_path(country), "post" do

      assert_select "input[name=?]", "country[name]"

      assert_select "input[name=?]", "country[abbreviation]"
    end
  end
end
