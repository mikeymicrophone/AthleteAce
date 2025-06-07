RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
  
  # For Warden test helpers
  config.include Warden::Test::Helpers
  
  config.before(:suite) do
    Warden.test_mode!
  end
  
  config.after(:each) do
    Warden.test_reset!
  end
end
