require "rails_helper"

RSpec.describe "Concurrent posting moderation" do
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

  it "serializes different mute requests and never silently extends an active mute" do
    ace_id, reviewer_id = committed { [ create(:ace).id, create(:ace, moderator: true).id ] }
    results = race do
      begin
        Moderation::PostingAction.call(ace: Ace.find(ace_id), actor: Ace.find(reviewer_id), kind: "mute",
          attributes: { request_key: SecureRandom.uuid, reason: "Stay on topic", duration_hours: "168" })
        :muted
      rescue Moderation::Review::Conflict
        :conflict
      end
    end
    expect(results.tally).to eq(muted: 1, conflict: 1)
    expect(Mute.where(ace_id: ace_id).count).to eq(1)
  end

  it "reuses the same warning request across independent connections" do
    ace_id, reviewer_id = committed { [ create(:ace).id, create(:ace, moderator: true).id ] }
    key = SecureRandom.uuid
    ids = race do
      Moderation::PostingAction.call(ace: Ace.find(ace_id), actor: Ace.find(reviewer_id), kind: "warn",
        attributes: { request_key: key, reason: "Keep proposals specific" }).id
    end
    expect(ids.uniq.size).to eq(1)
    expect(PostingWarning.where(ace_id: ace_id).count).to eq(1)
  end

  it "blocks an already-open draft after a concurrent mute commits, without reserving credit" do
    ace_id, reviewer_id, draft_id = committed do
      ace = create(:ace)
      buy_credit(ace)
      draft = ace.shout_out_drafts.create!(target: create(:player), message: "A game to remember")
      [ ace.id, create(:ace, moderator: true).id, draft.id ]
    end
    muted, release, submitting = Queue.new, Queue.new, Queue.new
    mutator = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ace = Ace.find(ace_id)
        ace.with_lock do
          Moderation::PostingAction.call(ace: ace, actor: Ace.find(reviewer_id), kind: "mute",
            attributes: { request_key: SecureRandom.uuid, reason: "Pause new posts", duration_hours: "24" })
          muted << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
          release.pop
        end
      end
    end
    mutator_pid = muted.pop
    submitter = Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        draft = ShoutOutDraft.find(draft_id)
        submitting << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
        begin
          ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 100, payment_method: "credit")
          :submitted
        rescue Ace::PostingMuted
          :blocked
        end
      end
    end
    submitter_pid = submitting.pop
    begin
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
      loop do
        blocked = ActiveRecord::Base.connection.select_value("SELECT #{mutator_pid} = ANY(pg_blocking_pids(#{submitter_pid}))")
        break if blocked
        raise "Submission did not wait for the account lock" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        Thread.pass
      end
      expect(mutator_pid).not_to eq(submitter_pid)
    ensure
      release << true
      mutator.value
    end
    expect(submitter.value).to eq(:blocked)
    expect(ShoutOut.where(created_by_id: ace_id).count).to eq(0)
    account = CreditAccount.for(Ace.find(ace_id))
    expect(account.available_cents).to eq(1000)
    expect(account.reserved_cents).to eq(0)
  end
end
