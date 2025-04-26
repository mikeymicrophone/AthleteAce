require 'rails_helper'

RSpec.describe "federations/edit", type: :view do
  let(:federation) {
    Federation.create!(
      name: "MyString",
      abbreviation: "MyString",
      description: "MyText",
      url: "MyString",
      logo_url: "MyString"
    )
  }

  before(:each) do
    assign(:federation, federation)
  end

  it "renders the edit federation form" do
    render

    assert_select "form[action=?][method=?]", federation_path(federation), "post" do

      assert_select "input[name=?]", "federation[name]"

      assert_select "input[name=?]", "federation[abbreviation]"

      assert_select "textarea[name=?]", "federation[description]"

      assert_select "input[name=?]", "federation[url]"

      assert_select "input[name=?]", "federation[logo_url]"
    end
  end
end
