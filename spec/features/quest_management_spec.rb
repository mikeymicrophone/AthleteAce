require 'rails_helper'

RSpec.feature "Quest Management", type: :feature do
  # Create a confirmed ace with a valid password
  let(:ace) do
    ace = create(:ace, 
      email: "test_ace@example.com", 
      password: "password123", 
      password_confirmation: "password123"
    )
    # Ensure the ace is confirmed
    ace.confirm if ace.respond_to?(:confirm)
    ace
  end
  
  before do
    # Log in the user using Warden
    login_as(ace, scope: :ace)
  end
  
  scenario "Ace views available quests" do
    # Create some test quests
    create_list(:quest, 3)
    
    # Visit the quests page
    visit quests_path
    
    # Expect to see the quests listed
    expect(page).to have_content("Quests")
    expect(page).to have_css(".quest-card", count: 3)
  end
  
  scenario "Ace begins a quest" do
    quest = create(:quest, name: "Learn 90% of NL Central names")
    
    visit quest_path(quest)
    
    # Click the begin quest button - use a more specific selector to avoid ambiguity
    within "#quest_#{quest.id}" do
      click_button "Begin Quest"
    end
    
    # Expect to see a success message
    expect(page).to have_content("You've successfully adopted this quest!")
    
    # Expect the button to change to "Continue Quest"
    expect(page).to have_content("Continue Quest")
    
    # Expect the participant count to be updated
    expect(page).to have_content("1 participant")
  end
  
  scenario "Ace discovers a random quest" do
    create_list(:quest, 5)
    
    visit quests_path
    
    # Click the Begin Quest button in the navigation
    within ".navigation-container" do
      click_link "Begin Quest"
    end
    
    # Expect to see the quest discovery section
    expect(page).to have_content("Quest Discovery")
    expect(page).to have_button("Begin Quest").or have_link("Continue Quest")
    expect(page).to have_link("Next Quest")
  end
  
  scenario "Ace abandons a quest" do
    quest = create(:quest)
    goal = create(:goal, ace: ace, quest: quest)
    
    visit quests_path
    
    # Should see Continue Quest button
    expect(page).to have_content("Continue Quest")
    
    # Since there's no direct UI for abandoning a quest, we'll test the controller action directly
    # by making a DELETE request to the goal path
    page.driver.submit :delete, goal_path(goal), {}
    
    # Expect to be redirected to quests page
    expect(current_path).to eq(quests_path)
    
    # Expect to see a success message
    expect(page).to have_content("You've abandoned the quest.")
    
    # Expect the button to change back to "Begin Quest"
    expect(page).to have_button("Begin Quest")
  end
  
  scenario "Ace views quest details with achievements" do
    # Create a quest with achievements
    quest = create(:quest, :with_achievements, achievements_count: 5, required_count: 3)
    
    visit quest_path(quest)
    
    # Expect to see quest details
    expect(page).to have_content(quest.name)
    expect(page).to have_content(quest.description)
    
    # Expect to see achievement sections
    expect(page).to have_content("Achievements in this Quest")
    expect(page).to have_content("Required Achievements")
    
    # Expect to see the correct number of achievements
    expect(page).to have_content("3 achievements required")
  end
end
