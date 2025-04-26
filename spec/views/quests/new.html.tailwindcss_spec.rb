require 'rails_helper'

RSpec.describe "quests/new", type: :view do
  before(:each) do
    assign(:quest, Quest.new(
      name: "MyString",
      description: "MyText"
    ))
  end

  it "renders new quest form" do
    render

    assert_select "form[action=?][method=?]", quests_path, "post" do

      assert_select "input[name=?]", "quest[name]"

      assert_select "textarea[name=?]", "quest[description]"
    end
  end
end
