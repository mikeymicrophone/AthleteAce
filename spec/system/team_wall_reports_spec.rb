require "rails_helper"

RSpec.describe "Team wall, reports and revenue", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "reports a wall post, hides it with a full credit refund, and shows the admin totals on mobile" do
    author = create(:ace)
    reporter = create(:ace)
    reviewer = create(:ace, moderator: true)
    admin = create(:ace, admin: true)
    team = create(:team, league: create(:mlb), territory: "Chicago", mascot: "Cubs", abbreviation: "CHC", primary_color: "#0E3386", secondary_color: "#CC3433")
    player = create(:player, team: team, first_name: "Nico", last_name: "Hoerner")
    buy_credit(author)
    post = submit_credit(ace: author, target: player, message: "Outstanding work in the final inning", bid: 125)
    review_post(post, action: "approve", reviewer: reviewer)
    sign_in reporter
    visit team_path(team, side: "feed")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page).to have_css("body[data-side='feed']")
    expect(page).to have_content(post.message)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/team-wall-light.png")
    within('[aria-label="Wall filters"]') { click_link "Players", exact: true }
    within("#shout_out_#{post.id}") { click_link "Report" }
    select "Off-topic", from: "Reason"
    fill_in "Note (optional)", with: "Please check this against the team context"
    click_button "Send report"
    expect(page).to have_content("Report received.")

    sign_in reviewer
    visit reports_path
    expect(page).to have_content("1 report")
    click_link "Review reports"
    expect(page).to have_content("Please check this against the team context")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/reports-light.png")
    fill_in "Decision reason", with: "This post is off topic"
    click_button "Hide and refund credit"
    expect(page).to have_content("Reports resolved.")
    expect(CreditAccount.for(author).available_cents).to eq(1000)
    visit team_path(team)
    expect(page).not_to have_content(post.message)

    admin.update!(theme: "dark")
    sign_in admin
    visit shout_out_revenue_path(days: 7)
    [ "Cash purchases", "Refunded to credit", "$10.00", "$1.25" ].each { |text| expect(page).to have_content(/#{Regexp.escape(text)}/i) }
    expect(page).to have_css("html[data-theme='dark'] body[data-side='admin']")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/revenue-dark.png")
    visit report_path(post)
    expect(page).to have_content("Hidden")
    expect(page).to have_content("This post is off topic")
    save_screenshot("/tmp/screenshots/reports-dark.png")
    visit team_path(team, side: "feed")
    expect(page).to have_content("No shout-outs here yet.")
    save_screenshot("/tmp/screenshots/team-wall-dark.png")
  end
end
