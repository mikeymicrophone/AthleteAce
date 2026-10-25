require "rails_helper"

RSpec.describe Person do
  it "gives new athletes a separate identity without changing their athletic profile" do
    player = create :player, first_name: "Jordan", last_name: "Reyes", entity_code: "PLAYER-REYES_JORDAN"
    expect(player.person.name).to eq("Jordan Reyes")
    expect(player.person.entity_code).to eq("PERSON-PLAYER-REYES_JORDAN")
    expect(player.person.player).to eq(player)
    expect(player.reload.entity_code).to eq("PLAYER-REYES_JORDAN")
  end

  it "allows staff without athletic profiles and keeps same-name people distinct" do
    first = create :person, name: "Alex Morgan"
    second = create :person, name: first.name
    expect(first.player).to be_nil
    expect(second).not_to eq(first)
    expect(build(:person, player: nil)).to be_valid
  end

  it "allows only one person to link an athletic profile at the model and database boundary" do
    player = create :player
    duplicate = build :person, player: player
    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:player_id]).to be_present
    expect { Person.transaction(requires_new: true) { duplicate.save!(validate: false) } }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "preserves a person and their appointments when an athletic profile is rebuilt" do
    player = create :player, entity_code: "PLAYER-REYES_JORDAN"
    person = player.person
    tenure = create :staff_tenure, :broadcaster, person: person
    player.delete
    expect(person.reload.player).to be_nil
    replacement = create :player, entity_code: "PLAYER-REYES_JORDAN"
    expect(replacement.person).to eq(person)
    expect(tenure.reload.person).to eq(person)
  end

  it "keeps career identity when a player transfers or changes their profile name" do
    player = create :player
    original = player.person
    player.update! team: create(:team), first_name: "Jordán"
    expect(player.person.reload).to eq(original)
    expect(player.person.name).to eq(original.name)
  end

  it "restricts deletion while appointments refer to a person" do
    tenure = create :staff_tenure
    expect(tenure.person.destroy).to be_falsey
    expect(tenure.reload.person).to be_persisted
  end
end
