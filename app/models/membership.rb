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
end
