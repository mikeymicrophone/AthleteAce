require "rails_helper"

RSpec.describe "Concurrent escalation decisions" do
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

  it "allows one open handoff when different requests race" do
    subject_id, reviewer_id = committed { [ create(:quest, created_by: create(:ace)).id, create(:ace, moderator: true).id ] }
    results = race do
      begin
        Moderation::Escalate.call(subject: Quest.find(subject_id), actor: Ace.find(reviewer_id), reason: "Check the roster scope",
          request_key: SecureRandom.uuid, revision: 1, status: "pending")
        :created
      rescue Moderation::Review::Conflict
        :conflict
      end
    end
    expect(results.tally).to eq(created: 1, conflict: 1)
    expect(ModerationEscalation.open.where(subject_type: "Quest", subject_id: subject_id).count).to eq(1)
  end

  it "reuses a repeated handoff across independent connections" do
    subject_id, reviewer_id = committed { [ create(:quest, created_by: create(:ace)).id, create(:ace, moderator: true).id ] }
    key = SecureRandom.uuid
    ids = race do
      Moderation::Escalate.call(subject: Quest.find(subject_id), actor: Ace.find(reviewer_id), reason: "Check the roster scope",
        request_key: key, revision: 1, status: "pending").id
    end
    expect(ids.uniq.size).to eq(1)
  end

  it "records one resolution and full credit refund when two admins hide the same post" do
    case_id, post_id, author_id, admin_ids = committed do
      author = create(:ace)
      reviewer = create(:ace, moderator: true)
      buy_credit(author)
      post = submit_credit(ace: author, target: create(:player), bid: 175)
      review_post(post, action: "approve", reviewer: reviewer)
      record = Moderation::Escalate.call(subject: post, actor: reviewer, reason: "Review its relevance",
        request_key: SecureRandom.uuid, revision: 1, status: "approved")
      [ record.id, post.id, author.id, 2.times.map { create(:ace, :admin).id } ]
    end
    results = race do |index|
      begin
        Moderation::ResolveEscalation.call(escalation: ModerationEscalation.find(case_id), actor: Ace.find(admin_ids[index]),
          resolution: "hide", reason: "Unrelated promotion", version: 0)
        :resolved
      rescue Moderation::Review::Conflict
        :conflict
      end
    end
    expect(results.tally).to eq(resolved: 1, conflict: 1)
    expect(ModerationEscalation.find(case_id).resolved_at).to be_present
    expect(ShoutOut.find(post_id).funding_status).to eq("refunded")
    expect(CreditEntry.where(source_type: "ShoutOut", source_id: post_id, kind: "refund").count).to eq(1)
    expect(CreditAccount.for(Ace.find(author_id)).available_cents).to eq(1000)
  end
end
