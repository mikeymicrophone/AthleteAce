class Campaign < ApplicationRecord
  belongs_to :team
  belongs_to :season
  
  has_one :league, through: :season
  has_one :sport, through: :league
  
  validates :team_id, presence: true
  validates :season_id, presence: true
  validates :team_id, uniqueness: { scope: :season_id }
  
  def self.ransackable_attributes auth_object = nil
    column_names
  end
  
  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end