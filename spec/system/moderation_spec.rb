require "rails_helper"

RSpec.describe "Moderation queue", type: :system do
  def wait_for_shortcuts
    expect(page).to have_css('[data-controller="moderation"]') {
      page.evaluate_script("!document.documentElement.hasAttribute('data-turbo-preview') && Boolean(window.Stimulus?.getControllerForElementAndIdentifier(document.querySelector('[data-controller=moderation]'), 'moderation'))")
    }
  end

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

  it "moves through the filtered queue with shortcuts and ignores keys while typing a reason" do
    author = create(:ace)
    reviewer = create(:ace, moderator: true)
    first = create(:quest, created_by: author, name: "First queue quest")
    second = create(:quest, created_by: author, name: "Second queue quest")
    create(:spectrum, created_by: author, name: "Other content")
    sign_in reviewer
    visit moderation_path
    click_link "Quests 2"
    expect(page).not_to have_content("Other content")
    wait_for_shortcuts
    page.driver.browser.action.send_keys("j").perform
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-label')")).to eq("Review First queue quest")
    page.driver.browser.action.send_keys("j").perform
    expect(page.evaluate_script("document.activeElement.getAttribute('aria-label')")).to eq("Review Second queue quest")
    page.driver.browser.action.send_keys("k", :enter).perform
    expect(page).to have_css("h1", text: /First queue quest/i)
    wait_for_shortcuts
    page.driver.browser.action.send_keys("j").perform
    expect(page).to have_css("h1", text: /Second queue quest/i)
    expect(page).to have_content("2 of 2 · Quests · pending")
    wait_for_shortcuts
    page.driver.browser.action.send_keys("k").perform
    expect(page).to have_css("h1", text: /First queue quest/i)
    wait_for_shortcuts
    page.driver.browser.action.send_keys("?").perform
    expect(page).to have_content("Shortcuts pause while you type in a field.")
    page.driver.browser.action.send_keys("r").perform
    expect(page.evaluate_script("document.activeElement.id")).to eq("reason")
    page.driver.browser.action.send_keys("a useful learning quest", :enter).perform
    expect(page).to have_field("Reason or note", with: "a useful learning quest\n")
    expect(first.reload.moderation_status).to eq("pending")
    expect(second.reload.moderation_status).to eq("pending")
    find("h1").click
    page.driver.browser.action.send_keys("a").perform
    expect(page).to have_content("Decision recorded.")
    expect(first.reload).to be_approved
    expect(page).to have_button("Hide")
    click_link "Next (J)"
    expect(page).to have_css("h1", text: /Second queue quest/i)
    fill_in "Reason or note", with: "Needs a clearer learning goal."
    click_button "Reject"
    expect(page).to have_content("Decision recorded.")
    expect(second.reload.moderation_status).to eq("rejected")
    click_link "Back to queue"
    expect(page).to have_content("Nothing waiting here.")
    expect(page).to have_link("Spectrums 1")
  end
end
