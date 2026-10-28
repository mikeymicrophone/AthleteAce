require "rails_helper"

RSpec.describe "Live Feed", type: :system do
  around do |example|
    server = ActionCable.server
    original = server.config.cable
    server.restart
    server.config.cable = { "adapter" => "async" }
    example.run
  ensure
    server.restart
    server.config.cable = original
  end

  after { page.driver.browser.execute_cdp "Emulation.clearDeviceMetricsOverride" }

  it "refreshes separate visitors with their own filters, pending visibility, reactions and stable ranking" do
    author = create(:ace)
    fan = create(:ace)
    mlb = create(:mlb, sport: create(:baseball))
    nba = create(:nba, sport: create(:basketball))
    cubs = create(:team, league: mlb, territory: "Chicago", mascot: "Cubs")
    bulls = create(:team, league: nba, territory: "Chicago", mascot: "Bulls")
    buy_credit(author, amount: 2000)
    first = submit_credit(ace: author, target: cubs, message: "Cubs hustle never stops", bid: 500)
    second = submit_credit(ace: author, target: cubs, message: "Cubs hustle through every inning", bid: 100)
    incoming = submit_credit(ace: author, target: cubs, message: "Cubs hustle wins again", bid: 100)
    private_post = submit_credit(ace: author, target: cubs, message: "A thought still in review", bid: 100)
    unrelated = submit_credit(ace: author, target: bulls, message: "Bulls hustle on the court", bid: 100)
    [ first, second ].each { |post| review_post(post, action: "approve") }
    second.shout_out_reactions.create!(ace: fan, kind: "fire")

    Capybara.using_session(:author) do
      sign_in author
      visit feed_path(sport_id: mlb.sport_id)
      expect(page).to have_css('turbo-cable-stream-source[connected]', visible: :all)
      expect(page).to have_content(private_post.message)
      expect(page).not_to have_content(unrelated.message)
    end

    sign_in fan
    path = feed_path(sport_id: mlb.sport_id, league_id: mlb.id, q: "hustle")
    visit path
    expect(page).to have_css('turbo-cable-stream-source[connected]', visible: :all)
    expect(page).to have_content(first.message)
    expect(page).not_to have_content(private_post.message)
    order = page.all('article[id^="shout_out_"]').map { |node| node[:id] }
    page.execute_script('window.feedRefreshCount = 0; document.addEventListener("turbo:morph", () => document.documentElement.dataset.feedRefreshCount = ++window.feedRefreshCount)')
    fill_in "Search live shout-outs", with: "An unfinished search"
    select nba.sport.name, from: "Sport"
    review_post(unrelated, action: "approve")
    expect(page).to have_content(first.message)
    expect(page).to have_css('html[data-feed-refresh-count="1"]')
    expect(page).to have_field("Search live shout-outs", with: "An unfinished search")
    expect(page).to have_select("Sport", selected: nba.sport.name)
    expect(page).to have_current_path(path)
    expect(page).not_to have_content(unrelated.message)
    expect(page.all('article[id^="shout_out_"]').map { |node| node[:id] }).to eq(order)

    review_post(incoming, action: "approve")
    expect(page).to have_content(incoming.message)
    expect(page).not_to have_content(private_post.message)
    expect(page.all('article[id^="shout_out_"]').map { |node| node[:id] } & order).to eq(order)
    within("#shout_out_#{second.id}") { expect(page).to have_css('button[aria-label="Fire, 1"][aria-pressed="true"]') }
    review_post(first, action: "hide")
    expect(page).not_to have_css("#shout_out_#{first.id}")
    expect(page).to have_content(second.message)
    expect(page).to have_content(incoming.message)
    expect(page).to have_field("Search live shout-outs", with: "An unfinished search")
    expect(page).to have_current_path(path)
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    expect(find_field("Search live shout-outs").rect.width).to be >= 200
    expect(find_field("Sport").rect.width).to be >= 200
    save_screenshot("/tmp/screenshots/live-feed-filters.png")

    Capybara.using_session(:author) do
      expect(page).to have_content(private_post.message)
      expect(page).to have_content(incoming.message)
      expect(page).not_to have_css("#shout_out_#{first.id}")
      within("#shout_out_#{second.id}") { expect(page).to have_css('button[aria-label="Fire, 1"][aria-pressed="false"]') }
    end
  end
end
