class City < ApplicationRecord
  belongs_to :state
  has_many :players, foreign_key: :birth_city_id
  has_many :stadiums
  has_many :teams, through: :stadiums

  delegate :country, to: :state
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "name", "state_id", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["players", "stadiums", "state", "teams"]
  end
end
