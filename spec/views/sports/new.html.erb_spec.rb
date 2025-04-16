require 'rails_helper'

RSpec.describe "sports/new", type: :view do
  before(:each) do
    assign(:sport, Sport.new(
      name: "MyString",
      description: "MyText"
    ))
  end

  it "renders new sport form" do
    render

    assert_select "form[action=?][method=?]", sports_path, "post" do

      assert_select "input[name=?]", "sport[name]"

      assert_select "textarea[name=?]", "sport[description]"
    end
  end
end
