require "rails_helper"

RSpec.describe "Admin content catalog", type: :request do
  let(:admin) { create :ace, :admin, display_name: "Rae Carter" }
  let(:author) { create :ace, username: "june_morris", display_name: "June Morris" }

  def document
    Nokogiri::HTML(response.body)
  end

  def rows
    document.css(".content-catalog-table tbody tr")
  end

  it "requires an admin and keeps the directory private" do
    quest = create :quest, name: "Private roster proposal", created_by: author
    get admin_content_catalog_path
    expect(response).to redirect_to(new_ace_session_path)
    [ create(:ace), create(:ace, moderator: true) ].each do |viewer|
      sign_in viewer
      get admin_content_catalog_path, params: { side: "admin" }
      expect(response).to redirect_to(root_path)
      expect(response.body).not_to include(quest.name)
    end
    sign_in admin
    get admin_content_catalog_path, params: { side: "play" }
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("private", "no-store")
    expect(document.at_css("body")["data-side"]).to eq("admin")
    expect(rows.text).to include(quest.name)
  end

  it "combines record types even when their ids overlap and includes all recorded statuses" do
    quest = create :quest, id: 9001, name: "Learn the Northern roster", created_by: author
    achievement = create :achievement, id: 9001, name: "Know the starting five", created_by: admin
    spectrum = create :spectrum, id: 9001, name: "Composure", moderation_status: "hidden"
    rejected = create :quest, name: "Archived roster challenge", moderation_status: "rejected"
    sign_in admin
    get admin_content_catalog_path
    expect(response).to have_http_status(:ok)
    expect(rows.map { |row| row["id"] }).to contain_exactly("content_quest_#{quest.id}", "content_achievement_#{achievement.id}", "content_spectrum_#{spectrum.id}", "content_quest_#{rejected.id}")
    expect(rows.text).to include(quest.name, achievement.name, spectrum.name, rejected.name, "Pending", "Approved", "Hidden", "Rejected")
    expect(document.at_css('section[aria-label="All content totals"]').text).to include("Quests", "Achievements", "Spectrums")
  end

  it "combines literal text, type, status and creator filters" do
    wanted = create :quest, name: "Learn 100% of the roster", description: "A backcourt challenge", created_by: author
    create :quest, name: "Learn the wings", created_by: admin
    create :spectrum, name: "Roster focus", created_by: author
    sign_in admin
    get admin_content_catalog_path, params: { q: "BACKCOURT", item_type: "Quest", status: "pending", creator_id: author.id.to_s }
    expect(rows.map { |row| row["id"] }).to eq([ "content_quest_#{wanted.id}" ])
    get admin_content_catalog_path, params: { q: "%" }
    expect(rows.map { |row| row["id"] }).to eq([ "content_quest_#{wanted.id}" ])
    get admin_content_catalog_path, params: { q: "_" }
    expect(rows).to be_empty
  end

  it "filters unattributed content without labeling it as created by a current account" do
    trusted = create :quest, name: "Original roster collection"
    owned = create :quest, name: "June's roster collection", created_by: author
    sign_in admin
    get admin_content_catalog_path, params: { creator_id: "unattributed" }
    expect(rows.map { |row| row["id"] }).to eq([ "content_quest_#{trusted.id}" ])
    expect(rows.text).to include("System or deleted account")
    get admin_content_catalog_path, params: { creator_id: author.id.to_s }
    expect(rows.map { |row| row["id"] }).to eq([ "content_quest_#{owned.id}" ])
    expect(rows.text).to include(author.public_name, author.handle)
    expect(rows.css("a").map { |link| link["href"] }).to include(admin_person_path(author))
  end

  it "sorts deterministically and retains all filters through mixed-type pagination" do
    quest = create :quest, name: "Alpha roster", created_by: author
    spectrum = create :spectrum, name: "Zulu focus", created_by: author
    create_list :achievement, 24, name: "Middle of the roster", created_by: author
    create :quest, name: "Not June's proposal"
    sign_in admin
    filters = { q: "", status: "pending", creator_id: author.id.to_s, sort: "name" }
    get admin_content_catalog_path, params: filters
    first_ids = rows.map { |row| row["id"] }
    expect(first_ids.size).to eq(25)
    expect(first_ids.first).to eq("content_quest_#{quest.id}")
    next_link = document.at_css('nav.pagy a[href*="page=2"]')
    expect(next_link).to be_present
    query = Rack::Utils.parse_nested_query(URI.parse(next_link["href"]).query)
    expect(query).to include(filters.stringify_keys.except("q"))
    get next_link["href"]
    expect(rows.map { |row| row["id"] }).to eq([ "content_spectrum_#{spectrum.id}" ])
    expect(rows.map { |row| row["id"] } & first_ids).to be_empty
  end

  it "sorts recently updated records across types without requiring a submission event" do
    quest = create :quest, name: "Older quest"
    spectrum = create :spectrum, name: "Recently refined scale"
    quest.update_columns(updated_at: 2.days.ago)
    spectrum.update_columns(updated_at: 1.hour.ago)
    sign_in admin
    get admin_content_catalog_path
    expect(rows.map { |row| row["id"] }).to eq([ "content_spectrum_#{spectrum.id}", "content_quest_#{quest.id}" ])
  end

  it "rejects malformed or unsupported filters" do
    sign_in admin
    [ { q: [ "roster" ] }, { item_type: "Ace" }, { status: "deleted" }, { creator_id: { id: "1" } }, { creator_id: "-1" }, { creator_id: "9999999999999999999" }, { sort: "name desc; DROP TABLE quests" } ].each do |filters|
      get admin_content_catalog_path, params: filters
      expect(response).to have_http_status(:bad_request), filters.inspect
    end
  end

  it "has a useful empty state and links to the existing creation and editing workflows" do
    sign_in admin
    get admin_content_catalog_path
    expect(response.body).to include("No matching content", "Try another name or change the filters.")
    expect(document.css("main a").map { |link| link["href"] }).to include(new_quest_path(side: "admin"), new_achievement_path(side: "admin"), new_spectrum_path(side: "admin"))
    quest = create :quest, name: "Rae's approved collection", created_by: admin
    get admin_content_catalog_path
    row = rows.sole
    expect(row.css("a").map { |link| link["href"] }).to include(quest_path(quest, side: "admin"), edit_quest_path(quest, side: "admin"), moderation_item_path(type: "Quest", id: quest.id, queue_status: "approved", item_type: "Quest"))
    get moderation_item_path(type: "Quest", id: quest.id)
    expect(response.body).to include("Another reviewer must decide your submission.")
    patch moderation_item_path(type: "Quest", id: quest.id), params: { decision: "hide", revision: quest.moderation_revision, status: "approved", reason: "Own submission" }
    expect(response).to have_http_status(:forbidden)
    expect(quest.reload).to be_approved
  end

  it "links only escalation cases the admin can view" do
    reviewer = create :ace, moderator: true
    quest = create :quest, name: "Handed-off roster challenge", created_by: author
    own = create :quest, name: "Admin's collection", created_by: admin
    case_record = Moderation::Escalate.call(subject: quest, actor: reviewer, reason: "Needs an admin decision", request_key: "other-case", revision: quest.moderation_revision, status: quest.moderation_status)
    own_case = Moderation::Escalate.call(subject: own, actor: reviewer, reason: "Another admin needed", request_key: "own-case", revision: own.moderation_revision, status: own.moderation_status)
    sign_in admin
    get admin_content_catalog_path
    links = rows.css("a").map { |link| link["href"] }
    expect(links).to include(escalation_path(case_record))
    expect(links).not_to include(escalation_path(own_case))
  end
end
