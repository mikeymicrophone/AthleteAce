require 'rails_helper'

RSpec.describe "cities/show", type: :view do
  before(:each) do
    assign(:city, City.create!(
      name: "Name",
      state: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(//)
  end
end
