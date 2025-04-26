require 'rails_helper'

RSpec.describe "federations/index", type: :view do
  before(:each) do
    assign(:federations, [
      Federation.create!(
        name: "Name",
        abbreviation: "Abbreviation",
        description: "MyText",
        url: "Url",
        logo_url: "Logo Url"
      ),
      Federation.create!(
        name: "Name",
        abbreviation: "Abbreviation",
        description: "MyText",
        url: "Url",
        logo_url: "Logo Url"
      )
    ])
  end

  it "renders a list of federations" do
    render
    cell_selector = 'div>p'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Abbreviation".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("MyText".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Url".to_s), count: 2
    assert_select cell_selector, text: Regexp.new("Logo Url".to_s), count: 2
  end
end
