class Contest < ApplicationRecord
  belongs_to :context, polymorphic: true
  belongs_to :champion, class_name: 'Team', optional: true
  belongs_to :season, optional: true
  has_one :championship_season, class_name: "Season", foreign_key: :championship_contest_id

  has_many :contestants, dependent: :destroy
  has_many :campaigns, through: :contestants
  has_many :teams, through: :campaigns
  has_many :leagues, -> { distinct }, through: :teams
  has_many :conferences, -> { distinct }, through: :teams
  has_many :divisions, -> { distinct }, through: :teams
  has_many :countries, -> { distinct }, through: :leagues, source: :jurisdiction, source_type: "Country"
  
  serialize :comments, coder: JSON
  
  def winner
    contestants.winners.first
  end
  
  def runner_up
    contestants.runner_ups.first
  end
  
  def final_standings
    contestants.by_placing
  end
end
