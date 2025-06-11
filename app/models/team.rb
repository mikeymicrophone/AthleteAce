class Team < ApplicationRecord
  include Ratable
  
  belongs_to :league
  belongs_to :stadium, optional: true
  has_many :players
  has_many :memberships, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_one :active_membership, -> { where(active: true) }, class_name: 'Membership'
  has_one :division, through: :active_membership
  has_one :conference, through: :division
  
  delegate :sport, to: :league
  delegate :city, :state, :country, to: :stadium

  def name
    "#{territory} #{mascot}"
  end
  alias :full_name :name
  
  
  # Define which attributes can be searched via Ransack
  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "league_id", "mascot", "stadium_id", "territory", "updated_at"]
  end
  
  # Define which associations can be searched via Ransack
  def self.ransackable_associations(auth_object = nil)
    ["active_membership", "campaigns", "conference", "division", "league", "memberships", "players", "ratings", "stadium"]
  end
end
