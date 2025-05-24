class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :seeded, -> { where.not(seed_version: nil) }
end
