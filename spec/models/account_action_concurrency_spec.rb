require "rails_helper"

RSpec.describe "Concurrent account administration" do
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
    values = threads.map(&:value)
    expect(connections.uniq.size).to eq(2)
    values
  end

  it "prevents reciprocal demotions from removing both admins" do
    ids = committed { 2.times.map { create(:ace, :admin).id } }
    results = race do |index|
      begin
        Admin::ChangeAccount.call(ace: Ace.find(ids[1 - index]), actor: Ace.find(ids[index]), action: "role", role: "fan",
          reason: "End admin duties", password: "password123", request_key: SecureRandom.uuid, version: 0)
        :changed
      rescue Moderation::Review::Forbidden
        :forbidden
      end
    end
    expect(results.tally).to eq(changed: 1, forbidden: 1)
    expect(Ace.where(id: ids, admin: true, suspended_at: nil).count).to eq(1)
  end

  it "records a retried role request once across independent connections" do
    admin_id, ace_id = committed { [ create(:ace, :admin).id, create(:ace).id ] }
    key = SecureRandom.uuid
    ids = race do
      Admin::ChangeAccount.call(ace: Ace.find(ace_id), actor: Ace.find(admin_id), action: "role", role: "moderator",
        reason: "Help review proposals", password: "password123", request_key: key, version: 0).id
    end
    expect(ids.uniq.size).to eq(1)
    expect(Ace.find(ace_id).account_version).to eq(1)
  end

  it "prevents concurrent account deletions from removing the last active admin" do
    ids = committed do
      Ace.where(admin: true).update_all(admin: false)
      2.times.map { create(:ace, :admin).id }
    end
    results = race { |index| !!Ace.find(ids[index]).destroy }
    expect(results.tally).to eq(true => 1, false => 1)
    expect(Ace.where(id: ids, admin: true, suspended_at: nil).count).to eq(1)
  end

  it "blocks a pending submission after suspension acquires the account lock" do
    admin_id, ace_id = committed { [ create(:ace, :admin).id, create(:ace).id ] }
    suspended, release, submitting = Queue.new, Queue.new, Queue.new
    suspender = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        Ace.transaction do
          Admin::ChangeAccount.call(ace: Ace.find(ace_id), actor: Ace.find(admin_id), action: "suspend",
            reason: "Review account access", password: "password123", request_key: SecureRandom.uuid, version: 0)
          suspended << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
          release.pop
        end
      end
    end
    suspender_pid = suspended.pop
    submitter = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ace = Ace.find(ace_id)
        submitting << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
        begin
          create(:quest, created_by: ace)
          :submitted
        rescue Ace::AccountSuspended
          :blocked
        end
      end
    end
    submitter_pid = submitting.pop
    begin
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      loop do
        blocked = ActiveRecord::Base.connection.select_value("SELECT #{suspender_pid} = ANY(pg_blocking_pids(#{submitter_pid}))")
        break if blocked
        raise "Submission did not wait for the account lock" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        Thread.pass
      end
      expect(submitter_pid).not_to eq(suspender_pid)
    ensure
      release << true
      suspender.value
    end
    expect(submitter.value).to eq(:blocked)
    expect(Quest.where(created_by_id: ace_id).count).to eq(0)
  end
end
