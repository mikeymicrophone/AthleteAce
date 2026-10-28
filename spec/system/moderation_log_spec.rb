require "rails_helper"

RSpec.describe "Moderation decision history", type: :system do
  it "filters recorded events on mobile, preserves export filters and supports both themes" do
    author = create(:ace, username: "wrigley_wes", display_name: "Wes Miller")
    reviewer = create(:ace, moderator: true, username: "roster_rae", display_name: "Rae Carter")
    quest = create(:quest, created_by: author, name: "Know every Cubs starter")
    spectrum = create(:spectrum, created_by: author, name: "Court vision")
    Moderation::Review.call(record: quest, actor: reviewer, action: "approve", revision: 1, status: "pending", reason: "A clear roster goal.")
    Moderation::Review.call(record: spectrum, actor: reviewer, action: "reject", revision: 1, status: "pending", reason: "Clarify the scale endpoints.")
    sign_in reviewer
    visit moderation_log_path
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page).to have_content("A clear roster goal.")
    expect(page).to have_content("Clarify the scale endpoints.")
    select "Quest", from: "Content type"
    select "Approved", from: "Action"
    select reviewer.handle, from: "Recorded actor"
    click_button "Apply filters"
    expect(page).to have_content("A clear roster goal.")
    expect(page).not_to have_content("Clarify the scale endpoints.")
    within('[aria-label="Decision totals"]') do
      expect(page).to have_content(/Recorded events\s+1/i)
      expect(page).to have_content(/Approved\s+1/i)
    end
    expect(page).to have_select("Content type", selected: "Quest")
    export = find_link("Export CSV")[:href]
    query = Rack::Utils.parse_nested_query(URI.parse(export).query)
    expect(query).to include("item_type" => "Quest", "decision_action" => "approved", "actor_id" => reviewer.id.to_s)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    expect(find_field("From (UTC)").rect.width).to be >= 200
    save_screenshot("/tmp/screenshots/moderation-log-light.png")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/moderation-log-dark.png")
    click_link "Clear filters"
    expect(page).to have_select("Content type", selected: "All types")
    expect(page).to have_content("Clarify the scale endpoints.")
    select "Hidden", from: "Action"
    click_button "Apply filters"
    expect(page).to have_content("No decisions match.")
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
