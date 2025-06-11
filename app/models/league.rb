class League < ApplicationRecord
  belongs_to :sport
  belongs_to :jurisdiction, polymorphic: true
  has_many :conferences, dependent: :destroy
  has_many :divisions, through: :conferences
  has_many :memberships, through: :divisions
  has_many :teams, through: :memberships
  has_many :players, through: :teams
  has_many :stadiums, through: :teams
  
  belongs_to :country, foreign_key: :jurisdiction_id, class_name: "Country", optional: true
  
  def self.ransackable_attributes(auth_object = nil)
    column_names
  end
  
  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
