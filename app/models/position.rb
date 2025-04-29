class Position < ApplicationRecord
  belongs_to :sport
  has_many :roles, dependent: :destroy
  has_many :players, through: :roles
  
  validates :name, presence: true
  validates :name, uniqueness: { scope: :sport_id, message: "already exists for this sport" }
  
  def to_s
    name
  end
end
