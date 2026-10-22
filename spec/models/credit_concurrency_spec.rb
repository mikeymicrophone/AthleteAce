require "rails_helper"

RSpec.describe "Concurrent credit operations" do
  self.use_transactional_tests = false
  before(:context) { raise "Concurrency fixtures require the test database" unless Rails.env.test? }
  after(:context) { DatabaseCleaner.clean_with(:truncation) }

  def committed(&block)
    Thread.new { ActiveRecord::Base.connection_pool.with_connection { block.call } }.value
  end

  def race
    ready = Queue.new
    start = Queue.new
    threads = 2.times.map do |index|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ready << ActiveRecord::Base.connection.select_value("SELECT pg_backend_pid()")
          start.pop
          yield(index)
        end
      end
    end
    connections = 2.times.map { ready.pop }
    2.times { start << true }
    result = threads.map(&:value)
    expect(connections.uniq.size).to eq(2)
    result
  end

  it "fulfills simultaneous Stripe deliveries once" do
    purchase_id = committed do
      create(:ace).stripe_purchases.create!(amount_cents: 300, request_key: SecureRandom.uuid).id
    end
    race do
      purchase = StripePurchase.find(purchase_id)
      purchase.fulfill!(paid_session(purchase))
    end
    account = CreditAccount.find_by!(ace_id: StripePurchase.find(purchase_id).ace_id)
    expect(account.available_cents).to eq(300)
    expect(account.credit_entries.count).to eq(1)
  end

  it "allows only one reservation when two bids exceed the same available balance" do
    ace_id, draft_ids = committed do
      ace = create(:ace)
      target = create(:player)
      buy_credit(ace, amount: 100)
      drafts = 2.times.map { |index| ace.shout_out_drafts.create!(target: target, message: "Remarkable finish #{index}") }
      [ ace.id, drafts.map(&:id) ]
    end
    outcomes = race do |index|
      begin
        ShoutOutSubmission.call(draft: ShoutOutDraft.find(draft_ids[index]), revision: 0, bid_cents: 75, payment_method: "credit")
        :funded
      rescue ArgumentError
        :declined
      end
    end
    expect(outcomes.tally).to eq(funded: 1, declined: 1)
    account = CreditAccount.find_by!(ace_id: ace_id)
    expect(account.attributes.values_at("available_cents", "reserved_cents")).to eq([ 25, 75 ])
    expect(ShoutOut.where(created_by_id: ace_id).count).to eq(1)
  end

  it "returns the bid only once when report decisions arrive together" do
    post_id, report_id, reviewer_id = committed do
      author = create(:ace)
      reviewer = create(:ace, moderator: true)
      buy_credit(author)
      post = submit_credit(ace: author, target: create(:player), bid: 125)
      review_post(post, action: "approve", reviewer: reviewer)
      report = post.shout_out_reports.create!(reporter: create(:ace), reason: "Spam")
      [ post.id, report.id, reviewer.id ]
    end
    results = race do
      begin
        post = ShoutOut.find(post_id)
        Moderation::ResolveReports.call(post: post, actor: Ace.find(reviewer_id), action: "hide",
          revision: 1, last_report_id: report_id, reason: "Off topic")
        :hidden
      rescue Moderation::Review::Conflict
        :stale
      end
    end
    expect(results.tally).to eq(hidden: 1, stale: 1)
    post = ShoutOut.find(post_id)
    expect(CreditAccount.for(post.created_by).available_cents).to eq(1000)
    expect(CreditEntry.where(source: post, kind: "refund").count).to eq(1)
    expect(ShoutOutReport.find(report_id).resolution).to eq("hidden")
  end

  it "enforces one report per ace and post even for simultaneous inserts" do
    post_id, reporter_id = committed do
      author = create(:ace)
      buy_credit(author)
      post = submit_credit(ace: author, target: create(:player))
      review_post(post, action: "approve")
      [ post.id, create(:ace).id ]
    end
    results = race do
      begin
        ShoutOutReport.create!(shout_out_id: post_id, reporter_id: reporter_id, reason: "Spam")
        :created
      rescue ActiveRecord::RecordNotUnique
        :duplicate
      end
    end
    expect(results.tally).to eq(created: 1, duplicate: 1)
    expect(ShoutOutReport.where(shout_out_id: post_id, reporter_id: reporter_id).count).to eq(1)
  end
end
