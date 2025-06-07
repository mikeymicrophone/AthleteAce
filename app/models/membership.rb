class Membership < ApplicationRecord
  belongs_to :team
  belongs_to :division
  
  has_one :conference, through: :division
  has_one :league, through: :conference
  has_one :sport, through: :league

  validates :team_id, presence: true
  validates :division_id, presence: true
  
  scope :active, -> { where(active: true) }
  
  def conference
    division.conference
  end
  
  def league
    division.conference.league
  end
  
  # Allow all attributes to be searchable with Ransack
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  # Allow all associations to be searchable with Ransack
  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
