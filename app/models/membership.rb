class Membership < ApplicationRecord
  belongs_to :team
  belongs_to :division
  
  validates :team_id, presence: true
  validates :division_id, presence: true
  
  scope :active, -> { where(active: true) }
  
  def conference
    division.conference
  end
  
  def league
    division.conference.league
  end
end
