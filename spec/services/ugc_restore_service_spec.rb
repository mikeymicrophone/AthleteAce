require 'rails_helper'

RSpec.describe UgcRestoreService do
  let(:backup_dir) { Pathname.new(Dir.mktmpdir("ugc_backup")) }

  after { FileUtils.remove_entry(backup_dir) }

  def write_backup(aces:, quests:)
    File.write(backup_dir.join("aces_and_ratings.yml"), { "aces" => aces, "spectrums" => [], "ratings" => [] }.to_yaml)
    File.write(backup_dir.join("quest_system.yml"), { "quests" => quests, "orphaned_achievements" => [] }.to_yaml)
    File.write(backup_dir.join("game_attempts.yml"), { "game_attempts" => [] }.to_yaml)
  end

  def quest_data(name, creator_id)
    { "id" => 1, "name" => name, "description" => "From a backup", "creator_id" => creator_id,
      "achievements" => [], "highlights" => [], "goals" => [] }
  end

  it "maps quest creators through the backup's aces by email" do
    ace = create(:ace)
    # The backup's ids don't match this database's
    write_backup aces: [{ "id" => ace.id + 1000, "email" => ace.email }],
                 quests: [quest_data("Restored Quest", ace.id + 1000)]

    described_class.new(backup_dir).restore_all

    expect(Quest.find_by!(name: "Restored Quest").creator).to eq(ace)
  end

  it "restores quests without a creator" do
    write_backup aces: [], quests: [quest_data("Seeded Quest", nil)]

    described_class.new(backup_dir).restore_all

    expect(Quest.find_by!(name: "Seeded Quest").creator).to be_nil
  end
end
