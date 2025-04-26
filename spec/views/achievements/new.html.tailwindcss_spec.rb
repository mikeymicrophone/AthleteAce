require 'rails_helper'

RSpec.describe "achievements/new", type: :view do
  before(:each) do
    assign(:achievement, Achievement.new(
      name: "MyString",
      description: "MyText",
      quest: nil,
      target: nil
    ))
  end

  it "renders new achievement form" do
    render

    assert_select "form[action=?][method=?]", achievements_path, "post" do

      assert_select "input[name=?]", "achievement[name]"

      assert_select "textarea[name=?]", "achievement[description]"

      assert_select "input[name=?]", "achievement[quest_id]"

      assert_select "input[name=?]", "achievement[target_id]"
    end
  end
end
