require 'rails_helper'

RSpec.describe "quests/show", type: :view do
  before(:each) do
    assign(:quest, Quest.create!(
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
