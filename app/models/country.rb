class Country < ApplicationRecord
  has_many :states
  has_many :cities, through: :states
  has_many :stadiums, through: :cities
  has_many :leagues, as: :jurisdiction
  has_many :players, through: :leagues
  has_many :teams, through: :leagues
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["abbreviation", "created_at", "flag_url", "id", "name", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["cities", "leagues", "players", "stadiums", "states", "teams"]
  end
end
