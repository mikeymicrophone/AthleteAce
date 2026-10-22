require "rails_helper"

RSpec.describe "Posting moderation workflow", type: :system do
  it "warns, privately notes, mutes and ends a mute on mobile while the ace retains Play access" do
    ace = create(:ace, username: "wrigley_wes", display_name: "Wes Miller")
    reviewer = create(:ace, moderator: true, username: "roster_rae", display_name: "Rae Carter")
    create(:quest, created_by: ace, name: "Know every Cubs starter")
    player = create(:player, first_name: "Nico", last_name: "Hoerner")
    sign_in reviewer
    visit ace_profile_path(ace)
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    find("summary", text: /\AWarn\z/i).click
    fill_in "Warning reason", with: "Keep proposals specific to the roster."
    select "Know every Cubs starter", from: "Related submission"
    click_button "Record warning"
    expect(page).to have_content("Posting moderation action recorded.")
    expect(page).to have_content("Keep proposals specific to the roster.")
    find("summary", text: /Add moderator note/i).click
    fill_in "Internal note", with: "Private review context for the team."
    click_button "Save moderator note"
    expect(page).to have_content("Private review context for the team.")
    find("summary", text: /\AMute from posting\z/i).click
    select "24 hours", from: "Duration"
    fill_in "Mute reason", with: "Please keep new posts about the players."
    fill_in "Private note for moderators", with: "Private mute context."
    click_button "Mute from posting"
    expect(page).to have_content("Please keep new posts about the players.")
    expect(page).to have_content("Private mute context.")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/posting-moderation-light.png")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    save_screenshot("/tmp/screenshots/posting-moderation-dark.png")

    sign_out reviewer
    sign_in ace
    visit posting_status_path
    expect(page).to have_content("Keep proposals specific to the roster.")
    expect(page).to have_content("Please keep new posts about the players.")
    expect(page).not_to have_content("Private mute context.")
    expect(page).not_to have_content("Private review context for the team.")
    visit new_shout_out_draft_path
    expect(page).to have_css("h1", text: /Posting paused/i)
    click_link "Continue playing"
    expect(page).to have_current_path(strength_path)
    expect(page).to have_content("You can still play and read.")
    save_screenshot("/tmp/screenshots/posting-muted-play.png")

    sign_out ace
    sign_in reviewer
    visit ace_profile_path(ace)
    find("summary", text: /End mute early/i).click
    fill_in "Reason for ending mute", with: "Ready to contribute again."
    click_button "End mute"
    expect(page).to have_content(/Ended early/i)
    expect(page).to have_content("Ready to contribute again.")
    sign_out reviewer
    sign_in ace
    visit new_shout_out_draft_path(target_type: "Player", target_id: player.id)
    expect(page).not_to have_css("h1", text: /Posting paused/i)
    fill_in "Your message", with: "A remarkable effort in every inning."
    expect(page).to have_button("Save draft")
    click_button "Save draft"
    expect(page).to have_content("Draft saved. Only you can see it.")
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end
end
