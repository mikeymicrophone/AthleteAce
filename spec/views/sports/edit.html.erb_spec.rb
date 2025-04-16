require 'rails_helper'

RSpec.describe "sports/edit", type: :view do
  let(:sport) {
    Sport.create!(
      name: "MyString",
      description: "MyText"
    )
  }

  before(:each) do
    assign(:sport, sport)
  end

  it "renders the edit sport form" do
    render

    assert_select "form[action=?][method=?]", sport_path(sport), "post" do

      assert_select "input[name=?]", "sport[name]"

      assert_select "textarea[name=?]", "sport[description]"
    end
  end
end
