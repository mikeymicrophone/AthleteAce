require 'rails_helper'

RSpec.describe "quests/index", type: :view do
  before(:each) do
    assign(:quests, [
      Quest.create!(
        name: "Name",
        description: "MyText"
      ),
      Quest.create!(
        name: "Name",
        description: "MyText"
      )
    ])
  end

  it "renders a list of quests" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
  end
end
