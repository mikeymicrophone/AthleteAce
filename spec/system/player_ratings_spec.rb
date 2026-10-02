require "rails_helper"

RSpec.describe "Player profiles and rating controls", type: :system do
  let(:ace) { create(:ace) }
  let!(:player) { create(:player, photo_urls: ["/missing-player-photo.png"]) }
  let!(:familiarity) { create(:familiarity) }
  let!(:skill) { create(:skill) }

  before do
    driven_by :selenium_chrome_headless
    sign_in ace
  end

  def row_for spectrum
    find("#rating_spectrum_#{spectrum.id}_player_#{player.id}")
  end

  def expect_saved spectrum, value, average
    row = row_for spectrum
    expect(row).to have_css(".slider-value", text: value)
    expect(row).to have_css(".status-indicator", text: "Saved")
    expect(row).to have_css(".rating-summary", text: average)
    expect(row).to have_css("input:not([disabled])")
  end

  it "preserves existing exact values and saves keyboard changes with coarse and fine precision" do
    original = create(:rating, ace: ace, target: player, spectrum: familiarity, value: 4300)
    create(:rating, target: player, spectrum: familiarity, value: 1700)
    visit player_path(player)

    click_button "Fine"
    expect(row_for(familiarity).find("input").value).to eq("4300")
    expect(ace.ratings.count).to eq(1)
    expect(row_for(familiarity)).not_to have_content("Saved")
    click_button "Coarse"
    row_for(familiarity).find("input").send_keys :arrow_right
    expect_saved familiarity, "+5,300", "Aces average +3,500 · 2 ratings"
    expect(original.reload).to be_archived
    expect(page).to have_css("#rating_spectrum_#{familiarity.id}_player_#{player.id} input:focus")

    click_button "Fine"
    row_for(familiarity).find("input").send_keys :arrow_left
    expect_saved familiarity, "+5,200", "Aces average +3,450 · 2 ratings"
    expect(ace.rating_for(player, familiarity).value).to eq(5200)
    expect(page).to have_css(".precision-control button[aria-pressed=true]", text: "Fine")
  end

  it "snaps pointer input to the chosen increments and offers a working retry after a failed save" do
    visit player_path(player)
    # Exercise a dropped request without changing the persisted data.
    page.execute_script <<~JS
      const originalFetch = window.fetch;
      window.fetch = (...args) => {
        if (args[1]?.method === 'POST') {
          window.fetch = originalFetch;
          return Promise.resolve(new Response('', { status: 503 }));
        }
        return originalFetch(...args);
      };
      const slider = document.querySelector('#rating_spectrum_#{familiarity.id}_player_#{player.id} input');
      slider.value = 2650;
      slider.dispatchEvent(new Event('input', { bubbles: true }));
      slider.dispatchEvent(new Event('change', { bubbles: true }));
    JS
    row = row_for familiarity
    expect(row).to have_css(".slider-value", text: "+3,000")
    expect(row).to have_content("Couldn’t save your rating.")
    expect(ace.ratings.active.count).to eq(0)
    within(row) { click_button "Retry" }
    expect_saved familiarity, "+3,000", "Aces average +3,000 · 1 rating"

    click_button "Fine"
    page.execute_script <<~JS
      const slider = document.querySelector('#rating_spectrum_#{familiarity.id}_player_#{player.id} input');
      slider.value = 2650;
      slider.dispatchEvent(new Event('input', { bubbles: true }));
      slider.dispatchEvent(new Event('change', { bubbles: true }));
    JS
    expect_saved familiarity, "+2,700", "Aces average +2,700 · 1 rating"
  end

  it "reuses the shared controls when the browse spectrum picker changes traits" do
    create(:rating, ace: ace, target: player, spectrum: skill, value: 2000)
    create(:rating, target: player, spectrum: skill, value: 4000)
    visit players_path
    click_button "Fine"
    find(".spectrum-picker-toggle").click
    within ".spectrum-picker-panel" do
      click_button "Skill", exact: true
    end
    expect(page).to have_css(".slider-label", text: "Skill", count: 1)
    expect(page).not_to have_css(".slider-label", text: "Familiarity")
    expect(row_for(skill)).to have_css(".slider-value", text: "+2,000")
    expect(row_for(skill)).to have_content("Aces average +3,000 · 2 ratings")
    row_for(skill).find("input").send_keys :arrow_right
    expect_saved skill, "+2,100", "Aces average +3,050 · 2 ratings"

    within ".spectrum-picker-panel" do
      check "Multiple"
      click_button "Familiarity", exact: true
    end
    expect(page).to have_css(".rating-slider-instance", count: 2)
    within ".spectrum-picker-panel" do
      click_button "Skill", exact: true
      click_button "Familiarity", exact: true
    end
    expect(page).to have_content("Select a spectrum to see rating sliders.")
    expect(page).not_to have_css(".rating-slider-instance")
  end

  it "keeps the profile readable on mobile and switches between jersey fallback and a loaded image" do
    player.team.update! primary_color: "#1450BE", abbreviation: "ACE"
    page.current_window.resize_to 390, 844
    visit player_path(player)

    expect(page).to have_css(".profile-portrait[data-image-state=fallback] .profile-jersey", text: "ACE", visible: true)
    expect(page).not_to have_css(".profile-photo", visible: true)
    expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    page.save_screenshot Rails.root.join("tmp/screenshots/player-profile-mobile.png")
    page.current_window.resize_to 1400, 1000
    page.save_screenshot Rails.root.join("tmp/screenshots/player-profile-desktop.png")

    player.update! photo_urls: ["/icon.png"]
    visit player_path(player)
    expect(page).to have_css(".profile-portrait[data-image-state=loaded] .profile-photo", visible: true)
    expect(page).not_to have_css(".profile-jersey", visible: true)
  ensure
    page.current_window.resize_to 1400, 1400
  end
end
