class Country < ApplicationRecord
  has_many :states
  has_many :cities, through: :states
  has_many :stadia, through: :cities
  has_many :leagues, as: :jurisdiction
  has_many :players, through: :leagues
  has_many :teams, through: :leagues
end
