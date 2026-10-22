require "rails_helper"

RSpec.describe "Shout-out payments and moderation", type: :system do
  before do
    @stripe_env = %w[STRIPE_SECRET_KEY STRIPE_WEBHOOK_SECRET].to_h { |key| [ key, ENV[key] ] }
    ENV["STRIPE_SECRET_KEY"] = "sk_test_fixture"
    ENV["STRIPE_WEBHOOK_SECRET"] = "whsec_fixture"
    allow(StripeCheckout).to receive(:call) { |purchase:, return_url:| return_url }
  end

  after do
    @stripe_env.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
    page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride"
  end

  it "reserves a custom credit bid, publishes after review, and restores the full bid when hidden on mobile" do
    ace = create(:ace)
    reviewer = create(:ace, moderator: true)
    player = create(:player, first_name: "Jalen", last_name: "Brunson")
    buy_credit(ace)
    sign_in ace
    visit player_path(player)
    click_link "Write a shout-out draft"
    fill_in "Your message", with: "That fourth quarter was unforgettable!"
    click_button "Save draft"
    expect(page).to have_content("Draft saved. Only you can see it.")
    within('[aria-labelledby="submit-shout-out-title"]') do
      fill_in "Your bid (USD)", with: "2.50"
      select "Use credit", from: "Payment method"
      click_button "Continue with bid"
    end
    expect(page).to have_content("In review. Your bid is reserved.")
    post = ace.shout_outs.sole
    visit wallet_path
    expect(page).to have_css(".wallet-available", text: "$7.50")
    expect(page).to have_css(".wallet-reserved", text: "$2.50")
    using_session(:reviewer) do
      sign_in reviewer
      visit moderation_item_path(type: "ShoutOut", id: post.id)
      click_button "Approve", exact: true
      expect(page).to have_css(".browse-header .eyebrow", text: /approved/i)
    end
    using_session(:visitor) do
      visit feed_path
      expect(page).to have_css(".shout-out-card", text: post.message)
      expect(page).not_to have_content("in review")
    end
    using_session(:reviewer) do
      fill_in "Reason or note", with: "Not about the target"
      click_button "Hide", exact: true
      expect(page).to have_css(".browse-header .eyebrow", text: /hidden/i)
    end
    visit wallet_path
    expect(page).to have_css(".wallet-available", text: "$10.00")
    expect(page).to have_css(".wallet-reserved", text: "$0.00")
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/credit-wallet-mobile.png")
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script("document.documentElement.scrollWidth <= innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/credit-wallet-dark.png")
    visit shout_out_path(post)
    expect(page).to have_content("full bid has been returned to your credit wallet")
  end

  it "keeps a direct Stripe payment unfunded until confirmed and reserves its whole amount" do
    ace = create(:ace)
    target = create(:team, territory: "New York", mascot: "Knicks")
    draft = ace.shout_out_drafts.create!(target: target, message: "What a comeback!")
    sign_in ace
    visit edit_shout_out_draft_path(draft)
    fill_in "Your bid (USD)", with: "0.50"
    select "Pay directly with Stripe", from: "Payment method"
    click_button "Continue with bid"
    expect(page).to have_content("Awaiting payment")
    click_button "Pay with Stripe"
    expect(page).to have_content(/Awaiting payment confirmation/i)
    purchase = ace.stripe_purchases.sole
    expect(CreditEntry.count).to eq(0)
    purchase.fulfill!(paid_session(purchase))
    click_link "Refresh status"
    expect(page).to have_content(/Payment received/i)
    click_link "Credit wallet"
    expect(page).to have_css(".wallet-available", text: "$0.00")
    expect(page).to have_css(".wallet-reserved", text: "$0.50")
  end
end
