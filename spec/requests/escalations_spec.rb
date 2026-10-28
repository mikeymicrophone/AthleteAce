require "rails_helper"

RSpec.describe "Moderation escalations", type: :request do
  let(:author) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }
  let(:admin) { create(:ace, :admin) }
  let(:quest) { create(:quest, created_by: author, name: "Know the Cubs starters") }

  def escalate(subject = quest, actor: reviewer, **changes)
    Moderation::Escalate.call(subject: subject, actor: actor, reason: "Needs policy guidance", request_key: SecureRandom.uuid,
      **(subject.is_a?(Ace) ? {} : { revision: subject.moderation_revision, status: subject.moderation_status }).merge(changes))
  end

  def resolve(record, resolution: "no_change", reason: "Reviewed the context", version: 0)
    patch escalation_path(record), params: { resolution: resolution, reason: reason, version: version }
  end

  it "captures private context, handles retries, and removes content from the normal queue" do
    sign_in reviewer
    key = SecureRandom.uuid
    attributes = { subject_type: "Quest", subject_id: quest.id, revision: 1, captured_status: "pending", reason: "Private escalation context", request_key: key }
    2.times { post escalations_path, params: attributes.merge(requested_by_id: author.id) }
    record = ModerationEscalation.sole
    expect(response).to redirect_to(escalation_path(record))
    expect(record.requested_by).to eq(reviewer)
    expect(record.snapshot['name']).to eq(quest.name)
    get moderation_path
    expect(response.body).not_to include(quest.name)
    get search_path, params: { q: "Cubs starters", side: "mod" }, headers: { "X-Requested-With" => "XMLHttpRequest" }
    expect(response.body).not_to include(quest.name)
    patch moderation_item_path(type: "Quest", id: quest.id), params: { decision: "approve", revision: 1, status: "pending" }
    expect(response).to have_http_status(:forbidden)
    post escalations_path, params: attributes.merge(request_key: SecureRandom.uuid)
    expect(response).to have_http_status(:conflict)
    post escalations_path, params: attributes.merge(reason: "Changed reason")
    expect(response).to have_http_status(:conflict)
    get escalation_path(record)
    expect(response.body).to include("Private escalation context", "An admin must resolve")
    expect(response.headers['Cache-Control']).to include('private', 'no-store')
    sign_in author
    get escalation_path(record)
    expect(response).to have_http_status(:forbidden)
    get feed_path
    expect(response.body).not_to include("Private escalation context")
    sign_out author
    get escalations_path
    expect(response).to redirect_to(new_ace_session_path)
  end

  it "requires admin resolution and applies the decision once with immutable original history" do
    record = escalate
    sign_in reviewer
    resolve(record, resolution: "approve")
    expect(response).to have_http_status(:forbidden)
    sign_in admin
    2.times { resolve(record, resolution: "approve", reason: "A valid roster quest") }
    expect(response).to have_http_status(:see_other)
    expect(quest.reload.moderation_status).to eq('approved')
    expect(quest.moderation_decisions.order(:id).pluck(:action)).to eq(%w[submitted approved])
    expect(record.reload.resolution).to eq('approve')
    expect(record.resolved_by).to eq(admin)
    expect(record.snapshot['name']).to eq("Know the Cubs starters")
    expect { record.update!(resolution_reason: 'Rewrite') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    resolve(record, resolution: "reject", reason: "Different decision")
    expect(response).to have_http_status(:conflict)
    get escalations_path(status: "resolved")
    expect(response.body).to include(quest.name)
  end

  it "excludes admins' own subjects and requires another admin for their own escalation" do
    own = create(:quest, created_by: admin)
    record = escalate(own)
    sign_in admin
    get escalation_path(record)
    expect(response).to have_http_status(:not_found)
    sign_in admin
    resolve(record)
    expect(response).to have_http_status(:not_found)
    sign_in admin
    post escalations_path, params: { subject_type: "Quest", subject_id: own.id, revision: 1, captured_status: "approved", reason: "Self", request_key: SecureRandom.uuid }
    expect(response).to have_http_status(:forbidden)
    self_requested = escalate(actor: admin)
    get escalation_path(self_requested)
    expect(response.body).to include("Another admin must resolve")
    resolve(self_requested)
    expect(response).to have_http_status(:forbidden)
    get escalations_path
    expect(response.body).not_to include(own.name)
  end

  it "captures account handoffs without changing roles, notes, mutes or sign-in access" do
    record = escalate(author)
    sign_in admin
    get escalation_path(record)
    expect(response.body).to include(author.public_name, "without changing account permissions")
    resolve(record, resolution: 'approve')
    expect(response).to have_http_status(:conflict)
    resolve(record)
    expect(response).to have_http_status(:see_other)
    expect(author.reload.mutes.count).to eq(0)
    expect(author.warnings.count).to eq(0)
    expect(author.moderator?).to be(false)
    sign_in author
    get strength_path
    expect(response).to have_http_status(:ok)
    staff = create(:ace, moderator: true)
    case_for_staff = escalate(staff)
    sign_in staff
    get escalation_path(case_for_staff)
    expect(response).to have_http_status(:not_found)
  end

  it "rejects stale creation and content resolution but permits closing changed or deleted cases without changes" do
    sign_in reviewer
    post escalations_path, params: { subject_type: "Quest", subject_id: quest.id, revision: 0, captured_status: "pending", reason: "Old form", request_key: SecureRandom.uuid }
    expect(response).to have_http_status(:conflict)
    record = escalate
    quest.update!(name: "Learn every Cubs starter")
    sign_in admin
    resolve(record, resolution: 'approve')
    expect(response).to have_http_status(:conflict)
    expect(quest.reload.moderation_status).to eq('pending')
    get escalation_path(record)
    expect(response.body).to include("Know the Cubs starters", "content changed")
    expect(Nokogiri::HTML(response.body).css('#resolution option').map { |node| node['value'] }).to eq([ 'no_change' ])
    resolve(record)
    expect(response).to have_http_status(:see_other)
    get moderation_path
    expect(response.body).to include(quest.name)
    get search_path, params: { q: "Cubs starter", side: "mod" }, headers: { "X-Requested-With" => "XMLHttpRequest" }
    expect(response.body).to include(quest.name)
    deleted = escalate
    quest.destroy!
    get escalation_path(deleted)
    expect(response.body).to include("no longer exists", "Learn every Cubs starter")
    resolve(deleted)
    expect(response).to have_http_status(:see_other)
  end

  it "hides a funded post with its full refund, blocks other review routes and prevents funded reversals" do
    buy_credit(author)
    post = submit_credit(ace: author, target: create(:team), bid: 125)
    review_post(post, action: 'approve', reviewer: reviewer)
    report = post.shout_out_reports.create!(reporter: create(:ace), reason: 'Spam', note: 'Private reporter evidence')
    record = escalate(post)
    sign_in admin
    get report_path(post)
    expect(response.body).to include("View escalation")
    expect(response.body).not_to include("Hide and refund credit")
    patch report_path(post), params: { decision: 'keep', revision: 1, last_report_id: report.id, reason: 'Bypass' }
    expect(response).to have_http_status(:forbidden)
    patch moderation_item_path(type: 'ShoutOut', id: post.id), params: { decision: 'hide', revision: 1, status: 'approved', reason: 'Bypass' }
    expect(response).to have_http_status(:forbidden)
    2.times { resolve(record, resolution: 'hide', reason: 'Off-topic post') }
    expect(response).to have_http_status(:see_other)
    expect(post.reload.funding_status).to eq('refunded')
    expect(CreditAccount.for(author).available_cents).to eq(1000)
    expect(CreditEntry.where(source: post, kind: 'refund').count).to eq(1)
    expect(report.reload.resolution).to eq('hidden')
    appeal = escalate(post)
    resolve(appeal, resolution: 'reopen')
    expect(response).to have_http_status(:conflict)
    expect(post.reload.moderation_status).to eq('hidden')
    expect(appeal.reload.resolved_at).to be_nil
    resolve(appeal)
    expect(response).to have_http_status(:see_other)
  end

  it "blocks own-report resolution and rolls back invalid or stale resolutions" do
    buy_credit(author)
    post = submit_credit(ace: author, target: create(:team))
    review_post(post, action: 'approve', reviewer: reviewer)
    post.shout_out_reports.create!(reporter: admin, reason: 'Spam')
    record = escalate(post)
    sign_in admin
    resolve(record, resolution: 'hide')
    expect(response).to have_http_status(:forbidden)
    resolve(record)
    expect(response).to have_http_status(:forbidden)
    get escalation_path(record)
    expect(response.body).to include('Another admin must decide your report')
    expect(response.body).not_to include('Resolve escalation')
    sign_in create(:ace, :admin)
    resolve(record, resolution: 'hide', reason: '')
    expect(response).to have_http_status(:unprocessable_content)
    resolve(record, resolution: 'hide', reason: 'x' * 2001)
    expect(response).to have_http_status(:unprocessable_content)
    resolve(record, resolution: 'hide', version: 9)
    expect(response).to have_http_status(:conflict)
    expect(post.reload.funding_status).to eq('spent')
    expect(record.reload.resolved_at).to be_nil
  end

  it "validates types/status filters and keeps private original reasons outside owner pages and CSV" do
    sign_in reviewer
    post escalations_path, params: { subject_type: 'CreditAccount', subject_id: 1, reason: 'No', request_key: SecureRandom.uuid }
    expect(response).to have_http_status(:not_found)
    sign_in reviewer
    post escalations_path, params: { subject_type: 'Quest', subject_id: quest.id, revision: 1, captured_status: 'pending', reason: '', request_key: SecureRandom.uuid }
    expect(response).to have_http_status(:unprocessable_content)
    record = escalate
    sign_in admin
    resolve(record, resolution: 'reject', reason: 'Clarify the goal')
    get moderation_log_path(format: :csv)
    expect(response.body).to include('Clarify the goal')
    expect(response.body).not_to include(record.reason)
    sign_in author
    get quest_path(quest)
    expect(response.body).to include('Clarify the goal')
    expect(response.body).not_to include(record.reason)
    sign_in reviewer
    get escalations_path(status: 'forged')
    expect(response).to have_http_status(:bad_request)
  end
end
