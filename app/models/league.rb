class League < ApplicationRecord
  belongs_to :sport
  belongs_to :jurisdiction, polymorphic: true
  has_many :teams
  has_many :players, through: :teams
  has_many :stadia, through: :teams
  has_many :conferences, dependent: :destroy
  has_many :divisions, through: :conferences

  belongs_to :country,
             foreign_key: :jurisdiction_id,
             class_name: "Country",
             optional: true
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "jurisdiction_id", "jurisdiction_type", "name", "sport_id", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["conferences", "divisions", "jurisdiction", "players", "sport", "stadia", "teams"]
  end
end
