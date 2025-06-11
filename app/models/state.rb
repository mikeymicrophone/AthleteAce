class State < ApplicationRecord
  belongs_to :country
  has_many :cities
  has_many :players, through: :cities
  has_many :stadiums, through: :cities
  has_many :teams, through: :cities
  has_many :memberships, through: :teams
  has_many :divisions, through: :memberships
  has_many :conferences, through: :divisions
  has_many :leagues, through: :conferences
  has_many :sports, through: :leagues
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
