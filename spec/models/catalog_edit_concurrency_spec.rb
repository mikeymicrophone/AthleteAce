require "rails_helper"

RSpec.describe "Concurrent catalog edits" do
  self.use_transactional_tests = false
  after(:context) { DatabaseCleaner.clean_with(:truncation) }

  def committed(&block)
    Thread.new { ActiveRecord::Base.connection_pool.with_connection { block.call } }.value
  end

  def race
    ready, start = Queue.new, Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
          start.pop
          yield index
        end
      end
    end
    connections = 2.times.map { ready.pop }
    2.times { start << true }
    results = threads.map(&:value)
    expect(connections.uniq.size).to eq(2)
    results
  end

  it "permits only one save when different admins submit the same snapshot" do
    player_id, version, admin_ids = committed do
      player = create(:player, first_name: "Jalen", last_name: "Brunson")
      [ player.id, Admin::EditCatalog.version(player), 2.times.map { create(:ace, :admin).id } ]
    end
    results = race do |index|
      begin
        Admin::EditCatalog.call(record: Player.find(player_id), actor: Ace.find(admin_ids[index]),
          attributes: { "first_name" => "Jalen #{index}" }, version: version, request_key: SecureRandom.uuid)
        :saved
      rescue Admin::EditCatalog::Conflict
        :conflict
      end
    end
    expect(results.tally).to eq(saved: 1, conflict: 1)
    expect(CatalogEdit.where(record_type: "Player", record_id: player_id).count).to eq(1)
  end

  it "records a concurrent retry once across separate connections" do
    player_id, version, admin_id = committed do
      player = create(:player, first_name: "Jalen", last_name: "Brunson")
      [ player.id, Admin::EditCatalog.version(player), create(:ace, :admin).id ]
    end
    key = SecureRandom.uuid
    ids = race do
      Admin::EditCatalog.call(record: Player.find(player_id), actor: Ace.find(admin_id),
        attributes: { "first_name" => "Jalen Marquis" }, version: version, request_key: key).id
    end
    expect(ids.uniq.size).to eq(1)
    expect(CatalogEdit.where(record_type: "Player", record_id: player_id).count).to eq(1)
  end

  it "retains one explanation when two tabs explain the same edit" do
    edit_id, admin_id = committed do
      player = create(:player)
      admin = create(:ace, :admin)
      edit = Admin::EditCatalog.call(record: player, actor: admin, attributes: { "first_name" => "Jalen" },
        version: Admin::EditCatalog.version(player), request_key: SecureRandom.uuid)
      [ edit.id, admin.id ]
    end
    results = race do |index|
      begin
        CatalogEdit.find(edit_id).supply_reason!(actor: Ace.find(admin_id), reason: "Official roster source #{index}")
        :saved
      rescue Admin::EditCatalog::Conflict
        :conflict
      end
    end
    expect(results.tally).to eq(saved: 1, conflict: 1)
    expect(CatalogEdit.find(edit_id).reason).to match(/Official roster source [01]/)
  end
end
