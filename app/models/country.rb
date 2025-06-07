class Country < ApplicationRecord
  has_many :states
  has_many :cities, through: :states
  has_many :stadiums, through: :cities
  has_many :leagues, as: :jurisdiction
  has_many :players, through: :leagues
  has_many :teams, through: :leagues
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes(auth_object = nil)
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
