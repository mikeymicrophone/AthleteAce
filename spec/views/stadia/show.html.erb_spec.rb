require 'rails_helper'

RSpec.describe "stadia/show", type: :view do
  before(:each) do
    assign(:stadium, Stadium.create!(
      name: "Name",
      city: nil,
      capacity: 2,
      opened_year: 3,
      url: "Url",
      address: "Address"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Url/)
    expect(rendered).to match(/Address/)
  end
end
