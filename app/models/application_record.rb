class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :seeded, -> { where.not(seed_version: nil) }
  
  def self.is_ratable?
    false
  end
  
  def is_ratable?
    self.class.is_ratable?
  end
end
