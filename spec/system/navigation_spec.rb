require 'rails_helper'

RSpec.describe "Navigation", type: :system do
  before do
    driven_by(:selenium_chrome_headless)
  end
  
  context "when user is not signed in" do
    it "shows sign in and sign up links" do
      visit root_path
      
      within ".navigation-container" do
        expect(page).to have_link("Sign In")
        expect(page).to have_link("Sign Up")
        expect(page).not_to have_link("Begin Quest")
      end
    end
    
    it "allows navigation through dropdown menus", js: true do
      # Create some data to ensure links have destinations
      create(:sport)
      create(:team)
      create(:quest)
      
      visit root_path
      
      # Open Sports & Teams dropdown
      find(".nav-group-title", match: :first).click
      
      # Dropdown content should be visible
      expect(page).to have_css(".nav-dropdown", visible: true)
      
      # Should see the links in the dropdown
      within(".nav-dropdown", match: :first) do
        expect(page).to have_link("Sports")
        expect(page).to have_link("Teams")
      end
    end
  end
  
  context "when user is signed in" do
    let(:ace) { create(:ace) }
    
    before do
      sign_in ace
    end
    
    it "shows account and sign out links" do
      visit root_path
      
      within ".navigation-container" do
        # The email is used instead of "Account"
        expect(page).to have_link(ace.email)
        expect(page).to have_link("Sign Out")
        expect(page).to have_link("Begin Quest")
      end
    end
    
    it "navigates to random quest when clicking Begin Quest" do
      create_list(:quest, 3)
      visit root_path
      
      within ".navigation-container" do
        click_link "Begin Quest"
      end
      
      # Should be on a quest page with the discovery section
      expect(page).to have_content("Quest Discovery")
      expect(page).to have_button("Begin Quest")
      expect(page).to have_link("Next Quest")
    end
    
    it "opens and closes dropdown menus", js: true do
      visit root_path
      
      # Initially, dropdown menus should be hidden
      expect(page).not_to have_css(".nav-dropdown", visible: true)
      
      # Open first dropdown
      first_dropdown = find(".nav-group-title", match: :first)
      first_dropdown.click
      
      # Dropdown should now be visible
      expect(page).to have_css(".nav-dropdown", visible: true)
      
      # Click elsewhere to close the dropdown
      find("body").click
      
      # Dropdown should be hidden again
      expect(page).not_to have_css(".nav-dropdown", visible: true)
    end

    it "keeps mobile navigation usable with keyboard dismissal", js: true do
      page.current_window.resize_to 390, 844
      visit root_path

      %w[Teams Locations Quests Time].each do |label|
        button = find_button label
        button.click
        expect(button["aria-expanded"]).to eq("true")
        expect(page).to have_css(".nav-dropdown.active", visible: true)
        button.send_keys :escape
        expect(button["aria-expanded"]).to eq("false")
        expect(page).not_to have_css(".nav-dropdown.active")
      end

      within ".nav-menu" do
        expect(page).to have_link("Begin Quest")
      end
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth")).to be(true)
    ensure
      page.current_window.resize_to 1400, 1400
    end
  end
end
