# AthleteAce Test Suite

This test suite uses RSpec, Capybara, and Factory Bot to provide comprehensive test coverage for the AthleteAce application.

## Test Structure

The test suite is organized into the following categories:

- **Model Tests**: Test the behavior of models, their associations, validations, and methods
- **Controller Tests**: Test the behavior of controllers, including authentication, authorization, and response handling
- **Helper Tests**: Test helper methods used in views
- **Feature Tests**: End-to-end tests that simulate user interactions with the application
- **System Tests**: Similar to feature tests but with better browser integration

## Running Tests

To run the entire test suite:

```bash
bundle exec rspec
```

To run specific test categories:

```bash
bundle exec rspec spec/models                # Run all model tests
bundle exec rspec spec/controllers           # Run all controller tests
bundle exec rspec spec/features              # Run all feature tests
bundle exec rspec spec/system                # Run all system tests
```

To run a specific test file:

```bash
bundle exec rspec spec/features/quest_management_spec.rb
```

## Test Coverage

Test coverage is tracked using SimpleCov. After running the test suite, you can view the coverage report at `coverage/index.html`.

## Factories

Test data is generated using Factory Bot. Factory definitions are located in the `spec/factories` directory.

Key factories include:

- `ace`: User accounts
- `quest`: Quests that users can adopt
- `goal`: Represents a user's adoption of a quest
- `achievement`: Accomplishments that can be part of quests
- `highlight`: Links achievements to quests

Many factories include traits for creating associated records. For example:

```ruby
# Create a quest with 3 achievements (2 required, 1 optional)
create(:quest, :with_achievements, achievements_count: 3, required_count: 2)

# Create a quest with 5 participants
create(:quest, :with_participants, participants_count: 5)
```

## JavaScript Testing

System tests with JavaScript enabled use the `:js` tag:

```ruby
scenario "User interacts with dropdown menu", js: true do
  # Test code that requires JavaScript
end
```

These tests use Selenium with Chrome in headless mode by default.

## Authentication in Tests

To test features that require authentication, use the Devise test helpers:

```ruby
before do
  sign_in create(:ace)
end
```

## Adding New Tests

When adding new features to the application, follow these guidelines for testing:

1. Add model tests for new models, associations, validations, and methods
2. Add controller tests for new controller actions
3. Add helper tests for new helper methods
4. Add feature or system tests for new user-facing functionality
5. Use factories to create test data
6. Keep tests focused and fast
