class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  # Applies seed versioning to all database operations within the block
  # Example usage:
  #   SEED_VERSION = "001.2025.05.23"
  #   ApplicationRecord.with_seed_version(SEED_VERSION) do
  #     Sport.find_or_create_by(name: "Basketball")
  #     # All creates/updates automatically get seed_version and last_seeded_at
  #   end
  def self.with_seed_version(version, &block)
    seed_time = Time.current
    
    # Define attributes to be applied automatically
    seed_attributes = { seed_version: version, last_seeded_at: seed_time }
    
    # Use unscoped to ensure we're not affected by any existing scopes
    unscoped do
      # Apply the seed attributes to all create operations
      with_scope(create: { defaults: seed_attributes }) do
        # Also ensure updates include the seed information
        # This affects methods like update, update_all, etc.
        scope = current_scope || all
        
        # Store original method to be restored later
        original_update = scope.singleton_class.instance_method(:update_all)
        
        # Override update_all to include seed attributes
        scope.singleton_class.define_method(:update_all) do |updates|
          merged_updates = updates.merge(seed_attributes)
          original_update.bind_call(self, merged_updates)
        end
        
        begin
          # Execute the seeding block
          yield
        ensure
          # Restore original update_all method
          scope.singleton_class.define_method(:update_all, original_update)
        end
      end
    end
  end
end
