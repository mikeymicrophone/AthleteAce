require 'rails_helper'

RSpec.describe "achievements/show", type: :view do
  before(:each) do
    assign(:achievement, Achievement.create!(
      name: "Name",
      description: "MyText",
      quest: nil,
      target: nil
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/MyText/)
    expect(rendered).to match(//)
    expect(rendered).to match(//)
  end
end
