class Country < ApplicationRecord
  has_many :states
  has_many :cities, through: :states
  has_many :stadiums, through: :cities
  has_many :leagues, as: :jurisdiction
  has_many :sports, through: :leagues
  has_many :teams, through: :leagues
  has_many :players, through: :teams
  has_many :conferences, through: :leagues
  has_many :divisions, through: :leagues
  has_many :memberships, through: :divisions
  has_many :campaigns, through: :teams
  has_many :contests, through: :campaigns

  def self.ransackable_attributes auth_object = nil
    column_names
  end

  def self.ransackable_associations auth_object = nil
    reflect_on_all_associations.map { |a| a.name.to_s }
  end
end
