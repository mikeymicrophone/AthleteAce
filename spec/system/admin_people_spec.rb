require "rails_helper"

RSpec.describe "Admin People workflow", type: :system do
  it "finds an ace, audits role changes, suspends and reactivates access on mobile" do
    admin = create(:ace, :admin, username: "roster_rae", display_name: "Rae Carter")
    ace = create(:ace, username: "wrigley_wes", display_name: "Wes Miller")
    SignInEvent.create!(ace: ace, outcome: 'success', ip_address: '192.0.2.14', user_agent: 'Firefox on macOS')
    sign_in admin
    visit admin_people_path
    page.driver.browser.execute_cdp "Emulation.setDeviceMetricsOverride", width: 390, height: 844, deviceScaleFactor: 1, mobile: false
    fill_in "Search aces", with: "wrigley_wes"
    click_button "Filter people"
    expect(page).to have_content('Wes Miller')
    expect(page).not_to have_content(admin.email)
    expect(page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')).to be(true)
    save_screenshot('/tmp/screenshots/admin-people-list.png')
    click_link 'Wes Miller'
    expect(page).to have_content('Firefox on macOS')
    expect(page).to have_content('192.0.2.14')
    select 'Moderator', from: 'Role'
    fill_in 'Action reason', with: 'Review roster proposals.'
    fill_in 'Your current password', with: 'password123'
    click_button 'Save role'
    expect(page).to have_content('Account action recorded.')
    expect(ace.reload.role).to eq('moderator')
    expect(page).to have_content('Review roster proposals.')
    page.execute_script("document.documentElement.dataset.theme = 'light'")
    expect(page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')).to be(true)
    save_screenshot('/tmp/screenshots/admin-person-light.png')
    page.execute_script("document.documentElement.dataset.theme = 'dark'")
    expect(page.evaluate_script('document.documentElement.scrollWidth <= window.innerWidth')).to be(true)
    save_screenshot('/tmp/screenshots/admin-person-dark.png')
    fill_in 'Action reason', with: 'Pause sign-in during account review.'
    fill_in 'Your current password', with: 'password123'
    click_button 'Suspend account'
    expect(page).to have_content('Account action recorded.')
    expect(ace.reload).to be_suspended
    expect(page).to have_button('Reactivate account')
    fill_in 'Action reason', with: 'Account review complete.'
    fill_in 'Your current password', with: 'password123'
    click_button 'Reactivate account'
    expect(page).to have_content('Account review complete.')
    expect(ace.reload).not_to be_suspended
    click_link 'View as moderator'
    expect(page).to have_current_path(ace_profile_path(ace, side: 'mod'))
    expect(page).to have_content('Wes Miller')
    expect(page).not_to have_content('Firefox on macOS')
  ensure
    page.driver.browser.execute_cdp 'Emulation.clearDeviceMetricsOverride'
  end
end
