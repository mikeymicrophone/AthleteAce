class Position < ApplicationRecord
  belongs_to :sport
  has_many :roles, dependent: :destroy
  has_many :players, through: :roles
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :sport_id, message: "already exists for this sport" }
  
  def to_s
    name
  end
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["abbreviation", "created_at", "description", "id", "name", "sport_id", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["players", "roles", "sport"]
  end
end
