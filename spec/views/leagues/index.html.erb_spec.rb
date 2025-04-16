require 'rails_helper'

RSpec.describe "leagues/index", type: :view do
  before(:each) do
    assign(:leagues, [
      League.create!(
        name: "Name",
        url: "Url",
        ios_app_url: "Ios App Url",
        year_of_origin: 2,
        official_rules_url: "Official Rules Url",
        sport: nil
      ),
      League.create!(
        name: "Name",
        url: "Url",
        ios_app_url: "Ios App Url",
        year_of_origin: 2,
        official_rules_url: "Official Rules Url",
        sport: nil
      )
    ])
  end

  it "renders a list of leagues" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Ios App Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(2.to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Official Rules Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new(nil.to_s), count: 2
  end
end
