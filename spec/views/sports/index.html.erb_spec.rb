require 'rails_helper'

RSpec.describe "sports/index", type: :view do
  before(:each) do
    assign(:sports, [
      Sport.create!(
        name: "Name",
        description: "MyText"
      ),
      Sport.create!(
        name: "Name",
        description: "MyText"
      )
    ])
  end

  it "renders a list of sports" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
