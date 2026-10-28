require "rails_helper"

RSpec.describe "Shout-out reports", type: :request do
  let(:author) { create(:ace) }
  let(:reporter) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }
  let(:post_record) do
    buy_credit(author)
    post = submit_credit(ace: author, target: create(:player), bid: 125)
    review_post(post, action: "approve", reviewer: reviewer)
    post.reload
  end

  def flag(post = post_record, ace: reporter, **attributes)
    post.shout_out_reports.create!({ reporter: ace, reason: "Spam", note: "Repeated promotion" }.merge(attributes))
  end

  def decide(post, report, decision: "keep", **params)
    patch report_path(post), params: { decision: decision, revision: post.moderation_revision,
      last_report_id: report.id, reason: "Checked in context" }.merge(params)
  end

  it "accepts one private reason and note per ace without changing money or publication" do
    get new_shout_out_shout_out_report_path(post_record)
    expect(response).to redirect_to(new_ace_session_path)
    sign_in reporter
    get new_shout_out_shout_out_report_path(post_record)
    expect(response).to have_http_status(:ok)
    2.times do
      post shout_out_shout_out_reports_path(post_record), params: { shout_out_report: { reason: "Spam", note: "private detail", reporter_id: author.id, resolution: "hidden" } }
      expect(response).to redirect_to(feed_path)
    end
    expect(post_record.shout_out_reports.count).to eq(1)
    report = post_record.shout_out_reports.sole
    expect(report.reporter).to eq(reporter)
    expect(report.resolved_at).to be_nil
    expect(post_record.reload.funding_status).to eq("spent")
    expect(CreditAccount.for(author).available_cents).to eq(875)
    sign_out reporter
    get feed_path
    expect(response.body).not_to include("private detail")
    get report_path(post_record)
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "rejects invalid notes/reasons and cannot flag pending or hidden posts" do
    sign_in reporter
    post shout_out_shout_out_reports_path(post_record), params: { shout_out_report: { reason: "Invented", note: "x" * 2001 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(post_record.shout_out_reports.count).to eq(0)
    review_post(post_record, action: "hide", reviewer: reviewer)
    get new_shout_out_shout_out_report_path(post_record)
    expect(response).to have_http_status(:not_found)
    pending = submit_credit(ace: author, target: post_record.target, bid: 1)
    post shout_out_shout_out_reports_path(pending), params: { shout_out_report: { reason: "Spam" } }
    expect(response).to have_http_status(:not_found)
  end

  it "protects reviewer views and groups open reports in count order" do
    first = post_record
    flag(first)
    flag(first, ace: create(:ace), reason: "Harassment")
    second = submit_credit(ace: author, target: first.target, message: "Another finish", bid: 5)
    review_post(second, action: "approve", reviewer: reviewer)
    flag(second, ace: create(:ace))
    sign_in reporter
    get reports_path
    expect(response).to have_http_status(:forbidden)
    sign_in reviewer
    get reports_path
    expect(response).to have_http_status(:ok)
    expect(response.body.index(report_path(first))).to be < response.body.index(report_path(second))
    get report_path(first)
    expect(response.body).to include("Repeated promotion", "Harassment", "Spam")
    expect(response.headers["Cache-Control"]).to include("no-store")
    sign_in author
    author.update!(moderator: true)
    get report_path(first)
    expect(response).to have_http_status(:not_found)
  end

  it "keeps live with audit fields and rejects stale or newly expanded report sets" do
    report = flag
    sign_in reviewer
    flag(post_record, ace: create(:ace))
    decide(post_record, report)
    expect(response).to have_http_status(:conflict)
    latest = post_record.shout_out_reports.order(:id).last
    decide(post_record, latest)
    expect(response).to redirect_to(report_path(post_record))
    expect(post_record.shout_out_reports.pluck(:resolution).uniq).to eq([ "kept_live" ])
    expect(report.reload.resolved_by).to eq(reviewer)
    expect(report.decision_reason).to eq("Checked in context")
    expect(post_record.reload.funding_status).to eq("spent")
    decide(post_record, latest, decision: "hide")
    expect(response).to have_http_status(:conflict)
    get reports_path(status: "resolved")
    expect(response).to have_http_status(:ok)
  end

  it "hides once, resolves reports and returns the complete bid to credit" do
    report = flag
    sign_in reviewer
    decide(post_record, report, decision: "hide")
    expect(response).to redirect_to(report_path(post_record))
    expect(post_record.reload.moderation_status).to eq("hidden")
    expect(report.reload.resolution).to eq("hidden")
    expect(CreditAccount.for(author).available_cents).to eq(1000)
    decide(post_record, report, decision: "hide")
    expect(response).to have_http_status(:conflict)
    expect(CreditEntry.where(source: post_record, kind: "refund").count).to eq(1)
    get feed_path
    expect(response.body).not_to include(post_record.message)
  end

  it "prevents self-review of posts and reports through either review entry point" do
    report = flag(post_record, ace: reviewer)
    sign_in reviewer
    decide(post_record, report, decision: "hide")
    expect(response).to have_http_status(:forbidden)
    patch moderation_item_path(type: "ShoutOut", id: post_record.id), params: { decision: "hide", revision: post_record.moderation_revision, status: "approved", reason: "Spam" }
    expect(response).to have_http_status(:forbidden)
    author.update!(moderator: true)
    sign_in author
    decide(post_record, report)
    expect(response).to have_http_status(:forbidden)
    expect(post_record.reload.moderation_status).to eq("approved")
  end

  it "also resolves reports when a different moderator hides from the ordinary queue" do
    report = flag
    review_post(post_record, action: "hide", reviewer: reviewer)
    expect(report.reload.resolution).to eq("hidden")
    expect(report.resolved_by).to eq(reviewer)
  end

  it "paginates grouped reports without omitting or repeating posts" do
    first = post_record
    flag(first)
    26.times do |index|
      post = submit_credit(ace: author, target: first.target, message: "Reported highlight #{index}", bid: 1)
      review_post(post, action: "approve", reviewer: reviewer)
      flag(post)
    end
    sign_in reviewer
    get reports_path
    expect(response).to have_http_status(:ok)
    first_page = Nokogiri::HTML(response.body).css(".moderation-row h2 a").map { |link| link["href"] }
    expect(first_page.size).to eq(25)
    get reports_path(page: 2)
    second_page = Nokogiri::HTML(response.body).css(".moderation-row h2 a").map { |link| link["href"] }
    expect(second_page.size).to eq(2)
    expect(first_page & second_page).to be_empty
  end
end
