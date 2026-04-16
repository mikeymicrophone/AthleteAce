class Team < ApplicationRecord
  include Ratable
  
  belongs_to :league
  belongs_to :stadium, optional: true
  has_many :players
  has_many :contracts, dependent: :destroy
  has_many :contract_players, through: :contracts, source: :player
  has_many :organization_affiliations, dependent: :destroy
  has_many :organizations, through: :organization_affiliations
  has_one :current_organization_affiliation, -> { current.order(start_date: :desc, created_at: :desc) }, class_name: "OrganizationAffiliation"
  has_one :current_organization, through: :current_organization_affiliation, source: :organization
  has_many :memberships, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_one :active_membership, -> { where(active: true) }, class_name: 'Membership'
  has_one :division, through: :active_membership
  has_one :conference, through: :division
  has_many :campaigns
  has_many :contestants, through: :campaigns
  has_many :contests, through: :contestants
  
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
    ["active_membership", "campaigns", "conference", "current_organization", "current_organization_affiliation", "division", "league", "memberships", "organization_affiliations", "organizations", "players", "ratings", "stadium"]
  end
end
