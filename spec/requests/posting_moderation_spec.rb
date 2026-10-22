require "rails_helper"

RSpec.describe "Warnings and posting mutes", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:ace) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }

  def act(kind, target: ace, **attributes)
    post ace_profile_posting_actions_path(target), params: { kind: kind, posting_action: { request_key: SecureRandom.uuid }.merge(attributes) }
  end

  def mute(target = ace, **attributes)
    Moderation::PostingAction.call(ace: target, actor: reviewer, kind: "mute",
      attributes: { request_key: SecureRandom.uuid, reason: "Keep discussion about the players", duration_hours: "24", note: "Private follow-up context" }.merge(attributes))
  end

  it "records warnings with owned related content, safely retries and protects identity and notes" do
    quest = create(:quest, created_by: ace, name: "Know the Cubs starters")
    sign_in reviewer
    key = SecureRandom.uuid
    2.times { act("warn", reason: "Keep proposals clear", related_item: "Quest:#{quest.id}", request_key: key, moderator_id: ace.id) }
    expect(response).to have_http_status(:see_other)
    expect(ace.warnings.count).to eq(1)
    warning = ace.warnings.sole
    expect(warning.moderator).to eq(reviewer)
    expect(warning.subject_name).to eq(quest.name)
    act("warn", reason: "A different action", related_item: "Quest:#{quest.id}", request_key: key)
    expect(response).to have_http_status(:conflict)
    act("warn", reason: "Forged owner", related_item: "Quest:#{create(:quest).id}")
    expect(response).to have_http_status(:not_found)
    act("warn", reason: "Bad target", related_item: ":12")
    expect(response).to have_http_status(:unprocessable_content)
    act("note", body: "Private moderator evidence")
    sign_in ace
    get posting_status_path(ace_id: reviewer.id)
    expect(response.body).to include("Keep proposals clear")
    expect(response.body).not_to include("Private moderator evidence", reviewer.email)
    get ace_profile_path(ace, tab: "notes")
    expect(response).to have_http_status(:forbidden)
    sign_out ace
    get ace_profile_path(ace)
    expect(response).to redirect_to(new_ace_session_path)
    get feed_path
    expect(response.body).not_to include("Keep proposals clear", "Private moderator evidence")
  end

  it "restricts self/staff actions, allows an admin to act on a moderator, and hides internal notes from that moderator" do
    sign_in ace
    act("warn", target: create(:ace), reason: "Not authorized")
    expect(response).to have_http_status(:forbidden)
    sign_in reviewer
    act("mute", target: reviewer, reason: "Self", duration_hours: 24)
    expect(response).to have_http_status(:forbidden)
    peer = create(:ace, moderator: true)
    act("warn", target: peer, reason: "Needs an admin")
    expect(response).to have_http_status(:forbidden)
    admin = create(:ace, :admin)
    act("warn", target: admin, reason: "Protected admin")
    expect(response).to have_http_status(:forbidden)
    sign_in admin
    act("mute", target: peer, reason: "Pause new proposals", duration_hours: 168, note: "Staff-only detail")
    expect(response).to have_http_status(:see_other)
    act("note", target: peer, body: "Private staff discussion")
    sign_in peer
    get ace_profile_path(peer, tab: "actions")
    expect(response.body).to include("Pause new proposals")
    expect(response.body).not_to include("Staff-only detail")
    get ace_profile_path(peer, tab: "notes")
    expect(response.body).not_to include("Private staff discussion")
    get moderation_path
    expect(response).to have_http_status(:ok)
  end

  it "blocks old and new composer/proposal requests in HTML and JSON while preserving reading, Play, preferences and money" do
    target = create(:player)
    draft = ace.shout_out_drafts.create!(target: target, message: "A memorable finish")
    buy_credit(ace)
    quest = create(:quest)
    achievement = create(:achievement)
    record = mute
    sign_in ace
    blocked_gets = [ new_shout_out_draft_path, edit_shout_out_draft_path(draft), new_quest_path,
      new_achievement_path, new_spectrum_path, new_quest_highlight_path(quest) ]
    blocked_gets.each do |path|
      get path
      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include("Posting paused", record.reason, "UTC")
      expect(response.body).not_to include(record.note)
    end
    requests = [
      [ shout_out_drafts_path, { shout_out_draft: { target_type: "Player", target_id: target.id, message: "A second draft" } } ],
      [ shout_outs_path, { draft_id: draft.id, draft_revision: 0, bid: "1.00", payment_method: "credit" } ],
      [ quests_path, { quest: { name: "A new quest" } } ],
      [ achievements_path, { achievement: { name: "New achievement", target_type: "Player", target_id: target.id } } ],
      [ spectrums_path, { spectrum: { name: "New spectrum" } } ],
      [ quest_highlights_path(quest), { highlight: { achievement_id: achievement.id } } ]
    ]
    before_counts = [ ShoutOut.count, ShoutOutDraft.count, Quest.count, Achievement.count, Spectrum.count, Highlight.count ]
    requests.each do |path, attributes|
      post path, params: attributes, as: :json
      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['ends_at']).to eq(record.ends_at.utc.iso8601)
    end
    patch shout_out_draft_path(draft), params: { shout_out_draft: { message: "A changed draft", lock_version: 0 } }, as: :json
    expect(response).to have_http_status(:forbidden)
    expect([ ShoutOut.count, ShoutOutDraft.count, Quest.count, Achievement.count, Spectrum.count, Highlight.count ]).to eq(before_counts)
    expect(CreditAccount.for(ace).available_cents).to eq(1000)
    expect(CreditAccount.for(ace).reserved_cents).to eq(0)
    [ feed_path, strength_path, new_game_round_path, quests_path, posting_status_path, wallet_path ].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(record.note)
    end
    post follows_path, params: { followable_type: "Player", followable_id: target.id }
    expect(response).to have_http_status(:see_other)
  end

  it "uses exact duration/expiry boundaries and records early ending without rewriting the original mute" do
    travel_to(Time.utc(2026, 10, 22, 16)) do
      record = mute
      expect(record.ends_at - record.starts_at).to eq(24.hours)
      travel_to(record.ends_at - 1.second)
      expect(ace.active_posting_mute).to eq(record)
      travel_to(record.ends_at)
      expect(ace.active_posting_mute).to be_nil
      travel_to(Time.utc(2026, 10, 22, 16))
      sign_in reviewer
      act("end_mute", mute_id: record.id, reason: "Reviewed the response")
      expect(response).to have_http_status(:see_other)
      expect(record.reload.ended_by).to eq(reviewer)
      expect(record.end_reason).to eq("Reviewed the response")
      expect(record.ends_at).to eq(Time.utc(2026, 10, 23, 16))
      sign_in ace
      post quests_path, params: { quest: { name: "Learn the 1990s quarterbacks" } }
      expect(response).to have_http_status(:found)
    end
  end

  it "atomically mutes and hides a reported post with one full refund, including retries" do
    buy_credit(ace)
    record = submit_credit(ace: ace, target: create(:team), bid: 125)
    review_post(record, action: "approve", reviewer: reviewer)
    report = record.shout_out_reports.create!(reporter: create(:ace), reason: "Spam", note: "Internal report")
    sign_in reviewer
    key = SecureRandom.uuid
    2.times { act("mute", duration_hours: 168, reason: "Stay on topic", note: "Internal context", hide_post_id: record.id, request_key: key) }
    expect(response).to have_http_status(:see_other)
    expect(ace.mutes.count).to eq(1)
    expect(record.reload.moderation_status).to eq("hidden")
    expect(CreditAccount.for(ace).available_cents).to eq(1000)
    expect(CreditEntry.where(source: record, kind: "refund").count).to eq(1)
    expect(report.reload.resolution).to eq("hidden")
    get ace_profile_path(ace, tab: "reports")
    expect(response.body).to include("Internal report")
    expect(response.headers['Cache-Control']).to include('private', 'no-store')
  end

  it "rolls back a combined hide when the mute is invalid and refuses own-report or unrelated hides" do
    buy_credit(ace)
    record = submit_credit(ace: ace, target: create(:team), bid: 100)
    review_post(record, action: "approve", reviewer: reviewer)
    record.shout_out_reports.create!(reporter: create(:ace), reason: "Spam")
    sign_in reviewer
    act("mute", duration_hours: 24, reason: "Clear reason", note: "x" * 2001, hide_post_id: record.id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(ace.mutes.count).to eq(0)
    expect(record.reload.moderation_status).to eq("approved")
    expect(CreditAccount.for(ace).available_cents).to eq(900)
    expect(CreditEntry.where(source: record, kind: "refund").count).to eq(0)
    record.shout_out_reports.create!(reporter: reviewer, reason: "Off-topic")
    act("mute", duration_hours: 24, reason: "Clear reason", hide_post_id: record.id)
    expect(response).to have_http_status(:forbidden)
    expect(ace.mutes.count).to eq(0)
    act("mute", duration_hours: 48, reason: "Unsupported duration")
    expect(response).to have_http_status(:unprocessable_content)
  end
end
