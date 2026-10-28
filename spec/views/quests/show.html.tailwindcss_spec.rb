require 'rails_helper'

RSpec.describe "quests/show", type: :view do
  before(:each) do
    # A helper_method from ApplicationController, which view specs don't include
    view.define_singleton_method(:can_manage?) { |_record| false }
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
