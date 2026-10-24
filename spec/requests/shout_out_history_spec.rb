require "rails_helper"

RSpec.describe "My shout-out history", type: :request do
  let(:ace) { create(:ace) }
  let(:target) { create(:player, team: create(:team)) }

  def stripe_submission(message: "Awaiting card payment")
    draft = ace.shout_out_drafts.create!(target: target, message: message)
    ShoutOutSubmission.call(draft: draft, revision: 0, bid_cents: 500, payment_method: "stripe")
  end

  it "filters owned submissions by their funding and moderation state, with unfiltered private totals" do
    buy_credit(ace, amount: 10_000)
    pending = submit_credit(ace: ace, target: target, message: "Review this finish", bid: 100)
    live = submit_credit(ace: ace, target: target, message: "A live celebration", bid: 250)
    review_post(live, action: "approve")
    rejected = submit_credit(ace: ace, target: target, message: "A rejected submission", bid: 300)
    review_post(rejected, action: "reject")
    hidden = submit_credit(ace: ace, target: target, message: "A removed celebration", bid: 400)
    review_post(hidden, action: "approve")
    review_post(hidden, action: "hide")
    unpaid = stripe_submission
    stranger = create(:ace)
    buy_credit(stranger)
    foreign = submit_credit(ace: stranger, target: target, message: "Another person's private post", bid: 999)
    sign_in ace

    { "awaiting_payment" => unpaid, "in_review" => pending, "live" => live, "rejected" => rejected, "hidden" => hidden }.each do |status, selected|
      get shout_outs_path, params: { status: status, created_by_id: stranger.id }
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("private", "no-store")
      document = Nokogiri::HTML(response.body)
      expect(document.css("article .draft-message").map(&:text)).to eq([ selected.message ])
      expect(document.at_css('[aria-label="Filter your shout-outs"] [aria-current="page"]').text).to include(ShoutOutsController::HISTORY_FILTERS.fetch(status).fetch(:label))
      expect(document.css('[aria-label="Filter your shout-outs"] a').map(&:text)).to eq([
        "All (5)", "Awaiting payment (1)", "In review (1)", "Live (1)", "Rejected (1)", "Hidden (1)"
      ])
      { "unfunded" => "$5.00", "reserved" => "$1.00", "spent" => "$2.50", "refunded" => "$7.00" }.each do |funding, amount|
        expect(document.at_css("[data-bid-total='#{funding}']").text).to eq(amount)
      end
      expect(response.body).not_to include(foreign.message)
    end
  end

  it "preserves the filter through stable pagination and distinguishes an empty filter from an empty history" do
    buy_credit(ace)
    6.times { |index| submit_credit(ace: ace, target: target, message: "Waiting post #{index}") }
    sign_in ace
    get shout_outs_path, params: { status: "in_review" }
    document = Nokogiri::HTML(response.body)
    first_messages = document.css("article .draft-message").map(&:text)
    expect(first_messages.size).to eq(5)
    next_page = document.css("a").find { |node| node["href"]&.include?("page=2") }
    expect(next_page["href"]).to include("status=in_review")
    get next_page["href"]
    second_messages = Nokogiri::HTML(response.body).css("article .draft-message").map(&:text)
    expect(second_messages.size).to eq(1)
    expect(first_messages & second_messages).to be_empty
    get shout_outs_path, params: { status: "live" }
    expect(response.body).to include("No shout-outs in this status.")
    expect(response.body).not_to include("No shout-outs yet.")
    get shout_outs_path, params: { status: "not_a_status" }
    expect(response).to have_http_status(:bad_request)
    sign_out ace
    get shout_outs_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "copies the submitted snapshot into a new owned draft without changing funding or the original post" do
    buy_credit(ace)
    original = submit_credit(ace: ace, target: target, message: "A spectacular finish", bid: 250)
    original.shout_out_draft.update!(message: "A later edit to the old draft")
    snapshot = original.reload.attributes
    account = CreditAccount.for(ace)
    balance = account.attributes
    ledger_count = CreditEntry.count
    sign_in ace
    expect {
      post copy_to_draft_shout_out_path(original), params: { created_by_id: create(:ace).id, message: "Injected replacement", bid: "9.99" }
    }.to change(ShoutOutDraft, :count).by(1).and change(ShoutOut, :count).by(0)
    draft = ace.shout_out_drafts.order(:id).last
    expect(response).to redirect_to(edit_shout_out_draft_path(draft))
    expect(draft.message).to eq("A spectacular finish")
    expect(draft.target).to eq(target)
    expect(draft).not_to eq(original.shout_out_draft)
    expect(draft.shout_outs).to be_empty
    expect(original.reload.attributes).to eq(snapshot)
    expect(account.reload.attributes).to eq(balance)
    expect(CreditEntry.count).to eq(ledger_count)
  end

  it "rejects foreign copies, blocks muted accounts, and handles a deleted target without creating a draft" do
    original = stripe_submission
    stranger = create(:ace)
    sign_in stranger
    expect { post copy_to_draft_shout_out_path(original) }.not_to change(ShoutOutDraft, :count)
    expect(response).to have_http_status(:not_found)
    sign_out stranger
    sign_in ace
    mute = ace.mutes.create!(reason: "Pause posting", request_key: SecureRandom.uuid, starts_at: 1.hour.ago, ends_at: 23.hours.from_now, duration_hours: 24)
    expect { post copy_to_draft_shout_out_path(original) }.not_to change(ShoutOutDraft, :count)
    expect(response).to have_http_status(:forbidden)
    mute.update!(ended_at: Time.current, end_reason: "Posting restored")
    target.destroy!
    expect { post copy_to_draft_shout_out_path(original) }.not_to change(ShoutOutDraft, :count)
    expect(response).to redirect_to(shout_out_path(original))
    follow_redirect!
    expect(response.body).not_to include("Copy to new draft")
  end
end
