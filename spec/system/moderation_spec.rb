require "rails_helper"

RSpec.describe "Moderation queue", type: :system do
  it "shows pending content and records a review on mobile in both themes" do
    author = create(:ace)
    reviewer = create(:ace, moderator: true)
    quest = create(:quest, created_by: author, name: "Know the starting lineup", description: "Learn the players on this season's roster.")
    create(:spectrum, created_by: author, name: "Court vision")
    sign_in reviewer
    visit moderation_path
    expect(page).to have_link("Moderate")
    expect(page).to have_content("Court vision")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: true
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/moderation-queue-mobile.png")
    click_link "Know the starting lineup"
    expect(page).to have_button("Approve")
    fill_in "Reason or note", with: "A clear learning quest."
    page.save_screenshot Rails.root.join("tmp/screenshots/moderation-review-mobile.png")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/moderation-review-dark.png")
    click_button "Approve"
    expect(page).to have_content("Decision recorded.")
    expect(page).to have_button("Hide")
    expect(quest.reload).to be_approved
    click_link "Back to queue"
    expect(page).not_to have_content("Know the starting lineup")
    click_link "Decision log"
    expect(page).to have_content("A clear learning quest.")
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
