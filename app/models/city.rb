class City < ApplicationRecord
  belongs_to :state
  has_many :players, foreign_key: :birth_city_id
  has_many :stadiums
  has_many :teams, through: :stadiums
  has_many :memberships, through: :teams
  has_many :divisions, through: :memberships
  has_many :conferences, through: :divisions
  has_many :leagues, through: :conferences
  has_many :sports, through: :leagues
  has_many :campaigns, through: :teams
  has_many :contests, through: :campaigns
  has_many :contracts, through: :teams
  has_many :activations, through: :contracts

  delegate :country, to: :state
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes(auth_object = nil)
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
