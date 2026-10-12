require 'rails_helper'

RSpec.describe "Quest creators" do
  it "keeps an ace's quests when the ace is deleted" do
    ace = create(:ace)
    quest = create(:quest, creator: ace)

    ace.destroy

    expect(quest.reload.creator).to be_nil
  end

  it "lists the quests an ace created" do
    ace = create(:ace)
    quest = create(:quest, creator: ace)
    create(:quest)

    expect(ace.created_quests).to eq([quest])
  end
end
