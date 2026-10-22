require "rails_helper"

RSpec.describe "Writing private shout-out drafts", type: :system do
  it "searches a target, previews emoji text, saves and edits a private draft on mobile" do
    ace = create(:ace)
    player = create(:player, first_name: "Jalen", last_name: "Brunson")
    sign_in ace
    visit feed_path
    click_link "Write a draft"
    expect(page).to have_button("Save draft", disabled: true)
    fill_in "Search players and teams", with: "Brunson"
    find('button[aria-label="Choose Jalen Brunson"]').click
    expect(page).to have_css(".draft-selected", text: player.name)
    fill_in "Your message", with: "What a finish! "
    find('button[aria-label="Add applause emoji"]').click
    expect(page).to have_css('[data-draft-composer-target="preview"]', text: "What a finish! 👏")
    expect(page).to have_css('[data-draft-composer-target="count"]', text: "16 / 200 characters")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/shout-out-draft-mobile.png")
    click_button "Save draft"
    expect(page).to have_content("Draft saved. Only you can see it.")
    expect(page).to have_field("Your message", with: "What a finish! 👏")
    expect(ace.shout_out_drafts.sole.target).to eq(player)
    fill_in "Your message", with: "\u00A0#{'👏' * 200}\u00A0"
    expect(page).to have_css('[data-draft-composer-target="count"]', text: "200 / 200 characters")
    expect(page).to have_button("Save draft", disabled: false)
    fill_in "Your message", with: "👏" * 201
    expect(page).to have_button("Save draft", disabled: true)
    fill_in "Your message", with: "Huge fourth quarter!"
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/shout-out-draft-dark.png")
    click_button "Save draft"
    expect(page).to have_content("Draft saved. Only you can see it.")
    expect(page).to have_css('input[name="shout_out_draft[lock_version]"][value="1"]', visible: false)
    expect(ace.shout_out_drafts.sole.reload.message).to eq("Huge fourth quarter!")
    click_link "My drafts"
    expect(page).to have_css(".draft-card", text: "Huge fourth quarter!")
    click_button "Delete draft"
    expect(page).to have_content("No drafts yet.")
    expect(ace.shout_out_drafts.reload).to be_empty
  ensure
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end

  it "prefills an entity from its page and shows server validation errors without losing text" do
    sign_in create(:ace)
    team = create(:team, territory: "New York", mascot: "Knicks")
    visit team_path(team)
    click_link "Write a shout-out draft"
    expect(page).to have_css(".draft-selected", text: team.name)
    fill_in "Your message", with: "See example.com for highlights"
    click_button "Save draft"
    expect(page).to have_css('[role="alert"]', text: "cannot include links or web addresses")
    expect(page).to have_field("Your message", with: "See example.com for highlights")
    expect(page).to have_css(".draft-selected", text: team.name)
    expect(ShoutOutDraft.count).to eq(0)
  end
end
