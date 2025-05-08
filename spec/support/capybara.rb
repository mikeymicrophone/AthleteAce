RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
  
  config.before(:each, type: :system, js: true) do
    driven_by :selenium_chrome_headless
  end
end

# Configure Capybara
Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }
