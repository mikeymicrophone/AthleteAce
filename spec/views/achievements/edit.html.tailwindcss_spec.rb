require 'rails_helper'

RSpec.describe "achievements/edit", type: :view do
  let(:achievement) {
    Achievement.create!(
      name: "MyString",
      description: "MyText",
      quest: nil,
      target: nil
    )
  }

  before(:each) do
    assign(:achievement, achievement)
  end

  it "renders the edit achievement form" do
    render

    assert_select "form[action=?][method=?]", achievement_path(achievement), "post" do

      assert_select "input[name=?]", "achievement[name]"

      assert_select "textarea[name=?]", "achievement[description]"

      assert_select "input[name=?]", "achievement[quest_id]"

      assert_select "input[name=?]", "achievement[target_id]"
    end
  end
end
