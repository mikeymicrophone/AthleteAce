require 'rails_helper'

RSpec.describe "countries/index", type: :view do
  before(:each) do
    assign(:countries, [
      Country.create!(
        name: "Name",
        abbreviation: "Abbreviation"
      ),
      Country.create!(
        name: "Name",
        abbreviation: "Abbreviation"
      )
    ])
  end

  it "renders a list of countries" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Abbreviation".to_s), count: 2
  end
end
