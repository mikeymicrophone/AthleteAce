require 'rails_helper'

RSpec.describe "stadia/index", type: :view do
  before(:each) do
    assign(:stadia, [
      Stadium.create!(
        name: "Name",
        city: nil,
        capacity: 2,
        opened_year: 3,
        url: "Url",
        address: "Address"
      ),
      Stadium.create!(
        name: "Name",
        city: nil,
        capacity: 2,
        opened_year: 3,
        url: "Url",
        address: "Address"
      )
    ])
  end

  it "renders a list of stadia" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(3.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Address".to_s), count: 2
  end
end
