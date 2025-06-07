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
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes(auth_object = nil)
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
