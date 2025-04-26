require 'rails_helper'

RSpec.describe "federations/new", type: :view do
  before(:each) do
    assign(:federation, Federation.new(
      name: "MyString",
      abbreviation: "MyString",
      description: "MyText",
      url: "MyString",
      logo_url: "MyString"
    ))
  end

  it "renders new federation form" do
    render

    assert_select "form[action=?][method=?]", federations_path, "post" do

      assert_select "input[name=?]", "federation[name]"

      assert_select "input[name=?]", "federation[abbreviation]"

      assert_select "textarea[name=?]", "federation[description]"

      assert_select "input[name=?]", "federation[url]"

      assert_select "input[name=?]", "federation[logo_url]"
    end
  end
end
