require "rails_helper"
require "csv"

RSpec.describe "Moderation decision log", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  around { |example| travel_to(Time.utc(2026, 10, 22, 14)) { example.run } }

  let(:author) { create(:ace) }
  let(:reviewer) { create(:ace, moderator: true) }
  let(:quest) { create(:quest, created_by: author, name: "Know every Cubs starter") }

  def event(action: "approved", actor: reviewer, subject: quest, at: Time.utc(2026, 10, 20, 12), reason: "Clear learning goal", **attributes)
    ModerationDecision.create!({ subject: subject, actor: actor, action: action, revision: 1, from_status: "pending",
      to_status: action == "reopened" ? "pending" : action, created_at: at, reason: reason, snapshot: { "name" => quest.name } }.merge(attributes))
  end

  def log_rows
    Nokogiri::HTML(response.body).css(".moderation-list .moderation-row")
  end

  it "requires a moderator or admin for both HTML and CSV and prevents caching private history" do
    [ nil, author, reviewer, create(:ace, :admin) ].each do |ace|
      ace ? sign_in(ace) : sign_out(:ace)
      [ moderation_log_path, moderation_log_path(format: :csv) ].each do |path|
        get path
        if ace&.can_moderate?
          expect(response).to have_http_status(:ok)
          expect(response.headers["Cache-Control"]).to include("private", "no-store")
        else
          expect(response.status).to eq(ace ? 403 : (path.end_with?(".csv") ? 401 : 302))
        end
      end
    end
  end

  it "intersects inclusive UTC dates, actor, content type and action with matching totals" do
    event(at: Time.utc(2026, 10, 19, 23, 59, 59), reason: "Before range")
    start = event(at: Time.utc(2026, 10, 20), reason: "First event in range")
    finish = event(at: Time.utc(2026, 10, 20, 23, 59, 59), reason: "Last event in range")
    event(at: Time.utc(2026, 10, 21), reason: "After range")
    event(actor: create(:ace, moderator: true), reason: "Another actor")
    event(action: "rejected", reason: "Different action")
    event(subject: create(:spectrum), reason: "Different content")
    sign_in reviewer
    filters = { from: "2026-10-20", through: "2026-10-20", item_type: "Quest", actor_id: reviewer.id, decision_action: "approved" }
    get moderation_log_path, params: filters
    expect(response).to have_http_status(:ok)
    expect(log_rows.size).to eq(2)
    expect(log_rows.first.text).to include(finish.reason)
    expect(log_rows.last.text).to include(start.reason)
    totals = Nokogiri::HTML(response.body).at_css('[aria-label="Decision totals"]').text.squish
    expect(totals).to include("Recorded events 2", "Approved 2", "Rejected 0")
    link = Nokogiri::HTML(response.body).at_css('a[href*=".csv"]')
    get link["href"]
    expect(CSV.parse(response.body, headers: true).map { |row| row["id"].to_i }).to eq([ finish.id, start.id ])
  end

  it "keeps all matching history beyond the former 100-event cutoff with stable ties and filter pagination" do
    records = 101.times.map { |index| event(reason: "Roster review #{index}") }
    sign_in reviewer
    filters = { from: "2026-10-20", through: "2026-10-20", item_type: "Quest", actor_id: reviewer.id, decision_action: "approved" }
    get moderation_log_path, params: filters
    expect(log_rows.size).to eq(25)
    expect(log_rows.first.text).to include(records.last.reason)
    expect(log_rows.last.text).to include(records[-25].reason)
    expect(Nokogiri::HTML(response.body).at_css('[aria-label="Decision totals"]').text.squish).to include("Recorded events 101", "Approved 101")
    page_link = Nokogiri::HTML(response.body).css('a[href]').find { |link| URI.parse(link['href']).query.to_s.include?('page=2') }
    query = Rack::Utils.parse_nested_query(URI.parse(page_link['href']).query)
    expect(query).to include(filters.stringify_keys.transform_values(&:to_s))
    get page_link['href']
    expect(log_rows.size).to eq(25)
    expect(log_rows.first.text).to include(records[-26].reason)
    get moderation_log_path(format: :csv), params: filters.merge(page: 5)
    rows = CSV.parse(response.body, headers: true)
    expect(rows.size).to eq(101)
    expect(rows.map { |row| row['id'].to_i }).to eq(records.reverse.map(&:id))
  end

  it "retains recorded names after edits or deletion and includes unattributed actors without claiming they are system actions" do
    decision = event
    quest.update!(name: "Learn the Cubs roster")
    quest.destroy!
    reviewer.destroy!
    admin = create(:ace, :admin)
    sign_in admin
    get moderation_log_path, params: { actor_id: "unattributed", decision_action: "approved" }
    expect(log_rows.text).to include("Know every Cubs starter", "System or deleted account")
    get moderation_log_path(format: :csv), params: { actor_id: "unattributed", decision_action: "approved" }
    row = CSV.parse(response.body, headers: true).find { |entry| entry['id'].to_i == decision.id }
    expect(row['recorded_name']).to eq("Know every Cubs starter")
    expect(row['actor_id']).to be_nil
    expect(row['actor_handle']).to be_nil
  end

  it "defaults to 30 days, shows empty results honestly and rejects invalid filters in both formats" do
    sign_in reviewer
    get moderation_log_path
    expect(response.body).to include('value="2026-09-23"', 'value="2026-10-22"', "No decisions match.")
    event(at: Time.utc(2026, 10, 22, 15), reason: "Future-dated event")
    get moderation_log_path
    expect(response.body).not_to include("Future-dated event")
    get moderation_log_path, params: { through: "2026-10-20" }
    expect(response.body).to include('value="2026-09-21"', 'value="2026-10-20"')
    invalid = [ { from: "2026-02-30" }, { from: "2026-1-02" }, { from: "0000-01-01" },
      { from: "2026-10-22", through: "2026-10-21" }, { through: "2026-10-23" }, { item_type: "Ace" },
      { actor_id: "1 OR 1=1" }, { actor_id: -1 }, { actor_id: 999999 }, { decision_action: "delete" },
      { from: [ "2026-10-20" ] }, { from: { year: "2026" } }, { actor_id: { id: reviewer.id } }, { item_type: [ "Quest" ] }, { actor_id: [ reviewer.id ] } ]
    invalid.each do |filters|
      [ :html, :csv ].each do |format|
        get moderation_log_path(format: format), params: filters
        expect(response).to have_http_status(:bad_request), "Expected #{filters.inspect} to fail for #{format}"
      end
    end
  end

  it "neutralizes spreadsheet formulas without exposing raw snapshots, private reports or account emails" do
    decision = event(reason: " \t=HYPERLINK(\"https://example.invalid\")", snapshot: { "name" => "+Know the starters", "private" => "Excluded snapshot field" })
    multiline = event(reason: "A clear goal, with detail\nand another line", snapshot: { "name" => "Nico's lineup" })
    sign_in reviewer
    get moderation_log_path(format: :csv)
    expect(response.headers['Content-Disposition']).to include('attachment', 'athleteace-decisions-2026-09-23-2026-10-22.csv')
    rows = CSV.parse(response.body, headers: true)
    row = rows.find { |entry| entry['id'].to_i == decision.id }
    expect(row['reason']).to eq("'#{decision.reason}")
    expect(row['recorded_name']).to eq("'+Know the starters")
    expect(row['actor_handle']).to eq("'#{reviewer.handle}")
    expect(rows.find { |entry| entry['id'].to_i == multiline.id }['reason']).to eq(multiline.reason)
    expect(response.body).not_to include(author.email, reviewer.email, "Excluded snapshot field")
  end

  it "includes funded review events without exporting reporter notes or changing credit" do
    buy_credit(author)
    post = submit_credit(ace: author, target: create(:team), message: "A brilliant finish")
    review_post(post, action: "approve", reviewer: reviewer)
    reporter = create(:ace, username: "courtside_kai")
    post.shout_out_reports.create!(reporter: reporter, reason: "Spam", note: "Private reporter evidence")
    review_post(post, action: "hide", reviewer: reviewer)
    balance = CreditAccount.for(author).available_cents
    sign_in reviewer
    get moderation_log_path(format: :csv), params: { item_type: "ShoutOut", actor_id: reviewer.id }
    rows = CSV.parse(response.body, headers: true)
    expect(rows.map { |row| row['action'] }).to eq(%w[hidden approved])
    expect(rows.map { |row| row['recorded_name'] }.uniq).to eq([ post.target_name ])
    expect(response.body).not_to include(post.message, "Private reporter evidence", reporter.handle, reporter.email)
    expect(CreditAccount.for(author).available_cents).to eq(balance)
    expect(post.reload.funding_status).to eq("refunded")
  end

  it "rejects an oversized export rather than silently dropping rows" do
    stub_const("Moderation::DecisionLog::EXPORT_LIMIT", 2)
    3.times { event }
    sign_in reviewer
    get moderation_log_path(format: :csv), params: { actor_id: reviewer.id }
    expect(response).to have_http_status(:bad_request)
    expect(response.body).to include("Export exceeds 2 events")
    get moderation_log_path(format: :csv), params: { actor_id: reviewer.id, decision_action: "hidden" }
    expect(response).to have_http_status(:ok)
    expect(CSV.parse(response.body).size).to eq(1)
  end
end
