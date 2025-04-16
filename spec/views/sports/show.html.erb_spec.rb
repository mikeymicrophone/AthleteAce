require 'rails_helper'

RSpec.describe "sports/show", type: :view do
  before(:each) do
    assign(:sport, Sport.create!(
      name: "Name",
      description: "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
  end
end
