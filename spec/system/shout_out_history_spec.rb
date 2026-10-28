require "rails_helper"

RSpec.describe "Shout-out history", type: :system do
  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "filters on mobile and copies a rejected submission into an editable unfunded draft" do
    ace = create(:ace)
    player = create(:player, first_name: "Jalen", last_name: "Brunson", team: create(:team))
    buy_credit(ace)
    rejected = submit_credit(ace: ace, target: player, message: "An unforgettable fourth quarter", bid: 250)
    review_post(rejected, action: "reject")
    live = submit_credit(ace: ace, target: player, message: "A live celebration", bid: 100)
    review_post(live, action: "approve")
    sign_in ace
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    visit shout_outs_path
    within('[aria-label="Filter your shout-outs"]') { click_link "Rejected (1)" }
    expect(page).to have_css("article", text: rejected.message)
    expect(page).not_to have_css("article", text: live.message)
    expect(page).to have_css('[data-bid-total="refunded"]', text: "$2.50")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/shout-out-history-mobile.png")
    click_link "Details", exact: true
    click_button "Copy to new draft"
    expect(page).to have_field("Your message", with: rejected.message)
    expect(page).to have_content("The original submission and its credit are unchanged.")
    fill_in "Your message", with: "That final possession was unforgettable"
    click_button "Save draft"
    expect(page).to have_content("Draft saved. Only you can see it.")
    expect(rejected.reload.message).to eq("An unforgettable fourth quarter")
    expect(ace.shout_outs.count).to eq(2)
    expect(CreditAccount.for(ace).reserved_cents).to eq(0)
    visit shout_outs_path
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page).to have_css('[data-bid-total="spent"]', text: "$1.00")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/shout-out-history-dark.png")
  end
end
