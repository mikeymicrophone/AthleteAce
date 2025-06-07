namespace :test do
  desc "Run tests for important pages to verify rendering after refactoring"
  task :important_pages => :environment do
    puts "Running important pages rendering tests..."
    
    # Run the specific test files for important pages
    test_files = [
      "spec/system/important_pages_spec.rb",
      "spec/requests/important_pages_rendering_spec.rb", 
      "spec/features/game_pages_spec.rb"
    ]
    
    test_files.each do |file|
      if File.exist?(file)
        puts "\n" + "="*50
        puts "Running #{file}"
        puts "="*50
        system("bundle exec rspec #{file}")
      else
        puts "Warning: #{file} not found"
      end
    end
    
    puts "\n" + "="*50
    puts "Important pages test run complete!"
    puts "="*50
  end

  desc "Run quick rendering check for critical pages"
  task :quick_render_check => :environment do
    puts "Running quick rendering check for critical pages..."
    
    # Just run the request specs for faster feedback
    system("bundle exec rspec spec/requests/important_pages_rendering_spec.rb")
  end

  desc "Run comprehensive page tests including JavaScript"
  task :comprehensive_pages => :environment do
    puts "Running comprehensive page tests with JavaScript..."
    
    # Run all page-related tests
    system("bundle exec rspec spec/system/important_pages_spec.rb spec/features/game_pages_spec.rb")
  end
end