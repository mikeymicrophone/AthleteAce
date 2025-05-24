class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  
  # Applies seed versioning to all database operations within the block
  # This method delegates to SeedHelpers.with_seed_version
  # 
  # Example usage:
  #   SEED_VERSION = "001.2025.05.23"
  #   ApplicationRecord.with_seed_version(SEED_VERSION) do
  #     Sport.find_or_create_by(name: "Basketball")
  #     # All creates/updates automatically get seed_version and last_seeded_at
  #   end
  # def self.with_seed_version(version, &block)
  #   require 'seed_helpers'
  #   SeedHelpers.with_seed_version(version, &block)
  # end
end
