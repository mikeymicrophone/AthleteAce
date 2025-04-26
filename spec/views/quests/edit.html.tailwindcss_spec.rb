require 'rails_helper'

RSpec.describe "quests/edit", type: :view do
  let(:quest) {
    Quest.create!(
      name: "MyString",
      description: "MyText"
    )
  }

  before(:each) do
    assign(:quest, quest)
  end

  it "renders the edit quest form" do
    render

    assert_select "form[action=?][method=?]", quest_path(quest), "post" do

      assert_select "input[name=?]", "quest[name]"

      assert_select "textarea[name=?]", "quest[description]"
    end
  end
end
