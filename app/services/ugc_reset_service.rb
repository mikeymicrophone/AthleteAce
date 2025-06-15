# UGC Reset Service Template
# Safely clears core sports hierarchy models while preserving UGC data

class UgcResetService
  # Define core models that will be reset (seeded data)
  CORE_MODELS = [
    # Sports hierarchy (top to bottom)
    Country, State, City, Stadium,
    Sport, League, Conference, Division, Team, Player,
    
    # Organizational structure
    Membership, Position, Role,
    
    # Time-based models
    Year, Season, Campaign, Contest, Contestant,
    
    # Contract system  
    Contract, Activation,
    
    # Other seeded models
    Federation
  ].freeze

  # UGC models that should NOT be reset
  UGC_MODELS = [
    Ace,           # User accounts
    Spectrum,      # Rating dimensions (could be core, but safer to preserve)
    Rating,        # User ratings
    Quest,         # User quests
    Achievement,   # Quest achievements
    Highlight,     # Quest-achievement relationships
    Goal,          # User quest progress
    GameAttempt    # Game interaction data
  ].freeze

  def initialize
    @reset_log = []
  end

  def reset_core_models
    Rails.logger.info "Starting core model reset..."
    
    validate_model_separation
    
    ActiveRecord::Base.transaction do
      disable_foreign_key_checks
      clear_core_models
      reset_sequences
      enable_foreign_key_checks
      
      # Run standard seeding
      run_seeding
    end
    
    generate_reset_report
    Rails.logger.info "Core model reset completed"
  end

  private

  def validate_model_separation
    # Ensure no overlap between core and UGC models
    overlap = CORE_MODELS & UGC_MODELS
    if overlap.any?
      raise "Model classification conflict: #{overlap.join(', ')} appear in both CORE_MODELS and UGC_MODELS"
    end
    
    # Warn about models not explicitly classified
    all_models = ApplicationRecord.descendants.select { |model| model.table_exists? }
    unclassified = all_models - CORE_MODELS - UGC_MODELS
    
    if unclassified.any?
      Rails.logger.warn "Unclassified models (will be preserved): #{unclassified.map(&:name).join(', ')}"
    end
  end

  def disable_foreign_key_checks
    # Temporarily disable foreign key constraints for bulk deletion
    case ActiveRecord::Base.connection.adapter_name.downcase
    when 'postgresql'
      ActiveRecord::Base.connection.execute("SET session_replication_role = 'replica';")
    when 'mysql', 'mysql2'
      ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 0;")
    when 'sqlite', 'sqlite3'
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = OFF;")
    end
  end

  def enable_foreign_key_checks
    # Re-enable foreign key constraints
    case ActiveRecord::Base.connection.adapter_name.downcase
    when 'postgresql'
      ActiveRecord::Base.connection.execute("SET session_replication_role = 'origin';")
    when 'mysql', 'mysql2'
      ActiveRecord::Base.connection.execute("SET FOREIGN_KEY_CHECKS = 1;")
    when 'sqlite', 'sqlite3'
      ActiveRecord::Base.connection.execute("PRAGMA foreign_keys = ON;")
    end
  end

  def clear_core_models
    # Clear models in reverse dependency order to minimize FK constraint issues
    CORE_MODELS.reverse.each do |model|
      begin
        record_count = model.count
        model.delete_all
        log_model_reset(model, record_count)
        Rails.logger.info "Cleared #{record_count} records from #{model.table_name}"
      rescue => e
        Rails.logger.error "Failed to clear #{model.table_name}: #{e.message}"
        raise e
      end
    end
  end

  def reset_sequences
    # Reset auto-increment sequences for cleared models
    CORE_MODELS.each do |model|
      begin
        ActiveRecord::Base.connection.reset_pk_sequence!(model.table_name)
        Rails.logger.debug "Reset sequence for #{model.table_name}"
      rescue => e
        Rails.logger.warn "Could not reset sequence for #{model.table_name}: #{e.message}"
        # Non-fatal - continue with reset
      end
    end
  end

  def run_seeding
    Rails.logger.info "Running database seeding..."
    
    # Capture seeding output
    original_stdout = $stdout
    seed_output = StringIO.new
    $stdout = seed_output
    
    begin
      Rails.application.load_seed
      Rails.logger.info "Database seeding completed successfully"
    rescue => e
      Rails.logger.error "Database seeding failed: #{e.message}"
      raise e
    ensure
      $stdout = original_stdout
      @seed_output = seed_output.string
    end
  end

  def log_model_reset(model, record_count)
    @reset_log << {
      model_name: model.name,
      table_name: model.table_name,
      records_cleared: record_count,
      timestamp: Time.current
    }
  end

  def generate_reset_report
    report_path = Rails.root.join("tmp", "core_model_reset_#{Time.current.strftime('%Y%m%d_%H%M%S')}.yml")
    
    # Calculate new record counts after seeding
    new_counts = CORE_MODELS.map do |model|
      { model.name => model.count }
    end.reduce(&:merge)
    
    preserved_counts = UGC_MODELS.map do |model|
      { model.name => model.count }
    end.reduce(&:merge)
    
    report = {
      reset_timestamp: Time.current,
      core_models_reset: CORE_MODELS.map(&:name),
      ugc_models_preserved: UGC_MODELS.map(&:name),
      reset_details: @reset_log,
      new_record_counts: new_counts,
      preserved_record_counts: preserved_counts,
      total_core_records_cleared: @reset_log.sum { |entry| entry[:records_cleared] },
      total_ugc_records_preserved: preserved_counts.values.sum,
      seed_output: @seed_output
    }
    
    File.write(report_path, report.to_yaml)
    Rails.logger.info "Reset report written to #{report_path}"
    
    # Log summary
    Rails.logger.info "Reset Summary:"
    Rails.logger.info "  - Core models reset: #{CORE_MODELS.size}"
    Rails.logger.info "  - UGC models preserved: #{UGC_MODELS.size}"
    Rails.logger.info "  - Records cleared: #{report[:total_core_records_cleared]}"
    Rails.logger.info "  - Records preserved: #{report[:total_ugc_records_preserved]}"
    Rails.logger.info "  - New records seeded: #{new_counts.values.sum}"
  end

  # === VALIDATION HELPERS ===

  def self.validate_dependencies
    puts "Analyzing UGC model dependencies..."
    puts ""
    
    # Find polymorphic associations that will need identifier-based remapping
    polymorphic_dependencies = []
    direct_fk_dependencies = []
    
    UGC_MODELS.each do |ugc_model|
      ugc_model.reflect_on_all_associations(:belongs_to).each do |association|
        if association.polymorphic?
          # Get actual target types from database
          target_types = get_polymorphic_target_types(ugc_model, association)
          core_target_types = target_types.select { |type| 
            begin
              klass = type.constantize
              CORE_MODELS.include?(klass)
            rescue NameError
              false
            end
          }
          
          if core_target_types.any?
            polymorphic_dependencies << {
              ugc_model: ugc_model.name,
              association: association.name,
              all_target_types: target_types,
              core_target_types: core_target_types,
              record_count: ugc_model.where.not("#{association.name}_type" => nil).count
            }
          end
        else
          # Regular association - check if it points to core model
          begin
            target_class = association.klass
            if CORE_MODELS.include?(target_class)
              direct_fk_dependencies << {
                ugc_model: ugc_model.name,
                association: association.name,
                core_model: target_class.name,
                record_count: ugc_model.where.not("#{association.name}_id" => nil).count
              }
            end
          rescue NameError
            # Skip associations that can't be resolved
            next
          end
        end
      end
    end
    
    # Report polymorphic associations (these are expected and handled)
    if polymorphic_dependencies.any?
      puts "🔗 Polymorphic associations requiring identifier-based remapping:"
      polymorphic_dependencies.each do |dep|
        puts "  #{dep[:ugc_model]}.#{dep[:association]} (#{dep[:record_count]} records)"
        puts "    Target types: #{dep[:all_target_types].join(', ')}"
        puts "    Core models: #{dep[:core_target_types].join(', ')}"
        puts ""
      end
    else
      puts "✓ No polymorphic associations to core models found."
      puts ""
    end
    
    # Report direct FK dependencies (these are higher risk)
    if direct_fk_dependencies.any?
      puts "⚠️  Direct FK dependencies to core models:"
      direct_fk_dependencies.each do |dep|
        puts "  #{dep[:ugc_model]}.#{dep[:association]} -> #{dep[:core_model]} (#{dep[:record_count]} records)"
      end
      puts "These require identifier-based remapping during restoration."
      puts ""
    else
      puts "✓ No direct FK dependencies to core models detected."
      puts ""
    end
    
    # Validate identifier coverage
    validate_identifier_coverage(polymorphic_dependencies, direct_fk_dependencies)
    
    { polymorphic: polymorphic_dependencies, direct: direct_fk_dependencies }
  end

  def self.get_polymorphic_target_types(model, association)
    # Query the database to see what types are actually used
    type_column = "#{association.name}_type"
    model.distinct.pluck(type_column).compact.sort
  end

  def self.validate_identifier_coverage(polymorphic_deps, direct_deps)
    puts "🔍 Validating identifier remapping coverage..."
    
    # Get all target types that need identifier support
    all_target_types = Set.new
    
    polymorphic_deps.each do |dep|
      all_target_types.merge(dep[:core_target_types])
    end
    
    direct_deps.each do |dep|
      all_target_types.add(dep[:core_model])
    end
    
    # Check if UgcBackupService can handle each target type
    missing_identifier_support = []
    missing_remapping_support = []
    
    all_target_types.each do |target_type|
      # Check if build_target_identifier handles this type
      has_identifier_support = check_identifier_support(target_type)
      has_remapping_support = check_remapping_support(target_type)
      
      missing_identifier_support << target_type unless has_identifier_support
      missing_remapping_support << target_type unless has_remapping_support
    end
    
    if missing_identifier_support.any?
      puts "❌ Missing identifier building support for: #{missing_identifier_support.join(', ')}"
    end
    
    if missing_remapping_support.any?
      puts "❌ Missing remapping support for: #{missing_remapping_support.join(', ')}"
    end
    
    if missing_identifier_support.empty? && missing_remapping_support.empty?
      puts "✅ All target types have identifier and remapping support!"
    end
    
    puts ""
  end

  def self.check_identifier_support(target_type)
    # Check if UgcBackupService.build_target_identifier has a case for this type
    service_file = Rails.root.join("app/services/ugc_backup_service.rb")
    return false unless File.exist?(service_file)
    
    content = File.read(service_file)
    content.include?("when #{target_type}")
  end

  def self.check_remapping_support(target_type)
    # Check if UgcRestoreService.find_target_by_identifiers has a case for this type
    service_file = Rails.root.join("app/services/ugc_restore_service.rb")
    return false unless File.exist?(service_file)
    
    content = File.read(service_file)
    content.include?("when \"#{target_type}\"")
  end

  def self.preview_reset
    # Show what would be reset without actually doing it
    puts "Core models that would be reset:"
    CORE_MODELS.each do |model|
      count = model.count rescue 0
      puts "  #{model.name}: #{count} records"
    end
    
    puts "\nUGC models that would be preserved:"
    UGC_MODELS.each do |model|
      count = model.count rescue 0
      puts "  #{model.name}: #{count} records"
    end
    
    puts "\nTo proceed with reset: UgcResetService.new.reset_core_models"
  end
end