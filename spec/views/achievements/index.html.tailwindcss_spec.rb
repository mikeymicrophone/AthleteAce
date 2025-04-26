require 'rails_helper'

RSpec.describe "achievements/index", type: :view do
  before(:each) do
    assign(:achievements, [
      Achievement.create!(
        name: "Name",
        description: "MyText",
        quest: nil,
        target: nil
      ),
      Achievement.create!(
        name: "Name",
        description: "MyText",
        quest: nil,
        target: nil
      )
    ])
  end

  it "renders a list of achievements" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
