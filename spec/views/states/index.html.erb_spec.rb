require 'rails_helper'

RSpec.describe "states/index", type: :view do
  before(:each) do
    assign(:states, [
      State.create!(
        name: "Name",
        abbreviation: "Abbreviation"
      ),
      State.create!(
        name: "Name",
        abbreviation: "Abbreviation"
      )
    ])
  end

  it "renders a list of states" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Abbreviation".to_s), count: 2
  end
end
