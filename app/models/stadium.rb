class Stadium < ApplicationRecord
  belongs_to :city
  has_many :teams
  has_many :players, through: :teams
  has_many :sports, through: :teams
  has_many :memberships, through: :teams
  has_many :divisions, through: :memberships
  has_many :conferences, through: :divisions
  has_many :leagues, through: :conferences
  has_many :seasons, through: :leagues
  has_many :campaigns, through: :teams
  has_many :contracts, through: :teams
  has_many :contests, through: :teams # this should be through games eventually
  has_many :activations, through: :contracts

  delegate :state, :country, to: :city
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes(auth_object = nil)
    # Returns all attributes of the model
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations(auth_object = nil)
    # Returns all reflections (associations) of the model
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
