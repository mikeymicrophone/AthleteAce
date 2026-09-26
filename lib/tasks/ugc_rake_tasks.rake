# UGC Preservation Rake Tasks Template
# Tasks for backing up, resetting, and restoring UGC data during core model reseeding

namespace :ugc do
  desc "Backup UGC data before core model reseed"
  task backup: :environment do
    puts "🔄 Starting UGC backup..."
    
    backup_timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    backup_dir = UgcBackupService::BACKUP_ROOT.join("backup_#{backup_timestamp}")
    
    # Create backup directory
    FileUtils.mkdir_p(backup_dir)
    
    # Run backup service
    UgcBackupService.new(backup_dir).backup_all
    
    puts "✅ UGC backup completed!"
    puts "📁 Backup location: #{backup_dir}"
    puts "🔧 To restore this backup: rails ugc:restore[#{backup_timestamp}]"
    puts "⚠️  Next step: rails ugc:reset_core_models"
  end

  desc "Reset core sports hierarchy models. mode=float (default) keeps ratings, achievements, and game attempts, which attach to the new records; mode=clear deletes them for ugc:restore to recreate (needs a fresh backup)"
  task :reset_core_models, [:mode] => :environment do |t, args|
    mode = args[:mode] || "float"
    unless UgcResetService::MODES.include?(mode)
      puts "❌ Unknown mode #{mode.inspect}. Use: rails \"ugc:reset_core_models[float]\" or rails \"ugc:reset_core_models[clear]\""
      exit 1
    end

    puts "⚠️  WARNING: This will DELETE all core sports data and reseed from JSON files!"
    if mode == "clear"
      puts "🧹 Clear mode: ratings, achievements, highlights, and game attempts will also be deleted."
      puts "   Restore them afterwards with rails ugc:restore[backup_timestamp]."
    else
      puts "🛡️  Float mode: UGC is kept. Ratings, achievements, and game attempts will attach to"
      puts "   whichever new records reuse their ids."
    end
    puts ""

    # Show what will be affected
    UgcResetService.preview_reset(mode)
    puts ""
    
    print "Are you sure you want to continue? (yes/no): "
    confirmation = $stdin.gets.chomp.downcase
    
    unless ['yes', 'y'].include?(confirmation)
      puts "❌ Reset cancelled."
      exit 0
    end
    
    puts "🔄 Starting core model reset..."
    
    # Run reset service
    UgcResetService.new(mode: mode).reset_core_models

    puts "✅ Core model reset completed!"
    puts "📊 Check the reset report in tmp/ for details"
    puts "🔧 Next step: rails ugc:restore[backup_timestamp]" if mode == "clear"
  end

  desc "Restore UGC data after core model reseed"
  task :restore, [:backup_timestamp] => :environment do |t, args|
    backup_timestamp = args[:backup_timestamp]
    
    unless backup_timestamp
      puts "❌ Error: Backup timestamp required"
      puts "Usage: rails ugc:restore[20241215_143022]"
      puts ""
      puts "Available backups:"
      backup_dirs = Dir.glob(UgcBackupService::BACKUP_ROOT.join("backup_*"))
      if backup_dirs.any?
        backup_dirs.each do |dir|
          timestamp = File.basename(dir).sub("backup_", "")
          puts "  #{timestamp}"
        end
      else
        puts "  No backups found"
      end
      exit 1
    end
    
    backup_dir = UgcBackupService::BACKUP_ROOT.join("backup_#{backup_timestamp}")
    
    unless Dir.exist?(backup_dir)
      puts "❌ Error: Backup directory not found: #{backup_dir}"
      exit 1
    end
    
    puts "🔄 Starting UGC restoration from backup #{backup_timestamp}..."
    
    # Run restore service
    UgcRestoreService.new(backup_dir).restore_all
    
    puts "✅ UGC restoration completed!"
    puts "📊 Check the restoration report in the backup directory for details"
    puts "🎉 Reseed with UGC preservation complete!"
  end

  desc "Complete reseed workflow with UGC preservation: backup, reset in the given mode (float or clear), and restore after a clear reset"
  task :full_reseed, [:mode] => :environment do |t, args|
    mode = args[:mode] || "float"
    unless UgcResetService::MODES.include?(mode)
      puts "❌ Unknown mode #{mode.inspect}. Use: rails \"ugc:full_reseed[float]\" or rails \"ugc:full_reseed[clear]\""
      exit 1
    end

    puts "🚀 Starting complete reseed workflow with UGC preservation (#{mode} mode)..."
    puts ""
    
    # Step 1: Backup
    puts "📋 Step 1: Backing up UGC data..."
    Rake::Task["ugc:backup"].invoke
    
    # Get the backup timestamp from the most recent backup
    backup_dirs = Dir.glob(UgcBackupService::BACKUP_ROOT.join("backup_*"))
    latest_backup = backup_dirs.max_by { |dir| File.ctime(dir) }
    backup_timestamp = File.basename(latest_backup).sub("backup_", "")
    
    puts ""
    puts "📋 Step 2: Resetting core models..."
    
    # Step 2: Reset (with confirmation)
    print "Proceed with core model reset? (yes/no): "
    confirmation = $stdin.gets.chomp.downcase
    
    unless ['yes', 'y'].include?(confirmation)
      puts "❌ Full reseed cancelled after backup."
      puts "🔧 Backup is available at: #{latest_backup}"
      exit 0
    end
    
    # Clear the reset task so it can be invoked again
    Rake::Task["ugc:reset_core_models"].reenable
    Rake::Task["ugc:reset_core_models"].invoke(mode)

    if mode == "float"
      # Float mode kept the UGC rows, so restoring would add copies next to them
      puts ""
      puts "🎉 Reseed finished. UGC was kept in place (float mode), so the restore step was skipped."
      puts "🔧 Backup is available at: #{latest_backup}"
      next
    end

    puts ""
    puts "📋 Step 3: Restoring UGC data..."
    
    # Step 3: Restore
    # Clear the restore task so it can be invoked again  
    Rake::Task["ugc:restore"].reenable
    Rake::Task["ugc:restore"].invoke(backup_timestamp)
    
    puts ""
    puts "🎉 Complete reseed workflow finished successfully!"
    puts "📊 Check reports in tmp/ and backup directory for details"
  end

  desc "List available UGC backups"
  task list_backups: :environment do
    backup_dirs = Dir.glob(UgcBackupService::BACKUP_ROOT.join("backup_*"))
    
    if backup_dirs.empty?
      puts "No UGC backups found."
      next
    end
    
    puts "Available UGC backups:"
    puts ""
    
    backup_dirs.sort.reverse.each do |dir|
      timestamp = File.basename(dir).sub("backup_", "")
      created_at = File.ctime(dir)
      
      # Try to load backup metadata if available
      metadata_file = File.join(dir, "backup_metadata.yml")
      if File.exist?(metadata_file)
        begin
          metadata = UgcBackupService.read_metadata(dir)
          total_records = metadata["total_records"]
          seed_version = metadata["seed_version"]
          
          puts "📁 #{timestamp}"
          puts "   Created: #{created_at.strftime('%Y-%m-%d %H:%M:%S')}"
          puts "   Seed Version: #{seed_version}" if seed_version
          if total_records
            puts "   Records: #{total_records['aces']} aces, #{total_records['ratings']} ratings, #{total_records['quests']} quests"
          end
          puts ""
        rescue
          puts "📁 #{timestamp} (created: #{created_at.strftime('%Y-%m-%d %H:%M:%S')})"
          puts ""
        end
      else
        puts "📁 #{timestamp} (created: #{created_at.strftime('%Y-%m-%d %H:%M:%S')})"
        puts ""
      end
    end
    
    puts "To restore a backup: rails ugc:restore[timestamp]"
  end

  desc "Validate UGC preservation setup"
  task validate: :environment do
    puts "🔍 Validating UGC preservation setup..."
    puts ""
    
    # Check model classifications
    puts "Checking model classifications..."
    dependencies = UgcResetService.validate_dependencies
    puts ""
    
    # Check if backup directory exists
    backup_root = UgcBackupService::BACKUP_ROOT
    if Dir.exist?(backup_root)
      puts "✅ Backup directory exists: #{backup_root}"
    else
      puts "⚠️  Backup directory will be created: #{backup_root}"
    end
    puts ""
    
    # Check required services exist
    required_services = [
      "UgcBackupService",
      "UgcResetService", 
      "UgcRestoreService"
    ]
    
    puts "Checking required service classes..."
    required_services.each do |service_name|
      begin
        service_name.constantize
        puts "✅ #{service_name} available"
      rescue NameError
        puts "❌ #{service_name} not found - needs to be implemented"
      end
    end
    puts ""
    
    # Show current data counts
    puts "Current data counts:"
    puts "Core models:"
    UgcResetService::CORE_MODELS.each do |model|
      count = model.count rescue 0
      puts "  #{model.name}: #{count}"
    end
    puts ""
    puts "UGC models:"
    UgcResetService::UGC_MODELS.each do |model|
      count = model.count rescue 0
      puts "  #{model.name}: #{count}"
    end
    puts ""
    
    if dependencies.empty?
      puts "✅ UGC preservation setup looks good!"
      puts "🔧 Ready to run: rails ugc:backup"
    else
      puts "⚠️  Setup complete but foreign key dependencies detected."
      puts "🔧 Identifier-based remapping will be needed during restoration."
    end
  end

  desc "Clean up old UGC backups (keeps last 5)"
  task cleanup_backups: :environment do
    backup_dirs = Dir.glob(UgcBackupService::BACKUP_ROOT.join("backup_*"))
    
    if backup_dirs.length <= 5
      puts "Only #{backup_dirs.length} backups found. No cleanup needed."
      next
    end
    
    # Sort by creation time and keep the 5 most recent
    sorted_backups = backup_dirs.sort_by { |dir| File.ctime(dir) }
    backups_to_delete = sorted_backups[0...-5]  # All except last 5
    
    puts "Found #{backup_dirs.length} backups. Cleaning up #{backups_to_delete.length} oldest backups..."
    
    backups_to_delete.each do |backup_dir|
      timestamp = File.basename(backup_dir).sub("backup_", "")
      puts "🗑️  Deleting backup: #{timestamp}"
      FileUtils.rm_rf(backup_dir)
    end
    
    puts "✅ Cleanup completed. #{sorted_backups.last(5).length} backups retained."
  end

  desc "Show detailed backup information"
  task :backup_info, [:backup_timestamp] => :environment do |t, args|
    backup_timestamp = args[:backup_timestamp]
    
    unless backup_timestamp
      puts "❌ Error: Backup timestamp required"
      puts "Usage: rails ugc:backup_info[20241215_143022]"
      exit 1
    end
    
    backup_dir = UgcBackupService::BACKUP_ROOT.join("backup_#{backup_timestamp}")
    
    unless Dir.exist?(backup_dir)
      puts "❌ Error: Backup directory not found: #{backup_dir}"
      exit 1
    end
    
    puts "📋 Backup Information: #{backup_timestamp}"
    puts "📁 Location: #{backup_dir}"
    puts ""
    
    # Show file sizes
    ["aces_and_ratings.yml", "quest_system.yml", "game_attempts.yml", "backup_metadata.yml"].each do |filename|
      file_path = backup_dir.join(filename)
      if File.exist?(file_path)
        size_kb = (File.size(file_path) / 1024.0).round(2)
        puts "📄 #{filename}: #{size_kb} KB"
      else
        puts "❌ #{filename}: Missing"
      end
    end
    puts ""
    
    # Show metadata if available
    metadata_file = backup_dir.join("backup_metadata.yml")
    if File.exist?(metadata_file)
      begin
        metadata = UgcBackupService.read_metadata(backup_dir)
        puts "📊 Metadata:"
        puts "   Backup Time: #{metadata['backup_timestamp']}"
        puts "   Rails Env: #{metadata['rails_env']}"
        puts "   Seed Version: #{metadata['seed_version']}"
        puts ""
        puts "📈 Record Counts:"
        metadata['total_records'].each do |model, count|
          puts "   #{model.to_s.humanize}: #{count}"
        end
      rescue => e
        puts "⚠️  Could not read metadata: #{e.message}"
      end
    else
      puts "⚠️  No metadata file found"
    end
  end
end