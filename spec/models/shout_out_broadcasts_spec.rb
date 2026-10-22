require "rails_helper"

RSpec.describe "Public Feed broadcasts" do
  self.use_transactional_tests = false
  after(:context) { DatabaseCleaner.clean_with(:truncation) }

  def committed(&block)
    Thread.new { ActiveRecord::Base.connection_pool.with_connection { block.call } }.value
  end

  def broadcasts
    ActionCable.server.pubsub.broadcasts("public_shout_outs")
  end

  before { broadcasts.clear }

  it "announces approval only after the outer transaction commits, without any post content" do
    committed do
      author = create(:ace)
      buy_credit(author)
      post = submit_credit(ace: author, target: create(:player), message: "Determination in every inning")
      expect(broadcasts).to be_empty
      Turbo.with_request_id("private-moderation-request") do
        ShoutOut.transaction do
          review_post(post, action: "approve")
          expect(broadcasts).to be_empty
        end
      end
      expect(broadcasts.size).to eq(1)
      stream = Nokogiri::HTML.fragment(ActiveSupport::JSON.decode(broadcasts.sole)).at_css("turbo-stream")
      expect(stream["action"]).to eq("refresh")
      expect(stream.children).to be_empty
      expect(stream.attributes.keys).to eq([ "action" ])
    end
  end

  it "does not announce a rolled-back approval or spend its reserved credit" do
    committed do
      author = create(:ace)
      buy_credit(author)
      post = submit_credit(ace: author, target: create(:player))
      ShoutOut.transaction do
        review_post(post, action: "approve")
        raise ActiveRecord::Rollback
      end
      expect(broadcasts).to be_empty
      expect(post.reload.moderation_status).to eq("pending")
      expect(post.funding_status).to eq("reserved")
      expect(CreditAccount.for(author).reserved_cents).to eq(post.bid_cents)
    end
  end

  it "announces a committed removal, while rejection and reactions send no public refresh" do
    committed do
      author = create(:ace)
      buy_credit(author)
      post = submit_credit(ace: author, target: create(:team))
      review_post(post, action: "approve")
      broadcasts.clear
      post.shout_out_reactions.create!(ace: author, kind: "fire")
      expect(broadcasts).to be_empty
      review_post(post, action: "hide")
      expect(broadcasts.size).to eq(1)
      expect(post.reload.funding_status).to eq("refunded")
      broadcasts.clear
      pending = submit_credit(ace: author, target: post.target)
      review_post(pending, action: "reject")
      expect(broadcasts).to be_empty
    end
  end
end
