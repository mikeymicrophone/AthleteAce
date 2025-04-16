require 'rails_helper'

RSpec.describe "countries/show", type: :view do
  before(:each) do
    assign(:country, Country.create!(
      name: "Name",
      abbreviation: "Abbreviation"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Abbreviation/)
  end
end
