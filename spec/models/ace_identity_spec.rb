require "rails_helper"

RSpec.describe Ace, type: :model do
  it "normalizes handles and trims display names" do
    ace = create(:ace, username: "  Courtside_Tess  ", display_name: "  Tess Moreno  ")
    expect(ace.reload.username).to eq("courtside_tess")
    expect(ace.handle).to eq("@courtside_tess")
    expect(ace.public_name).to eq("Tess Moreno")
    expect(ace.initials).to eq("TM")
  end

  it "requires a handle and display name for new accounts" do
    ace = build(:ace, username: nil, display_name: nil)
    expect(ace).not_to be_valid
    expect(ace.errors[:username]).to be_present
    ace.username = "courtside_tess"
    expect(ace).not_to be_valid
    expect(ace.errors[:display_name]).to be_present
  end

  it "rejects duplicate handles without regard to case" do
    create(:ace, username: "courtside_tess")
    ace = build(:ace, username: "COURTSIDE_TESS")
    expect(ace).not_to be_valid
    expect(ace.errors[:username]).to include("has already been taken")
  end

  it "enforces case-insensitive uniqueness in the database" do
    create(:ace, username: "courtside_tess")
    other = create(:ace)
    expect {
      Ace.transaction(requires_new: true) { other.update_columns(username: "COURTSIDE_TESS") }
    }.to raise_error(ActiveRecord::RecordNotUnique)
  end

  %w[ab name-with-dashes @tess tess.moreno café admin MODERATOR AthleteAce].each do |username|
    it "rejects the invalid or reserved handle #{username}" do
      expect(build(:ace, username: username)).not_to be_valid
    end
  end

  it "enforces handle and display-name limits" do
    expect(build(:ace, username: "a" * 24, display_name: "T" * 60)).to be_valid
    expect(build(:ace, username: "a" * 25)).not_to be_valid
    expect(build(:ace, display_name: "T" * 61)).not_to be_valid
  end

  it "keeps handles fixed while allowing name and avatar changes" do
    ace = create(:ace, username: "courtside_tess")
    expect(ace.update(username: "renamed_tess")).to be(false)
    expect(ace.errors[:username]).to include("cannot be changed")
    ace.reload.update! display_name: "Tess Rivera", avatar_color: Ace::AVATAR_COLORS.fetch("Harbor")
    expect(ace.initials).to eq("TR")
    expect(ace.username).to eq("courtside_tess")
  end

  it "supports old accounts until they choose an identity without exposing email" do
    ace = create(:ace, :without_identity)
    expect(ace.update(theme: "dark")).to be(true)
    expect(ace.public_name).to eq("Ace")
    expect(ace.initials).to eq("A")
    ace.update! username: "bleacher_sam", display_name: "Sam Carter"
    expect(ace.reload.handle).to eq("@bleacher_sam")
  end

  it "rejects unrecognized avatar colors" do
    expect(build(:ace, avatar_color: "red; background: url(https://example.net)")).not_to be_valid
  end
end
