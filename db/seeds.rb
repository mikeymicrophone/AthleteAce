Rails.application.load_tasks unless defined?(Rake::Task) && Rake::Task.task_defined?("seeds:import")
Rake::Task["seeds:import"].reenable
Rake::Task["seeds:import"].invoke
