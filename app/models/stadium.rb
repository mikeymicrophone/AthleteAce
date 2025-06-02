class Stadium < ApplicationRecord
  belongs_to :city
  has_many :teams
  has_many :players, through: :teams
  has_many :leagues, through: :teams

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
