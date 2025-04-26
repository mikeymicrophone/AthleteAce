require 'rails_helper'

RSpec.describe "federations/show", type: :view do
  before(:each) do
    assign(:federation, Federation.create!(
      name: "Name",
      abbreviation: "Abbreviation",
      description: "MyText",
      url: "Url",
      logo_url: "Logo Url"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Abbreviation/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(/Url/)
    expect(rendered).to match(/Logo Url/)
  end
end
